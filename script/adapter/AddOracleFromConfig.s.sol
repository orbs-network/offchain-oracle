// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {IOracle} from "contracts/interfaces/IOracle.sol";

/// @notice Adds an existing oracle (from config env.address) to OffchainOracle.
contract AddOracleFromConfig is ConfigDeploy {
    function run() external returns (address oracleAddr) {
        oracleAddr = _adapterAddress("address");
        require(oracleAddr != address(0), "adapter env.address is zero");
        vm.broadcast();
        _addOracle(IOracle(oracleAddr), OffchainOracle.OracleType.WETH);
    }
}
