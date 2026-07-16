# Bridge Validation Design

## Scope

Validate every `bridge` URL in `$XDG_CONFIG_HOME/defi/chains.json` against current official provider support. Remove only entries that are currently deprecated or unsupported. Preserve supported entries without requiring dev-wallet transaction history.

## Output

Keep each chain's bridge value as an ordered array with an official chain bridge first when available. Report all production chains with configured bridges, current support state, and available transaction-test evidence.

## Verification

Require valid JSON, nonempty unique HTTPS arrays, official-first ordering, and no provider URL on a chain absent from that provider's current support surface.
