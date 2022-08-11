// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "ds-test/test.sol";
import "./console.sol";
import "./vm.sol";

import "../BtcProofUtils.sol";

contract BtcProofUtilsTest is DSTest {
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    // correct header for bitcoin block #717695
    // all bitcoin header values are little-endian:
    bytes constant bVer = hex"04002020";
    bytes constant bParent =
        hex"edae5e1bd8a0e007e529fe33d099ebb7a82a06d6d63d0b000000000000000000";
    bytes constant bTxRoot =
        hex"f8aec519bcd878c9713dc8153a72fd62e3667c5ade70d8d0415584b8528d79ca";
    bytes constant bTime = hex"0b40d961";
    bytes constant bBits = hex"ab980b17";
    bytes constant bNonce = hex"3dcc4d5a";

    bytes headerGood =
        bytes.concat(bVer, bParent, bTxRoot, bTime, bBits, bNonce);

    bytes32 blockHash717695 =
        0x00000000000000000000135a8473d7d3a3b091c928246c65ce2a396dd2a5ca9a;

    // correct header for bitcoin block #717696
    // in order, all little-endian:
    // - version
    // - parent hash
    // - tx merkle root
    // - timestamp
    // - difficulty bits
    // - nonce
    bytes constant header717696 = (
        hex"00004020"
        hex"9acaa5d26d392ace656c2428c991b0a3d3d773845a1300000000000000000000"
        hex"aa8e225b1f3ea6c4b7afd5aa1cecf691a8beaa7fa1e579ce240e4a62b5ac8ecc"
        hex"2141d961"
        hex"8b8c0b17"
        hex"0d5c05bb"
    );

    // header for bitcoin block #736000
    bytes constant header736000 = (
        hex"04000020"
        hex"d8280f9ce6eeebd2e117f39e1af27cb17b23c5eae6e703000000000000000000"
        hex"31b669b35884e22c31b286ed8949007609db6cb50afe8b6e6e649e62cc24e19c"
        hex"a5657c62"
        hex"ba010917"
        hex"36d09865"
    );

    bytes32 blockHash736000 =
        hex"00000000000000000002d52d9816a419b45f1f0efe9a9df4f7b64161e508323d";

    // a Bitcoin P2SH (pay to script hash) transaction.
    // in order, all little-endian:
    // - version
    // - flags
    // - tx inputs
    // - tx outputs
    // - witnesses
    // - locktime
    // bytes constant tx736000_2 = (
    //     hex"02000000"
    //     hex"0001"
    //     hex"01"
    //     hex"bb185dfa5b5c7682f4b2537fe2dcd00ce4f28de42eb4213c68fe57aaa264268b"
    //     hex"01000000"
    //     hex"17"
    //     hex"16001407bf360a5fc365d23da4889952bcb59121088ee1"
    //     hex"feffffff"
    //     hex"02"
    //     hex"8085800100000000"
    //     hex"17"
    //     hex"a914ae2f3d4b06579b62574d6178c10c882b9150374087"
    //     hex"1c20590500000000"
    //     hex"17"
    //     hex"a91415ecf89e95eb07fbc351b3f7f4c54406f7ee5c1087"
    //     hex"0247"
    //     hex"3044022025ace11487fbd2fb222ef00b14f0be6dc38cf0d028d8fc67476f4e2bb844d301022061d5a922d87186688d86d36507b1633a94d180a4f7f2b36f0f5c004e440ae57801"
    //     hex"21"
    //     hex"028401531bb6226b1068f4482ae50f94cc78f64a1dd5cf7e1e41c8eceb1dcc0be3"
    //     hex"00000000"
    // );

    // the same transaction, excluding flags and witnesses
    // the txid is a hash of this serialization
    bytes constant tx736 = (
        hex"02000000"
        hex"01"
        hex"bb185dfa5b5c7682f4b2537fe2dcd00ce4f28de42eb4213c68fe57aaa264268b"
        hex"01000000"
        hex"17"
        hex"16001407bf360a5fc365d23da4889952bcb59121088ee1"
        hex"feffffff"
        hex"02"
        hex"8085800100000000"
        hex"17"
        hex"a914ae2f3d4b06579b62574d6178c10c882b9150374087"
        hex"1c20590500000000"
        hex"17"
        hex"a91415ecf89e95eb07fbc351b3f7f4c54406f7ee5c1087"
        hex"00000000"
    );

    // merkle proof that transaction above is in block 736000
    bytes constant txProof736 = (
        hex"d298f062a08ccb73abb327f01d2e2c6109a363ac0973abc497eec663e08a6a13"
        hex"2e64222ee84f7b90b3c37ed29e4576c41868c7dcf73b1183c1c84a73c3bb0451"
        hex"ea4cc81f31578f895bd3c14fcfdd9273173e754bddca44252f261e28ba814b8a"
        hex"d3199dac99561c60e9ea390d15633534de8864c7eb37512c6a6efa1e248e91e5"
        hex"fb0f53df4e177151d7b0a41d7a49d42f4dcf5984f6198b223112d20cf6ae41ed"
        hex"b0914821bd72a12b518dc94e140d651b7a93e5bb7671b3c8821480b0838740ab"
        hex"19d90729a753c500c9dc22cc7fec9a36f9f42597edbf15ccd1d68847cf76da67"
        hex"bc09b6091ec5863f23a2f4739e4c6ba28bb7ba9bcf2266527647194e0fccd94a"
        hex"e6925c8491e0ff7e5a7db9d35c5c15f1cccc49b082fc31b1cc0a364ca1ecc358"
        hex"d7ff70aa2af09f007a0aba4e1df6e850906d22a4c3cc23cd3b87ba0cb3a57e33"
        hex"fb1f9877e50b5cbb8b88b2db234687ea108ac91a232b2472f96f08f136a5eba4"
        hex"0b2be0cdd7773b1ddd2b847c14887d9005daf04da6188f9beeccab698dcc26b9"
    );

    // Counting down from the chain of Bitcoin block hashes, to a specific txo.
    // 5. verify that we can hash a block header correctly
    function testGetBlockHash() public {
        // Block 717695
        assertEq(BtcProofUtils.getBlockHash(headerGood), blockHash717695);

        // Block 736000
        assertEq(BtcProofUtils.getBlockHash(header736000), blockHash736000);
    }

    // 4. verify that we can get the transaction merkle root from a block header
    function testGetBlockTxMerkleRoot() public {
        bytes32 expectedRoot = 0xf8aec519bcd878c9713dc8153a72fd62e3667c5ade70d8d0415584b8528d79ca;
        assertEq(BtcProofUtils.getBlockTxMerkleRoot(headerGood), expectedRoot);

        assertEq(
            BtcProofUtils.getBlockTxMerkleRoot(header736000),
            0x31b669b35884e22c31b286ed8949007609db6cb50afe8b6e6e649e62cc24e19c
        );
    }

    // 3. verify that we can recreate the same merkle root from a merkle proof
    function testGetTxMerkleRoot() public {
        // block 100000 has just 4 txs, short proof
        assertEq(
            BtcProofUtils.getTxMerkleRoot(
                0xfff2525b8931402dd09222c50775608f75787bd2b87e56995a7bdd30f79702c4,
                1,
                hex"8c14f0db3df150123e6f3dbbf30f8b955a8249b62ac1d1ff16284aefa3d06d87"
                hex"8e30899078ca1813be036a073bbf80b86cdddde1c96e9e9c99e9e3782df4ae49"
            ),
            0x6657a9252aacd5c0b2940996ecff952228c3067cc38d4885efb5a4ac4247e9f3
        );

        // block 736000, long proof
        bytes32 txId = 0x3667d5beede7d89e41b0ec456f99c93d6cc5e5caff4c4a5f993caea477b4b9b9;
        uint256 txIndex = 1;
        bytes32 expectedRoot = 0x31b669b35884e22c31b286ed8949007609db6cb50afe8b6e6e649e62cc24e19c;
        assertEq(
            BtcProofUtils.getTxMerkleRoot(txId, txIndex, txProof736),
            expectedRoot
        );
    }

    // 2. verify that we can get hash a raw tx to get the txid (merkle leaf)
    function testGetTxID() public {
        bytes32 expectedID = 0x3667d5beede7d89e41b0ec456f99c93d6cc5e5caff4c4a5f993caea477b4b9b9;
        assertEq(BtcProofUtils.getTxID(tx736), expectedID);
    }

    // 1a. to parse a raw transaction, we must understand Bitcoin's
    //     wire format. verify that we can deserialize varints.
    bytes constant buf63_offset = hex"00003f";
    bytes constant buf255 = hex"fdff00";
    bytes constant buf2to16 = hex"fe00000100";
    bytes constant buf2to32 = hex"ff0000000001000000";

    function testReadVarInt() public {
        uint256 val;
        uint256 newOffset;
        (val, newOffset) = BtcProofUtils.readVarInt(buf63_offset, 0);
        assertEq(val, 0);
        assertEq(newOffset, 1);

        (val, newOffset) = BtcProofUtils.readVarInt(buf63_offset, 2);
        assertEq(val, 63);
        assertEq(newOffset, 3);

        (val, newOffset) = BtcProofUtils.readVarInt(buf255, 0);
        assertEq(val, 255);
        assertEq(newOffset, 3);

        (val, newOffset) = BtcProofUtils.readVarInt(buf2to16, 0);
        assertEq(val, 2**16);
        assertEq(newOffset, 5);

        (val, newOffset) = BtcProofUtils.readVarInt(buf2to32, 0);
        assertEq(val, 2**32);
        assertEq(newOffset, 9);
    }

    // 1b. verify that we can parse a raw Bitcoin transaction
    function testParseTx() public {
        BitcoinTx memory t = BtcProofUtils.parseBitcoinTx(tx736);
        assertTrue(t.validFormat);

        assertEq(t.version, 2); // BIP68

        assertEq(t.inputs.length, 1);
        assertEq(
            t.inputs[0].prevTxID,
            0x8b2664a2aa57fe683c21b42ee48df2e40cd0dce27f53b2f482765c5bfa5d18bb
        );
        assertEq(t.inputs[0].prevTxIndex, 1);
        assertEq(t.inputs[0].scriptLen, 23);
        assertEq(
            t.inputs[0].script,
            bytes32(hex"16001407bf360a5fc365d23da4889952bcb59121088ee1")
        );
        assertEq(t.inputs[0].seqNo, 4294967294);

        assertEq(t.outputs.length, 2);
        assertEq(t.outputs[0].valueSats, 25200000);
        assertEq(t.outputs[0].scriptLen, 23);
        assertEq(
            t.outputs[0].script,
            bytes32(hex"a914ae2f3d4b06579b62574d6178c10c882b9150374087")
        );

        assertEq(t.locktime, 0);
    }

    // 1c. finally, verify the recipient of a transaction *output*
    bytes constant b0 = hex"0000000000000000000000000000000000000000";

    function testGetP2SH() public {
        bytes32 validP2SH = hex"a914ae2f3d4b06579b62574d6178c10c882b9150374087";
        bytes32 invalidP2SH1 = hex"a914ae2f3d4b06579b62574d6178c10c882b9150374086";
        bytes32 invalidP2SH2 = hex"a900ae2f3d4b06579b62574d6178c10c882b9150374087";

        assertEq(
            uint160(BtcProofUtils.getP2SH(23, validP2SH)),
            0x00ae2f3d4b06579b62574d6178c10c882b91503740
        );

        assertEq(uint160(BtcProofUtils.getP2SH(22, validP2SH)), 0);
        assertEq(uint160(BtcProofUtils.getP2SH(24, validP2SH)), 0);
        assertEq(uint160(BtcProofUtils.getP2SH(23, invalidP2SH1)), 0);
        assertEq(uint160(BtcProofUtils.getP2SH(23, invalidP2SH2)), 0);
    }

    // 1,2,3,4,5. putting it all together, verify a payment.
    function testValidatePayment() public {
        bytes32 txId736 = 0x3667d5beede7d89e41b0ec456f99c93d6cc5e5caff4c4a5f993caea477b4b9b9;
        bytes20 destScriptHash = hex"ae2f3d4b06579b62574d6178c10c882b91503740";

        // Should succeed
        // this.validate(
        //     blockHash736000,
        //     BtcTxProof(header736000, txId736, 1, txProof736, tx736),
        //     0,
        //     destScriptHash,
        //     25200000
        // );

        // Make each argument invalid, one at a time.
        vm.expectRevert("Block hash mismatch");
        this.validate(
            blockHash717695,
            BtcTxProof(header736000, txId736, 1, txProof736, tx736),
            0,
            destScriptHash,
            25200000
        );

        // - Bad tx proof (doesn't match root)
        vm.expectRevert("Tx merkle root mismatch");
        this.validate(
            blockHash717695,
            BtcTxProof(headerGood, txId736, 1, txProof736, tx736),
            0,
            destScriptHash,
            25200000
        );

        // - Wrong tx index
        vm.expectRevert("Tx merkle root mismatch");
        this.validate(
            blockHash736000,
            BtcTxProof(header736000, txId736, 2, txProof736, tx736),
            0,
            destScriptHash,
            25200000
        );

        // - Wrong tx output index
        vm.expectRevert("Script hash mismatch");
        this.validate(
            blockHash736000,
            BtcTxProof(header736000, txId736, 1, txProof736, tx736),
            1,
            destScriptHash,
            25200000
        );

        // - Wrong dest script hash
        vm.expectRevert("Script hash mismatch");
        this.validate(
            blockHash736000,
            BtcTxProof(header736000, txId736, 1, txProof736, tx736),
            0,
            bytes20(hex"abcd"),
            25200000
        );

        // - Wrong amount, off by one satoshi
        vm.expectRevert("Amount mismatch");
        this.validate(
            blockHash736000,
            BtcTxProof(header736000, txId736, 1, txProof736, tx736),
            0,
            destScriptHash,
            25200001
        );
    }

    function validate(
        bytes32 blockHash,
        BtcTxProof calldata txProof,
        uint256 txOutIx,
        bytes20 destScriptHash,
        uint256 sats
    ) public pure {
        BtcProofUtils.validatePayment(
            blockHash,
            txProof,
            txOutIx,
            destScriptHash,
            sats
        );
    }
}
