# C-?? / serum-swap — Serum Swap AMM (SPL token-swap `SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8`)

**Date:** 2026-10-15 · **Chain:** Solana mainnet · **Status:** read-only; no transaction signed or
sent; all evidence from public RPC `get*` calls and `simulateTransaction` (probes only). Folder:
`l2-related/analysis/serum-swap/`.

## TL;DR

| target | live extractable (unprivileged) | why closed / open | latent risk |
|---|---|---|---|
| Serum Swap program + its 292 live pools ($204.4 k realizable / $259.3 k at DefiLlama prices) | **$0 (E-U)** | every value-moving instruction is gated by an SPL-token `burn` of the caller's own LP tokens (proven by simulation) or priced by the curve; the deployed build's single-sided withdrawal even **over-charges** the withdrawer (proven by simulation to match the pre-fix formula to 2.5e-11); no admin path exists | a single **non-revoked upgrade key** (`DpWjxjJE2SC…`) can rewrite the program; the program-owner fee key `HfoTxFR1…` owns **$140.7 k of LP** (68.9 % of live value) and can withdraw it |
| normal AMM arbitrage (not a bug) | $4.22 realizable (ConstantPrice pools) / $15,186.78 if dead Sollet tokens are valued at DefiLlama prices | pools are continuously arbitraged by aggregators today; 0.30 % round-trip fee kills the residual | $13.4 k of real-side value sits behind unmarketable Sollet tokens (soUSDT/soYFI) — extractable only by someone who already holds those dead tokens |
| stuck | $0.05 + 0.151 SOL rent | pre-#1637 build: deposits into zero-LP pools revert; no close instruction | — |

## Total live extractable by an external unprivileged attacker: **$0** (confidence: high)

* No bug-based extraction: **$0** (high confidence).
* Normal-trading value available at curve prices: **$4.22** realizable (**$15,186.78** under
  DefiLlama prices) — reported separately, explicitly **not** a vulnerability.
* Holder-only (LP redemption): **$63,652.21**; key-gated to the SPL/Serum fee key: **$140,698.78**.

## The mechanism in exact terms

Deployed program = `solana-labs/solana-program-library@9281b6e82899` (2021-04-14, token-swap 2.1.0,
built with `--features production`; last upgrade slot **73,737,036** = **2021-04-15 04:22:07 UTC**).
The value paths are:

* `Swap` (tag 1) — curve-priced with 0.30 % total input fee; output rounded with `checked_ceil_div`
  in the pool's favour. Open to everyone **by design**.
* `WithdrawAllTokenTypes` (3) / `WithdrawSingleTokenTypeExactAmountOut` (5) — the caller's LP account
  is `burn`t via a CPI signed by the caller *before* any vault transfer. The vault authority PDA is
  derived from the pool account itself (`create_program_address([pool, nonce])`), and the vaults are
  pinned to the pool's stored `token_a`/`token_b` accounts.
* `DepositAllTokenTypes` (2) / `DepositSingleTokenTypeExactAmountIn` (4) — require real tokens in
  (`Floor`/`Ceiling` rounding both favour the pool).
* `Initialize` (0) — under the production constraints the fee account must be owned by
  `HfoTxFR1Tm6kGmWgYWD6J7YHVy1UwqSULUGVLXkJqaKN`, fees must meet minimums, and the curve must be
  ConstantProduct/ConstantPrice. No admin/authority instruction exists.

