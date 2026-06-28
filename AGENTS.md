# AGENTS.md

## Spot Notion Dashboard

When asked to update the Spot Notion integrations dashboard:

1. Use Notion database `TWAP/Spot Integrations` with id `262312ca68a98089837bfaf4ac9ef209`.
2. Assume `NOTION_API_KEY` is already available in the shell environment; never print secrets.
3. This repo owns the dashboard `Oracle` column. Set it from this repo's `config.json` state only.
4. Do not update the dashboard `Contracts` column from this repo; that column belongs to `spot` repo.

## Config Invariants

These are hard requirements when generating or editing `config.json`. Treat them as invariants.

- The deployment scripts build the runtime token list as `tokens = [native, WNATIVE, ...connectors]` where `native` is `0x0000000000000000000000000000000000000000` and `WNATIVE` is the `WETH` env var.
- The deployment scripts build the runtime connector list as `connectors = [NONE, native, WNATIVE, ...connectors]` where `NONE` is `0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF`.
- `connectors` defines the base tokens only. Do not include `NONE`, `native`, or `WNATIVE` in `connectors`.
- Do not set `env.tokens`; it is no longer used.
- If `env.feeds` is present, its length must be `connectors.length + 2` and its order must align with `tokens = [native, WNATIVE, ...connectors]`.
- If `env.pyths` is present, its length must be `connectors.length + 2`, its order must align with `tokens = [native, WNATIVE, ...connectors]`, and `env.pyth` must be set to a non-zero address. Do not use zero bytes32 fallback entries in production config unless explicitly approved; add a direct feed or remove the token.
- If `env.api3s` is present, its length must be `connectors.length + 2` and its order must align with `tokens = [native, WNATIVE, ...connectors]`. Do not use zero address fallback entries in production config unless explicitly approved; add a direct feed or remove the token.
- If `env.ftso` is present (Flare), its length must be `connectors.length + 2` and its order must align with `tokens = [native, WNATIVE, ...connectors]`.
- Only one of `env.feeds`, `env.pyths`, `env.api3s`, or `env.ftso` should be set for any single chain entry.
- `adapters[i].name` must match an existing deploy script `script/adapter/Deploy${name}.s.sol` unless `adapters[i].env.address` is already set (then `AddOracleFromConfig` is used).
- When `adapters[i].env.address` is omitted, ensure the adapter `env` contains every required field expected by its deploy script.
- When set, `aggregator` must match `^0x111111` (case-insensitive) and `oracle` must match `^0xcee000` (case-insensitive), per the create2 prefix constraints in `script/deploy`.

## Chain Config How-To

- Use `getchain <id>` then `chain <id>` to load chain context (`WETH`, RPC, explorer).
- Use `a -c <id> -a` and chain docs to list known assets and pick `connectors` as base tokens only.
- If available, run `tokens <chain-or-id>` (example `tokens katana`) to enumerate chain tokens and cross-check `connectors`.
- Set `connectors` order intentionally; it defines `tokens = [native, WNATIVE, ...connectors]`.
- Use DefiLlama `protocols` list to filter `category=Dexs`, then filter by chain and TVL threshold.
- Use Dexscreener search with token addresses and the DEX name to find active pools and sample pool addresses.
- Use the `chain` skill + `cast` to confirm pool type: `getReserves()` -> V2-like, `slot0()` -> V3-like, `globalState()` -> Algebra-like.
- Use `cast call <pool> "factory()(address)"` to confirm factory addresses and `cast call <pool> "token0()(address)"` / `token1()` for ordering.
- For V2-like factories, use `cast call <factory> "pairCodeHash()(bytes32)"` as `initcodehash`.
- For V3-like or Algebra factories, use the `etherscan` skill to fetch verified pool source, compile with `solc` or `forge`, then `cast keccak` the pool creation bytecode to get `initcodehash`.
- When configuring `env.feeds`, `env.pyths`, `env.api3s`, or `env.ftso`, pick exactly one and align its array to `tokens`.
- Ensure the chosen env array length is `connectors.length + 2` and aligned to `tokens = [native, WNATIVE, ...connectors]`.
- If multiple tokens share the same USD feed, repeat the feed entry for each token position.
- For Flare `env.ftso`, store bytes32-padded FTSO v2 feed IDs aligned to `tokens`.
- For Flare feed IDs, use `FtsoFeedIdConverter.getFeedId(1, "<SYMBOL>/USD")`, then pad to bytes32.
- After adding `env.feeds`, manually verify feed mapping by printing each token symbol and the Chainlink feed description using `chain` + `cast`.

```zsh
chain <id>
connectors=($(jq -r ".\"$CHAIN_ID\".connectors[]" config.json))
feeds=($(jq -r ".\"$CHAIN_ID\".env.feeds[]" config.json))
tokens=(0x0000000000000000000000000000000000000000 $WETH $connectors)
for i in {1..${#tokens[@]}}; do
  token=${tokens[$i]}
  feed=${feeds[$i]}
  if [[ "$token" == "0x0000000000000000000000000000000000000000" ]]; then
    sym="NATIVE"
  else
    sym=$(symbol $token | tr -d '"')
  fi
  desc=$(cast call $feed "description()(string)")
  echo "$sym -> $desc ($feed)"
done
```
