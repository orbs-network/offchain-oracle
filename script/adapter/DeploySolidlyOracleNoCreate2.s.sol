// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {SolidlyOracleNoCreate2} from "contracts/oracles/SolidlyOracleNoCreate2.sol";

contract DeploySolidlyOracleNoCreate2 is ConfigDeploy {
    function run() external returns (SolidlyOracleNoCreate2 oracle) {
        address factory = _adapterAddress("factory");
        require(factory != address(0), "missing factory");

        vm.broadcast();
        oracle = new SolidlyOracleNoCreate2(factory);
        vm.broadcast();
        _addOracle(oracle, OffchainOracle.OracleType.WETH);
    }
}
