// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "ds-test/test.sol";
import "./console.sol";
import "./vm.sol";

import "../Contract.sol";

contract ContractTest is DSTest {
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    BtcMirror mirror = new BtcMirror();

    // correct header for bitcoin block #718115
    // all bitcoin header values are little-endian:
    bytes constant bVer = hex"04000020";
    bytes constant bParent =
        hex"8a461e6629f2ef70bd2e74c1627468713bcf5d3b9af803000000000000000000";
    bytes constant bTxRoot =
        hex"e1ee22cb8f17145d6df6b159c2a9ad0f8ed88522510b15a3e4cb501592d50a94";
    bytes constant bTime = hex"9e10dd61";
    bytes constant bBits = hex"8b8c0b17";
    bytes constant bNonce = hex"41b360cd";

    // in order, all little-endian:
    // - version
    // - parent hash
    // - tx merkle root
    // - timestamp
    // - difficulty bits
    // - nonce
    bytes headerGood =
        bytes.concat(bVer, bParent, bTxRoot, bTime, bBits, bNonce);

    bytes headerWrongParentHash =
        bytes.concat(bVer, bTxRoot, bTxRoot, bTime, bBits, bNonce);

    bytes headerWrongLength =
        bytes.concat(bVer, bParent, bTxRoot, bTime, bBits, bNonce, bNonce);

    bytes headerHashTooEasy =
        bytes.concat(bVer, bParent, bTxRoot, bTime, bBits, hex"41b360c0");

    function testHash() public {
        bytes32 expectedHash = 0x25ff9311c3a38c23735898bd8f89d88dfaab4efa231206000000000000000000;
        assertEq(mirror.hashBlock(headerGood), expectedHash);
    }

    function testGetTarget() public {
        uint256 expectedTarget = 0x0000000000000000000B8C8B0000000000000000000000000000000000000000;
        assertEq(mirror.getTarget(hex"8b8c0b17"), expectedTarget);
        expectedTarget = 0x00000000000404CB000000000000000000000000000000000000000000000000;
        assertEq(mirror.getTarget(hex"cb04041b"), expectedTarget);
    }

    function testSubmitError() public {
        assertEq(mirror.getLatestBlockHeight(), 718114);
        vm.expectRevert("bad parent");
        mirror.submit(718115, headerWrongParentHash);
        vm.expectRevert("wrong header length");
        mirror.submit(718115, headerWrongLength);
        vm.expectRevert("block hash above target");
        mirror.submit(718115, headerHashTooEasy);
    }

    function testSubmit() public {
        assertEq(mirror.getLatestBlockHeight(), 718114);
        mirror.submit(718115, headerGood);
        assertEq(mirror.getLatestBlockHeight(), 718115);
    }
}
