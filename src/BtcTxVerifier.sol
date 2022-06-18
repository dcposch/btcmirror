// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./interfaces/IBtcMirror.sol";
import "./interfaces/IBtcTxVerifier.sol";
import "./BtcProofUtils.sol";

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
// BtcVerifier implements a Merkle proof that a Bitcoin payment succeeded. It
// uses BtcMirror as a source of truth for which Bitcoin block hashes are in the
// canonical chain.
contract BtcTxVerifier is IBtcTxVerifier {
    IBtcMirror immutable mirror;

    constructor(IBtcMirror _mirror) {
        mirror = _mirror;
    }

    function verifyPayment(
        uint256 minConfirmations,
        uint256 blockNum,
        BtcTxProof calldata inclusionProof,
        uint256 txOutIx,
        bytes20 destScriptHash,
        uint256 amountSats
    ) external view returns (bool) {
        {
            uint256 mirrorHeight = mirror.getLatestBlockHeight();

            require(
                mirrorHeight >= blockNum,
                "Bitcoin Mirror doesn't have that block yet"
            );

            require(
                mirrorHeight + 1 >= minConfirmations + blockNum,
                "Not enough Bitcoin block confirmations"
            );
        }

        bytes32 blockHash = mirror.getBlockHash(blockNum);

        require(
            BtcProofUtils.validatePayment(
                blockHash,
                inclusionProof,
                txOutIx,
                destScriptHash,
                amountSats
            ),
            "Invalid transaction proof"
        );

        return true;
    }
}
