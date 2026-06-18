// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigUtils} from "test/utils/ConfigUtils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {MultiWrapper} from "contracts/MultiWrapper.sol";
import {BaseCoinWrapper} from "contracts/wrappers/BaseCoinWrapper.sol";
import {IOracle} from "contracts/interfaces/IOracle.sol";
import {IWrapper} from "contracts/interfaces/IWrapper.sol";

contract OffchainOracleAvaxTest is ConfigUtils {
    address private constant WETH = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address private constant TOKEN_FBOMB = 0x5C09A9cE08C4B332Ef1CC5f7caDB1158C32767Ce;
    string private constant CHAIN_KEY = ".43114";

    OffchainOracle private aggregator;

    function setUp() public {
        vm.createSelectFork(_rpcUrl("avax"));
        _deployFromConfig();
    }

    function test_fBomb_hasRateToEth_onLatestFork() public {
        uint256 rateThreshold10 = aggregator.getRateToEthWithThreshold(IERC20(TOKEN_FBOMB), true, 10);
        uint256 rateThreshold0 = aggregator.getRateToEthWithThreshold(IERC20(TOKEN_FBOMB), true, 0);

        emit log_named_uint("rateToEth_threshold10", rateThreshold10);
        emit log_named_uint("rateToEth_threshold0", rateThreshold0);

        assertGt(rateThreshold10, 0, "rateToEth=0 at threshold 10");
    }

    function _deployFromConfig() private {
        address owner = address(this);
        string memory json = vm.readFile(CONFIG_PATH);

        IERC20[] memory connectors = _runtimeConnectors(json, CHAIN_KEY, WETH);

        BaseCoinWrapper baseCoinWrapper = new BaseCoinWrapper(NATIVE, IERC20(WETH));
        IWrapper[] memory initialWrappers = new IWrapper[](1);
        initialWrappers[0] = baseCoinWrapper;
        MultiWrapper multiWrapper = new MultiWrapper(initialWrappers, owner);

        IOracle[] memory emptyOracles = new IOracle[](0);
        OffchainOracle.OracleType[] memory emptyTypes = new OffchainOracle.OracleType[](0);
        aggregator = new OffchainOracle(multiWrapper, emptyOracles, emptyTypes, connectors, IERC20(WETH), owner);

        uint256 adaptersLength = _adaptersLength(json, CHAIN_KEY);
        for (uint256 i = 0; i < adaptersLength; i++) {
            address oracle = vm.parseJsonAddress(json, string.concat(_adapterPath(CHAIN_KEY, i), ".env.address"));
            aggregator.addOracle(IOracle(oracle), OffchainOracle.OracleType(0));
        }
    }
}
