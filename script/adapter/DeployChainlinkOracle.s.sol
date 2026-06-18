// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {ChainlinkOracle} from "contracts/oracles/ChainlinkOracle.sol";
import {IChainlink} from "contracts/interfaces/IChainlink.sol";

contract DeployChainlinkOracle is ConfigDeploy {
    function run() external returns (ChainlinkOracle oracle) {
        address chainlink = _adapterAddress("chainlink");
        require(chainlink != address(0), "missing chainlink");

        vm.broadcast();
        oracle = new ChainlinkOracle(IChainlink(chainlink));
        vm.broadcast();
        _addOracle(oracle, OffchainOracle.OracleType.ETH);
    }
}
