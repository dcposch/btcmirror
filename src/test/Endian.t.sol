// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "ds-test/test.sol";
import "./console.sol";
import "./vm.sol";

import "../Endian.sol";

contract EndianTest is DSTest {
    function test32() public {
        uint32 input = 0x12345678;
        assertEq(Endian.reverse32(input), 0x78563412);
    }

    function test256() public {
        uint256 input = 0x00112233445566778899aabbccddeeff00000000000000000123456789abcdef;
        assertEq(
            Endian.reverse256(input),
            0xefcdab89674523010000000000000000ffeeddccbbaa998877665544332211
        );
    }
}
