// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {UsdOracleFlare} from "contracts/view/UsdOracleFlare.sol";

contract DeployUsdOracleFlare is ConfigDeploy {
    function run() external returns (UsdOracleFlare oracle) {
        address[] memory tokens = _tokens();
        bytes32[] memory ftsos = _envBytes32Array("ftso");

        _logCreate2(type(UsdOracleFlare).creationCode, abi.encode(cfg.aggregator, tokens, ftsos));
        vm.broadcast();
        oracle = new UsdOracleFlare{salt: cfg.salt}(cfg.aggregator, tokens, ftsos);
    }
}
