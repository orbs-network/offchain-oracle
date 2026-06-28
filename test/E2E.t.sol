// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";

contract E2ETest is Test {
    function testUsdOracleE2E() public {
        string[] memory cmd = new string[](3);
        cmd[0] = "zsh";
        cmd[1] = "-c";
        cmd[2] =
            unicode"set -euo pipefail; output=$(test/e2e); [[ $output == *$'\\n┌'* ]]; [[ $output == *Adapters* ]]; [[ $output != *Connectors* ]]; [[ $output != *Checks* ]]; [[ $output != *Result* ]]; [[ $output != *[0-9]/[0-9]* ]]; [[ $output == *$'\\nOK'* ]]; { print -r -- \"$output\" >/dev/tty } 2>/dev/null || true; print -r -- \"$output\"";

        bytes memory output = vm.ffi(cmd);
        if (output.length == 0) {
            fail(string(output));
        }
    }
}
