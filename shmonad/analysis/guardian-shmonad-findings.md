# Published-audit cross-check — Guardian "ShMonad Updates" (2026-08-21)

**Source:** Guardian (guardian.security), report *ShMonad Updates* for FastLane Labs, published 2026-08-21.
Full PDF (public): `https://raw.githubusercontent.com/GuardianAudits/Audits/main/FastLane%20Labs/2026-08-21_FastLane_Labs_ShMonad_Updates.pdf`
Scope repo: `FastLane-Labs/fastlane-contracts-internal` (private), commits `7910434ed0`, `14e40ee449`,
`cd406b6f61`, `9f116de99a`, `642d82e34b`, `78f7b9da1d` (6 review rounds, 29 files, 6,404 nSLOC).
Counts: **118 findings — 0 Critical, 4 High, 65 Medium, 42 Low, 7 Informational**.
Statuses at publication: 31 resolved · 2 partially resolved · **21 acknowledged** · 26 reported · 38 pending.

The deployed implementation (`0x8Ee4FF5FF50198dcbB7B882A0781F42724Dd095f`, set at Monad block
**108,665,496 = 2026-09-28 05:57 UTC**) post-dates the report window (Apr 30 – Aug 21 2026), so the team
shipped further fixes after publication. Every claim below is checked against the **deployed** source
(`analysis/src/`), not against the report snapshot.

---

## 1. The four published Highs — all FIXED in the deployed code

| # | Round | Title | Report status | Deployed-code check | Verdict |
|---|---|---|---|---|---|
| H-01 | Main Review 1 | **Turnover Can Pin Validator Crank** (DoS) | Pending (PR 742) | `_applyStakeDelta()` (StakeTracker.sol:1538) now caps a withdrawal at `validatorUnstakableAmount`, keeps the unavailable tail in the target and requeues it (`QueueLib.getTurnoverAmountToRequeue`) — the exact mitigation the report asked for | **FIXED** |
| H-02 | Main Review 1 | **Stale denominator amplifies turnover** | Pending | `_recomputeCurrentAllocationTotals()` (StakeTracker.sol:821,846) now reads `validatorEpochPtr_N(0, cursorId)` with the in-code comment *"These totals are stored in pre-advance N(0), then read by validators as post-advance N(-1)"* — the denominator now matches the numerator epoch | **FIXED** |
| H-01 | Remediation Review 1 | **Sub-Dust Isolated Exit Freezes Protocol** (permissionless protocol freeze) | Reported (PR 788) | `_queueAndInitiateIsolatedUnstake()` (StakeTracker.sol:2254) now mirrors Monad's dust rounding: `if (remainingActiveStake != 0 && remainingActiveStake < DUST_THRESHOLD) amountToWithdraw = state.activeStake;` | **FIXED** |
| H-01 | Remediation Review 2 | **Pooled unstake accounting can freeze protocol** (dust rounding mismatch) | Reported (PR 808) | `_initiateStakeAllocationDecrease()` (StakeTracker.sol:2486) mirrors the same dust rule for pooled stake | **FIXED** |

> These are the only paths that would have made the **whole $7.26M vault** freeze/stop (an **S**-class
> impact) reachable by an unprivileged caller (H-01 RR1's own PoC needed only `createPolicy`-free flows:
> isolated deposit into a validator with zero pooled allocation, `sendValidatorRewards(val, SCALE)`,
> `requestUnstakeIsolated`, then public `crank()`). The dust mirrors close them.

## 2. MR1 JIT-fee findings — FIXED in the deployed code

| # | Title | Deployed-code check | Verdict |
|---|---|---|---|
| L-06 | Atomic unstake fees immediately capturable by JIT deposits | `_accountForWithdraw()` (StakeTracker.sol:3425) now books the fee: `globalRevenuePtr_N(0).earnedRevenue += _fee` (line 3455) and `distributedAmount += net + fee`. The report snapshot only credited `net`, leaving the fee as instantaneous pooled equity. Deposit pricing uses full equity while exit pricing subtracts `_recentRevenueOffset()`, so the fee is now smoothed and a JIT depositor cannot capture it | **FIXED** |
| L-07 | UNKNOWN/inactive-proposer boost yield bypasses smoothing | `_handleBoostYield()` (StakeTracker.sol:2686) now records `globalRevenuePtr_N(0).earnedRevenue += pooledAmount` **and** `globalAllocationRevenuePtr_N(0).nonStakingRevenue += pooledAmount` in the inactive/UNKNOWN branch (lines 2729-2735), so the yield is smoothed for exits | **FIXED** |

