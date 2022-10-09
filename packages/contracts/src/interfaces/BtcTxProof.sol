// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/** @notice Proof that a transaction (rawTx) is in a given block. */
struct BtcTxProof {
    /** @notice 80-byte block header. */
    bytes blockHeader;
    /** @notice Bitcoin transaction ID, equal to SHA256(SHA256(rawTx)) */
    // This is not gas-optimized--we could omit it and compute from rawTx. But
    //s the cost is minimal, and keeping it allows better revert messages.
    bytes32 txId;
    /** @notice Index of transaction within the block. */
    uint256 txIndex;
    /** @notice Merkle proof. Concatenated sibling hashes, 32*n bytes. */
    bytes txMerkleProof;
    /** @notice Raw transaction, HASH-SERIALIZED, no witnesses. */
    bytes rawTx;
}
