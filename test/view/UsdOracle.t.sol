// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {UsdOracle} from "contracts/view/UsdOracle.sol";
import {UsdOracleCore} from "contracts/view/UsdOracleCore.sol";
import {MockAggregatorV3, MockOffchainOracleAggregator, MockToken} from "test/utils/UsdOracleMocks.sol";

contract UsdOracleTest is Test {
    UsdOracle public oracleUsd;
    MockOffchainOracleAggregator public offchainOracle;
    MockAggregatorV3 public ethUsdFeed;

    function setUp() public {
        offchainOracle = new MockOffchainOracleAggregator();
        ethUsdFeed = new MockAggregatorV3();

        // 3000 USD/ETH with 8 decimals
        ethUsdFeed.setDecimals(8);
        ethUsdFeed.setAnswer(3000e8, block.timestamp);

        address[] memory tokens = new address[](1);
        address[] memory feeds = new address[](1);
        tokens[0] = address(0); // ETH as base
        feeds[0] = address(ethUsdFeed);

        oracleUsd = new UsdOracle(address(offchainOracle), tokens, feeds);
    }

    function testEthUsd_scalesTo1e18() public view {
        (uint256 price, uint8 decimals) = oracleUsd.usd(address(0));
        assertEq(price, 3000e18);
        assertEq(decimals, 18);
    }

    function testUsd_convertsTokenToUsd() public {
        MockToken token = new MockToken(6);

        // rateToEth = ETH_atomic / token_atomic * 1e18
        // If 1 token (1e6) == 0.0005 ETH (5e14 wei):
        //   rateToEth = (5e14 / 1e6) * 1e18 = 5e26
        offchainOracle.setRateToEth(5e26);

        (uint256 usdPerToken, uint8 tokenDecimals) = oracleUsd.usd(address(token));
        assertEq(usdPerToken, 1.5e18); // 0.0005 ETH * 3000 USD/ETH = 1.5 USD
        assertEq(tokenDecimals, 6);
    }

    function testUsd_batch() public {
        MockToken token = new MockToken(6);
        offchainOracle.setRateToEth(5e26);

        address[] memory tokens = new address[](2);
        tokens[0] = address(0);
        tokens[1] = address(token);

        UsdOracleCore.Quote[] memory quotes = oracleUsd.usd(tokens);
        assertEq(quotes.length, 2);
        assertEq(quotes[0].price, 3000e18);
        assertEq(quotes[1].price, 1.5e18);
        assertEq(quotes[0].decimals, 18);
        assertEq(quotes[1].decimals, 6);
    }

    function testEthUsd_revertsOnStaleAnswer() public {
        ethUsdFeed.setAnswer(3000e8, block.timestamp);
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert(abi.encodeWithSelector(UsdOracleCore.StaleAnswer.selector, address(0)));
        oracleUsd.usd(address(0));
    }
}
