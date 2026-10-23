# shMonad (FastLane Labs) — residual deep-dive (ZH4 pass4-recon OPEN #2)

**Date:** 2026-10-23 · **Chain:** Monad (chain-id **143**) · **Status:** read-only; PoC fork-verified only; **no mainnet transactions**; no keyed RPC URLs or secrets in this folder.

| | |
|---|---|
| Target | `0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c` (TransparentUpgradeableProxy) |
| Implementation (EIP-1967) | `0x8Ee4FF5FF50198dcbB7B882A0781F42724Dd095f` (`ShMonad`, solc 0.8.30, cancun, optimizer 200) |
| ProxyAdmin (EIP-1967 admin slot) | `0x00B16590295092f12f4CEc655296b6129c49489c` |
| Deployed | impl set at block **108,665,496 = 2026-09-28 05:57 UTC** (6 `Upgraded` events since 2025) |
| `owner()` | `0x48a3267BCc4Cf230e9Bc4cae0c11EEbDb9a6A687` |
| `getCodeUpgradeAuthority()` | `0x4B7f4A4316c44B6928FB449B14Bd21b9718932F3` |
| `getZeroYieldToken()` | `0x06aB4F89B4abAeE213a8Cf64188DEa47e4AB11EB` |
| Live state (block 115,800,000) | `totalAssets` **333,801,143.43 MON ($7,261,182)** · `totalSupply` 203,383,957.22 shMON · share rate 1.6412 · frozen/closed **false/false** |
| Latest re-read (block 115,899,665) | `totalAssets` 333,815,463.51 MON ($7,261,621) · escrow `rewardsPayable` 10,523 MON · not frozen/closed |

---

## 1. TL;DR

| Surface | Live unprivileged extractable | Why closed / open | Latent risk |
|---|---|---|---|
| **shMonad core (ERC-4626 mint/redeem/share math)** | **$0** | `cbPooledShareRate` circuit breaker (FLERC4626.sol:383) + `CircuitBreakerLib` enforce a non-decreasing pooled share rate on every value path; deposit ≥ fair, redeem ≤ fair (verified on fork, 8/8 tests) | none material |
| **Atomic-unstake fee JIT capture** (Guardian L-06, MR1) | **$0** | **FIXED** in the deployed impl: `_accountForWithdraw()` books the fee into `earnedRevenue` (StakeTracker.sol:3455) | — |
| **UNKNOWN-proposer boost-yield JIT capture** (Guardian L-07, MR1) | **$0** | **FIXED**: `_handleBoostYield()` now records pooled revenue for inactive/UNKNOWN proposers (StakeTracker.sol:2729-2735) | — |
| **Permissionless protocol-freeze DoS** (Guardian H-01 RR1/RR2, MR1 H-01/H-02) | **$0** | **FIXED** in the deployed impl: Monad dust-rounding mirrored at StakeTracker.sol:2254 and :2486; turnover capped at `validatorUnstakableAmount` (StakeTracker.sol:1538); stale-denominator fixed (StakeTracker.sol:846) | re-arm if downgraded |
| **Deposit underpricing of un-booked reward escrow** (Guardian M-09 / M-01-RR4 / M-19, all *Acknowledged*) | **≈$0** (mechanism live) | `rewardsPayable` is a liability excluded from deposit equity; when realised as pooled yield a late depositor captures a pro-rata slice. Live escrow pool **315–10,255 MON ($7–$223)** → `profit = D·A/E ≈ 3e-5·D` | becomes material only if the reward escrow / in-flight priority rewards spike |
| **Operator / policy-agent surface** | **$0** | `_spendFromCommitted` can only reach an account's *committed* bucket (or its uncommitting/top-up, which the victim must opt into); a fresh agent cannot touch a victim's uncommitted balance (fork test 07) | social-engineering only |
| **Privileged surface** (freeze/close/upgrade/params/validator admin) | n/a | `onlyOwner` / `onlyCodeUpgradeAuthority` (fork test 06) | owner is a single EOA — see §8 |

## 2. Total live extractable now: **$0.00** (confidence: **medium**)

No unprivileged path to material value extraction was found. The one live mispricing *mechanism* (JIT
dilution of un-booked reward escrow) is real and acknowledged by the auditors, but its exploitable pool at
current state is **$7–$223** (peak `rewardsPayable` over a 30-block sample), making the captured value
`≈3e-5 × attacker_capital` — below gas/opportunity cost. The vault is solvent and not frozen/closed.

