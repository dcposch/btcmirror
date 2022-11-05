// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

import "../src/BtcMirror.sol";
import "../src/BtcTxVerifier.sol";

contract BtcTxVerifierTest is DSTest {
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    // correct header for bitcoin block #717695
    // all bitcoin header values are little-endian:
    bytes constant b717695 = (
        hex"04002020"
        hex"edae5e1bd8a0e007e529fe33d099ebb7a82a06d6d63d0b000000000000000000"
        hex"f8aec519bcd878c9713dc8153a72fd62e3667c5ade70d8d0415584b8528d79ca"
        hex"0b40d961"
        hex"ab980b17"
        hex"3dcc4d5a"
    );

    function testVerifyTx() public {
        BtcMirror mirror = new BtcMirror(
            736000, // start at block #736000
            0x00000000000000000002d52d9816a419b45f1f0efe9a9df4f7b64161e508323d,
            0,
            0x0,
            false
        );
        assertEq(mirror.getLatestBlockHeight(), 736000);

        BtcTxVerifier verif = new BtcTxVerifier(mirror);

        // validate payment 736000 #1
        bytes memory header736000 = (
            hex"04000020"
            hex"d8280f9ce6eeebd2e117f39e1af27cb17b23c5eae6e703000000000000000000"
            hex"31b669b35884e22c31b286ed8949007609db6cb50afe8b6e6e649e62cc24e19c"
            hex"a5657c62"
            hex"ba010917"
            hex"36d09865"
        );
        bytes memory txProof736 = (
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
        bytes32 txId736 = 0x3667d5beede7d89e41b0ec456f99c93d6cc5e5caff4c4a5f993caea477b4b9b9;
        bytes memory tx736 = (
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
        bytes20 destSH = hex"ae2f3d4b06579b62574d6178c10c882b91503740";

        BtcTxProof memory txP = BtcTxProof(
            header736000,
            txId736,
            1,
            txProof736,
            tx736
        );

        assertTrue(verif.verifyPayment(1, 736000, txP, 0, destSH, 25200000));

        vm.expectRevert("Not enough Bitcoin block confirmations");
        assertTrue(!verif.verifyPayment(2, 736000, txP, 0, destSH, 25200000));

        vm.expectRevert("Amount mismatch");
        assertTrue(!verif.verifyPayment(1, 736000, txP, 0, destSH, 25200001));

        vm.expectRevert("Script hash mismatch");
        assertTrue(!verif.verifyPayment(1, 736000, txP, 1, destSH, 25200000));

        vm.expectRevert("Block hash mismatch");
        assertTrue(!verif.verifyPayment(1, 735990, txP, 0, destSH, 25200000));
    }
}
