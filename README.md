# Offchain Oracle

Foundry fork of 1inch `OffchainOracle`.

## Layout

1. `contracts/OffchainOracle.sol` - core oracle.
2. `contracts/oracles/` - DEX/feed adapters.
3. `contracts/view/` - read-only USD helpers returning `1e18` prices.
4. `script/` - deployment scripts.
5. `config.json` - per-chain deployment config.

## Config

`connectors` contains base tokens only. Deploy scripts derive:

1. USD tokens: `[native, WETH, ...connectors]`
2. Connector tokens: `[NONE, native, WETH, ...connectors]`

Do not set `env.tokens`.

## Commands

```sh
forge test
```
