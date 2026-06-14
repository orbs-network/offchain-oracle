# Spot Price Aggregator

This is a fork of the upstream 1inch Spot Price Aggregator. The original README is preserved at:

- [`README.upstream.md`](./README.upstream.md)

### Upstream sync note

As of 2026-06-14, `oneinch/master` is 19 commits ahead of `origin/master`, while `origin/master` is 91 commits ahead of `oneinch/master`; shared base is `393e7b1`.

1. Upstream added `OffchainOracle` oracle/token blacklist support plus blacklist-count gas optimization.
2. Upstream added connector routing for `UniswapV4LikeOracle`.
3. Upstream bumped `handlebars` to `4.7.9` and adjusted tests/fixtures.
4. Future sync: re-check remotes first; not fast-forwarding now because value is low versus redeploying all chains.

### Configuration

- [`config.json`](./config.json)

### Deployment status

The current `config.json` entries for chains `10` and `5000` are config-only and are not yet recorded as deployed by this fork's deploy flow.

- Chain `10` references adapter addresses that already have Optimism bytecode, but the entry has no recorded `aggregator`, `oracle`, `salt`, or `aggregatorSalt`.
- Chain `5000` has connector and adapter factory config only, with no recorded adapter, `aggregator`, `oracle`, `salt`, or `aggregatorSalt` addresses.
- A completed broadcast deployment should leave `aggregator`, `oracle`, `salt`, and `aggregatorSalt` in the chain entry and Foundry broadcast records for that chain id.

### Automatic base tokens

When deploying view USD oracles and aggregators, the scripts automatically prepend the native token and WETH:

- USD oracle token list: `tokens` is built as `[native, WETH, ...connectors]`.
- Connector list: `connectors` is built as `[NONE, native, WETH, ...connectors]`.

## `/contracts/view` overview

The `/contracts/view` entrypoints provide view-only USD pricing helpers meant for off-chain reads. They follow a simple flow:

- Prefer direct USD sources when configured for a token.
- Otherwise convert the token to a configured base asset via the offchain oracle, then convert that base to USD.
- Prices are normalized to a consistent 1e18 scale.

This fork keeps the full upstream documentation separate; use this README only for the fork-level view entrypoint overview.
