// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/** @notice Proof that a transaction (rawTx) is in a given block. */
struct BtcTxProof {
    bytes blockHeader;
    bytes32 txId;
    uint256 txIndex;
    bytes txMerkleProof;
    bytes rawTx;
}
