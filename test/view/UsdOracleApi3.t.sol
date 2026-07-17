// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {UsdOracleApi3} from "contracts/view/UsdOracleApi3.sol";
import {MockOffchainOracleAggregator} from "test/utils/UsdOracleMocks.sol";

contract UsdOracleApi3Test is Test {
    UsdOracleApi3 public oracleUsd;
    MockOffchainOracleAggregator public offchainOracle;
    MockApi3ReaderProxy public ethUsdFeed;

    function setUp() public {
        offchainOracle = new MockOffchainOracleAggregator();
        ethUsdFeed = new MockApi3ReaderProxy();

        // API3 reader proxies return 18-decimal fixed-point values.
        ethUsdFeed.setAnswer(3000e18, uint32(block.timestamp));

        address[] memory tokens = new address[](1);
        address[] memory feeds = new address[](1);
        tokens[0] = address(0); // ETH as base
        feeds[0] = address(ethUsdFeed);

        oracleUsd = new UsdOracleApi3(address(offchainOracle), tokens, feeds);
    }

    function testEthUsd_readsApi3Value() public view {
        (uint256 price, uint8 decimals) = oracleUsd.usd(address(0));
        assertEq(price, 3000e18);
        assertEq(decimals, 18);
    }
}

contract MockApi3ReaderProxy {
    int224 public value;
    uint32 public timestamp;

    function setAnswer(int224 answer, uint32 updated) external {
        value = answer;
        timestamp = updated;
    }

    function read() external view returns (int224, uint32) {
        return (value, timestamp);
    }
}
