// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigUtils} from "test/utils/ConfigUtils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AlgebraOracle} from "contracts/oracles/AlgebraOracle.sol";
import {AlgebraCustomPoolOracle} from "contracts/oracles/AlgebraCustomPoolOracle.sol";

contract AlgebraCustomPoolOracleAvaxTest is ConfigUtils {
    string private constant CHAIN_KEY = ".43114";

    address private poolDeployer;
    address private cl50Deployer;
    bytes32 private initcodeHash;
    IERC20 private wavax;
    IERC20 private usdc;

    function setUp() public {
        vm.createSelectFork(_rpcUrl("avax"));

        string memory json = vm.readFile(CONFIG_PATH);
        string memory adapterPath = _adapterPathByLabel(json, CHAIN_KEY, "BlackholeCL50");
        poolDeployer = vm.parseJsonAddress(json, string.concat(adapterPath, ".env.poolDeployer"));
        cl50Deployer = vm.parseJsonAddress(json, string.concat(adapterPath, ".env.customDeployer"));
        initcodeHash = vm.parseJsonBytes32(json, string.concat(adapterPath, ".env.initcodehash"));

        address[] memory connectors = _configConnectors(json, CHAIN_KEY);
        require(connectors.length >= 2, "connectors length < 2");
        usdc = IERC20(connectors[1]);
        wavax = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    }

    function test_blackholeClCustomPoolOracle_resolvesWavaxUsdc() public {
        AlgebraCustomPoolOracle fixedOracle = new AlgebraCustomPoolOracle(poolDeployer, cl50Deployer, initcodeHash);
        (uint256 fixedRate, uint256 fixedWeight) = fixedOracle.getRate(wavax, usdc, NONE, 0);
        assertGt(fixedRate, 0, "fixed rate=0");
        assertGt(fixedWeight, 0, "fixed weight=0");

        // Prior AlgebraOracle config (factory = custom deployer) does not resolve pools.
        AlgebraOracle oldOracle = new AlgebraOracle(cl50Deployer, initcodeHash);
        (uint256 oldRate, uint256 oldWeight) = oldOracle.getRate(wavax, usdc, NONE, 0);
        assertEq(oldRate, 0, "old rate should be 0");
        assertEq(oldWeight, 0, "old weight should be 0");
    }
}