Categories (block 115,800,000, MON = $0.0217534):

| Category | USD | Meaning |
|---|---|---|
| **E-U** (external unprivileged) | **0.00** | no material extraction |
| **E-U-conditional** | `D·A/E` | with capital `D` and a reward pool `A` realised during the window; ≈$3,100 for `D=$1M`, `A=$22k` (a 100× escrow spike) |
| **H-O** (holder-only) | **99,900** | `redemptionsPayable` 4,593,274 MON — users' own matured withdrawals (atomic instant-exit is additionally capped at ~$67k of pool liquidity) |
| **P** (privileged) | **7,261,182** | the whole vault is owner-controlled (freeze/close/upgrade/params) |
| **S** (stuck) | **0** | protocol is not frozen/closed |

## 3. The mechanism in exact terms (deployed code)

**Share pricing is anchored on "equity", and equity excludes liabilities** (`AccountingLib.totalEquity`,
libraries/AccountingLib.sol:252): `equity = stakedAmount + address(this).balance − (rewardsPayable + redemptionsPayable + totalZeroYieldPayable) − isolatedTotalAssets`.

- **Deposit** (`_previewDeposit`, FLERC4626.sol:346 → `_convertToShares`, :273) prices with
  `deductRecentRevenue = false` → **full** equity; the `rewardsPayable` escrow is a liability so it is
  **absent** from equity.
- **Exit / `convertToAssets`** (FLERC4626.sol:456) prices with `deductRecentRevenue = true` → equity
  **minus** `_recentRevenueOffset()` (current-epoch revenue + unvested smoother).
- **`sendValidatorRewards(valId, feeRate)`** (FLERC4626.sol:73 → `_handleValidatorRewards`,
  StakeTracker.sol:2592) escrows the validator payout as `s_globalLiabilities.rewardsPayable` and
  `s_globalCapital.reservedAmount` (StakeTracker.sol:2623,2641-2643) — i.e. **outside equity**.
- When the escrow settles it becomes pooled yield: either `_handleRewardsRedirect()` (inactive validator,
  StakeTracker.sol:3216-3230: `rewardsPayable -= A; reservedAmount -= A; earnedRevenue += A`) or the
  staking round-trip via `_handleEarnedStakingYield()` (StakeTracker.sol:3151).

Consequence (Guardian **M-09**, *Acknowledged*): a depositor who enters **while the escrow is queued** mints
shMON at a price that omits `A`; after `A` is realised as yield, that depositor owns `A·D/(E+D)` of a reward
that pre-existing holders earned. Guardian's own example: `E=1000, A=1000, D=1000 → 500 MON profit`.
`_requestUnstake()` (ShMonad.sol:338-357) has the mirror-image flaw for exiting holders (**M-19**).

**Protections that hold** (fork-verified): `cbPooledShareRate` (FLERC4626.sol:383) reverts any call that
would lower the virtual-offset share rate by more than 1 wei (`CircuitBreakerLib.isNonDecreasingRate`);
deposit uses full equity (a JIT depositor pays the higher price) while exits use the smoothed lower price —
so an *atomic* round trip always loses (test 01: 100 MON → 99.45 MON). The fork test 03 reproduces the
mispricing exactly: a 5,000 MON escrow queued by a third party leaves `totalAssets()`, `totalSupply()` and
`previewDeposit(1 MON)` **bit-identical**, and after the escrow is realised the JIT depositor's shares are
worth 5,000.0749 MON (profit 0.0749 MON = `D·A/E`).

## 4. Live-state assessment (all read at block 115,800,000; JSON in `analysis/live-state-115800000.json`)

