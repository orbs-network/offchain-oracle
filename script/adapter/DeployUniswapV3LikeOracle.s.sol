// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {UniswapV3LikeOracle} from "contracts/oracles/UniswapV3LikeOracle.sol";

contract DeployUniswapV3LikeOracle is ConfigDeploy {
    function run() external returns (UniswapV3LikeOracle oracle) {
        address factory = _adapterAddress("factory");
        bytes32 initcodehash = _adapterBytes32("initcodehash");
        uint256[] memory fees = _adapterUintArray("fees");
        require(factory != address(0), "missing factory");
        require(initcodehash != bytes32(0), "missing initcodehash");
        require(fees.length > 0, "missing fees");

        vm.broadcast();
        oracle = new UniswapV3LikeOracle(factory, initcodehash, _toUint24(fees));
        vm.broadcast();
        _addOracle(oracle, OffchainOracle.OracleType.WETH);
    }
}
