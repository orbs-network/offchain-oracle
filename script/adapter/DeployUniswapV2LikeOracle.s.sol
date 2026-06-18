// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {UniswapV2LikeOracle} from "contracts/oracles/UniswapV2LikeOracle.sol";

contract DeployUniswapV2LikeOracle is ConfigDeploy {
    function run() external returns (UniswapV2LikeOracle oracle) {
        address factory = _adapterAddress("factory");
        bytes32 initcodehash = _adapterBytes32("initcodehash");
        require(factory != address(0), "missing factory");
        require(initcodehash != bytes32(0), "missing initcodehash");

        vm.broadcast();
        oracle = new UniswapV2LikeOracle(factory, initcodehash);
        vm.broadcast();
        _addOracle(oracle, OffchainOracle.OracleType.WETH);
    }
}
