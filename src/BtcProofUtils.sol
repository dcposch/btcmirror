// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

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
// BtcProofUtils provides functions to prove things about Bitcoin transactions.
// Verifies Merkle inclusion proofs, tx IDs, and payment details.
library BtcProofUtils {
    function getBlockHash(bytes calldata blockHeader)
        public
        pure
        returns (bytes32)
    {
        require(blockHeader.length == 80);
        return sha256(abi.encodePacked(sha256(blockHeader)));
    }

    function getBlockTxMerkleRoot(bytes calldata blockHeader)
        public
        pure
        returns (bytes32)
    {
        require(blockHeader.length == 80);
        return bytes32(blockHeader[36:68]);
    }

    function getTxMerkleRoot(
        bytes32 txId,
        int256 txIndex,
        bytes32[] calldata siblings
    ) public pure returns (bool) {
        // TODO
    }

    function getTxID(bytes calldata rawTransaction)
        public
        pure
        returns (bytes32)
    {
        // TODO
    }

    function getPayment(bytes32 addressTo, bytes calldata rawTransaction)
        public
        pure
        returns (uint256)
    {
        // TODO
    }
}
