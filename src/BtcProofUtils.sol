// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./Endian.sol";

/**
 * @dev A parsed (but NOT fully validated) Bitcoin transaction.
 */
struct BitcoinTx {
    /**
     * @dev Whether we successfully parsed this Bitcoin TX, valid version etc.
     *      Does NOT check signatures or whether inputs are unspent.
     */
    bool validFormat;
    /**
     * @dev Version. Must be 1 or 2.
     */
    uint32 version;
    /**
     * @dev Each input spends a previous UTXO.
     */
    BitcoinTxIn[] inputs;
    /**
     * @dev Each output creates a new UTXO.
     */
    BitcoinTxOut[] outputs;
    /**
     * @dev Locktime. Either 0 for no lock, blocks if <500k, or seconds.
     */
    uint32 locktime;
}

struct BitcoinTxIn {
    /** @dev Previous transaction. */
    uint256 prevTxID;
    /** @dev Specific output from that transaction. */
    uint32 prevTxIndex;
    /** @dev Mostly useless for tx v1, BIP68 Relative Lock Time for tx v2. */
    uint32 seqNo;
    /** @dev Input script length */
    uint32 scriptLen;
    /** @dev Input script, spending a previous UTXO. Over 32 bytes unsupported. */
    bytes32 script;
}

struct BitcoinTxOut {
    /** @dev TXO value, in satoshis */
    uint64 valueSats;
    /** @dev Output script length */
    uint32 scriptLen;
    /** @dev Output script. Over 32 bytes unsupported.  */
    bytes32 script;
}

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
    /**
     * @dev Validates that a given payment appears under a given block hash.
     *
     * This verifies a whole chain:
     * 1. Raw transaction really does pay X satoshis to Y script hash.
     * 2. Raw tx hashes to a transaction ID.
     * 3. Transaction ID appears under transaction root (Merkle proof).
     * 4. Transaction root is part of the block header.
     * 5. Block header hashes to a given block hash.
     */
    function validatePayment(
        bytes32 blockHash,
        bytes calldata blockHeader,
        bytes32 txId,
        uint256 txIndex,
        bytes calldata txMerkleProof,
        bytes calldata rawTx,
        uint256 txOutIx,
        bytes20 recipientScriptHash,
        uint256 satoshisExpected
    ) public pure returns (bool) {
        // 5. Block header to block hash
        if (getBlockHash(blockHeader) != blockHash) {
            return false;
        }

        // 4. and 3. Transaction ID included in block
        bytes32 blockTxRoot = getBlockTxMerkleRoot(blockHeader);
        bytes32 txRoot = getTxMerkleRoot(txId, txIndex, txMerkleProof);
        if (blockTxRoot != txRoot) {
            return false;
        }

        // 2. Raw transaction to TxID
        if (getTxID(rawTx) != txId) {
            return false;
        }

        // 1. Finally, validate raw transaction pays stated recipient.
        BitcoinTx memory parsedTx = parseBitcoinTx(rawTx);
        BitcoinTxOut memory txo = parsedTx.outputs[txOutIx];
        bytes20 actualScriptHash = getP2SH(txo.scriptLen, txo.script);
        if (recipientScriptHash != actualScriptHash) {
            return false;
        }
        if (txo.valueSats < satoshisExpected) {
            return false;
        }

        // We've verified that blockHash contains a P2SH transaction
        // that sends at least satoshisExpected to the given hash.
        //
        // This function does NOT verify that blockHash is in the canonical
        // chain. Do that separately using BtcMirror.
        return true;
    }

    /**
     * @dev Get a block hash given a block header.
     */
    function getBlockHash(bytes calldata blockHeader)
        public
        pure
        returns (bytes32)
    {
        require(blockHeader.length == 80);
        bytes32 ret = sha256(abi.encodePacked(sha256(blockHeader)));
        return bytes32(Endian.reverse256(uint256(ret)));
    }

    /**
     * @dev Get the transactions root given a block header.
     */
    function getBlockTxMerkleRoot(bytes calldata blockHeader)
        public
        pure
        returns (bytes32)
    {
        require(blockHeader.length == 80);
        return bytes32(blockHeader[36:68]);
    }

    /**
     * @dev Recomputes the transactions root given a merkle proof.
     *
     * TODO: pre-reverse txId and proof to save gas
     */
    function getTxMerkleRoot(
        bytes32 txId,
        uint256 txIndex,
        bytes calldata siblings
    ) public pure returns (bytes32) {
        bytes32 ret = bytes32(Endian.reverse256(uint256(txId)));
        uint256 len = siblings.length / 32;
        for (uint256 i = 0; i < len; i++) {
            bytes32 s = bytes32(
                Endian.reverse256(
                    uint256(bytes32(siblings[i * 32:(i + 1) * 32]))
                )
            );
            if (txIndex & 1 == 0) {
                ret = doubleSha(abi.encodePacked(ret, s));
            } else {
                ret = doubleSha(abi.encodePacked(s, ret));
            }
            txIndex = txIndex >> 1;
        }
        return ret;
    }

    /**
     * @dev Computes the ubiquitious Bitcoin SHA256(SHA256(x))
     */
    function doubleSha(bytes memory buf) internal pure returns (bytes32) {
        return sha256(abi.encodePacked(sha256(buf)));
    }

    /**
     * @dev Recomputes the transaction ID for a raw transaction.
     */
    function getTxID(bytes calldata rawTransaction)
        public
        pure
        returns (bytes32)
    {
        bytes32 ret = doubleSha(rawTransaction);
        return bytes32(Endian.reverse256(uint256(ret)));
    }

    /**
     * @dev Parses a HASH-SERIALIZED Bitcoin transaction.
     *      This means no flags and no witnesses for segwit txs.
     */
    function parseBitcoinTx(bytes calldata rawTx)
        public
        pure
        returns (BitcoinTx memory ret)
    {
        ret.version = Endian.reverse32(uint32(bytes4(rawTx[0:4])));
        if (ret.version < 1 || ret.version > 2) {
            return ret; // invalid version
        }

        // Read transaction inputs
        uint256 offset = 4;
        uint256 nInputs;
        (nInputs, offset) = readVarInt(rawTx, offset);
        ret.inputs = new BitcoinTxIn[](nInputs);
        for (uint256 i = 0; i < nInputs; i++) {
            BitcoinTxIn memory txIn;
            txIn.prevTxID = Endian.reverse256(
                uint256(bytes32(rawTx[offset:offset + 32]))
            );
            offset += 32;
            txIn.prevTxIndex = Endian.reverse32(
                uint32(bytes4(rawTx[offset:offset + 4]))
            );
            offset += 4;
            uint256 nInScriptBytes;
            (nInScriptBytes, offset) = readVarInt(rawTx, offset);
            require(nInScriptBytes <= 32, "Scripts over 32 bytes unsupported");
            txIn.scriptLen = uint32(nInScriptBytes);
            txIn.script = bytes32(rawTx[offset:offset + nInScriptBytes]);
            offset += nInScriptBytes;
            txIn.seqNo = Endian.reverse32(
                uint32(bytes4(rawTx[offset:offset + 4]))
            );
            offset += 4;
            ret.inputs[i] = txIn;
        }

        // Read transaction outputs
        uint256 nOutputs;
        (nOutputs, offset) = readVarInt(rawTx, offset);
        ret.outputs = new BitcoinTxOut[](nOutputs);
        for (uint256 i = 0; i < nOutputs; i++) {
            BitcoinTxOut memory txOut;
            txOut.valueSats = Endian.reverse64(
                uint64(bytes8(rawTx[offset:offset + 8]))
            );
            offset += 8;
            uint256 nOutScriptBytes;
            (nOutScriptBytes, offset) = readVarInt(rawTx, offset);
            require(nOutScriptBytes <= 32, "Scripts over 32 bytes unsupported");
            txOut.scriptLen = uint32(nOutScriptBytes);
            txOut.script = bytes32(rawTx[offset:offset + nOutScriptBytes]);
            offset += nOutScriptBytes;
            ret.outputs[i] = txOut;
        }

        // Finally, read locktime, the last four bytes in the tx.
        ret.locktime = Endian.reverse32(
            uint32(bytes4(rawTx[offset:offset + 4]))
        );
        offset += 4;
        if (offset != rawTx.length) {
            return ret; // Extra data at end of transaction.
        }

        // Parsing complete, sanity checks passed, return success.
        ret.validFormat = true;
        return ret;
    }

    function readVarInt(bytes calldata buf, uint256 offset)
        public
        pure
        returns (uint256 val, uint256 newOffset)
    {
        uint8 pivot = uint8(buf[offset]);
        if (pivot < 0xfd) {
            val = pivot;
            newOffset = offset + 1;
        } else if (pivot == 0xfd) {
            val = Endian.reverse16(uint16(bytes2(buf[offset + 1:offset + 3])));
            newOffset = offset + 3;
        } else if (pivot == 0xfe) {
            val = Endian.reverse32(uint32(bytes4(buf[offset + 1:offset + 5])));
            newOffset = offset + 5;
        } else {
            // pivot == 0xff
            val = Endian.reverse64(uint64(bytes8(buf[offset + 1:offset + 9])));
            newOffset = offset + 9;
        }
    }

    /**
     * @dev Verifies a standard P2PKH payment = to an address starting with 1.
     */
    // function getPaymentP2PKH(
    //     bytes20 recipientPubKeyHash,
    //     BitcoinTxOut calldata txOut
    // ) internal pure returns (uint256) {
    //     if (txOut.script.length != 23) {
    //         return 0;
    //     }
    //     return 0;
    //     // TODO: if (bytes2(txOut.script[0:2]) != hex"a914") return txOut.valueSats;
    // }

    /**
     * @dev Verifies that `script` is a standard P2SH (pay to script hash) tx.
     * @return hash The recipient script hash, or 0 if verification failed.
     */
    function getP2SH(uint256 scriptLen, bytes32 script)
        internal
        pure
        returns (bytes20)
    {
        if (scriptLen != 23) {
            return 0;
        }
        if (script[0] != 0xa9 || script[1] != 0x14 || script[22] != 0x87) {
            return 0;
        }
        uint256 sHash = (uint256(script) >> 80) &
            0x00ffffffffffffffffffffffffffffffffffffffff;
        return bytes20(uint160(sHash));
    }
}
