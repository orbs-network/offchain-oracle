// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigDeploy} from "script/ConfigDeploy.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MultiWrapper} from "contracts/MultiWrapper.sol";
import {IOracle} from "contracts/interfaces/IOracle.sol";
import {IWrapper} from "contracts/interfaces/IWrapper.sol";
import {BaseCoinWrapper} from "contracts/wrappers/BaseCoinWrapper.sol";

contract DeployAggregator is ConfigDeploy {
    IERC20 private constant _NONE = IERC20(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
    IERC20 private constant _NATIVE = IERC20(0x0000000000000000000000000000000000000000);

    function run() external returns (OffchainOracle aggregator) {
        IERC20[] memory connectors = _appendConnectors(_cfgAddressArray("connectors"), weth);

        // Deploy base WETH wrapper and seed MultiWrapper with it
        vm.broadcast();
        BaseCoinWrapper baseCoinWrapper = new BaseCoinWrapper(_NATIVE, weth);
        IWrapper[] memory initialWrappers = new IWrapper[](1);
        initialWrappers[0] = baseCoinWrapper;

        vm.broadcast();
        MultiWrapper multiWrapper = new MultiWrapper(initialWrappers, owner);

        // Deploy offchain oracle (empty oracles; add later with dedicated scripts)
        IOracle[] memory emptyOracles = new IOracle[](0);
        OffchainOracle.OracleType[] memory emptyTypes = new OffchainOracle.OracleType[](0);

        _logCreate2(
            type(OffchainOracle).creationCode,
            abi.encode(multiWrapper, emptyOracles, emptyTypes, connectors, weth, owner)
        );

        vm.broadcast();
        aggregator = new OffchainOracle{salt: cfg.aggregatorSalt}(
            multiWrapper, emptyOracles, emptyTypes, connectors, weth, owner
        );
    }

    // ------- Internals -------
    function _appendConnectors(address[] memory envConnectors, IERC20 wNative)
        private
        pure
        returns (IERC20[] memory connectors)
    {
        connectors = new IERC20[](envConnectors.length + 3);
        connectors[0] = _NONE;
        connectors[1] = _NATIVE;
        connectors[2] = wNative;
        for (uint256 i = 0; i < envConnectors.length; i++) {
            connectors[i + 3] = IERC20(envConnectors[i]);
        }
    }
}
