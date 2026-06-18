// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {AlgebraCustomPoolOracle} from "contracts/oracles/AlgebraCustomPoolOracle.sol";

contract DeployAlgebraCustomPoolOracle is ConfigDeploy {
    function run() external returns (AlgebraCustomPoolOracle oracle) {
        address poolDeployer = _adapterAddress("poolDeployer");
        address customDeployer = _adapterAddress("customDeployer");
        bytes32 initcodehash = _adapterBytes32("initcodehash");
        require(poolDeployer != address(0), "missing poolDeployer");
        require(initcodehash != bytes32(0), "missing initcodehash");
        // customDeployer is optional; zero means default Algebra salt (token0, token1)

        vm.broadcast();
        oracle = new AlgebraCustomPoolOracle(poolDeployer, customDeployer, initcodehash);
        vm.broadcast();
        _addOracle(oracle, OffchainOracle.OracleType.WETH);
    }
}
