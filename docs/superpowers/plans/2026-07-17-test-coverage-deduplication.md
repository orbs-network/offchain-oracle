# Test Coverage Deduplication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove redundant live and shared-core tests while keeping E2E as the integration authority for bases, wrappers, feeds, and curated tokens.

**Architecture:** Preserve the existing `test/e2e` flow unchanged. Keep shared USD-oracle behavior in the Chainlink-backed core suite, retain only provider-specific decoding in the Pyth and API3 suites, and retain the unique BSC adapter fork test.

**Tech Stack:** Solidity 0.8.23, Foundry, zsh, jq, GNU parallel, local `chain`/`cast` tooling

---

## File Map

1. Delete `test/view/UsdOracle.monad.t.sol`: redundant single-chain live coverage.
2. Modify `test/view/UsdOraclePyth.t.sol`: keep only Pyth exponent scaling.
3. Modify `test/view/UsdOracleApi3.t.sol`: keep only API3 proxy decoding.
4. Modify `test/utils/ConfigUtils.sol`: retain helpers used by the BSC adapter test.
5. Modify `test/utils/UsdOracleMocks.sol`: remove unused mock behavior and normalize formatting.
6. Preserve `test/e2e`, `test/fixtures/tokens.json`, production contracts, and `config.json` unchanged.

### Task 1: Record the Green Baseline

**Files:**
- Inspect: `test/view/UsdOracle.t.sol`
- Inspect: `test/view/UsdOraclePyth.t.sol`
- Inspect: `test/view/UsdOracleApi3.t.sol`
- Inspect: `test/view/UsdOracle.monad.t.sol`
- Inspect: `test/AlgebraCustomPoolOracle.bsc.t.sol`
- Inspect: `test/e2e`

- [ ] **Step 1: Run the isolated unit suites**

Run:

```zsh
forge test --no-match-contract 'E2ETest|UsdOracleMonadTest|AlgebraCustomPoolOracleBscTest'
```

Expected: 10 tests pass: four `UsdOracle`, three Pyth, and three API3 tests.

- [ ] **Step 2: Run the duplicated Monad fork suite**

Run:

```zsh
forge test --match-contract UsdOracleMonadTest
```

Expected: four tests pass, proving the soon-to-be-removed fork suite starts green.

- [ ] **Step 3: Run the unique BSC adapter suite**

Run:

```zsh
forge test --match-contract AlgebraCustomPoolOracleBscTest
```

Expected: two tests pass and resolve both configured Thena V3 adapter variants.

- [ ] **Step 4: Run the integration authority**

Run:

```zsh
test/e2e
```

Expected: the config status table ends with `OK`, proving live base, wrapper-route, feed, and curated-token coverage starts green.

### Task 2: Remove Repeated Shared-Core Provider Tests

**Files:**
- Modify: `test/view/UsdOraclePyth.t.sol`
- Modify: `test/view/UsdOracleApi3.t.sol`
- Test: `test/view/UsdOracle.t.sol`

- [ ] **Step 1: Confirm the retained shared-core assertions**

Run:

```zsh
forge test --match-path test/view/UsdOracle.t.sol
```

Expected: four tests pass, including fallback conversion, batch output, and stale-answer behavior.

- [ ] **Step 2: Reduce the Pyth suite to its unique behavior**

Replace `test/view/UsdOraclePyth.t.sol` with:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {UsdOraclePyth} from "contracts/view/UsdOraclePyth.sol";
import {MockOffchainOracleAggregator, MockPythOracle} from "test/utils/UsdOracleMocks.sol";

