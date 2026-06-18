// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ConfigUtils} from "test/utils/ConfigUtils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IOracle} from "contracts/interfaces/IOracle.sol";
import {AlgebraCustomPoolOracle} from "contracts/oracles/AlgebraCustomPoolOracle.sol";
import {UniswapV3LikeOracle} from "contracts/oracles/UniswapV3LikeOracle.sol";
import {V2FactoryLookupOracle} from "contracts/oracles/V2FactoryLookupOracle.sol";

contract TokenRoutesTest is ConfigUtils {
    string private constant FIXTURE_PATH = "test/fixtures/token-routes.json";

    struct Adapter {
        string label;
        IOracle oracle;
    }

    function testEthereumTokenRoutes() public {
        _checkChain("1");
    }

    function testEthereumAdapterProofPairs() public {
        _checkAdapterProofPairs("1");
    }

    function testOptimismTokenRoutes() public {
        _checkChain("10");
    }

    function testOptimismAdapterProofPairs() public {
        _checkAdapterProofPairs("10");
    }

    function testFlareTokenRoutes() public {
        _checkChain("14");
    }

    function testBnbTokenRoutes() public {
        _checkChain("56");
    }

    function testPolygonTokenRoutes() public {
        _checkChain("137");
    }

    function testPolygonAdapterProofPairs() public {
        _checkAdapterProofPairs("137");
    }

    function testMonadTokenRoutes() public {
        _checkChain("143");
    }

    function testMonadAdapterProofPairs() public {
        _checkAdapterProofPairs("143");
    }

    function testSonicTokenRoutes() public {
        _checkChain("146");
    }

    function testHyperEvmTokenRoutes() public {
        _checkChain("999");
    }

    function testSeiTokenRoutes() public {
        _checkChain("1329");
    }

    function testMantleTokenRoutes() public {
        _checkChain("5000");
    }

    function testBaseTokenRoutes() public {
        _checkChain("8453");
    }

    function testArbitrumTokenRoutes() public {
        _checkChain("42161");
    }

    function testArbitrumAdapterProofPairs() public {
        _checkAdapterProofPairs("42161");
    }

    function testAvalancheTokenRoutes() public {
        _checkChain("43114");
    }

    function testLineaTokenRoutes() public {
        _checkChain("59144");
    }

    function testBerachainTokenRoutes() public {
        _checkChain("80094");
    }

    function testKatanaTokenRoutes() public {
        _checkChain("747474");
    }

    function _checkChain(string memory chainIdString) private {
        string memory routesJson = vm.readFile(FIXTURE_PATH);
        vm.createSelectFork(_rpcUrl(chainIdString));

        string memory configJson = vm.readFile(CONFIG_PATH);
        string memory chainPath = _chainPath(chainIdString);
        address wNative = vm.parseJsonAddress(routesJson, string.concat(chainPath, ".wnative"));
        address[] memory tokens = vm.parseJsonAddressArray(routesJson, string.concat(chainPath, ".tokens"));
        IERC20[] memory connectors = _runtimeConnectors(configJson, chainPath, wNative);
        Adapter[] memory adapters = _adapters(configJson, chainPath);

        require(tokens.length > 0, string.concat("missing tokens for chain ", chainIdString));
        require(adapters.length > 0, string.concat("missing adapters for chain ", chainIdString));
        address[] memory adapterProbeTokens = _adapterProbeTokens(tokens, connectors);
        bool[] memory adapterHasProof = _adapterProofs(routesJson, chainPath, adapters);

        for (uint256 i = 0; i < tokens.length; i++) {
            require(!_isConnector(tokens[i], connectors), string.concat("token is connector on chain ", chainIdString));

            bool tokenHasRoute;
            for (uint256 j = 0; j < adapters.length; j++) {
                if (adapterHasProof[j]) continue;
                if (_hasRoute(adapters[j].oracle, IERC20(tokens[i]), IERC20(wNative), connectors)) {
                    tokenHasRoute = true;
                }
            }

            assertTrue(tokenHasRoute, string.concat("token has zero liquidity on chain ", chainIdString));
        }

        for (uint256 i = 0; i < adapters.length; i++) {
            if (adapterHasProof[i]) continue;

            assertTrue(
                _hasAnyRoute(adapters[i].oracle, IERC20(wNative), connectors, adapterProbeTokens),
                string.concat("adapter ", adapters[i].label, " has zero liquidity on chain ", chainIdString)
            );
        }

        _assertAdapterProofPairs(routesJson, chainPath, adapters);
    }

    function _checkAdapterProofPairs(string memory chainIdString) private {
        string memory routesJson = vm.readFile(FIXTURE_PATH);
        vm.createSelectFork(_rpcUrl(chainIdString));

        string memory configJson = vm.readFile(CONFIG_PATH);
        string memory chainPath = _chainPath(chainIdString);
        Adapter[] memory adapters = _adapters(configJson, chainPath);

        _assertAdapterProofPairs(routesJson, chainPath, adapters);
    }

    function _adapters(string memory configJson, string memory chainPath) private returns (Adapter[] memory adapters) {
        uint256 adaptersLength = _adaptersLength(configJson, chainPath);
        adapters = new Adapter[](adaptersLength);
        for (uint256 i = 0; i < adaptersLength; i++) {
            string memory adapterPath = _adapterPath(chainPath, i);
            adapters[i] = Adapter({
                label: vm.parseJsonString(configJson, string.concat(adapterPath, ".label")),
                oracle: _newOracle(configJson, chainPath, i)
            });
        }
    }

    function _newOracle(string memory configJson, string memory chainPath, uint256 index) private returns (IOracle) {
        string memory adapterPath = _adapterPath(chainPath, index);
        string memory addressPath = string.concat(adapterPath, ".env.address");
        if (vm.keyExistsJson(configJson, addressPath)) {
            return IOracle(vm.parseJsonAddress(configJson, addressPath));
        }

        string memory name = vm.parseJsonString(configJson, string.concat(adapterPath, ".name"));

        if (_eq(name, "UniswapV3LikeOracle")) {
            return new UniswapV3LikeOracle(
                vm.parseJsonAddress(configJson, string.concat(adapterPath, ".env.factory")),
                vm.parseJsonBytes32(configJson, string.concat(adapterPath, ".env.initcodehash")),
                _toUint24(vm.parseJsonUintArray(configJson, string.concat(adapterPath, ".env.fees")))
            );
        }

        if (_eq(name, "AlgebraCustomPoolOracle")) {
            address customDeployer;
            string memory customDeployerPath = string.concat(adapterPath, ".env.customDeployer");
            if (vm.keyExistsJson(configJson, customDeployerPath)) {
                customDeployer = vm.parseJsonAddress(configJson, customDeployerPath);
            }

            return new AlgebraCustomPoolOracle(
                vm.parseJsonAddress(configJson, string.concat(adapterPath, ".env.poolDeployer")),
                customDeployer,
                vm.parseJsonBytes32(configJson, string.concat(adapterPath, ".env.initcodehash"))
            );
        }

        if (_eq(name, "V2FactoryLookupOracle")) {
            return
                new V2FactoryLookupOracle(vm.parseJsonAddress(configJson, string.concat(adapterPath, ".env.factory")));
        }

        revert(string.concat("unsupported undeployed adapter ", name));
    }

    function _hasRoute(IOracle oracle, IERC20 token, IERC20 wNative, IERC20[] memory connectors)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < connectors.length; i++) {
            IERC20 connector = connectors[i];
            if (connector == token || connector == wNative) continue;
            try oracle.getRate(token, wNative, connector, 0) returns (uint256 rate, uint256 weight) {
                if (rate > 0 && weight > 0) return true;
            } catch {}
        }

        return false;
    }

    function _hasAnyRoute(IOracle oracle, IERC20 wNative, IERC20[] memory connectors, address[] memory probeTokens)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < probeTokens.length; i++) {
            IERC20 token = IERC20(probeTokens[i]);
            if (_isSpecialConnector(token, wNative)) continue;
            if (_hasRoute(oracle, token, wNative, connectors)) return true;
        }

        return false;
    }

    function _assertAdapterProofPairs(string memory routesJson, string memory chainPath, Adapter[] memory adapters)
        private
        view
    {
        uint256 adapterPairsLength = _adapterPairsLength(routesJson, chainPath);
        for (uint256 i = 0; i < adapterPairsLength; i++) {
            string memory adapterPairsPath = _adapterPairsPath(chainPath, i);
            string memory label = vm.parseJsonString(routesJson, string.concat(adapterPairsPath, ".label"));
            IOracle oracle = _adapterByLabel(adapters, label);
            address[][] memory pairs =
                abi.decode(vm.parseJson(routesJson, string.concat(adapterPairsPath, ".pairs")), (address[][]));

            require(pairs.length >= 3, string.concat("adapter ", label, " proof needs three pairs"));
            for (uint256 j = 0; j < pairs.length; j++) {
                require(pairs[j].length == 2, string.concat("adapter ", label, " proof pair is invalid"));
                assertTrue(
                    _hasDirectPair(oracle, IERC20(pairs[j][0]), IERC20(pairs[j][1])),
                    string.concat("adapter ", label, " proof pair has zero liquidity")
                );
            }
        }
    }

    function _adapterProofs(string memory routesJson, string memory chainPath, Adapter[] memory adapters)
        private
        view
        returns (bool[] memory hasProof)
    {
        hasProof = new bool[](adapters.length);
        for (uint256 i = 0; i < adapters.length; i++) {
            hasProof[i] = _hasAdapterProof(routesJson, chainPath, adapters[i].label);
        }
    }

    function _hasAdapterProof(string memory routesJson, string memory chainPath, string memory label)
        private
        view
        returns (bool)
    {
        uint256 adapterPairsLength = _adapterPairsLength(routesJson, chainPath);
        for (uint256 i = 0; i < adapterPairsLength; i++) {
            string memory adapterPairsPath = _adapterPairsPath(chainPath, i);
            if (_eq(vm.parseJsonString(routesJson, string.concat(adapterPairsPath, ".label")), label)) return true;
        }

        return false;
    }

    function _hasDirectPair(IOracle oracle, IERC20 tokenA, IERC20 tokenB) private view returns (bool) {
        try oracle.getRate(tokenA, tokenB, NONE, 0) returns (uint256 rate, uint256 weight) {
            return rate > 0 && weight > 0;
        } catch {
            return false;
        }
    }

    function _adapterByLabel(Adapter[] memory adapters, string memory label) private pure returns (IOracle) {
        for (uint256 i = 0; i < adapters.length; i++) {
            if (_eq(adapters[i].label, label)) return adapters[i].oracle;
        }

        revert(string.concat("missing adapter label ", label));
    }

    function _adapterPairsPath(string memory chainPath, uint256 index) private pure returns (string memory) {
        return string.concat(chainPath, ".adapterPairs[", vm.toString(index), "]");
    }

    function _adapterPairsLength(string memory routesJson, string memory chainPath)
        private
        view
        returns (uint256 length)
    {
        while (vm.keyExistsJson(routesJson, string.concat(_adapterPairsPath(chainPath, length), ".label"))) {
            length++;
        }
    }

    function _isConnector(address token, IERC20[] memory connectors) private pure returns (bool) {
        for (uint256 i = 0; i < connectors.length; i++) {
            if (address(connectors[i]) == token) return true;
        }
        return false;
    }

    function _isSpecialConnector(IERC20 token, IERC20 wNative) private pure returns (bool) {
        return token == NONE || token == NATIVE || token == wNative;
    }

    function _adapterProbeTokens(address[] memory tokens, IERC20[] memory connectors)
        private
        pure
        returns (address[] memory probeTokens)
    {
        probeTokens = new address[](tokens.length + connectors.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            probeTokens[i] = tokens[i];
        }
        for (uint256 i = 0; i < connectors.length; i++) {
            probeTokens[tokens.length + i] = address(connectors[i]);
        }
    }

    function _toUint24(uint256[] memory src) private pure returns (uint24[] memory dst) {
        dst = new uint24[](src.length);
        for (uint256 i = 0; i < src.length; i++) {
            dst[i] = uint24(src[i]);
        }
    }
}
