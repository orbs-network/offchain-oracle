// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OffchainOracle} from "contracts/OffchainOracle.sol";
import {IOracle} from "contracts/interfaces/IOracle.sol";

abstract contract ConfigDeploy is Script {
    string internal constant CONFIG_PATH = "config.json";
    string internal _json;

    struct DeployConfig {
        string chainKey;
        uint256 index;
        address aggregator;
        bytes32 salt;
        bytes32 aggregatorSalt;
    }

    DeployConfig internal cfg;
    address internal owner;
    IERC20 internal weth;

    function setUp() public virtual {
        _loadConfig();
    }

    function _loadConfig() internal {
        _json = vm.readFile(CONFIG_PATH);
        cfg.chainKey = string.concat(".", vm.toString(block.chainid));
        cfg.index = vm.envOr("INDEX", uint256(0));
        owner = vm.envAddress("ETH_FROM");
        require(owner != address(0), "missing ETH_FROM env");
        weth = IERC20(vm.envAddress("WETH"));
        require(address(weth) != address(0), "missing WETH env");

        cfg.aggregator = _cfgAddress("aggregator");
        cfg.salt = _cfgBytes32OrZero("salt");
        cfg.aggregatorSalt = _cfgBytes32OrZero("aggregatorSalt");
    }

    function _envPath(string memory key) internal view returns (string memory) {
        return string.concat(cfg.chainKey, ".env.", key);
    }

    function _adapterEnvPath(string memory key) internal view returns (string memory) {
        return string.concat(cfg.chainKey, ".adapters[", vm.toString(cfg.index), "].env.", key);
    }

    function _logCreate2(bytes memory creationCode, bytes memory args) internal pure {
        console.logBytes32(hashInitCode(creationCode, args));
    }

    function _addOracle(IOracle oracle, OffchainOracle.OracleType oracleType) internal {
        OffchainOracle(cfg.aggregator).addOracle(oracle, oracleType);
    }

    function _toUint24(uint256[] memory src) internal pure returns (uint24[] memory dst) {
        dst = new uint24[](src.length);
        for (uint256 i = 0; i < src.length; i++) {
            dst[i] = uint24(src[i]);
        }
    }

    function _toInt24(uint256[] memory src) internal pure returns (int24[] memory dst) {
        dst = new int24[](src.length);
        for (uint256 i = 0; i < src.length; i++) {
            dst[i] = int24(int256(src[i]));
        }
    }

    function _cfgPath(string memory key) private view returns (string memory) {
        return string.concat(cfg.chainKey, ".", key);
    }

    function _cfgAddress(string memory key) internal view returns (address addr) {
        string memory path = _cfgPath(key);
        if (vm.keyExistsJson(_json, path)) addr = vm.parseJsonAddress(_json, path);
    }

    function _cfgAddressArray(string memory key) internal view returns (address[] memory arr) {
        string memory path = _cfgPath(key);
        if (vm.keyExistsJson(_json, path)) return vm.parseJsonAddressArray(_json, path);
        return new address[](0);
    }

    function _cfgBytes32OrZero(string memory key) internal view returns (bytes32 value) {
        string memory path = _cfgPath(key);
        if (!vm.keyExistsJson(_json, path)) return bytes32(0);
        string memory raw = vm.parseJsonString(_json, path);
        if (bytes(raw).length == 0) return bytes32(0);
        return vm.parseJsonBytes32(_json, path);
    }

    function _envAddressArray(string memory key) internal view returns (address[] memory arr) {
        string memory path = _envPath(key);
        return vm.keyExistsJson(_json, path) ? vm.parseJsonAddressArray(_json, path) : new address[](0);
    }

    function _envBytes32Array(string memory key) internal view returns (bytes32[] memory arr) {
        string memory path = _envPath(key);
        return vm.keyExistsJson(_json, path) ? vm.parseJsonBytes32Array(_json, path) : new bytes32[](0);
    }

    function _envStringArray(string memory key) internal view returns (string[] memory arr) {
        string memory path = _envPath(key);
        return vm.keyExistsJson(_json, path) ? vm.parseJsonStringArray(_json, path) : new string[](0);
    }

    function _envUintArray(string memory key) internal view returns (uint256[] memory arr) {
        string memory path = _envPath(key);
        return vm.keyExistsJson(_json, path) ? vm.parseJsonUintArray(_json, path) : new uint256[](0);
    }

    function _envAddress(string memory key) internal view returns (address addr) {
        string memory path = _envPath(key);
        if (vm.keyExistsJson(_json, path)) addr = vm.parseJsonAddress(_json, path);
    }

    function _tokens() internal view returns (address[] memory tokens) {
        address[] memory baseTokens = _cfgAddressArray("connectors");
        tokens = new address[](baseTokens.length + 2);
        tokens[0] = address(0);
        tokens[1] = address(weth);
        for (uint256 i = 0; i < baseTokens.length; i++) {
            tokens[i + 2] = baseTokens[i];
        }
    }

    function _adapterAddress(string memory key) internal view returns (address addr) {
        string memory json = _json;
        string memory path = _adapterEnvPath(key);
        if (vm.keyExistsJson(json, path)) addr = vm.parseJsonAddress(json, path);
    }

    function _adapterBytes32(string memory key) internal view returns (bytes32 value) {
        string memory json = _json;
        string memory path = _adapterEnvPath(key);
        if (vm.keyExistsJson(json, path)) value = vm.parseJsonBytes32(json, path);
    }

    function _adapterUint(string memory key) internal view returns (uint256 value) {
        string memory json = _json;
        string memory path = _adapterEnvPath(key);
        if (vm.keyExistsJson(json, path)) value = vm.parseJsonUint(json, path);
    }

    function _adapterUintArray(string memory key) internal view returns (uint256[] memory value) {
        string memory json = _json;
        string memory path = _adapterEnvPath(key);
        return vm.keyExistsJson(json, path) ? vm.parseJsonUintArray(json, path) : new uint256[](0);
    }
}
