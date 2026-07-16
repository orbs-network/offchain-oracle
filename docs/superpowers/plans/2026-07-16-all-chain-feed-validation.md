# All-Chain Feed Validation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the E2E harness fail when any configured chain lacks a deployed oracle, aligned provider-identified feeds, or three working assorted tokens.

**Architecture:** Keep config.json as the only address/ID source of truth. Extend the existing zsh E2E harness with provider-specific metadata readers, a small symbol canonicalizer, all-chain completeness checks, and live jobs for every base and curated token.

**Tech Stack:** zsh, jq, Foundry cast/forge, GNU parallel, curl, Git stash

---

## File Structure

- Modify: `test/e2e` — validate every config key, decode provider metadata, compare token/feed identities, and run all live jobs.
- Modify: `config.json` — remove incomplete Tempo and Fuse entries after preserving them.
- Read only: `test/fixtures/tokens.json` — remain the independent curated non-base token sample.
- Transient then stashed: `.tempo-fuse-config.json` — exact recovery snapshot, absent from the final worktree.

### Task 1: Make Incomplete Config Chains Fail

**Files:**
- Modify: `test/e2e:6-198`
- Modify: `test/e2e:200-230`
- Modify: `test/e2e:310-318`

- [ ] **Step 1: Keep static validation focused on fixture shape**

Remove the second jq expression from `assert_static_config`. The first expression continues to require every fixture entry to be an array of at least three unique, nonzero EVM addresses.

- [ ] **Step 2: Require an oracle, tokens, and exactly one feed array on every chain**

Pass the token fixture into the existing config-rules query:

~~~diff
-    jq -r --arg native "$native_token" --arg none "$none_token" '
+    jq -r --slurpfile tokens "$tokens_file" --arg native "$native_token" --arg none "$none_token" '
~~~

In the error array inside `assert_config_rules`, add the oracle/token checks and replace the conditional feed check:

