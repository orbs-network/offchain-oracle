// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MooniswapOracle} from "contracts/oracles/MooniswapOracle.sol";
import {IMooniswapFactory} from "contracts/interfaces/IMooniswapFactory.sol";

contract DeployMooniswapOracle is ConfigDeploy {
    function run() external returns (MooniswapOracle oracle) {
        address factory = _adapterAddress("factory");
        require(factory != address(0), "missing factory");

        vm.broadcast();
        oracle = new MooniswapOracle(IMooniswapFactory(factory));
        vm.broadcast();
        _addOracle(oracle, OffchainOracle.OracleType.WETH_ETH);
    }
}
