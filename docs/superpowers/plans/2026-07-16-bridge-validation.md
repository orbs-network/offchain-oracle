# Bridge Validation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove currently deprecated or unsupported bridge entries and report current support and test status for every configured production chain.

**Architecture:** Query current official provider support surfaces for Squid, Stargate, Across, and LI.FI, then compare those chain IDs with the ordered bridge arrays in `$XDG_CONFIG_HOME/defi/chains.json`. Preserve chain-native bridges unless their official service is deprecated, and combine the resulting support map with existing dev-wallet bridge test evidence.

**Tech Stack:** zsh, `jq`, provider HTTP APIs, JSON configuration

---

### Task 1: Audit Current Support

**Files:**
- Read: `$XDG_CONFIG_HOME/defi/chains.json`

- [ ] Query each provider's current chain-support surface.
- [ ] Compare configured provider URLs with returned chain IDs.
- [ ] Check chain-native bridge URLs for explicit deprecation notices.

### Task 2: Remove Deprecated Entries

**Files:**
- Modify: `$XDG_CONFIG_HOME/defi/chains.json`

- [ ] Remove only entries confirmed deprecated or unsupported.
- [ ] Preserve official-first ordering and all supported alternatives.

### Task 3: Verify and Report

**Files:**
- Test: `$XDG_CONFIG_HOME/defi/chains.json`

- [ ] Run `jq empty "$XDG_CONFIG_HOME/defi/chains.json"` and assert every production `bridge` value is a nonempty array of unique HTTPS URLs.
- [ ] Verify each configured provider URL maps to a currently supported chain ID.
- [ ] Produce an aligned table covering all 33 production chains, configured bridges, live support, and transaction-test state.
