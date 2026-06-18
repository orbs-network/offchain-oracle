// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {SolidlyOracle} from "contracts/oracles/SolidlyOracle.sol";

contract DeploySolidlyOracle is ConfigDeploy {
    function run() external returns (SolidlyOracle oracle) {
        address factory = _adapterAddress("factory");
        bytes32 initcodehash = _adapterBytes32("initcodehash");
        require(factory != address(0), "missing factory");
        require(initcodehash != bytes32(0), "missing initcodehash");

        vm.broadcast();
        oracle = new SolidlyOracle(factory, initcodehash);
        vm.broadcast();
        _addOracle(oracle, OffchainOracle.OracleType.WETH);
    }
}