~~~jq
if (($cfg.oracle // "") | test("^0x[cC][eE][eE]000[0-9a-fA-F]{34}$") | not)
then "\($chain) missing valid deployed oracle"
else empty
end,
if (($tokens[0][$chain] // []) | length) < 3
then "\($chain) missing 3 non-base tokens"
else empty
end,
if ($feed_fields | length) != 1
then "\($chain) must set exactly one env feed array"
else empty
end,
~~~

Keep the existing feed-length, Pyth, API3, connector, and `env.tokens` checks.

- [ ] **Step 3: Remove active-only filtering**

Make these exact loop/query changes:

~~~diff
-  for chain_id in ${(f)"$(jq -r 'to_entries[] | select((.value.oracle // "") != "") | .key' "$config_file")"}; do
+  for chain_id in ${(f)"$(jq -r 'keys[]' "$config_file")"}; do

-    | select((.value.oracle // "") != "")

-  jq -r 'to_entries[] | select((.value.oracle // "") != "") | [.key, .value.oracle] | @tsv' "$config_file" \
+  jq -r 'to_entries[] | [.key, .value.oracle] | @tsv' "$config_file" \
~~~

Also change `assert_non_base_tokens` to iterate `jq -r 'keys[]' "$config_file"`, not fixture keys.

- [ ] **Step 4: Run the E2E test and verify RED**

Run:

~~~zsh
test/e2e
~~~

Expected: FAIL before live price jobs, reporting both `4217 missing valid deployed oracle` and `122 missing valid deployed oracle`, plus chain-specific missing feed/token coverage.

### Task 2: Preserve and Remove Tempo/Fuse

**Files:**
- Create transiently: `.tempo-fuse-config.json`
- Modify: `config.json:1655-1676`
- Modify: `config.json:1728-1745`

- [ ] **Step 1: Create the exact stash snapshot with apply_patch**

~~~json
{
  "4217": {
    "connectors": [
      "0x20c00000000000000000000014f22ca97301eb73",
      "0x20c000000000000000000000b9537d11c60e8b50"
    ],
    "adapters": [
      {
        "label": "UniswapV3",
        "name": "UniswapV3LikeOracle",
        "env": {
          "factory": "0x24a3d4757e330890a8b8978028c9e58e04611fd6",
          "initcodehash": "0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54",
          "fees": [100, 500, 3000, 10000]
        }
      }
    ]
  },
  "122": {
    "connectors": [
      "0x620fd5fa44BE6af63715Ef4E65DDFA0387aD13F5",
      "0xfadbbf8ce7d5b7041be672561bba99f79c532e10",
      "0x2f6f07cdcf3588944bf4c42ac74ff24bf56e7590",
      "0x33284f95ccb7b948d9d352e1439561cf83d8d00d"
    ],
    "adapters": [
      {
        "label": "Voltage",
        "name": "UniswapV2LikeOracle",
        "env": {
          "factory": "0x1998E4b0F1F922367d8Ec20600ea2b86df55f34E",
          "initcodehash": "0xe5f5532292e2e2a7aee3c2bb13e6d26dca6e8cc0a843ddd6f37c436c23cfab22"
        }
      }
    ]
  }
}
~~~

- [ ] **Step 2: Stash only the transient snapshot**

Run:

~~~zsh
git stash push -u -m 'config: preserve Tempo and Fuse' -- .tempo-fuse-config.json
git show 'stash@{0}^3:.tempo-fuse-config.json' |
  jq -e --slurpfile config config.json '
    ."4217" == $config[0]."4217" and ."122" == $config[0]."122"
  '
~~~

Expected: a new named stash and jq output `true`. Existing staged and unstaged files remain unchanged.

- [ ] **Step 3: Remove both config members with apply_patch**

Delete the complete `"4217"` member, including its trailing comma. Delete the complete final `"122"` member and change the preceding Rootstock member terminator from `},` to `}`.

Use these exact patches:

~~~diff
-    "4217": {
-        "connectors": [
-            "0x20c00000000000000000000014f22ca97301eb73",
-            "0x20c000000000000000000000b9537d11c60e8b50"
-        ],
-        "adapters": [
-            {
-                "label": "UniswapV3",
-                "name": "UniswapV3LikeOracle",
-                "env": {
-                    "factory": "0x24a3d4757e330890a8b8978028c9e58e04611fd6",
-                    "initcodehash": "0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54",
-                    "fees": [
-                        100,
-                        500,
-                        3000,
-                        10000
-                    ]
-                }
-            }
-        ]
-    },
~~~

~~~diff
-    },
-    "122": {
-        "connectors": [
-            "0x620fd5fa44BE6af63715Ef4E65DDFA0387aD13F5",
-            "0xfadbbf8ce7d5b7041be672561bba99f79c532e10",
-            "0x2f6f07cdcf3588944bf4c42ac74ff24bf56e7590",
-            "0x33284f95ccb7b948d9d352e1439561cf83d8d00d"
-        ],
-        "adapters": [
-            {
-                "label": "Voltage",
-                "name": "UniswapV2LikeOracle",
-                "env": {
-                    "factory": "0x1998E4b0F1F922367d8Ec20600ea2b86df55f34E",
-                    "initcodehash": "0xe5f5532292e2e2a7aee3c2bb13e6d26dca6e8cc0a843ddd6f37c436c23cfab22"
-                }
-            }
-        ]
-    }
+    }
~~~

- [ ] **Step 4: Verify the removal and JSON validity**

Run:

~~~zsh
jq -e 'has("4217") | not' config.json
jq -e 'has("122") | not' config.json
jq empty config.json
git stash list | head -n 1
~~~

Expected: all jq commands exit 0; the newest stash is `config: preserve Tempo and Fuse`.

- [ ] **Step 5: Run E2E and verify GREEN for completeness**

Run:

~~~zsh
test/e2e
~~~

Expected: `OK`; no chain is skipped by missing `oracle`.

- [ ] **Step 6: Commit only the isolated harness change**

Run:

~~~zsh
git add test/e2e
git commit --only -m 'test: require complete config for every chain' -- test/e2e
~~~

Do not stage or commit `config.json`, `.gas-snapshot`, `test/fixtures/tokens.json`, or the existing deleted Avalanche test.

### Task 3: Add Tested Metadata Parsing

**Files:**
- Modify: `test/e2e:8-16`
- Modify: `test/e2e:88-105`
- Modify: `test/e2e:321-328`

- [ ] **Step 1: Add failing in-script parser assertions**

Add this function and call it first in `run_all`:

~~~zsh
assert_metadata_helpers() {
  [[ "$(canonical_symbol 'USD₮0')" == USDT ]] || fail "USD₮0 normalization failed"
  [[ "$(canonical_symbol 'WETH.e')" == ETH ]] || fail "WETH.e normalization failed"
  [[ "$(canonical_symbol WPOL)" == MATIC ]] || fail "WPOL normalization failed"
  [[ "$(pair_from_metadata 'ETH / USD')" == $'ETH\tUSD' ]] || fail "slash pair parsing failed"
  [[ "$(pair_from_metadata 'RedStone Price Feed for BTC')" == $'BTC\tUSD' ]] || fail "RedStone pair parsing failed"
  [[ "$(pair_from_metadata 'USDM-USD (USDtb Underlying)')" == $'USDM\tUSD' ]] || fail "hyphen pair parsing failed"
  [[ "$(bytes32_ascii 0x5345492f55534400000000000000000000000000000000000000000000000000 api3)" == SEI/USD ]] || fail "API3 bytes32 decoding failed"
  [[ "$(bytes32_ascii 0x01464c522f555344000000000000000000000000000000000000000000000000 ftso)" == FLR/USD ]] || fail "FTSO bytes32 decoding failed"
}
~~~

- [ ] **Step 2: Run the assertions and verify RED**

Run:

~~~zsh
test/e2e
~~~

Expected: FAIL with `canonical_symbol: command not found`.

- [ ] **Step 3: Implement symbol canonicalization**

Add:

~~~zsh
canonical_symbol() {
  local raw clean
  raw=${1:u}
  raw=${raw//₮/T}
  raw=${raw%.E}
  clean=${raw//[^A-Z0-9]/}

  case "$clean" in
    USDT0) clean=USDT ;;
    WETH|UETH|VBETH|XETH) clean=ETH ;;
    WBTC|VBWBTC|BTCB) clean=BTC ;;
    VBUSDC) clean=USDC ;;
    VBUSDT) clean=USDT ;;
    WPOL) clean=MATIC ;;
    WBNB) clean=BNB ;;
    WAVAX) clean=AVAX ;;
    WMNT) clean=MNT ;;
    WMON) clean=MON ;;
    WHYPE) clean=HYPE ;;
    WS) clean=S ;;
    WHBAR) clean=HBAR ;;
    WXPL) clean=XPL ;;
    WRBTC) clean=RBTC ;;
    WBERA) clean=BERA ;;
  esac

  print -r -- "$clean"
}
~~~