| Item | Value (MON) | USD | Note |
|---|---|---|---|
| `totalAssets()` | 333,801,143.43 | 7,261,182 | equity (ERC-4626 "totalAssets") |
| `totalSupply()` | 203,383,957.22 shMON | — | share rate 1.6412 MON/shMON |
| `getWorkingCapital().stakedAmount` | 346,580,286.61 | 7,539,498 | staked + pending |
| `native balance` | 9,269,249.25 | 201,635 | liquid MON |
| `globalLiabilities().rewardsPayable` | 11,298.63 | 245.8 | **the JIT-dilution pool** (peak ~10,255 in sample) |
| `globalLiabilities().redemptionsPayable` | 4,593,274.18 | 99,900 | user withdrawals owed |
| `globalLiabilities().totalZeroYieldPayable` | 17,439,408.63 | 379,357 | zero-yield tranche + owner commission (`unclaimedOwnerCommission` 3,004,122 MON) |
| `getAtomicCapital()` | allocated 6,663,485.28 / distributed 3,603,680.76 | — | atomic instant-exit liquidity ≈ 3.06M MON ($66.6k) |
| `getGlobalStatus(0)` | `frozen=false, closed=false` | — | live |
| `getAdminValues()` | epoch 1583 · targetLiq 200 bps · stakingComm 500 bps · boostComm 5000 bps | — | boost commission is 50% |
| active validators | 136 | — | `listActiveValidators()` |

Fee curve: `r(u) = 0.05% + 1.00%·u` (`yInterceptRay` 5e22, `slopeRateRay` 1e25 RAY); live `getCurrentUnstakeFeeRateRay` ≈ 0.53–0.58%.

## 5. What an attacker can / cannot do

**Cannot:** steal another holder's shMON/MON; drain the atomic pool; force a share-rate decrease
(circuit breaker); mint shares for free (test 04); round-trip the zero-yield tranche for a gain (test 05);
call any owner/authority function (test 06); reach a victim's uncommitted balance through the policy-agent
role (test 07); atomically extract more than the ~$66.6k instant-exit liquidity.

**Can (bounded, non-material):** deposit while reward escrow is queued and later capture `D·A/E` of it
(test 03) — requires (a) timing the escrow window, (b) locking `D` across the settlement and the
`MONAD_EPOCH_LENGTH = 50,000`-block (~5.5 h) smoothing window, (c) a non-trivial `A`. Also
`createPolicy(escrowDuration)` is permissionless and `commit(policyID, recipient, shares)` lets a caller
park their *own* shares under an arbitrary recipient — a social-engineering / policy-trust surface, not a
drain (test 07).

## 6. PoC / fork-verification

- `poc/` — Foundry project (`foundry.toml` pins `eth_rpc_url` to the keyless public Monad RPC, `via_ir = true`).
- `poc/test/ShMonad.t.sol` — **8/8 PASS** on a fork of Monad block 115,800,000:

  | test | what it proves |
  |---|---|
  | `test_00_live_state` | not frozen/closed; equity/supply/liability reads |
  | `test_01_deposit_redeem_roundtrip_is_lossy` | atomic round trip loses (100 → 99.4536 MON) |
  | `test_02_queued_escrow_invisible_to_deposit_price` | 1,000 MON escrow leaves `totalAssets`, `totalSupply`, `previewDeposit` bit-identical |
  | `test_03_jit_capture_on_escrow_settlement` | escrow realised → JIT depositor profits `D·A/E` (0.0749 MON on D=5,000, A=5,000); same-block exit quote is still smoothed |
  | `test_04_mint_requires_fair_value` | `mint` costs > 1 MON per shMON; mint→redeem lossy |
  | `test_05_zero_yield_tranche_roundtrip_is_lossy` | $379k zero-yield tranche cannot be round-tripped |
  | `test_06_privileged_surface_is_gated` | `setFrozenStatus`/`setClosedStatus`/`addValidator`/`upgradeCoinbaseBeaconImplementation` revert for a fresh EOA |
  | `test_07_policy_agent_cannot_take_victim_funds` | agent cannot over-draw a victim's committed bucket; victim balance untouched |

- CI: `bash /home/heisenberg/CA/ci/ci-run.sh shmonad` → `ci-log.txt`, `ci-artifacts/`, run URL in `summary.json`.
  `ci/run.sh` re-reads live state keylessly (`analysis/live_check.py` → `ci-out/live-state.json`) and runs a
  secret scan.

