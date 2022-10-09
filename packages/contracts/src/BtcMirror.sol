// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Endian.sol";
import "./interfaces/IBtcMirror.sol";

//
//                                        #
//                                       # #
//                                      # # #
//                                     # # # #
//                                    # # # # #
//                                   # # # # # #
//                                  # # # # # # #
//                                 # # # # # # # #
//                                # # # # # # # # #
//                               # # # # # # # # # #
//                              # # # # # # # # # # #
//                                   # # # # # #
//                               +        #        +
//                                ++++         ++++
//                                  ++++++ ++++++
//                                    +++++++++
//                                      +++++
//                                        +
//
// BtcMirror lets you prove that a BTC transaction executed, on Ethereum. In
// other words, it lets other Ethereum contracts run Simple Payment
// Verification (SPV) on BTC transactions.
//
// Anyone can submit block headers to BtcMirror. The contract verifies
// proof-of-work, keeping only the longest chain it has seen. As long as 50% of
// Bitcoin hash power is honest and at least one person is running the submitter
// script, the BtcMirror contract always reports the current canonical Bitcoin
// chain.
contract BtcMirror is IBtcMirror {
    /**
     * Emitted whenever the contract accepts a new heaviest chain.
     */
    event NewTip(uint256 blockHeight, uint256 blockTime, bytes32 blockHash);

    /**
     * Emitted only right after a difficulty retarget, when the contract
     * accepts a new heaviest chain with updated difficulty.
     */
    event NewTotalDifficultySinceRetarget(
        uint256 blockHeight,
        uint256 totalDifficulty,
        uint32 newDifficultyBits
    );

    /**
     * Emitted when we reorg out a portion of the chain.
     */
    event Reorg(uint256 count, bytes32 oldTip, bytes32 newTip);

    uint256 private latestBlockHeight;

    uint256 private latestBlockTime;

    mapping(uint256 => bytes32) private blockHeightToHash;

    mapping(uint256 => uint256) private periodToTarget;

    uint256 public longestReorg;

    bool public immutable isTestnet;

    constructor(
        uint256 _blockHeight,
        bytes32 _blockHash,
        uint256 _blockTime,
        uint256 _expectedTarget,
        bool _isTestnet
    ) {
        blockHeightToHash[_blockHeight] = _blockHash;
        latestBlockHeight = _blockHeight;
        latestBlockTime = _blockTime;
        periodToTarget[_blockHeight / 2016] = _expectedTarget;
        isTestnet = _isTestnet;
    }

    /**
     * Returns the Bitcoin block hash at a specific height.
     */
    function getBlockHash(uint256 number) public view returns (bytes32) {
        return blockHeightToHash[number];
    }

    /**
     * Returns the height of the last submitted canonical Bitcoin chain.
     */
    function getLatestBlockHeight() public view returns (uint256) {
        return latestBlockHeight;
    }

    /**
     * Returns the timestamp of the last submitted canonical Bitcoin chain.
     */
    function getLatestBlockTime() public view returns (uint256) {
        return latestBlockTime;
    }

    /**
     * Submits a new Bitcoin chain segment. Must be heavier (not necessarily
     * longer) than the chain rooted at getBlockHash(getLatestBlockHeight()f).
     */
    function submit(uint256 blockHeight, bytes calldata blockHeaders) public {
        uint256 numHeaders = blockHeaders.length / 80;
        require(numHeaders * 80 == blockHeaders.length, "wrong header length");
        require(numHeaders > 0, "must submit at least one block");

        // sanity check: the new chain must end in a past difficulty period
        // (BtcMirror does not support a 2-week reorg)
        uint256 oldPeriod = latestBlockHeight / 2016;
        uint256 newHeight = blockHeight + numHeaders - 1;
        uint256 newPeriod = newHeight / 2016;
        require(newPeriod >= oldPeriod, "old difficulty period");

        uint256 parentPeriod = (blockHeight - 1) / 2016;
        uint256 oldWork = 0;
        if (newPeriod > parentPeriod) {
            assert(newPeriod == parentPeriod + 1);
            // the submitted chain segment contains a difficulty retarget.
            if (newPeriod == oldPeriod) {
                // the old canonical chain is past the retarget
                // we cannot compare length, we must compare total work
                oldWork =
                    ((latestBlockHeight % 2016) + 1) *
                    getWPerBlock(oldPeriod);
            } else {
                // the old canonical chain is before the retarget
                assert(oldPeriod == parentPeriod);
            }
        }

        // submit each block
        bytes32 oldTip = getBlockHash(latestBlockHeight);
        uint256 nReorg = 0;
        for (uint256 i = 0; i < numHeaders; i++) {
            uint256 blockNum = blockHeight + i;
            nReorg += submitBlock(blockNum, blockHeaders[80 * i:80 * (i + 1)]);
        }

        // check that we have a new longest chain = heaviest chain
        if (newPeriod > parentPeriod) {
            // the submitted chain segment crosses into a new difficulty
            // period. this is only happens once every ~2 weeks and requires
            // some extra bookkeeping
            bytes calldata lastHeader = blockHeaders[80 * (numHeaders - 1):];
            uint32 newDifficultyBits = Endian.reverse32(
                uint32(bytes4(lastHeader[72:76]))
            );

            uint256 newWork = ((newHeight % 2016) + 1) *
                getWPerBlock(newPeriod);
            require(newWork > oldWork, "insufficient difficulty");

            emit NewTotalDifficultySinceRetarget(
                newHeight,
                newWork,
                newDifficultyBits
            );
        } else {
            // here we know what newPeriod == oldPeriod == parentPeriod
            // the per-block difficulty hasn't changed. keep longest chain.
            assert(newPeriod == oldPeriod);
            assert(newPeriod == parentPeriod);
            require(newHeight > latestBlockHeight, "insufficient chain length");
        }

        // erase any block hashes above newHeight, now invalidated.
        for (uint256 i = newHeight + 1; i <= latestBlockHeight; i++) {
            blockHeightToHash[i] = 0;
        }

        // track timestamps
        latestBlockHeight = newHeight;
        uint256 ixT = blockHeaders.length - 12;
        uint32 time = uint32(bytes4(blockHeaders[ixT:ixT + 4]));
        latestBlockTime = Endian.reverse32(time);

        bytes32 newTip = getBlockHash(newHeight);
        emit NewTip(newHeight, latestBlockTime, newTip);
        if (nReorg > 0) {
            emit Reorg(nReorg, oldTip, newTip);
        }
    }

    function getWPerBlock(uint256 period) private view returns (uint256) {
        uint256 target = periodToTarget[period];
        return (2**256 - 1) / target;
    }

    function submitBlock(uint256 blockHeight, bytes calldata blockHeader)
        private
        returns (uint256 numReorged)
    {
        // compute the block hash
        assert(blockHeader.length == 80);
        uint256 blockHashNum = Endian.reverse256(
            uint256(sha256(abi.encode(sha256(blockHeader))))
        );

        // optimistically save the block hash
        // we'll revert if the header turns out to be invalid
        bytes32 oldHash = blockHeightToHash[blockHeight];
        bytes32 newHash = bytes32(blockHashNum);
        if (oldHash != bytes32(0) && oldHash != newHash) {
            numReorged = 1;
        }
        // this is the most expensive line. 20k gas to use a new storage slot
        blockHeightToHash[blockHeight] = newHash;

        // verify previous hash
        bytes32 prevHash = bytes32(
            Endian.reverse256(uint256(bytes32(blockHeader[4:36])))
        );
        require(prevHash == blockHeightToHash[blockHeight - 1], "bad parent");
        require(prevHash != bytes32(0), "parent block not yet submitted");

        // verify proof-of-work
        bytes32 bits = bytes32(blockHeader[72:76]);
        uint256 target = getTarget(bits);
        require(blockHashNum < target, "block hash above target");

        // ignore difficulty update rules on testnet
        // Bitcoin testnet has some clown hacks regarding difficulty:
        // https://blog.lopp.net/the-block-storms-of-bitcoins-testnet/
        if (isTestnet) {
            return numReorged;
        }

        // support once-every-2016-blocks retargeting
        uint256 period = blockHeight / 2016;
        if (blockHeight % 2016 == 0) {
            // Bitcoin enforces a minimum difficulty of 25% of the previous
            // difficulty. Doing the full calculation here does not necessarily
            // add any security. We keep the heaviest chain, not the longest.
            uint256 lastTarget = periodToTarget[period - 1];
            require(target >> 2 < lastTarget, "<25% difficulty retarget");
            periodToTarget[period] = target;
        } else {
            require(target == periodToTarget[period], "wrong difficulty bits");
        }
    }

    function getTarget(bytes32 bits) public pure returns (uint256) {
        uint256 exp = uint8(bits[3]);
        uint256 mantissa = uint8(bits[2]);
        mantissa = (mantissa << 8) | uint8(bits[1]);
        mantissa = (mantissa << 8) | uint8(bits[0]);
        uint256 target = mantissa << (8 * (exp - 3));
        return target;
    }
}
