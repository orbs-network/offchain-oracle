// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {UsdOraclePyth} from "contracts/view/UsdOraclePyth.sol";

contract DeployUsdOraclePyth is ConfigDeploy {
    function run() external returns (UsdOraclePyth oracle) {
        address[] memory tokens = _tokens();
        address pythAddr = _envAddress("pyth");
        bytes32[] memory pyths = _envBytes32Array("pyths");

        _logCreate2(type(UsdOraclePyth).creationCode, abi.encode(cfg.aggregator, pythAddr, tokens, pyths));
        vm.broadcast();
        oracle = new UsdOraclePyth{salt: cfg.salt}(cfg.aggregator, pythAddr, tokens, pyths);
    }
}
