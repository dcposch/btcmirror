// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/** @notice Proof that a transaction (rawTx) is in a given block. */
struct BtcTxProof {
    /** 80-byte block header. */
    bytes blockHeader;
    /** Bitcoin transaction ID, equal to SHA256(SHA256(rawTx)) */
    bytes32 txId;
    /** Index of transaction within the block. */
    uint256 txIndex;
    /** Merkle proof. Concatenated sibling hashes, 32*n bytes. */
    bytes txMerkleProof;
    /** Raw transaction, HASH-SERIALIZED, no witnesses. */
    bytes rawTx;
}
