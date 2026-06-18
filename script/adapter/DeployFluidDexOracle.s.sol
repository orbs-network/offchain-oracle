// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {FluidDexOracle, IFluidDexReservesResolver} from "contracts/oracles/FluidDexOracle.sol";

contract DeployFluidDexOracle is ConfigDeploy {
    function run() external returns (FluidDexOracle oracle) {
        address resolver = _adapterAddress("resolver");
        require(resolver != address(0), "missing resolver");

        vm.broadcast();
        oracle = new FluidDexOracle(IFluidDexReservesResolver(resolver));
        vm.broadcast();
        _addOracle(oracle, OffchainOracle.OracleType.WETH);
    }
}
