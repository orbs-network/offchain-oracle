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

E2E verifies deployed feed mappings and publication timestamps for Chainlink,
API3, Pyth, and FTSO before checking USD quotes. Non-USD-pegged assets must have
updates less than five minutes old. USD pegs (USDC, USDT, DAI, USDe, AUSD, USDm,
and USDG, including recognized bridged variants) must have updates less than one
day old. Yield-bearing assets such as sUSDe use the five-minute limit. Missing,
zero, or future timestamps fail. Age is measured against current wall-clock time.

These checks do not refresh feeds or relax the deployed oracle's freshness rules.
