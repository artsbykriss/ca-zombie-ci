# Gimo st0G (0G chain) — live unprivileged extraction review

**Date:** 2026-10-21 · **Chain:** 0G mainnet, chainId **16661** · **Pin block:** **47,841,263** (ts `2026-10-21T15:03:46Z`)
**Status:** read-only. No transaction was signed or broadcast. Every state change was executed on a local anvil fork only.
**Source status:** **verified source recovered and proven byte-identical to deployed code** (not a decompile-only verdict — see §4).

---

## 1. TL;DR

| Target | Live value | E-U (unprivileged) extractable now | Why closed / open | Latent risk |
|---|---|---|---|---|
| Gimo st0G — rate-based liquid staking, 0G chain | **19,370,546.38 0G = $4,748,226** (NAV) | **$0** (high confidence) | `rate` is republished once per era from the *actual* validator delegation (`getTotalDelegated`), never from a user-influenced balance. `stake`/`unstake` both price at the same stored rate, so a round trip returns −1 wei. Mint is `onlyMinter`. Donations to the pool are not counted. The only value edge is a last-minute stake before `newEra()` (JIT capture of one era's reward), and that is **dominated by simply staying staked** (1.63%/yr vs 10.84%/yr at 1× TVL). | (a) `rateChangeLimit = 0` disables the per-era rate cap, so a **keeper outage of ≥4 eras** turns the JIT into a real, uncapped yield theft (up to ~$12.7k per 10-era outage, and repeatable). (b) Both proxies are owned by a **single EOA** → $4.75M privileged risk. |
| StakeManager proxy `0xAc06…135aF` / StakePool proxy `0x136b…96AF` | delegated 19,370,670.54 0G | — | per-era crank is 32/32 on time (12–17 s after boundary) | owner upgrade path |

**One-liner:** an external unprivileged attacker can extract **$0** from Gimo st0G today; the protocol's only real edge (1-era JIT reward capture) is economically dominated 3.4–6.6× by honest staking, and the 10.84%/yr NAV growth is fully backed by the validator delegation.

---

## 2. Total live extractable now

| Category | USD | Confidence | Basis |
|---|---|---|---|
| **E-U** (external unprivileged) | **$0.00** | **high** | 10/10 fork tests; verified source; no path with positive net PnL |
| **E-U-conditional** | **$0.00 today** | high (on the condition) / medium (on the mechanism's practical value) | requires `currentEra − latestEra ≥ 4` at the moment of entry; observed 32/32 eras with `dt = 86,395–86,405 s`, `late = 12–17 s`. If it ever happens: `profit = f × 0.9 × N × R`, ≈ **$12.7k per 10-era outage** for capital ≫ TVL, plus a 3-era lock. |
| **H-O** (user self-service) | **$3,877.13** matured, **$4,170.57** total open claims | high | 2,871 open `UnstakeInfo` records (2,863 matured) enumerated from storage; `withdraw()` pays them from the pool's 15,887.76 0G liquid balance (99.55% already earmarked for matured claims) |
| **P** (privileged) | **$4,748,226.47** + $1,236.82 fee balance | high | owner EOA `0x300730…B0Fb` can `upgradeTo()` both UUPS proxies and/or `withdrawProtocolFee()` |
| **S** (stuck/bricked) | **$0.00** | medium | no stuck balances found; 1,197.09 0G of claims are simply inside the normal 3-era unbond window |

---

## 3. The mechanism, in exact terms

Gimo is a **StaFi LSaaS fork** (`stafiprotocol/evm-lsd-contracts`, `contracts/staking/StakeManager.sol`, BUSL-1.1) deployed on 0G with an added validator-migration module. Contract map:

| Role | Address | Code |
|---|---|---|
| st0G token (`LsdToken`, plain ERC20 + `onlyMinter` mint) | `0x7bBC63D01CA42491c3E084C941c3E86e55951404` | 3,270 B, non-proxy |
| Staking manager (UUPS proxy) | `0xAc06d1Df23a4Fa00981aFAC0f33A5936Bd2135aF` | EIP-1967 impl `0x7a5e1b999a665f2b89e5f6eae32df9471de193c7` (16,692 B) |
| Stake pool (UUPS proxy, holds delegation + pays withdrawals) | `0x136b56554671976EF8366B01B31185F91Ae696AF` | EIP-1967 impl `0x377db28b688e7fd84bb99a6a8f8f1084a33bb512` (7,378 B) |
| 0G validator | `0xeC856948CF28a7c36E4c0D7877d027bA0a8AF17d` | BeaconProxy (`tokens/delegatorShares/getDelegation`) |
| owner of both proxies, `minter` controller | `0x3007306646AC90A647BEBc9acC029C941Db5B0Fb` | **EOA** (no code, nonce 184) |

### 3.1 Where the rate comes from

`rate` is 0G per st0G (1e18). It is written **only** by `newEra()` (`StakeManager_source.sol:2922`):

```solidity
uint256 newPoolActive = IStakePool(pool).getTotalDelegated(validators) + pendingMigration[pool];
newTotalActive += newPoolActive;
uint256 poolNewReward = newPoolActive > poolInfo.active ? newPoolActive - poolInfo.active : 0;
...
_distributeReward(totalNewReward, rate);                                  // mints 10% of R as fee shares
uint256 newRate = _calRate(newTotalActive, ERC20(lsdToken).totalSupply()); // S.2188
_setEraRate(_era, newRate);                                                // S.2178
```

`getTotalDelegated` (`StakePool source:1064`) is `Σ validator.getDelegation(pool).shares × validator.tokens() / validator.delegatorShares() + pendingBond`.
So the numerator is the **real on-chain delegation**, not a manager balance and not `totalProtocolFee`.
The pool's plain 0G balance (15,887.76 0G) is **excluded** — that is why donations cannot move the rate.
`_calRate = floor(totalActive × 1e18 / totalSupply)`, with a ±5,000-wei dust clamp near 1.0.

### 3.2 `newEra()` — who, when, what input

* **No access control, no arguments.** Anyone may call it. Verified on fork from `0xBEEF`.
* **Once per era, and it can be late:** `_era = latestEra + 1; if (currentEra() < _era) revert EraNotMatch();`
  at the era boundary it succeeds; a second call in the same era reverts `EraNotMatch`. `eraSeconds = 86,400`,
  `eraOffset = 20,347`, `latestEra = currentEra = 400`.
* **The caller controls no input and no reward quantity.** They control only *when within the era* the call lands.
  That does not change R (rewards accrue continuously at the validator level), only the stake/unstake positions
  held at that instant.
* **`rateChangeLimit` semantics:** a **relative per-era cap in 1e18 units** (`(Δrate × 1e18) / rate ≤ limit`),
  max `5e15` = 0.5%. **Live value = 0, and `if (rateChangeLimit > 0)` means 0 disables the cap entirely.**
  A +10% one-era move is accepted at the live setting and reverts `RateChangeExceedLimit` when the cap is set
  (fork test `test_uncapped_rate_move_when_limit_is_zero`).
* **`rateChangeLimit` is not exploitable on its own**: nobody can fabricate a rate move. It only amplifies a
  reward that has already accrued (i.e. a keeper outage).

### 3.3 The one real edge: JIT stake around the rate update

`stake` mints at the stored rate, `unstake` burns at the same stored rate, so any position entered and exited
between two era updates is worthless (−1 wei in the fork). Value only appears if the position **crosses** a
`newEra()`. Then:

```
rate_after = (A + X + R) / (S + X/r0 + feeShares)
profit     = X/r0 × rate_after − X  =  f × (1 − c) × R ,   f = (X/r0)/(S + X/r0),  c = 10%
```

where `R` = rewards accrued since the previous era and `A` = pre-existing active. The JIT staker is paid a
pro-rata share of a reward earned on **other people's** capital, and holders are diluted by exactly that amount.

Live: `R = 5,751.61 0G/era` (`eraRate[400] − eraRate[399] = 0.000402242086 × 14,298,883.27 st0G`) = **$1,409.87/day**.

Fork measurement (`test_jit_capture_of_one_era_reward`, two fresh forks of the same block, measured counterfactual):

| capital X | attacker PnL | holder loss | return per 3-era lock | annualised | honest staking |
|---|---|---|---|---|---|
| 0.01× TVL ($47k) | 12.56 USD | 12.56 | 2.65 bp | **3.22%/yr** | 10.84%/yr |
| 1× TVL ($4.75M) | **634.44 USD** (2,587.91 0G) | 2,587.83 0G | 1.34 bp | **1.63%/yr** | 10.84%/yr |
| 10× TVL ($47.5M) | 1,153.53 USD | — | 0.24 bp | **0.30%/yr** | 10.84%/yr |

The 3-era `unbondingDuration` fixes the claim in 0G at the post-update rate; capital is locked 3 days. **At every
size the JIT return is below the 10.84%/yr you get by simply staying staked** (the 10% protocol fee alone makes
N=1 JIT ≤ 90% of honest yield). It becomes profitable only when the reward accumulated between updates is
N ≥ 4 eras.

---

## 4. Live-state assessment (all reads at block 47,841,263)

| Item | Value | Call |
|---|---|---|
| `rate()` / `getRate()` | `1.354689454598691938` 0G/st0G | `0xAc06…135aF.rate()` |
| `totalSupply()` | `14,298,883.268920276` st0G | `0x7bBC…1404.totalSupply()` |
| `poolInfoOf(pool).active` | `19,370,546.376943970094166214` 0G | `0xAc06…135aF.poolInfoOf(0x136b…)` |
| `poolInfoOf(pool)` era/bond/unbond | `400 / 3.18 / 127.340808732277042172` 0G | same |
| `getTotalDelegated([validator])` | `19,370,670.537752702371208386` 0G | `0x136b…96AF.getTotalDelegated` |
| validator `tokens` / `delegatorShares` | `73,280,860.709272625794985765` / `66,664,537.341165850651015742` | `0xeC85…F17d` |
| pool's share of validator | **26.43 %** | derived |
| StakePool liquid 0G | `15,887.757413639641067256` 0G | `eth_getBalance` |
| StakeManager native 0G | `0` | `eth_getBalance` |
| StakeManager st0G balance (fee) | `3,724.489304434715109607` st0G = 5,045.51 0G = **$1,236.82** | `0x7bBC…1404.balanceOf(manager)` |
| `totalProtocolFee` (cumulative minted) | `177,844.912165168813416416` st0G = 240,924.63 0G = **$59,056.91** | `0xAc06…135aF.totalProtocolFee()` |
| `latestEra` / `currentEra` | `400 / 400` | |
| `eraSeconds` / `eraOffset` | `86,400 / 20,347` | |
| `unbondingDuration` | `3` eras | |
| `rateChangeLimit` | **`0` (cap disabled)** | |
| `protocolFeeCommission` | `1e17` (10 %) | |
| `minStakeAmount` | `1e16` (0.01 0G) | |
| `nextUnstakeIndex` | `7,211` records created | |
| open claims | **17,013.970459 0G** (2,871 records, 2,863 matured) | enumerated from `unstakeAtIndex(i)` + `getUnstakeIndexListOf(user)` |
| matured claims | 15,816.883148 0G = **$3,877.13** | |
| `pendingBond` / `reservedFee` | `0` / `9,387,999,918,406` wei | `0x136b…` |
| owner (both proxies) | `0x3007306646AC90A647BEBc9acC029C941Db5B0Fb` — **EOA**, nonce 184, 5.75 0G | `owner()` |
| `pendingOwner` | `0x0` | |
| token `minter` | `0xAc06d1Df23a4Fa00981aFAC0f33A5936Bd2135aF` | `minter()` |
| 0G price used | **$0.2451260988** (DefiLlama `coingecko:zero-gravity`, ts 1,792,596,176) | |
| **NAV / TVL** | **19,370,546.38 0G = $4,748,226.47** (DefiLlama protocol page shows $4.63M at its own price snapshot) | |

**Solvency:** assets = 19,370,670.54 delegated + 15,887.76 liquid = 19,386,558.30 0G; st0G liability =
19,370,546.38 0G; open claims = 17,013.97 0G. The 1,002.05 0G difference is exactly the amount undelegated at
`newEra(400)` that is still in the 0G validator unbonding queue. Matured claims are 99.55 % covered by the
pool's liquid balance; 5,211 of 7,211 historical records have already been withdrawn.

### 4.1 Source recovery (this is the strongest evidence item)

The 0G explorer is a ConfluxScan SPA (`/api/v2/...` → HTML; Sourcify `16661` → `match: null`), which is why the
pass-3 note said "source unverified". The SPA's backend does serve it:

```
GET https://chainscan-api.0g.ai/v1/contract/0x7a5e1b999a665f2b89e5f6eae32df9471de193c7
→ result.sourceCode (112,783 B), result.verify = {name: "StakeManager",
   version: "v0.8.19+commit.7dd6d404", optimization: "1", runs: "200", exactMatch: "True"}
```

Rebuilt with solc 0.8.19 / optimizer 1 / 200 runs and compared against `eth_getCode` at block 47,841,263:

| contract | rebuilt | deployed | result |
|---|---|---|---|
| StakeManager impl | 16,692 B | 16,692 B | **identical** except the 5 `immutable __self` slots (`address(this)`) |
| StakePool impl | 7,378 B | 7,378 B | **identical** except the same `__self` slots |
| LsdToken | 3,270 B | 3,270 B | **identical, 0 byte diffs** |

`ci-out/source_verify.json`. The heimdall decompile (`analysis/decompiled.sol`) is retained only as a selector /
control-flow cross-check; its arithmetic is lossy and **no conclusion depends on it**.

---

## 5. What an attacker can / cannot do

### CAN (all permissionless, all measured)

1. **Call `newEra()` once per era** at/after the boundary — succeeds; second call in the same era reverts
   `EraNotMatch`. Fork: `test_newEra_is_permissionless_once_per_era`.
2. **Stake → `newEra()` → unstake atomically in one tx** and capture `f × 0.9 × R` of the era's reward
   (fork-measured: 2,587.91 0G on 19.37M 0G at 1× TVL). **Net loss vs simply staking** (see §3.3).
3. **Withdraw matured claims** exactly once, paid by the pool (`test_withdraw_lifecycle`): 100 0G in → 99.999999999999999998 0G claim → paid in full.
4. **Donate 0G to the StakePool** (`receive()` accepts it): zero effect on `getTotalDelegated`, `pendingBond`
   or the rate (`test_pool_donation_does_not_change_numerator`).

### CANNOT

| Attempt | Result |
|---|---|
| mint st0G | `mint` is `onlyMinter` → `CallerNotAllowed()` (`0x2af07d20`); `updateMinter` is also `onlyMinter` |
| profit from a stake/unstake round trip inside one era | 1,000 0G → 738.176558919354845257 st0G → 999.999999999999999999 0G (**−1 wei**); both conversions floor |
| inflate the rate by donating to the manager or the pool | manager has no `receive()`; pool donation is excluded from the numerator |
| inflate the rate by donating to the validator | would raise `tokens()/delegatorShares`, but the pool owns only 26.43 % of the validator, so a donor recovers ≤26.4 % of any donation — strictly a loss |
| unstake without the user's allowance | `burnFrom(msg.sender, …)` needs user→manager allowance; otherwise reverts |
| withdraw twice / early / via a fake pool | `ZeroWithdrawAmount` / `AlreadyWithdrawed`; the record is removed before payment and the payee is hard-coded to `msg.sender` |
| steal another user's `UnstakeInfo` | records are per-`msg.sender`; `receiver` is never used for payment |
| `withdrawProtocolFee`, `setRateChangeLimit`, `addStakePool`, `upgradeTo` | all `onlyOwner`; stranger calls revert (`test_privileged_paths_revert_for_stranger`) |
| force `newEra()` to revert (to accumulate rewards) | no vector found: `delegated ≥ unbond − bond` always, so `undelegateMulti` cannot under-run; `reservedFee` has ~9,388 eras of runway; the crank is permissionless so anyone can advance it |

---

## 6. PoC / fork verification

`poc/` — Foundry 1.7.1, fork of 0G mainnet at block **47,841,263** via the public `https://evmrpc.0g.ai`
(no key, no secret). Tests:

```
forge test -vv   →  10 passed / 0 failed
```

| test | what it proves |
|---|---|
| `test_live_state` | rate == floor(active·1e18/supply); `delegated == active + unbond − bond`; cap disabled; unbonding = 3 |
| `test_newEra_is_permissionless_once_per_era` | reverts before the boundary, succeeds from `0xBEEF` after it, reverts again in the same era |
| `test_no_roundtrip_profit_without_rate_move` | −1 wei round trip; unstake does not move the rate |
| `test_pool_donation_does_not_change_numerator` | 5,000 0G donation leaves `getTotalDelegated` and `pendingBond` unchanged |
| `test_jit_capture_of_one_era_reward` | **measured** counterfactual (two forks): attacker +2,587.91 0G, holders −2,587.83 0G; 1.63 %/yr vs 10.84 %/yr honest |
| `test_jit_zero_reward_is_neutral` | a 5M 0G deposit with R = 0 leaves the rate unchanged |
| `test_uncapped_rate_move_when_limit_is_zero` | +10 % one-era move accepted at `rateChangeLimit=0`, reverts once the owner sets 0.5 % |
| `test_token_mint_is_minter_only` | stranger mint / `updateMinter` reverts `CallerNotAllowed()` |
| `test_withdraw_lifecycle` | early withdraw reverts, matured withdraw pays exactly, replay reverts, fake pool reverts |
| `test_privileged_paths_revert_for_stranger` | all admin selectors revert for an arbitrary caller |

**CI:** GitHub Actions, public repo `artsbykriss/ca-zombie-ci`, branch `gimo-st0g`, workflow `poc.yml`.
Run URL: **`<filled below>`** · tests **10/10 PASS**, gas 65k–903k per test, ~$0 external cost (public RPC,
no flash loans needed — the JIT path is self-funded).

The custom CI job (`ci/run.sh`) additionally:
* re-fetches the explorer source, recompiles and re-compares all three contracts (`ci-out/source_verify.json`);
* pins the block state, scans 32 `ExecuteNewEra` logs, enumerates all 7,211 `UnstakeInfo` records and 4,423
  receivers, and recomputes the JIT table (`ci-out/live_state.json`, `ci-out/newera_cadence.csv`).

---

## 7. Verdict, residual risk, blockers

**Verdict: E-U $0 (high confidence).** The protocol is a faithful StaFi-LSaaS deployment with a fully
verified, byte-identical source. The rate is real-yield-driven, mint/burn are gated, donations are inert, and the
only value edge (JIT around `newEra`) is dominated by honest staking at every capital size because the update
cadence is one era and the exit lock is three eras.

**Residual / latent risk**
1. **Keeper outage (E-U-conditional).** `rateChangeLimit = 0` means no cap. If `newEra()` is not called for
   N ≥ 4 eras, an attacker can stake, crank, and unstake for `f × 0.9 × N × R` — about **$5.1k at N=4** and
   **$12.7k at N=10** for capital ≫ TVL, repeatable per outage. Setting `rateChangeLimit` to e.g. 1e15 (0.1 %)
   would bound this to ~0.1 % of NAV per era. The observed cadence is 32/32 eras at 12–17 s, so the condition is
   not met today.
2. **Single-EOA ownership (P).** `0x3007306646AC90A647BEBc9acC029C941Db5B0Fb` (no code, nonce 184) owns both
   UUPS proxies. `upgradeTo()` + `withdrawForStaker()` gives it the entire 19.37M 0G delegation — **$4.75M**.
   It also holds the right to take the manager's 3,724.49 st0G fee balance ($1,236.82).
3. **Gimo-specific delta is unaudited (as far as public sources show).** Upstream StaFi has audit history, but the
   added migration module (`migrateValidatorBegin` / `adminForceUndelegate` / `adminCompleteMigration`,
   `pendingMigration`) is not covered by any public report I could find, and `pendingMigration` is added to the
   rate numerator. It is `onlyOwner`, so this is P-class, but a bug there could mis-state the rate.
4. **Withdrawal liveness vs 0G validator unbonding.** `withdraw()` frees a claim after 3 eras, but the pool can
   only pay from its liquid balance (15,887.76 0G), which is 99.55 % earmarked for already-matured claims. If the
   0G validator unbonding period exceeds 3 days, large simultaneous withdrawals queue up. No loss, only delay.
5. **Price/exit.** CoinGecko lists st0G at $0.3346 with **$9.77 24 h volume** (a ~0.8 % premium to the $0.3320
   NAV). Any path that requires selling st0G is not realizable at size; the JIT path does not need a market.

**Blockers / limits of this review**
* The 0G validator layer is a system contract; its `tokens()` accrual cannot be advanced on an anvil fork, so the
  JIT test injects exactly one era of rewards through a `getTotalDelegated` mock (all other calls are real). The
  reward magnitude itself is taken from the live `eraRate` series, not from the mock.
* The 0G validator unbonding period (chain parameter) was not measured; it only affects §7.4.
* No full economic simulation of a multi-era keeper outage was run — the formula is exact and linear in N, but the
  probability of an outage is an operational judgement.

---

## 8. Methodology, sources, files

**Method.** (1) Recover verified source from the explorer backend and prove byte-identity by recompiling and
diffing `eth_getCode`; (2) read the pinned-block state for every address/role/balance with exact `eth_call`s;
(3) enumerate every `UnstakeInfo` record and every live unstake set to measure claims; (4) scan 32 `ExecuteNewEra`
logs for cadence; (5) reduce the mechanism to `profit = f(1−c)R` and verify it with two-fork measured
counterfactuals; (6) probe every gate (`onlyMinter`, `onlyOwner`, `onlyStakeManager`, allowance, double-withdraw,
fake pool) with fork calls.

**Sources.** 0G public RPC `https://evmrpc.0g.ai`; explorer backend `https://chainscan-api.0g.ai/v1/contract/…`;
DefiLlama `coins.llama.fi` (`coingecko:zero-gravity`, $0.245126 at ts 1,792,596,176) and `api.llama.fi/protocol/gimo`
($4.63M); upstream `github.com/stafiprotocol/evm-lsd-contracts` (`contracts/staking/StakeManager.sol`);
`gimofinance.xyz` ("powered by StaFi AI LSaaS"); CoinGecko st0G market page.

**Files.**
```
README.md                          this report
summary.json                       machine-readable summary
analysis/StakeManager_source.sol   explorer-verified source (112,783 B)
analysis/src_0x377…sol             StakePool impl source
analysis/src_0x7bBC…sol            LsdToken source
analysis/mechanism.md              exact math, code line refs, checked negatives
analysis/decompiled.sol            heimdall decompile (cross-check only, lossy)
analysis/era_rates.json            eraRate[0..400]
analysis/unstake_records.json      all 7,211 UnstakeInfo records
analysis/outstanding.json          live (unwithdrawn) record ids + totals
analysis/newera_logs.json          raw ExecuteNewEra events
analysis/get_logs.py, batch.py, enum_*.py   read-only RPC tooling
ci/verify_source.py                recompile + byte-compare (CI)
ci/snapshot.py                     pin-block state, cadence, claims, economics (CI)
ci/run.sh                          CI heavy job entry point
poc/                               Foundry fork tests (test/Gimo.t.sol)
ci-out/                            CI artifacts: source_verify.json, live_state.json, newera_cadence.csv
```