The one place where this build is known to differ from later, fixed SPL code is the *single-asset
withdrawal formula* (fixed in PR #1794, 2021-05-25). The live program was proven to implement the
**old** formula: a simulated 5 %-of-reserve exact-out withdrawal burned `318,221,048,603` LP, matching
the old formula's `318,221,048,611` (2.5×10⁻¹¹ relative) and **2.54 % above** the fixed formula
(`310,153,567,464`). Old formula = over-charging the withdrawer ⇒ a user loss, never a gain.

## Live-state assessment (all addresses verified on-chain)

* Program `SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8` (executable, BPFLoaderUpgradeab1e);
  programdata `FV9WWFWYzWHDpAc8oxiFKV1LmFUyWw7HGdo4GK19MiZW` (619,629 B, ELF sha256 `f86b866c…65719`).
* **340 accounts** owned by the program: 339 × 324 B + 1 × 323 B → **292 initialized pools**
  (262 ConstantProduct, 30 ConstantPrice), 48 uninitialised (0.1509972 SOL rent, `S`).
* **292/292** pools: `vault_a.owner == vault_b.owner == PDA([pool], nonce)` and
  `pool_mint.mint_authority == PDA` (independent `solders` derivation) — no mis-initialised pool.
* Fees: 286 pools at trade 25/10000 / owner 5/10000 / withdraw 0 / host 20/100; 6 pools at 0/10000.
  **No absurd fees.**
* **All 292 fee accounts** are owned by `HfoTxFR1…` (0.8 SOL, active 2026), holding
  **$140,698.78** of LP by value (68.9 % of live value; e.g. 64 % of the biggest pool).
* Value: **$259,285.47** at DefiLlama prices, **$204,350.99** realizable. Two SOL/USDC(SDT) pools
  (`AmHUjHK…` $143.5 k, `HChRYaZ…` $28.9 k) are 84 % of the realizable total. DefiLlama's own page
  says $221,430.68 (its adapter misses the biggest pool's SOL side).
* Pools are live: aggregator-routed swaps decoded at slots 457,161,704 / 457,163,225 / 457,163,236 /
  457,163,289 (today).
* Upgrade authority `DpWjxjJE2SCsraeZqKqLtvdPjiaABmcmNAZSP9iUaGrn` — **not revoked**, single key,
  signed the last upgrade, active 2022-03 → 2024-02, account currently 0 lamports.
  **Correction to the task brief:** the brief's `7orsQE9o…` has no account and no signatures; the
  authoritative programdata decode is `DpWjxjJE2SC…`. An unrelated upgrade attempt at slot 61,737,896
  was rejected with `IncorrectAuthority`.
* All 292 pools were enumerated and decoded (see `state-summary.md` for the method and top-pool
  table, `pools.json` for every pool with reserves, decimals, LP supply, fee-account balances, USD
  values and the arbitrage estimate).

## What an attacker can / cannot do

* **Cannot** withdraw anything without owning LP tokens (proven: `custom program error 0x1` in the
  Tokenkeg `burn` CPI for both withdraw instructions).
* **Cannot** substitute vaults, mints, fee accounts or the authority (pinned/derived checks, and
  Tokenkeg enforces mint equality on transfers).
* **Cannot** capture an existing pool's vaults by initializing a new pool (PDA keyed on the pool
  account; collision = 2²⁵⁶ pre-image).
* **Cannot** revive a zero-supply pool in this build (deposits revert) — dust is stuck (`S`).
* **Can** trade at curve prices (normal AMM), and can name itself as `host fee` account for a
  1 bp LP rebate while paying ≥ 29 bp — net loss.
* **Can** extract the $4.22 of genuine ConstantPrice mispricing (a normal trade), or up to $13.4 k of
  real-side value if it already owns the dead Sollet token on the other side (a normal sale).
* **Cannot** do anything about the $140.7 k of LP held by the fee key or the upgradeable program —
  both are key-gated (`P`).

## Evidence list

| evidence | file |
|---|---|
| All 340 accounts, raw + decoded (layout verified field-by-field) | `raw-program-accounts.json`, `pools-raw.json` |
| Per-pool decoded state + USD (llama & realizable) + arb estimate | `pools.json` |
| Enumeration method, counts, totals, prices, version analysis, known-fixes checklist | `state-summary.md` |
| Per-instruction gate audit + the mission's six sub-questions | `gates.md` |
| Simulation transcripts (gate proofs + version fingerprint) | `simulations.md`, `sim-results.json`, `sim-raw-version-probe.json`, `sim-version-probe-analysis.json` |
| Reproducible scripts (public RPC only, no keys) | `fetch_state.py`, `analyze_value.py`, `sim_probe.py`, `sim-config.json` |
| Live pool activity (signatures) | `pool-activity.json` |

## Blockers / open questions

* **LP-holder census**: `getTokenLargestAccounts` hit public-RPC rate limits; the "other LP holders"
  figure (31.1 %) is derived by subtraction from the fee-account share, not by enumerating holders.
  Would refine H-O attribution, not the E-U verdict.
* **Price layer**: totals depend on how the dead Sollet tokens are valued; both extremes are reported
  ($259.3 k vs $204.4 k; arb $15.2 k vs $4.2). Nothing in the E-U verdict depends on it.
* **Upgrade-key status**: whether `DpWjxjJE2SC…`'s private key still exists cannot be determined
  from chain data; the authority field is `Some`, so the program is *upgradeable in principle*.
* Not investigated in depth: Token-2022 pools (none exist here), the Crates-io v3.x client
  differences, and historical MEV capture by aggregators (out of scope).
