// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Script.sol";

import "../src/BtcMirror.sol";
import "../src/BtcTxVerifier.sol";

contract DeployBtcMirror is Script {
    function setUp() public {}

    /**
     * @notice Deploys BtcMirror and BtcTxVerifier, tracking either mainnet or
     *         testnet Bitcoin.
     */
    function run(bool mainnet) public {
        vm.broadcast();

        // Deploy BtcMirror
        BtcMirror mirror;
        if (mainnet) {
            // ...tracking Bitcoin mainnet, starting at block 739000
            mirror = new BtcMirror(
                739000,
                hex"00000000000000000001059a330a05e66e4fa2d1a5adcd56d1bfefc5c114195d",
                1654182075,
                0x96A200000000000000000000000000000000000000000,
                false
            );
        } else {
            // ...tracking Bitcoin testnet, starting at block 2315360
            mirror = new BtcMirror(
                2315360,
                hex"0000000000000022201eee4f82ca053dfbc50d91e76e9cbff671699646d0982c",
                1659901500,
                0x000000000000003723C000000000000000000000000000000000000000000000,
                true
            );
        }

        // Deploy the transaction verifier
        new BtcTxVerifier(mirror);

        vm.stopBroadcast();
    }
}
