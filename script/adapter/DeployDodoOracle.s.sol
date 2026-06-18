// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {DodoOracle} from "contracts/oracles/DodoOracle.sol";
import {IDodoZoo} from "contracts/interfaces/IDodoFactories.sol";

contract DeployDodoOracle is ConfigDeploy {
    function run() external returns (DodoOracle oracle) {
        address zoo = _adapterAddress("zoo");
        require(zoo != address(0), "missing zoo");

        vm.broadcast();
        oracle = new DodoOracle(IDodoZoo(zoo));
        vm.broadcast();
        _addOracle(oracle, OffchainOracle.OracleType.WETH);
    }
}
