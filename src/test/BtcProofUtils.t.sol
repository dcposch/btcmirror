// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "ds-test/test.sol";
import "./console.sol";

import "../BtcProofUtils.sol";

contract BtcProofUtilsTest is DSTest {
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

    // correct header for bitcoin block #717696
    // in order, all little-endian:
    // - version
    // - parent hash
    // - tx merkle root
    // - timestamp
    // - difficulty bits
    // - nonce
    bytes constant b717696 = (
        hex"00004020"
        hex"9acaa5d26d392ace656c2428c991b0a3d3d773845a1300000000000000000000"
        hex"aa8e225b1f3ea6c4b7afd5aa1cecf691a8beaa7fa1e579ce240e4a62b5ac8ecc"
        hex"2141d961"
        hex"8b8c0b17"
        hex"0d5c05bb"
    );

    bytes headerGood =
        bytes.concat(bVer, bParent, bTxRoot, bTime, bBits, bNonce);

    function testGetBlockHash() public {
        bytes32 expectedHash = 0x9acaa5d26d392ace656c2428c991b0a3d3d773845a1300000000000000000000;
        assertEq(BtcProofUtils.getBlockHash(headerGood), expectedHash);
    }

    function testGetBlockTxMerkleRoot() public {
        bytes32 expectedRoot = 0xf8aec519bcd878c9713dc8153a72fd62e3667c5ade70d8d0415584b8528d79ca;
        assertEq(BtcProofUtils.getBlockTxMerkleRoot(headerGood), expectedRoot);
    }
}
