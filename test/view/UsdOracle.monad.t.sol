// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigUtils} from "test/utils/ConfigUtils.sol";
import {UsdOracle} from "contracts/view/UsdOracle.sol";

contract UsdOracleMonadTest is ConfigUtils {
    UsdOracle public oracle;

    address private constant WBASE = 0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A;

    address public usdc;
    address public usdt;
    address public weth;
    address public wbtc;

    function setUp() public {
        vm.createSelectFork(_rpcUrl("monad"));

        string memory json = vm.readFile(CONFIG_PATH);
        string memory chainKey = _chainPath("143");
        string memory aggregatorRaw = vm.parseJsonString(json, string.concat(chainKey, ".aggregator"));
        require(bytes(aggregatorRaw).length != 0, "missing aggregator for chain 143");
        address aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        require(aggregator != address(0), "aggregator is zero for chain 143");
        address[] memory connectors = _configConnectors(json, chainKey);
        address[] memory feeds = vm.parseJsonAddressArray(json, string.concat(chainKey, ".env.feeds"));
        require(connectors.length >= 4, "connectors length < 4");
        require(feeds.length == connectors.length + 2, "feeds length must be connectors+2");

        address[] memory deployTokens = _runtimeTokens(json, chainKey, WBASE);

        oracle = new UsdOracle(aggregator, deployTokens, feeds);

        weth = connectors[0];
        usdt = connectors[1];
        usdc = connectors[2];
        wbtc = connectors[3];
    }

    function testUsd_usdc() public view {
        (uint256 price,) = oracle.usd(usdc);
        assertGt(price, 0.9e18);
        assertLt(price, 1.1e18);
    }

    function testUsd_usdt() public view {
        (uint256 price,) = oracle.usd(usdt);
        assertGt(price, 0.9e18);
        assertLt(price, 1.1e18);
    }

    function testUsd_weth() public view {
        (uint256 price,) = oracle.usd(weth);
        assertGt(price, 100e18);
        assertLt(price, 10_000e18);
    }

    function testUsd_wbtc() public view {
        (uint256 price,) = oracle.usd(wbtc);
        assertGt(price, 1000e18);
        assertLt(price, 1_000_000e18);
    }
}