## 3. Acknowledged, UNFIXED findings that touch unprivileged value transfer (the live residual)

| # | Round | Title | Mechanism | Deployed-code check | Live magnitude |
|---|---|---|---|---|---|
| **M-09** | MR2 | Queued validator rewards dilute existing holders | `sendValidatorRewards()` escrows the validator payout as `s_globalLiabilities.rewardsPayable` (StakeTracker.sol:2623,2641) which is a **liability**, so deposit pricing (`_totalEquity`, FLERC4626.sol:410 / AccountingLib.sol:252) **excludes it**. When the escrow later settles as pooled yield (`_handleRewardsRedirect`, StakeTracker.sol:3216, or the staking round-trip via `_handleEarnedStakingYield`), a depositor who entered while it was queued owns a pro-rata slice | **PRESENT** | live escrow `rewardsPayable` 315 – 10,255 MON (**$7 – $223**) sampled over 30 blocks; attacker profit ≈ `D·A/E` |
| **M-01** | RR4 | Unclaimed priority rewards underprice new deposits | Coinbase priority-fee rewards forwarded to the Monad staking precompile are only booked when claimed on a later crank; deposits priced in the interim are too cheap | **PRESENT** (Acknowledged) | bounded by in-flight priority rewards per crank |
| **M-19** | MR2 | Unstake burns erase deferred reward claims | `requestUnstake()` (ShMonad.sol:338) burns shares at the *discounted* exit price (`previewUnstake` → `deductRecentRevenue: true`) and stores only a fixed `amountMon`; the deferred revenue stays with the remaining cohort | **PRESENT** | bounded by current-epoch revenue `earnedRevenue(0)` (~18k MON ≈ **$392** observed) |
| **M-22** | MR2 | Tiny validator slices stall redemptions | The dust check is applied to the *aggregate* queue, not per validator: a queue of `DUST_THRESHOLD+1` split across validators yields sub-dust slices everywhere, so nothing undelegates and a matured `completeUnstake()` reverts | **PRESENT** | availability (H-O delay), not theft; not attacker-controllable at will |
| **M-23** | MR2 | Final isolated sweep rewards late minter | leftover isolated withdrawal surplus is swept into pooled equity at the moment `completeUnstakeIsolatedFor()` is called (permissionless); a JIT depositor captures it | **PRESENT** | isolated totals are **4,411 MON ≈ $96** — negligible |
| **M-08** | MR2 | Coinbase spoofing redirects validator rewards | a *former* validator controller plants code at the old custom-coinbase address that lies about `VAL_ID()`; the new proxy imports poisoned commission settings during migration; then permissionless `crank()` pays the attacker | **PRESENT** | needs a legacy custom-coinbase + the owner running the migration → **P-assisted**, not purely unprivileged |

## 4. Why the JIT-dilution residual is economically negligible today

`profit = D · A / (E + D)` where `D` = attacker capital, `A` = reward value realised during the holding
window, `E` = vault equity. With live `E ≈ 333.8M MON ($7.26M)` and the **observed peak escrow
`A ≈ 10,255 MON ($223)`**, an attacker deploying `D = $1M` captures
`1e6 · 223 / 7.26e6 ≈ $30` (0.003%), and must lock the capital across the settlement **and** the
`MONAD_EPOCH_LENGTH = 50,000`-block (~5.5 h) smoothing window before the captured value is realisable.
The in-flight-priority-reward pool (M-01) and current-epoch revenue (M-19, ~$392) are of the same order.
No material E-U.

## 5. Reproduce

```
python3 analysis/live_check.py        # live state (keyless public RPC)
cd poc && forge test -vv              # 8/8 fork tests (eth_rpc_url pinned in foundry.toml)
```
