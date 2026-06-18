// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";

contract E2ETest is Test {
    function testUsdOracleE2E() public {
        string[] memory cmd = new string[](1);
        cmd[0] = "test/e2e";

        bytes memory output = vm.ffi(cmd);
        if (keccak256(output) != keccak256(bytes("OK\n"))) {
            fail(string(output));
        }
    }
}
