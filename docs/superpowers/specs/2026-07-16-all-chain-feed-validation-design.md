# All-Chain Feed Validation Design

## Scope

Make `test/e2e` validate every chain present in `config.json`. A chain must not be silently skipped because `oracle`, feeds, or assorted-token coverage is missing.

Preserve the Tempo (`4217`) and Fuse (`122`) entries in a named Git stash snapshot, verify the snapshot, then remove those entries from `config.json` because they are not deployment-complete.

## Completeness

For every remaining config chain, require:

1. A nonzero deployed `oracle`.
2. Exactly one of `feeds`, `pyths`, `api3s`, or `ftso`.
3. A feed count equal to `connectors.length + 2`.
4. Runtime base assets ordered as native, WNATIVE, then config connectors.
5. At least three unique non-base tokens in `test/fixtures/tokens.json`.

Generate live price jobs from every config entry rather than entries filtered by `oracle`. Missing configuration must fail during validation with a chain-specific diagnostic.

## Feed Identity And Alignment

Derive feed identity independently instead of duplicating token/feed addresses in another fixture:

1. Chainlink-compatible and RedStone feeds: call `description()` and extract the base/quote pair.
2. API3 proxies: call `dapiName()` and decode the bytes32 pair.
3. Flare FTSO: decode the pair embedded in the bytes32 feed ID.
4. Pyth: fetch the official Hermes feed catalog once, resolve each configured ID, and read its base and quote metadata. Send `PYTH_API_KEY` as a bearer token when set and fail clearly if the catalog cannot be fetched or decoded.

For each index, pair the runtime token with the configured feed, require a USD quote, and compare canonical base symbols. Canonicalization handles case, punctuation, wrapped-native prefixes, common bridged suffixes, and a minimal symbol-alias table such as `USD₮0 -> USDT` and `WPOL -> MATIC`. Aliases are symbol-to-symbol rules only; they do not repeat config addresses or feed IDs.

## Runtime Checks

Query the deployed USD oracle for every base asset and every curated non-base token. Require a successful call, nonzero sane price, and plausible decimals. These checks prove availability while provider metadata proves feed identity and array alignment.

The test does not require every adapter or every possible routing path to be used; the curated token set remains the routing sample for each chain.

## Error Handling

Failures identify the chain, token, feed type, configured feed value, derived token symbol, and derived feed pair. Provider RPC/API failures are fatal because an identity check that cannot run must not be treated as success.

## Verification

Use the existing incomplete Tempo and Fuse entries to prove the new completeness assertion fails before removing them. After stashing and removal, run the E2E script and Forge suite, then run a cleanup pass without broadening scope.
