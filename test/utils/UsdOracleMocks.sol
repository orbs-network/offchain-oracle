// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IOffchainOracleAggregator} from "contracts/view/AggregatorLib.sol";
import {IChainlinkAggregatorV3} from "contracts/view/UsdOracle.sol";
import {IPythOracle} from "contracts/view/UsdOraclePyth.sol";

contract MockOffchainOracleAggregator is IOffchainOracleAggregator {
    uint256 public rate;

    function setRateToEth(uint256 _rate) external {
        rate = _rate;
    }

    function setRateToBase(uint256 _rate) external {
        rate = _rate;
    }

    function getRateWithThreshold(IERC20, IERC20, bool, uint256) external view returns (uint256 weightedRate) {
        return rate;
    }
}

contract MockAggregatorV3 is IChainlinkAggregatorV3 {
    uint8 public override decimals;
    int256 public answer;
    uint256 public updated;

    function setDecimals(uint8 d) external {
        decimals = d;
    }

    function setAnswer(int256 a, uint256 t) external {
        answer = a;
        updated = t;
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 _answer, uint256 startedAt, uint256 _updated, uint80 answeredInRound)
    {
        return (1, answer, updated, updated, 1);
    }
}

    contract MockPythOracle is IPythOracle {
        struct PriceData {
            int64 price;
            uint64 confidence;
            int32 exponent;
            uint256 updated;
        }

        mapping(bytes32 => PriceData) public prices;

        function setPrice(bytes32 id, int64 price, uint64 confidence, int32 exponent, uint256 updated) external {
            prices[id] = PriceData(price, confidence, exponent, updated);
        }

        function getPriceUnsafe(bytes32 id)
            external
            view
            override
            returns (int64 price, uint64 confidence, int32 exponent, uint256 updated)
        {
            PriceData memory data = prices[id];
            return (data.price, data.confidence, data.exponent, data.updated);
        }
    }

    contract MockToken {
        uint8 private immutable _decimals;

        constructor(uint8 d) {
            _decimals = d;
        }

        function decimals() external view returns (uint8) {
            return _decimals;
        }
    }
