// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {UniswapV4LikeOracle} from "contracts/oracles/UniswapV4LikeOracle.sol";
import {IUniswapV4StateView} from "contracts/interfaces/IUniswapV4StateView.sol";

contract DeployUniswapV4LikeOracle is ConfigDeploy {
    function run() external returns (UniswapV4LikeOracle oracle) {
        address stateView = _adapterAddress("stateview");
        uint256[] memory fees = _adapterUintArray("fees");
        uint256[] memory spacings = _adapterUintArray("spacings");
        require(stateView != address(0), "missing stateview");
        require(fees.length > 0, "missing fees");
        require(spacings.length > 0, "missing spacings");

        vm.broadcast();
        oracle = new UniswapV4LikeOracle(IUniswapV4StateView(stateView), _toUint24(fees), _toInt24(spacings));
        vm.broadcast();
        _addOracle(oracle, OffchainOracle.OracleType.WETH);
    }
}
