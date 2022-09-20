// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8;

import "forge-std/Script.sol";

import "../src/BtcMirror.sol";
import "../src/BtcTxVerifier.sol";

contract DeployBtcMirror is Script {
    function setUp() public {}

    function run(bool mainnet) public {
        vm.broadcast();

        // DEPLOY MIRROR
        BtcMirror mirror;
        if (mainnet) {
            // ...STARTING AT MAINNET BLOCK 739000
            mirror = new BtcMirror(
                739000,
                hex"00000000000000000001059a330a05e66e4fa2d1a5adcd56d1bfefc5c114195d",
                1654182075,
                0x96A200000000000000000000000000000000000000000,
                false
            );
        } else {
            // ...STARTING AT TESTNET BLOCK 2315360
            mirror = new BtcMirror(
                2315360,
                hex"0000000000000022201eee4f82ca053dfbc50d91e76e9cbff671699646d0982c",
                1659901500,
                0x000000000000003723C000000000000000000000000000000000000000000000,
                true
            );
        }

        // DEPLOY VERIFIER
        new BtcTxVerifier(mirror);

        vm.stopBroadcast();
    }
}
