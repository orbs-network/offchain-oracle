// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {AlgebraOracle} from "contracts/oracles/AlgebraOracle.sol";

contract DeployAlgebraOracle is ConfigDeploy {
    function run() external returns (AlgebraOracle oracle) {
        address factory = _adapterAddress("factory");
        bytes32 initcodehash = _adapterBytes32("initcodehash");
        require(factory != address(0), "missing factory");
        require(initcodehash != bytes32(0), "missing initcodehash");

        vm.broadcast();
        oracle = new AlgebraOracle(factory, initcodehash);
        vm.broadcast();
        _addOracle(oracle, OffchainOracle.OracleType.WETH);
    }
}
