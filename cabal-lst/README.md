# Cabal LST (Initia Move) — residual re-check of Code4rena H-01

**Date:** 2026-10-23 · **Chain:** Initia mainnet (`interwoven-1`) · **Target:** ZH4-pass4 residual **OPEN #1**
**Status:** read-only; no transaction signed or sent on any network; no keyed RPC URL or secret in this folder.
**Question:** does the **deployed** Cabal LST Move package still contain Code4rena `2025-04-cabal-liquid-staking-token` **H-01** ("LP unstake burns shares but leaves underlying → ratio distortion"), and can an unprivileged attacker extract value today?

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---|---|---|
| Cabal LST — Initia `0x53c3f5d8…` (~$2.11M DL) | **$0** | **Deployed code is a different, post-audit build in which H-01 is fixed.** The audited function `process_lp_unstake` does not exist on chain; its successor `process_lp_undelegate` and the live stake/price/estimate paths add `unstaked_pending_amounts` back into the supply denominator (the exact H-01 mitigation). Live view oracle returns the fixed formula. | The live package is **upgradeable (`COMPATIBLE`)** and this 16-module revision has **no published audit covering it** — the 2025-04 audit covered the older 10-module build. A future upgrade could regress. |
| Cabal iUSD/DN vaults (`cabal-1`, ~$128k) and Strat xSLP (`strat-1`, ~$503k) | n/a | Separate products, not the audited LST; not in H-01 scope. | not assessed here |

## 2. Total live extractable now: **$0.00**

| Category | USD | Notes |
|---|---|---|
| **E-U** external unprivileged | **$0.00** | H-01 path removed from the deployed code (high confidence) |
| **H-O** holder-only recoverable | $0.00 | no stuck/frozen funds found; `initiate_unstake` / `claim_unbonded_assets` work, `emergency::paused = false` |
| **P** privileged | $0.00 | admin fns exist (`set_pause`, `set_*_fee_bps`, `change_validator`, …) but are role-gated, not unprivileged |
| **S** stuck/bricked | $0.00 | none identified in the H-01 path |

**Confidence: HIGH** (that H-01 is not exploitable in the deployed code). Basis: on-chain bytecode
disassembly of the live module + an exact live view-function oracle, cross-checked against the
audited commit. This is **not** an "unknown" outcome — the deployed code was reachable and read.

## 3. The mechanism (audited), and why it is gone on chain

