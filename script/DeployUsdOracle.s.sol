// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {UsdOracle} from "contracts/view/UsdOracle.sol";

contract DeployUsdOracle is ConfigDeploy {
    function run() external returns (UsdOracle oracle) {
        address[] memory tokens = _tokens();
        address[] memory feeds = _envAddressArray("feeds");

        _logCreate2(type(UsdOracle).creationCode, abi.encode(cfg.aggregator, tokens, feeds));
        vm.broadcast();
        oracle = new UsdOracle{salt: cfg.salt}(cfg.aggregator, tokens, feeds);
    }
}
