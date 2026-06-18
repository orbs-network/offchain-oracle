// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigUtils} from "test/utils/ConfigUtils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AlgebraCustomPoolOracle} from "contracts/oracles/AlgebraCustomPoolOracle.sol";

contract AlgebraCustomPoolOracleBscTest is ConfigUtils {
    string private constant CHAIN_KEY = ".56";

    IERC20 private constant WBNB = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 private constant DAI = IERC20(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3);
    IERC20 private constant ETH = IERC20(0x2170Ed0880ac9A755fd29B2688956BD959F933F8);
    IERC20 private constant USDC = IERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);
    IERC20 private constant USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 private constant BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20 private constant BTCB = IERC20(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c);

    address private thenaV3Oracle;
    address private thenaV3FeeOnlyOracle;

    function setUp() public {
        vm.createSelectFork(_rpcUrl("bnb"));

        string memory json = vm.readFile(CONFIG_PATH);
        thenaV3Oracle =
            vm.parseJsonAddress(json, string.concat(_adapterPathByLabel(json, CHAIN_KEY, "ThenaV3"), ".env.address"));
        thenaV3FeeOnlyOracle =
            vm.parseJsonAddress(json, string.concat(_adapterPathByLabel(json, CHAIN_KEY, "ThenaV3-2"), ".env.address"));
    }

    function test_thenaV3_resolvesPools() public view {
        AlgebraCustomPoolOracle oracle = AlgebraCustomPoolOracle(thenaV3Oracle);
        (uint256 rate, uint256 weight) = _findRate(oracle);
        assertGt(rate, 0, "no Thena V3 pool resolved");
        assertGt(weight, 0, "no Thena V3 pool weight");
    }

    function test_thenaV3FeeOnly_resolvesPools() public view {
        AlgebraCustomPoolOracle oracle = AlgebraCustomPoolOracle(thenaV3FeeOnlyOracle);
        (uint256 rate, uint256 weight) = _findRate(oracle);
        assertGt(rate, 0, "no Thena V3 fee-only pool resolved");
        assertGt(weight, 0, "no Thena V3 fee-only pool weight");
    }

    function _findRate(AlgebraCustomPoolOracle oracle) internal view returns (uint256 rate, uint256 weight) {
        IERC20[] memory tokens = new IERC20[](7);
        tokens[0] = WBNB;
        tokens[1] = USDC;
        tokens[2] = USDT;
        tokens[3] = BUSD;
        tokens[4] = DAI;
        tokens[5] = BTCB;
        tokens[6] = ETH;

        for (uint256 i = 0; i < tokens.length; i++) {
            for (uint256 j = i + 1; j < tokens.length; j++) {
                (rate, weight) = oracle.getRate(tokens[i], tokens[j], NONE, 0);
                if (rate > 0 && weight > 0) return (rate, weight);
                (rate, weight) = oracle.getRate(tokens[j], tokens[i], NONE, 0);
                if (rate > 0 && weight > 0) return (rate, weight);
            }
        }

        return (0, 0);
    }
}
