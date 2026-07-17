// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {RpcUtils} from "test/utils/RpcUtils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ConfigUtils is RpcUtils {
    IERC20 internal constant NONE = IERC20(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);

    string internal constant CONFIG_PATH = "config.json";

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

    function _eq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
