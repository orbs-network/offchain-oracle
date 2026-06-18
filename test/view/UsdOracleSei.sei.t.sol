// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigUtils} from "test/utils/ConfigUtils.sol";
import {UsdOracleSei, ISeiPrecompile} from "contracts/view/UsdOracleSei.sol";
import {UsdOracleCore} from "contracts/view/UsdOracleCore.sol";

contract UsdOracleSeiTest is ConfigUtils {
    UsdOracleSei public oracleSei;

    address private constant WBASE = 0xE30feDd158A2e3b13e9badaeABaFc5516e95e8C7;

    address public aggregator;
    address public usdc;
    address public usdt;
    address public weth;
    address public wbtc;
    address public sei;
    address public wsei;

    function setUp() public {
        string memory json = vm.readFile(CONFIG_PATH);
        string memory chainKey = _chainPath("1329");
        string memory aggregatorRaw = vm.parseJsonString(json, string.concat(chainKey, ".aggregator"));
        require(bytes(aggregatorRaw).length != 0, "missing aggregator for chain 1329");
        address[] memory deployConnectors = _configConnectors(json, chainKey);
        string[] memory deployDenoms = vm.parseJsonStringArray(json, string.concat(chainKey, ".env.denoms"));
        aggregator = vm.parseJsonAddress(json, string.concat(chainKey, ".aggregator"));
        require(aggregator != address(0), "aggregator is zero for chain 1329");
        require(deployConnectors.length >= 4, "connectors length < 4");
        require(deployDenoms.length == deployConnectors.length + 2, "denoms length must be connectors+2");

        address[] memory tokens = _runtimeTokens(json, chainKey, WBASE);
        string[] memory denoms = deployDenoms;

        sei = tokens[0];
        wsei = tokens[1];
        usdc = tokens[2];
        usdt = tokens[3];
        weth = tokens[4];
        wbtc = tokens[5];

        vm.createSelectFork(_rpcUrl("sei"));

        // Foundry (revm) doesn't implement Sei's custom oracle precompile at 0x1008. We fetch the real
        // precompile output via `vm.rpc(eth_call)` and mock the call locally for determinism.
        // Only map the base token (USDC) to force `usd(token)` to go through the offchain oracle path for other tokens.
        address[] memory baseTokens = new address[](1);
        string[] memory baseDenoms = new string[](1);
        baseTokens[0] = usdc;
        baseDenoms[0] = denoms[2];

        oracleSei = new UsdOracleSei(aggregator, baseTokens, baseDenoms);

        address seiPrecompile = address(oracleSei.SEI_PRECOMPILE());
        bytes memory callData = abi.encodeWithSelector(ISeiPrecompile.getExchangeRates.selector);
        try this.fetchRates(seiPrecompile, callData) returns (bytes memory rawRates) {
            vm.mockCall(seiPrecompile, callData, rawRates);
        } catch {
            vm.skip(true, "Sei oracle precompile rates unavailable");
        }
    }

    function testUsd_usdc() public view {
        (uint256 price,) = oracleSei.usd(usdc);
        assertGt(price, 0.9e18);
        assertLt(price, 1.1e18);
    }

    function testUsd_usdt() public view {
        (uint256 price,) = oracleSei.usd(usdt);
        assertGt(price, 0.9e18);
        assertLt(price, 1.1e18);
    }

    function testUsd_weth() public view {
        (uint256 price,) = oracleSei.usd(weth);
        assertGt(price, 100e18);
        assertLt(price, 100_000e18);
    }

    function testUsd_wbtc() public view {
        (uint256 price,) = oracleSei.usd(wbtc);
        assertGt(price, 1000e18);
        assertLt(price, 10_000_000e18);
    }

    function testUsd_sei() public view {
        (uint256 price,) = oracleSei.usd(sei);
        assertGt(price, 0.0001e18);
        assertLt(price, 100e18);
    }

    function testUsd_wsei() public view {
        (uint256 price,) = oracleSei.usd(wsei);
        assertGt(price, 0.0001e18);
        assertLt(price, 100e18);
    }

    function testUsd_batch() public view {
        address[] memory tokens = new address[](3);
        tokens[0] = usdc;
        tokens[1] = usdt;
        tokens[2] = wbtc;

        UsdOracleCore.Quote[] memory quotes = oracleSei.usd(tokens);
        assertEq(quotes.length, 3);

        assertGt(quotes[0].price, 0.9e18);
        assertLt(quotes[0].price, 1.1e18);
        assertGt(quotes[1].price, 0.9e18);
        assertLt(quotes[1].price, 1.1e18);
        assertGt(quotes[2].price, 1000e18);
        assertLt(quotes[2].price, 10_000_000e18);
    }

    function _fetchRates(address precompile, bytes memory callData) internal returns (bytes memory raw) {
        string memory params =
            string.concat('[{"to":"', vm.toString(precompile), '","data":"', vm.toString(callData), '"},"latest"]');
        bytes memory resp = vm.rpc("eth_call", params);
        if (resp.length > 0 && resp[0] == bytes1("{")) {
            raw = vm.parseJsonBytes(string(resp), ".result");
        } else if (resp.length > 1 && resp[0] == bytes1("0") && resp[1] == bytes1("x")) {
            raw = vm.parseBytes(string(resp));
        } else {
            raw = resp;
        }
    }

    function fetchRates(address precompile, bytes memory callData) external returns (bytes memory raw) {
        return _fetchRates(precompile, callData);
    }
}
