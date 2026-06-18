// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {RpcUtils} from "test/utils/RpcUtils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ConfigUtils is RpcUtils {
    IERC20 internal constant NONE = IERC20(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
    IERC20 internal constant NATIVE = IERC20(address(0));

    string internal constant CONFIG_PATH = "config.json";

    function _chainPath(string memory chainId) internal pure returns (string memory) {
        return string.concat(".", chainId);
    }

    function _configConnectors(string memory json, string memory chainPath) internal pure returns (address[] memory) {
        return vm.parseJsonAddressArray(json, string.concat(chainPath, ".connectors"));
    }

    function _adapterPath(string memory chainPath, uint256 index) internal pure returns (string memory) {
        return string.concat(chainPath, ".adapters[", vm.toString(index), "]");
    }

    function _adaptersLength(string memory json, string memory chainPath) internal view returns (uint256 length) {
        while (vm.keyExistsJson(json, string.concat(_adapterPath(chainPath, length), ".name"))) {
            length++;
        }
    }

    function _adapterPathByLabel(string memory json, string memory chainPath, string memory label)
        internal
        view
        returns (string memory)
    {
        return _adapterPath(chainPath, _adapterIndexByLabel(json, chainPath, label));
    }

    function _adapterIndexByLabel(string memory json, string memory chainPath, string memory label)
        internal
        view
        returns (uint256)
    {
        uint256 adaptersLength = _adaptersLength(json, chainPath);
        for (uint256 i = 0; i < adaptersLength; i++) {
            string memory adapterPath = _adapterPath(chainPath, i);
            string memory labelPath = string.concat(adapterPath, ".label");
            if (vm.keyExistsJson(json, labelPath) && _eq(vm.parseJsonString(json, labelPath), label)) {
                return i;
            }
        }

        revert(string.concat("missing adapter label ", label));
    }

    function _runtimeConnectors(string memory json, string memory chainPath, address wNative)
        internal
        pure
        returns (IERC20[] memory connectors)
    {
        address[] memory configConnectors = _configConnectors(json, chainPath);
        connectors = new IERC20[](configConnectors.length + 3);
        connectors[0] = NONE;
        connectors[1] = NATIVE;
        connectors[2] = IERC20(wNative);
        for (uint256 i = 0; i < configConnectors.length; i++) {
            connectors[i + 3] = IERC20(configConnectors[i]);
        }
    }

    function _runtimeTokens(string memory json, string memory chainPath, address wNative)
        internal
        pure
        returns (address[] memory tokens)
    {
        address[] memory configConnectors = _configConnectors(json, chainPath);
        tokens = new address[](configConnectors.length + 2);
        tokens[0] = address(NATIVE);
        tokens[1] = wNative;
        for (uint256 i = 0; i < configConnectors.length; i++) {
            tokens[i + 2] = configConnectors[i];
        }
    }

    function _eq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