**Tooling limits (precise):** the Monad public RPC keeps only recent state — the deploy block 108,665,496
returns *"Block requested not found"*, so historical state at the audit/deploy commit could not be read
live (the impl source was obtained from the explorer's verified source). The Monad staking **precompile**
is not present in an anvil fork, so `crank()`, `_crankValidator` and the reward-settlement/redirect paths
**cannot be executed** on a fork; `test_03` therefore reaches the post-settlement state by writing the
`CurrentLiabilities`/`WorkingCapital` slots (located by scanning for the packed struct values, so the demo
is layout-independent) rather than by driving `crank()`. This is the main confidence limitation.

## 7. Verdict & residual risk

**E-U $0** (medium confidence). The deployed v1.2 implementation is *more* guarded than the audited
snapshot: it adds the `cbPooledShareRate` circuit breaker on every value path and ships fixes for all four
published Highs and the MR1 JIT-fee findings. The only live unprivileged mispricing is the acknowledged
escrow-underpricing (M-09/M-01-RR4/M-19), whose live pool is **$7–$223**.

**Residual / latent (monitor, do not re-hunt unless state changes):**
- **M-09 / M-01-RR4** — re-arms if `rewardsPayable` or in-flight priority rewards grow large relative to
  equity. Watch `globalLiabilities().rewardsPayable` (currently ~$250).
- **M-22** (*Acknowledged*, MR2) — the redemption-dust rule is checked on the aggregate queue, not per
  validator, so a matured `completeUnstake()` can transiently stall. Availability (H-O delay), not theft;
  not attacker-controllable at will.
- **M-08** (*Acknowledged*, MR2) — coinbase-spoofing redirect of validator rewards needs a legacy
  custom-coinbase **and** the owner to run the migration → P-assisted.
- **Owner key** — `owner()` is a single EOA holding freeze/close/upgrade/param rights over the full
  $7.26M; `getCodeUpgradeAuthority()` is a separate address (a partial mitigation).

## 8. Methodology & sources

1. Pulled the deployed `TransparentUpgradeableProxy` + `ShMonad` implementation source from the Monad
   explorer (Etherscan V2, chain 143) and reconstructed the v1.2 tree (`analysis/src/`, 60 files).
2. Read the LST mint/redeem/share math (`FLERC4626.sol`, `AccountingLib.sol`, `CircuitBreakerLib.sol`,
   `FeeLib.sol`, `AtomicUnstakePool.sol`), the policy/agent surface (`Policies.sol`, `Holds.sol`) and the
   validator/coinbase accounting (`StakeTracker.sol`, `CoinbaseUpgradeable.sol`).
3. Diffed the deployed impl against the **previous** impl (`0x856a4019228c265dee336df705277607c4a18e1b`,
   v1.1) to see what the v1.2 upgrade changed, and against the published **Guardian "ShMonad Updates"**
   review (2026-08-21, 118 findings) to check each finding against the *deployed* code
   (`analysis/guardian-shmonad-findings.md`).
4. Read live state keylessly at explicit blocks; enumerated the external surface and auth modifiers.
5. Fork-tested the candidate paths (8 tests) — including the mispricing proof and three negative results.

**Caveats:** (i) the precompile-dependent crank/settlement paths could not be executed on a fork (§6);
(i-bis) the deployed implementation source was taken from the explorer's **verified metadata** (solc 0.8.30,
cancun, optimizer 200); a full re-compilation/bytecode-match was not performed, but the deployed bytecode
`0x8Ee4FF5F…` (120,874 bytes) contains the v1.2-only selectors `0x485cc955` (`initialize(address,address)`),
`0x93f8bff5`, `0xcfd4ad73`, `0xda243e6f`, `0x6b1bdb96`, consistent with the analysed source;
(ii) the E-U-conditional figure depends on an escrow spike that has not been observed above ~$223 in a
30-block sample; (iii) point-in-time reads 2026-10-23 at block 115,800,000 / latest 115,899,665 — re-read
before acting; (iv) MON priced at $0.0217534 (DefiLlama `coingecko:monad`).

## 9. Files

```
shmonad/
├── README.md                                   # this file
├── summary.json                                # machine-readable summary
├── analysis/
│   ├── src/                                    # deployed ShMonad v1.2 source (60 files, from explorer)
│   ├── prev_src/                               # previous impl (v1.1) source, for the diff
│   ├── guardian-shmonad-findings.md            # audit cross-check (fixed vs present)
│   ├── live-state-115800000.json               # pinned fork-block state snapshot
│   ├── live_check.py                           # keyless live re-read (CI)
│   └── live_state.sh                           # ad-hoc cast reads
├── poc/                                        # Foundry project (8/8 PASS)
│   ├── foundry.toml  src/IShMonad.sol  test/ShMonad.t.sol  lib/forge-std
├── ci/run.sh                                   # CI: live re-read + secret scan
├── ci-out/                                     # CI artifacts
├── ci-log.txt · ci-artifacts/                  # downloaded by the CI helper
```
