// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {V2FactoryLookupOracle} from "contracts/oracles/V2FactoryLookupOracle.sol";

contract DeployV2FactoryLookupOracle is ConfigDeploy {
    function run() external returns (V2FactoryLookupOracle oracle) {
        address factory = _adapterAddress("factory");
        require(factory != address(0), "missing factory");

        vm.broadcast();
        oracle = new V2FactoryLookupOracle(factory);
        vm.broadcast();
        _addOracle(oracle, OffchainOracle.OracleType.WETH);
    }
}
