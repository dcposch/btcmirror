// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "ds-test/test.sol";
import "./console.sol";
import "./vm.sol";

import "../BtcMirror.sol";

contract BtcMirrorTest is DSTest {
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

    bytes constant b717697 = (
        hex"0400c020"
        hex"bf559a5b0479c2a73627af40cef1835d44de7b32dd3503000000000000000000"
        hex"fe7be65b41f6cf522eac2a63f9dde1f7a6f61eee93c648c74b79cfc242dd1a94"
        hex"f241d9618b8c0b17ac09604c"
    );

    bytes headerGood =
        bytes.concat(bVer, bParent, bTxRoot, bTime, bBits, bNonce);

    bytes headerWrongParentHash =
        bytes.concat(bVer, bTxRoot, bTxRoot, bTime, bBits, bNonce);

    bytes headerWrongLength =
        bytes.concat(bVer, bParent, bTxRoot, bTime, bBits, bNonce, hex"00");

    bytes headerHashTooEasy =
        bytes.concat(bVer, bParent, bTxRoot, bTime, bBits, hex"41b360c0");

    function testGetTarget() public {
        BtcMirror mirror = createBtcMirror();
        uint256 expectedTarget;
        expectedTarget = 0x0000000000000000000B8C8B0000000000000000000000000000000000000000;
        assertEq(mirror.getTarget(hex"8b8c0b17"), expectedTarget);
        expectedTarget = 0x00000000000404CB000000000000000000000000000000000000000000000000;
        assertEq(mirror.getTarget(hex"cb04041b"), expectedTarget);
        expectedTarget = 0x000000000000000000096A200000000000000000000000000000000000000000;
        assertEq(mirror.getTarget(hex"206a0917"), expectedTarget);
    }

    function testSubmitError() public {
        BtcMirror mirror = createBtcMirror();
        assertEq(mirror.getLatestBlockHeight(), 717694);
        vm.expectRevert("bad parent");
        mirror.submit(717695, headerWrongParentHash);
        vm.expectRevert("wrong header length");
        mirror.submit(717695, headerWrongLength);
        vm.expectRevert("block hash above target");
        mirror.submit(717695, headerHashTooEasy);
    }

    // function testSubmitErrorFuzz1(bytes calldata x) public {
    //     vm.expectRevert("");
    //     mirror.submit(718115, x);
    //     assert(mirror.getLatestBlockHeight() == 718115);
    // }

    // function testSubmitErrorFuzz2(uint256 height, bytes calldata x) public {
    //     vm.expectRevert("");
    //     mirror.submit(height, x);
    //     assert(mirror.getLatestBlockHeight() == 718115);
    // }

    event NewTip(uint256 blockHeight, uint256 blockTime, bytes32 blockHash);
    event NewTotalDifficultySinceRetarget(
        uint256 blockHeight,
        uint256 totalDifficulty,
        uint32 newDifficultyBits
    );

    function createBtcMirror() internal returns (BtcMirror mirror) {
        mirror = new BtcMirror(
            717694, // start at block #717694, two  blocks before retarget
            0x0000000000000000000b3dd6d6062aa8b7eb99d033fe29e507e0a0d81b5eaeed,
            1641627092,
            0x0000000000000000000B98AB0000000000000000000000000000000000000000
        );
    }

    function testSubmit() public {
        BtcMirror mirror = createBtcMirror();
        assertEq(mirror.getLatestBlockHeight(), 717694);
        vm.expectEmit(true, true, true, true);
        emit NewTip(
            717695,
            1641627659,
            0x00000000000000000000135a8473d7d3a3b091c928246c65ce2a396dd2a5ca9a
        );
        mirror.submit(717695, headerGood);
        assertEq(mirror.getLatestBlockHeight(), 717695);
        assertEq(mirror.getLatestBlockTime(), 1641627659);
        assertEq(
            mirror.getBlockHash(717695),
            0x00000000000000000000135a8473d7d3a3b091c928246c65ce2a396dd2a5ca9a
        );
    }

    function testSubmitError2() public {
        BtcMirror mirror = createBtcMirror();
        mirror.submit(717695, headerGood);
        assertEq(mirror.getLatestBlockHeight(), 717695);
        vm.expectRevert("must submit at least one block");
        mirror.submit(717696, hex"");
        assertEq(mirror.getLatestBlockHeight(), 717695);
    }

    function testRetarget() public {
        BtcMirror mirror = createBtcMirror();
        mirror.submit(717695, headerGood);
        assertEq(mirror.getLatestBlockHeight(), 717695);

        vm.expectEmit(true, true, true, true);
        emit NewTotalDifficultySinceRetarget(
            717696,
            104678001670374021593451, // = (2^256 - 1) / (new target)
            386632843
        );
        vm.expectEmit(true, true, true, true);
        emit NewTip(
            717696,
            1641627937,
            0x0000000000000000000335dd327bde445d83f1ce40af2736a7c279045b9a55bf
        );
        mirror.submit(717696, b717696);
        assertEq(mirror.getLatestBlockHeight(), 717696);
        assertEq(mirror.getLatestBlockTime(), 1641627937);
        assertEq(
            mirror.getBlockHash(717696),
            0x0000000000000000000335dd327bde445d83f1ce40af2736a7c279045b9a55bf
        );
    }

    function testRetargetLonger() public {
        BtcMirror mirror = createBtcMirror();
        mirror.submit(717695, headerGood);
        assertEq(mirror.getLatestBlockHeight(), 717695);

        vm.expectEmit(true, true, true, true);
        emit NewTotalDifficultySinceRetarget(
            717697,
            209356003340748043186902,
            386632843
        );
        vm.expectEmit(true, true, true, true);
        emit NewTip(
            717697,
            1641628146,
            0x00000000000000000000794d6f4f6ee1c09e69a81469d7456e67be3d724223fb
        );
        mirror.submit(717695, bytes.concat(headerGood, b717696, b717697));
        assertEq(mirror.getLatestBlockHeight(), 717697);
    }
}
