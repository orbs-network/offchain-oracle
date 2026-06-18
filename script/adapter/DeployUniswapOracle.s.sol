// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {UniswapOracle} from "contracts/oracles/UniswapOracle.sol";
import {IUniswapFactory} from "contracts/interfaces/IUniswapFactory.sol";

contract DeployUniswapOracle is ConfigDeploy {
    function run() external returns (UniswapOracle oracle) {
        address factory = _adapterAddress("factory");
        require(factory != address(0), "missing factory");

        vm.broadcast();
        oracle = new UniswapOracle(IUniswapFactory(factory));
        vm.broadcast();
        _addOracle(oracle, OffchainOracle.OracleType.ETH);
    }
}
