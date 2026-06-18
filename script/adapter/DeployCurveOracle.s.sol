// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {CurveOracle} from "contracts/oracles/CurveOracle.sol";
import {ICurveProvider} from "contracts/interfaces/ICurveProvider.sol";

contract DeployCurveOracle is ConfigDeploy {
    function run() external returns (CurveOracle oracle) {
        address provider = _adapterAddress("provider");
        uint256 maxPools = _adapterUint("maxpools");
        require(provider != address(0), "missing provider");
        require(maxPools != 0, "missing maxpools");

        vm.broadcast();
        oracle = new CurveOracle(ICurveProvider(provider), maxPools);
        vm.broadcast();
        _addOracle(oracle, OffchainOracle.OracleType.WETH);
    }
}
