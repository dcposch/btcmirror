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

    uint256 private latestBlockHeight;

    uint256 private latestBlockTime;

    mapping(uint256 => bytes32) private blockHeightToHash;

    mapping(uint256 => uint256) private blockHeightToTotalDifficulty;

    uint256 private expectedTarget;

    bool public isTestnet;

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
        expectedTarget = _expectedTarget;
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
     * longer) than the chain rooted at getBlockHash(getLatestBlockHeight()).
     */
    function submit(uint256 blockHeight, bytes calldata blockHeaders) public {
        uint256 numHeaders = blockHeaders.length / 80;
        require(numHeaders * 80 == blockHeaders.length, "wrong header length");
        require(numHeaders > 0, "must submit at least one block");

        uint256 newHeight = blockHeight + numHeaders - 1;
        uint256 startP = blockHeight / 2016;
        uint256 endP = newHeight / 2016;
        uint256 lastP = latestBlockHeight / 2016;
        if (startP == lastP && endP == lastP) {
            // new segment entirely in SAME retarget period.
            // simply check that we have a new longest chain = heaviest chain
            require(newHeight > latestBlockHeight, "chain segment too short");
            for (uint256 i = 0; i < numHeaders; i++) {
                submitBlock(blockHeight + i, blockHeaders[80 * i:80 * (i + 1)]);
            }
        } else {
            // new segment STARTS from PREV or CURRENT retarget period.
            require(startP >= lastP - 1, "ancient retarget period");
            require(endP >= lastP, "chain segment ends in old retarget period");
            uint256 lastRetargetH = endP * 2016;

            // this is the trickiest part of BtcMirror.
            // we have crossed a retargetting period. we want to gas efficiently
            // allow a SHORTER but HEAVIER chain to replace a LONG, LIGHTER one.
            // (otherwise, our 50% honest assumption degrades to 80% honest, as
            // a colluding 21% can simply withold their hashpower for a whole
            // 2-week retarget period, then mine a far-future spoof block at the
            // very end, setting the difficulty to the minimum 25% of previous.
            // then, as they are over 25% of the honest hashpower, they outrun
            // the honest chain on length and fool BtcMirror.)
            //
            // we avoid this by calculating total difficulty since retarget.
            uint256 oldTotalSince = 0;
            uint256 MAX = ~uint256(0);
            if (lastP == endP) {
                uint256 oldNSince = latestBlockHeight - lastRetargetH + 1;
                oldTotalSince = oldNSince * (MAX / expectedTarget);
            }

            for (uint256 i = 0; i < numHeaders; i++) {
                submitBlock(blockHeight + i, blockHeaders[80 * i:80 * (i + 1)]);
            }

            uint256 newNSince = newHeight - lastRetargetH + 1;
            uint256 newTotal = newNSince * (MAX / expectedTarget);
            require(newTotal > oldTotalSince, "total difficulty too low");
            uint256 ixB = blockHeaders.length - 8;
            uint32 newBits = Endian.reverse32(
                uint32(bytes4(blockHeaders[ixB:ixB + 4]))
            );
            emit NewTotalDifficultySinceRetarget(newHeight, newTotal, newBits);

            // erase any block hashes above newHeight, now invalidated.
            for (uint256 i = newHeight + 1; i <= latestBlockHeight; i++) {
                blockHeightToHash[i] = 0;
            }
        }

        latestBlockHeight = newHeight;
        uint256 ixT = blockHeaders.length - 12;
        uint32 time = uint32(bytes4(blockHeaders[ixT:ixT + 4]));
        latestBlockTime = Endian.reverse32(time);

        emit NewTip(newHeight, latestBlockTime, getBlockHash(newHeight));
    }

    function submitBlock(uint256 blockHeight, bytes calldata blockHeader)
        private
    {
        // compute the block hash
        assert(blockHeader.length == 80);
        uint256 blockHashNum = Endian.reverse256(
            uint256(sha256(abi.encode(sha256(blockHeader))))
        );

        // optimistically save the block hash
        // we'll revert if the header turns out to be invalid
        blockHeightToHash[blockHeight] = bytes32(blockHashNum);

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
            return;
        }

        // support once-every-2016-blocks retargeting
        if (blockHeight % 2016 == 0) {
            // Bitcoin enforces a minimum difficulty of 25% of the previous
            // difficulty. Doing the full calculation here does not necessarily
            // add any security. We keep the heaviest chain, not the longest.
            require(target >> 2 < expectedTarget, "<25% difficulty retarget");
            expectedTarget = target;
        } else {
            require(target == expectedTarget, "wrong difficulty bits");
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