**Audited (buggy) — `sources/cabal.move@5b5f92ab…`, `process_lp_unstake` L1043–L1085:**
```
lp_amount = compound_reward + pool_router::get_real_total_stakes(stake_meta)  // gross: still includes the
                                                                             // tokens backing already-burned shares
cabal_lp  = fungible_asset::supply(cabal_token)   // live share supply at process time
unbonding = (unstake_amount / cabal_lp) * lp_amount                          // -> over-claim when pending > 0
```
When `unstaked_pending_amounts > 0` (a prior unstaker's shares are burned but their tokens are
still delegated), the numerator `lp_amount` still counts those tokens, so the unstaker is
credited `(unstake_amount / supply) × pending` that belongs to prior unstakers, at the expense
of remaining holders. The audit PoC (whose `mock_unstake` runs the process step *before* the
burn, matching `initiate_unstake`'s call order): A stakes 100, B stakes 50, B unstakes 50, A
unstakes 50 → **A should get 50 but gets 75**. `process_lp_stake` had the mirrored defect
(under-mints shares while pending > 0). Recommended fix: subtract `unstaked_pending_amounts`
from `lp_amount`.

**Deployed (fixed) — live `cabal` module `0x53c3f5d8…` (disassembled from `raw_bytes`):**
- `process_lp_undelegate` (replaces `process_lp_unstake`):
  `s_eff = supply_after_burn + unstake_amount` (= supply **before** the burn = `supply + pending`),
  `unbonding = (unstake_amount / s_eff) * (reward + get_real_total_stakes)`. Replays the audit PoC
  as **50/50 — correct**.
- `process_lp_stake`: `mint = (stake_amount / A) * (supply + unstaked_pending_amounts[type])`.
- `get_estimate_unstake_amount` and `get_cabal_stake_token_price_rel_to_underlying`:
  `price = get_real_total_stakes / (supply + unstaked_pending_amounts[type])`.
- The audited over-claiming formula (denominator = bare `supply`) is **absent everywhere**;
  the audited function name `process_lp_unstake` is **absent** from the live module.

Live integer oracle at height **23,353,451** (pool 1 = USDC-INIT LP):
`supply = 2,726,911,250,625`, `unstaked_pending_amounts[1] = 63,778,039`, `get_real_total_stakes = 4,737,924,767,617`
→ `get_estimate_unstake_amount(1, 1_000_000)` returned **`1,737,428`** = deployed formula
(`real/(supply+pending)`), **not** audited `1,737,469` (`real/supply`). Same for
`get_cabal_stake_token_price_rel_to_underlying(1)` = `1.737428732502257193`.

## 4. Live-state assessment (exact addresses / chain / height)

| Item | Value |
|---|---|
| Chain | Initia mainnet, chain-id `interwoven-1`; REST `https://rest.initia.xyz`, RPC `https://rpc.initia.xyz` |
| Observed height | `23,353,451` (capture `23,352,892`) |
| Live Cabal package | **`0x53c3f5d8e11844ba3747ebaec1b2d25051574ffbeedc69d72068395991e3ea28`** |
| Modules | 16, all `upgrade_policy = COMPATIBLE` |
| `cabal` module sha256 | `36379fa2e72e6ff81ab3487e9552be9c59b995254bca1002cc18c088387c90a5` (18,207 B) |
| `pool_router` sha256 | `a2e3d55995e6b4c30ce9e060b87c12d80343de7ea3bd3c2ff97e3076ab37f647` (13,234 B) |
| `cabal_token` sha256 | `c53bde479dc697df54267a8a0f64bc076e6f07904ef268b903b9acdbc46c8aa6` (5,513 B) |
| Audited commit | `5b5f92ab4f95e5f9f405bbfa252860472d164705` (repo `code-423n4/2025-04-cabal`; HEAD adds only a discord export) |
| Audited named address | `0xe472ba1c00b2ee2b007b4c5788839d6fb7371c6` — **0 modules on mainnet** (not the deployment) |
| Pause state | `emergency::paused` = `false` |
| Live TVL (DefiLlama) | Initia $2,114,327 + Cabal $127,578 + Strat $502,890 ≈ $2.74M |
| Live LP pending (H-01 state variable) | `unstaked_pending_amounts[1] = 63.778 LP`; `[0] = 0` |

All raw reads: `analysis/live-view-raw.json`, `analysis/live-reads.md`. Module hashes:
`analysis/deployed-module-hashes.json`.

## 5. What an attacker can / cannot do

**Can (all permissionless):**
- `cabal::initiate_unstake(type, shares)` — burn shares, queue an unbonding entry.
- `cabal::batch_undelegate_pending_lps()` — anyone can call (rate-limited to once per 259,200 s
  by `last_undelegate_time`); it triggers `process_lp_undelegate` for the whole pool.
- `cabal::claim_unbonded_assets / claim_all_unbonded_assets` — self-service withdrawal.

**Cannot:** reproduce H-01. The over-claim arises only if the unstake denominator excludes the
burned-pending shares. The live `process_lp_undelegate` adds them back
(`s_eff = supply_after_burn + unstake_amount`), and the live price/estimate/stake paths add
`unstaked_pending_amounts`. There is no unprivileged call that manipulates the denominator to
inflate a payout. Even the *hypothetical* H-01 over-claim would have been bounded by the pending
amount (`63.78 LP ≈ $15` today), because the leak is a transfer from other holders equal to the
double-counted pending — so the residual exposure was always small, and it is now zero.

**Privileged-only (not attacker-reachable):** `manager` role store, `emergency::set_pause`,
`set_unbond_period`, `set_*_fee_bps`, `change_validator`,
`admin_overwrite_voting_power_history`.

## 6. PoC / verification (run URLs in §8)

- `poc/audited_h01_repro.py` — faithful model of the **audited** `process_lp_unstake` /
  `process_lp_stake`; replays the audit PoC → **A gets 75 (fair 50), 25 LP stolen**; stake side
  under-mints 33.33 (fair 50). *This is an audited-source repro.*
- `poc/deployed_fix_check.py` — model of the **deployed bytecode** arithmetic (from the
  disassembly) + a **live oracle** that reads the chain and asserts the returned value matches
  the fixed formula and not the audited one. Exits 0 on "H-01 FIXED".
- `ci/run.sh` (run on GitHub Actions): re-fetches the live modules and verifies their sha256
  against the recorded hashes; clones + checks out the audited commit and confirms the buggy
  formula is present there; downloads aptos-cli, disassembles the **live** `cabal` bytecode and
  asserts the fix markers (audited function absent, `unstaked_pending_amounts` in the
  stake/estimate denominators); runs both PoC scripts; writes `ci-out/verdict.json`.

Result: **`deployed_is_patched_for_H01 = true`, `extractable_EU_usd = 0.0`.**

## 7. Verdict, residual / latent risk, blockers

**Verdict: CLOSED — H-01 is not present in the deployed Cabal LST package.** The live code is a
post-audit rewrite (16 modules vs the audited 10; `process_lp_unstake` → `process_lp_undelegate`)
that implements the audit's recommended mitigation. E-U = **$0** (high confidence).

**Residual / latent:**
- **Upgradeability.** Every module is `COMPATIBLE`; a future upgrade could reintroduce the
  pattern. Re-run `ci/run.sh` after any package upgrade (it detects a changed `cabal` sha256).
- **Un-audited revision.** The 2025-04 C4/Zellic reports and the SBSecurity 2026 vault reports do
  not cover this exact 16-module build. Only the H-01 question was assessed here; the newer
  mechanisms (`unstaked_release_amount` pro-rata claims, `get_real_total_unbonding`,
  `batch_undelegate_pending_lps` 3-day rate limit, whale voting) were **not** exhaustively
  audited in this pass.
- **No blockers were needed** — the path is permissionless and the code is patched, so there is no
  freeze/whitelist hiding a live bug.

## 8. Methodology & sources, caveats, files

**Method.** (1) Pulled the C4 report (web + sponsor PDF mirror `0xCabal/cabal-audits`) and cloned
`code-423n4/2025-04-cabal` at `5b5f92a`; extracted H-01 and the exact audited arithmetic. (2)
Found the live package via the DefiLlama `projects/cabal` adapter and confirmed it with live view
calls. (3) Fetched each live module's `raw_bytes` from the Initia Move REST API. (4) Disassembled
`cabal` with aptos-cli 9.6.0 and read `process_lp_undelegate`, `process_lp_stake`,
`get_estimate_unstake_amount`, `get_cabal_stake_token_price_rel_to_underlying`, `unstake_lp`,
`initiate_unstake`, `batch_undelegate_pending_lps`, `claim_unbonded_assets_internal`. (5) Built an
exact integer live oracle discriminating the audited vs deployed formula. See
`analysis/tooling-notes.md` for what the tooling can/cannot do.

**Caveats.** Read-only — no tx was submitted, so the conclusion rests on bytecode + view-function
oracle, not on a signed round-trip. TVL figures are DefiLlama point-in-time. The live package may
be upgraded after the recorded height; `ci/run.sh` re-verifies hashes. The `cabal-1` / `strat-1`
vaults (~$630k of the $2.74M) are separate products and were not in scope for H-01.

**Files index.**
```
README.md                          this report
summary.json                       machine-readable summary
analysis/c4-report-H01.md          verbatim H-01 + mitigation rec. (no team response exists)
analysis/repo-and-commits.md       audited commit vs live package; module/surface diffs
analysis/formula-discriminator.md  audited vs deployed arithmetic; live integer oracle
analysis/live-reads.md             all live view calls (height 23,352,892)
analysis/live-view-raw.json        raw JSON responses
analysis/deployed-modules-list.json / deployed-module-hashes.json
analysis/disasm-cabal.mv.masm      full disassembly of the live `cabal` module
analysis/disasm-annotated.md       annotated live disassembly of the H-01-relevant functions
analysis/cabal.mv                  live compiled bytecode
analysis/defillama-adapter-cabal.js  DL adapter (address discovery)
analysis/tooling-notes.md          what worked / what failed (exact)
poc/audited_h01_repro.py           audited-source repro (75 vs 50)
poc/deployed_fix_check.py          deployed-formula model + live oracle
ci/run.sh                          CI job (hash verify + disasm + PoCs + verdict)
ci-out/                            CI results (verdict.json, hashes, disasm checks)
ci-log.txt / ci-artifacts/         CI log + artifacts
```

**CI run:** **https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39958247850** — SUCCESS,
`deployed_is_patched_for_H01 = true`, `extractable_EU_usd = 0.0`, module hashes `ALL MATCH`.
(An earlier attempt `…/runs/39922352821` hung in the optional Move-toolchain download and was
cancelled; the job was hardened to make the verdict independent of the toolchain download.)
