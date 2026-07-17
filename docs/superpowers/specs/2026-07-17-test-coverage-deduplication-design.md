# Test Coverage Deduplication Design

## Goal

Remove duplicated test coverage while preserving focused regression protection. The E2E test is the sole live integration authority for configured bases, wrapper routes, feeds, and curated tokens.

## Coverage Ownership

`test/e2e` continues to validate every configured chain:

1. Price native, WNATIVE, and every connector through the deployed USD oracle.
2. Match each runtime base asset to its configured provider feed.
3. Price every curated non-base token.
4. Exercise wrapper routing through curated wrapper assets and the aggregator's `useWrappers=true` path.

Focused Solidity tests retain behavior that the E2E success path does not isolate:

1. `UsdOracle.t.sol` owns Chainlink scaling and shared core coverage for fallback conversion, batch output, and stale answers.
2. `UsdOraclePyth.t.sol` owns Pyth exponent scaling.
3. `UsdOracleApi3.t.sol` owns API3 proxy value decoding.
4. `AlgebraCustomPoolOracle.bsc.t.sol` retains its adapter-specific pool-resolution checks.

## Changes

Delete `UsdOracle.monad.t.sol` because its live config, feed, and base-price checks are covered across all chains by `test/e2e`.

Remove the fallback-conversion and stale-answer tests repeated in the Pyth and API3 suites. Those paths are implemented by `UsdOracleCore` and remain covered once through `UsdOracle.t.sol`; the provider suites keep only their distinct input conversion.

After deleting tests, remove utility methods, imports, and mock behavior that no remaining test uses. Do not change production contracts, `config.json`, the token fixture, or E2E behavior.

## Verification

Run focused unit and adapter tests without E2E, then run the complete Forge suite so `test/e2e` validates live bases, wrapper assets, feed alignment, and curated tokens. Finish with a dead-code and duplication scan of the changed test files.
