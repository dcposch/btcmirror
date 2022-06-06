// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./BtcTxProof.sol";

/** @notice Verifies Bitcoin transaction proofs. */
interface IBtcTxVerifier {
    /**
     * @notice Verifies that the a transaction cleared, paying a given amount to
     *         a given address. Specifically, verifies a proof that the tx was
     *         in block N, and that block N has at least M confirmations.
     */
    function verifyPayment(
        uint256 minConfirmations,
        uint256 blockNum,
        BtcTxProof calldata inclusionProof,
        uint256 txOutIx,
        bytes20 recipientScriptHash,
        uint256 amountSats
    ) external view returns (bool);
}