- [ ] **Step 4: Implement pair and bytes32 parsing**

Add:

~~~zsh
pair_from_metadata() {
  local raw=$1 pair base quote

  if [[ "$raw" == *"Price Feed for "* ]]; then
    pair="${raw##*Price Feed for }/USD"
  elif [[ "$raw" == */* ]]; then
    pair=$raw
  elif [[ "${raw:u}" == *-USD* ]]; then
    pair="${raw%%-USD*}/USD"
  else
    return 1
  fi

  base=${pair%%/*}
  quote=${pair#*/}
  base=${base//[[:space:]]/}
  quote=${quote//[[:space:]]/}
  print -r -- "$(canonical_symbol "$base")"$'\t'"$(canonical_symbol "$quote")"
}

bytes32_ascii() {
  local value=$1 kind=$2 hex
  if [[ "$kind" == ftso ]]; then
    hex=${value#0x}
    value="0x${hex[3,-1]}"
  fi
  cast to-ascii "$value"
}
~~~

- [ ] **Step 5: Run E2E and verify parser assertions GREEN**

Run:

~~~zsh
test/e2e
~~~

Expected: parser assertions pass and the existing live checks finish with `OK`.

### Task 4: Verify Provider Identity and Array Alignment

**Files:**
- Modify: `test/e2e:6-11`
- Modify: `test/e2e:290-333`

- [ ] **Step 1: Add a failing live feed worker**

Add this case before implementing `check_feed`:

~~~zsh
--feed)
  check_feed "$2" "$3" "$4" "$5"
  ;;
~~~

Run:

~~~zsh
feed=$(jq -r '."30".env.feeds[0]' config.json)
test/e2e --feed chainlink 30 0x0000000000000000000000000000000000000000 "$feed"
~~~

Expected: FAIL with `check_feed: command not found`.

- [ ] **Step 2: Add overridable paths and the Pyth catalog URL**

Replace the token fixture assignment and add:

~~~zsh
tokens_file=${TOKENS_FILE:-$repo_root/test/fixtures/tokens.json}
pyth_catalog_url=${PYTH_CATALOG_URL:-https://hermes.pyth.network/v2/price_feeds}
~~~

- [ ] **Step 3: Implement provider metadata resolution**

Add:

~~~zsh
provider_pair() {
  local kind=$1 feed=$2 rpc_url=$3 raw id

  case "$kind" in
    chainlink)
      raw=$(cast call --json "$feed" 'description()(string)' --rpc-url "$rpc_url" | jq -er '.[0]')
      ;;
    api3)
      raw=$(cast call --json "$feed" 'dapiName()(bytes32)' --rpc-url "$rpc_url" | jq -er '.[0]')
      raw=$(bytes32_ascii "$raw" api3)
      ;;
    ftso)
      raw=$(bytes32_ascii "$feed" ftso)
      ;;
    pyth)
      [[ -n "${PYTH_CATALOG_FILE:-}" ]] || return 1
      id=${feed#0x}
      raw=$(jq -er --arg id "$id" '
        map(select(.id == $id))
        | if length == 1 then .[0].attributes.display_symbol
          else error("Pyth feed ID not found exactly once")
          end
      ' "$PYTH_CATALOG_FILE")
      ;;
    *)
      return 1
      ;;
  esac

  pair_from_metadata "$raw"
}

prepare_pyth_catalog() {
  local catalog curl_args
  jq -e 'any(.[]; (.env.pyths // [] | length) > 0)' "$config_file" >/dev/null || return
  catalog=$(mktemp)
  curl_args=(-fsS)
  [[ -z "${PYTH_API_KEY:-}" ]] || curl_args+=(-H "Authorization: Bearer $PYTH_API_KEY")
  curl "${curl_args[@]}" "$pyth_catalog_url" > "$catalog" || { rm -f "$catalog"; fail "unable to fetch Pyth feed catalog"; }
  jq -e 'type == "array" and all(.[]; has("id") and (.attributes | has("display_symbol")))' "$catalog" >/dev/null || { rm -f "$catalog"; fail "invalid Pyth feed catalog"; }
  print -r -- "$catalog"
}
~~~

- [ ] **Step 4: Emit one alignment job per base/feed index**

Add:

~~~zsh
feed_jobs() {
  local chain_id kind i
  local -a base_tokens feeds

  for chain_id in ${(f)"$(jq -r 'keys[]' "$config_file")"}; do
    kind=$(jq -r --arg chain "$chain_id" '
      .[$chain].env
      | if (.pyths // [] | length) > 0 then "pyth"
        elif (.ftso // [] | length) > 0 then "ftso"
        elif (.api3s // [] | length) > 0 then "api3"
        else "chainlink"
        end
    ' "$config_file")
    base_tokens=(${(f)"$(base_assets "$chain_id")"})
    feeds=(${(f)"$(jq -r --arg chain "$chain_id" '
      .[$chain].env
      | if (.pyths // [] | length) > 0 then .pyths[]
        elif (.ftso // [] | length) > 0 then .ftso[]
        elif (.api3s // [] | length) > 0 then .api3s[]
        else .feeds[]
        end
    ' "$config_file")"})

    for i in {1..${#base_tokens[@]}}; do
      print -- "$kind\t$chain_id\t${base_tokens[$i]}\t${feeds[$i]}"
    done
  done
}
~~~

- [ ] **Step 5: Implement the live alignment assertion**

Add:

~~~zsh
check_feed() {
  local kind=$1 chain_id=$2 token=$3 feed=$4 token_symbol token_base pair feed_base quote

  chain "$chain_id" >/dev/null
  [[ -n "${ETH_RPC_URL:-}" && -n "${WETH:-}" ]] || fail "$chain_id missing RPC or WETH"

  [[ "$token" == "$native_token" ]] && token=$WETH
  token_symbol=$(symbol "$token" 2>/dev/null | tr -d '"') || fail "$chain_id cannot read symbol for $token"
  token_base=$(canonical_symbol "$token_symbol")
  pair=$(provider_pair "$kind" "$feed" "$ETH_RPC_URL") || fail "$chain_id cannot identify $kind feed $feed for $token_symbol"
  IFS=$'\t' read -r feed_base quote <<<"$pair"

  [[ "$quote" == USD ]] || fail "$chain_id $token_symbol uses non-USD $kind feed $feed: $feed_base/$quote"
  [[ "$token_base" == "$feed_base" ]] || fail "$chain_id feed mismatch: token=$token token_symbol=$token_symbol token_base=$token_base feed_type=$kind feed=$feed feed_pair=$feed_base/$quote"

  print -- "ok\tfeed\t$chain_id\t$token\t$feed_base/$quote"
}
~~~

- [ ] **Step 6: Wire alignment into the parent mode**

In `run_all`, fetch the catalog once, export its path, run feed jobs before price jobs, and always remove the temporary file:

~~~zsh
run_all() {
  local pyth_catalog=
  assert_metadata_helpers
  assert_static_config
  assert_config_rules
  assert_non_base_tokens

  pyth_catalog=$(prepare_pyth_catalog)
  export PYTH_CATALOG_FILE=$pyth_catalog
  {
    feed_jobs | parallel --line-buffer --colsep '\t' "$script_path --feed {1} {2} {3} {4}"
    jobs | parallel --line-buffer --colsep '\t' "$script_path --price {1} {2} {3} {4}"
  } always {
    [[ -z "$pyth_catalog" ]] || rm -f "$pyth_catalog"
  }
}
~~~

- [ ] **Step 7: Verify the live feed worker GREEN**

Run:

~~~zsh
feed=$(jq -r '."30".env.feeds[0]' config.json)
test/e2e --feed chainlink 30 0x0000000000000000000000000000000000000000 "$feed"
~~~

Expected: one `ok feed 30` row for the Rootstock native/BTC feed.

- [ ] **Step 8: Prove a swapped feed fails**

Run this in-memory negative check:

~~~zsh
bad_config=$(mktemp)
negative_log=$(mktemp "$XDG_CACHE_HOME/offchain-oracle-e2e.XXXXXX")
trap 'rm -f "$bad_config" "$negative_log"' EXIT
jq '."10".env.feeds[2:4] |= reverse' config.json > "$bad_config"
if CONFIG_FILE=$bad_config test/e2e > "$negative_log" 2>&1; then
  print -u2 -- "swapped feeds unexpectedly passed"
  exit 1
fi
rg 'feed mismatch' "$negative_log"
rm -f "$negative_log"
~~~

Expected: nonzero E2E exit and a chain `10` feed mismatch.

- [ ] **Step 9: Run E2E and verify GREEN**

Run:

~~~zsh
test/e2e
~~~

Expected: every provider identity check and every live price job passes; final output contains `OK`.

- [ ] **Step 10: Commit only the metadata harness**

Run:

~~~zsh
git add test/e2e
git commit --only -m 'test: verify base asset feed alignment' -- test/e2e
~~~

### Task 5: Negative Coverage, Cleanup, and Full Verification

**Files:**
- Modify only if cleanup finds duplication: `test/e2e`

- [ ] **Step 1: Verify missing oracle fails before network work**

Run:

~~~zsh
bad_config=$(mktemp)
negative_log=$(mktemp "$XDG_CACHE_HOME/offchain-oracle-e2e.XXXXXX")
jq 'del(."10".oracle)' config.json > "$bad_config"
CONFIG_FILE=$bad_config test/e2e > "$negative_log" 2>&1 && exit 1
rg '10 missing valid deployed oracle' "$negative_log"
rm -f "$bad_config" "$negative_log"
~~~

- [ ] **Step 2: Verify missing feed fails**

Run:

~~~zsh
bad_config=$(mktemp)
negative_log=$(mktemp "$XDG_CACHE_HOME/offchain-oracle-e2e.XXXXXX")
jq 'del(."10".env.feeds)' config.json > "$bad_config"
CONFIG_FILE=$bad_config test/e2e > "$negative_log" 2>&1 && exit 1
rg '10 must set exactly one env feed array' "$negative_log"
rm -f "$bad_config" "$negative_log"
~~~

- [ ] **Step 3: Verify missing assorted tokens fails**

Run:

~~~zsh
bad_tokens=$(mktemp)
negative_log=$(mktemp "$XDG_CACHE_HOME/offchain-oracle-e2e.XXXXXX")
jq 'del(."10")' test/fixtures/tokens.json > "$bad_tokens"
TOKENS_FILE=$bad_tokens test/e2e > "$negative_log" 2>&1 && exit 1
rg '10 missing 3 non-base tokens' "$negative_log"
rm -f "$bad_tokens" "$negative_log"
~~~

- [ ] **Step 4: Run the cleanup pass**

Inspect only `test/e2e` for duplicated feed selection, duplicated config-key queries, unused locals, and helpers used once without improving clarity. Keep one feed-kind selector and one runtime base-asset constructor.

- [ ] **Step 5: Run focused and full verification**

Run:

~~~zsh
test/e2e
forge test --match-contract E2ETest
forge test
git diff --check
jq empty config.json
git status --short
~~~

Expected: E2E prints `OK`; both Forge commands report zero failures; diff and JSON checks exit 0. The status retains the user’s pre-existing staged changes, the intended `config.json` edit, and no transient snapshot/catalog files.

- [ ] **Step 6: Commit cleanup only when test/e2e changed**

If cleanup changed the harness, run:

~~~zsh
git add test/e2e
git commit --only -m 'refactor: simplify feed validation harness' -- test/e2e
~~~

Do not commit `config.json` or any pre-existing staged user file.