contract UsdOraclePythTest is Test {
    UsdOraclePyth public oracleUsd;
    MockOffchainOracleAggregator public offchainOracle;
    MockPythOracle public pythOracle;
    bytes32 public constant ETH_USD_PRICE_ID = bytes32(uint256(1));

    function setUp() public {
        offchainOracle = new MockOffchainOracleAggregator();
        pythOracle = new MockPythOracle();

        // 3000 USD/ETH with exponent -8
        pythOracle.setPrice(ETH_USD_PRICE_ID, 3000e8, 0, -8, block.timestamp);

        address[] memory tokens = new address[](1);
        bytes32[] memory feeds = new bytes32[](1);
        tokens[0] = address(0); // ETH as base
        feeds[0] = ETH_USD_PRICE_ID;

        oracleUsd = new UsdOraclePyth(address(offchainOracle), address(pythOracle), tokens, feeds);
    }

    function testEthUsd_scalesTo1e18() public view {
        (uint256 price, uint8 decimals) = oracleUsd.usd(address(0));
        assertEq(price, 3000e18);
        assertEq(decimals, 18);
    }
}
```

- [ ] **Step 3: Reduce the API3 suite to its unique behavior**

Replace `test/view/UsdOracleApi3.t.sol` with:

```solidity
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
```

- [ ] **Step 4: Run the focused unit suites**

Run:

```zsh
forge test --no-match-contract 'E2ETest|UsdOracleMonadTest|AlgebraCustomPoolOracleBscTest'
```

Expected: six tests pass: four shared/Chainlink tests, one Pyth test, and one API3 test.

- [ ] **Step 5: Commit the provider-suite cleanup**

Run:

```zsh
git add test/view/UsdOraclePyth.t.sol test/view/UsdOracleApi3.t.sol
git commit -m 'test: deduplicate usd provider coverage'
```

Expected: one commit containing only the Pyth and API3 test reductions.

### Task 3: Delete the Redundant Fork Test and Dead Helpers

**Files:**
- Delete: `test/view/UsdOracle.monad.t.sol`
- Modify: `test/utils/ConfigUtils.sol`
- Modify: `test/utils/UsdOracleMocks.sol`
- Test: `test/AlgebraCustomPoolOracle.bsc.t.sol`

- [ ] **Step 1: Confirm helper ownership before deletion**

Run:

```zsh
rg -n '_chainPath|_configConnectors|_runtimeConnectors|_runtimeTokens|setRateToBase' test
```

Expected: the runtime-token helpers are used only by `UsdOracle.monad.t.sol`, and `setRateToBase` has no caller.

- [ ] **Step 2: Delete the duplicated Monad suite**

Delete `test/view/UsdOracle.monad.t.sol` in full. Do not replace it with another fork test.

- [ ] **Step 3: Reduce `ConfigUtils` to BSC adapter support**

Replace `test/utils/ConfigUtils.sol` with:

```solidity
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
```

- [ ] **Step 4: Remove the unused mock setter and normalize the mock file**

Replace `test/utils/UsdOracleMocks.sol` with:

```solidity
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
```

- [ ] **Step 5: Format the changed Solidity tests**

Run:

```zsh
forge fmt test/view/UsdOraclePyth.t.sol test/view/UsdOracleApi3.t.sol test/utils/ConfigUtils.sol test/utils/UsdOracleMocks.sol
```

Expected: the command exits successfully and changes no behavior.

- [ ] **Step 6: Confirm dead coverage and helpers are gone**

Run:

```zsh
test ! -e test/view/UsdOracle.monad.t.sol
! rg -n '_chainPath|_configConnectors|_runtimeConnectors|_runtimeTokens|setRateToBase|UsdOracleMonadTest' test
```

Expected: both commands exit successfully with no matching dead symbols.

- [ ] **Step 7: Run all remaining non-E2E tests**

Run:

```zsh
forge test --no-match-contract E2ETest
```

Expected: eight tests pass: six USD-oracle unit tests and two unique BSC adapter tests.

- [ ] **Step 8: Commit the fork and helper cleanup**

Run:

```zsh
git add test/view/UsdOracle.monad.t.sol test/utils/ConfigUtils.sol test/utils/UsdOracleMocks.sol
git commit -m 'test: remove redundant fork coverage'
```

Expected: one commit deleting the Monad suite and trimming only its dead support code.

### Task 4: Verify Integration Ownership and Final Scope

**Files:**
- Verify: `test/e2e`
- Verify: `test/fixtures/tokens.json`
- Verify: `test/view/UsdOracle.t.sol`
- Verify: `test/view/UsdOraclePyth.t.sol`
- Verify: `test/view/UsdOracleApi3.t.sol`
- Verify: `test/AlgebraCustomPoolOracle.bsc.t.sol`

- [ ] **Step 1: Check formatting and patch hygiene**

Run:

```zsh
forge fmt --check test/view/UsdOracle.t.sol test/view/UsdOraclePyth.t.sol test/view/UsdOracleApi3.t.sol test/AlgebraCustomPoolOracle.bsc.t.sol test/utils/ConfigUtils.sol test/utils/RpcUtils.sol test/utils/UsdOracleMocks.sol
git diff --check HEAD~2..HEAD
```

Expected: both commands exit successfully with no formatting or whitespace errors.

- [ ] **Step 2: Run the integration authority directly**

Run:

```zsh
test/e2e
```

Expected: the config status table ends with `OK`. This proves the unchanged E2E path still checks runtime bases, configured feed identity/alignment, curated wrapper routes, and non-base tokens.

- [ ] **Step 3: Run the complete Forge suite**

Run:

```zsh
forge test
```

Expected: nine tests pass with zero failures: eight focused tests plus the E2E wrapper test.

- [ ] **Step 4: Review the final coverage inventory**

Run:

```zsh
rg -n 'function test' test
git diff --stat 28d88b5..HEAD
git status --short
```

Expected: nine test functions remain, the diff contains only the planned test cleanup and plan document, and the worktree is clean.
