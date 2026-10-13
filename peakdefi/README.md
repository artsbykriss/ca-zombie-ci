# PEAKDEFI (Ethereum + BNB Chain) — L2 Phase-2 deep dive

**Date:** 2026-10-13 · **Chains:** Ethereum mainnet, BNB Chain · **Status:** read-only; PoC fork-verified only; no mainnet transactions

**Question:** how much can an external, unprivileged attacker extract live from PEAKDEFI right now
(no keys, roles, whitelists, or legacy positions — only public contracts + own capital)?

---

## 1. TL;DR

| Target | Live value (latest block) | Attacker-extractable (E-U) | Why closed / open | Latent risk |
|---|---|---|---|---|
| Global Fund `0x07cDB44f…400e4` | 51,248.64 USDC ($51,236) | **$0** | Admin/upgrade surface is a **no-op** in the live impl chain; deposits/withdrawals are NAV-priced (no arbitrage); pools need entitlement | Referral pool claimable by legacy referrers (H-O); manager pool has no claimer (S) |
| NFT Fund `0xC120C7dB…B4685` | 58,985.68 USDC ($58,971) | **$0** | Same; `isPermissioned=true` does **not** block deposits but grants no extraction | 31,280 USDC referral pool mostly claimable by one legacy referrer (H-O) |
| BSC PeakStaking `0xe9428B8a…9A009` | 156,799,455.23 PEAK ($10,400) + 1.70 USDT | **$0** | Staker-only withdrawal; **mint cap 99.999997% exhausted** → stake() (and its mint-farming referral bonus) reverts | 156.8M PEAK is owed to legacy stakers (H-O) |

**Total live value ≈ $120,609 · Total live extractable by an unprivileged attacker: $0 (high confidence).**

---

## 2. Total live extractable now

**E-U (external unprivileged): $0.00.** No permissionless function pays the caller; no re-init / proxy
takeover; no NAV or referral-farming arbitrage that nets a profit; no arbitrary-call escape; all PEAK
mint caps exhausted. Verified on a mainnet fork (9/9 tests PASS, §7).

Value remains only for **entitled parties** (H-O) or is **stranded** (S):

| Category | Amount (USD) | Detail |
|---|---|---|
| **E-U** | **$0.00** | — |
| H-O | $107,065.83 | fund share holders ($62,989.16, sell-phase withdrawals at NAV) · referral pools ($33,675.29, entitled referrers, sell-phase only) · BSC stakers ($10,401.38) |
| P | $0.00 | the admin/owner surface cannot move funds at all (no-ops, see §4.2) |
| S | $13,543.20 | Global Fund **manager commission pool** — all three REP holders have `commission == 0`; no call path pays it |

Total = $120,609.03 (USDC @ $0.999758, PEAK @ $0.000066327, DefiLlama, 2026-10-13).

---

## 3. Architecture (as found on-chain)

```
Global Fund 0x07cDB44f…  (EIP-1167 minimal proxy, 46 bytes)
  └─ DELEGATECALL → 0xa1dFf47E… (v-facade, 10,503 bytes; dispatcher + version fallbacks)
       └─ DELEGATECALL → 0x7CE70A3a… (EIP-1167 → 0xef4eF84d…)
            └─ DELEGATECALL → 0xef4eF84d… (module router)
                 ├─ deposit/withdraw → 0x80bBA403…
                 └─ nextPhase / referral → 0x2FC2528861…
NFT Fund 0xC120C7dB… — same proxy family, per-fund storage
BSC PeakStaking 0xe9428B8a… — standalone v0.5.17 contract (same code as ETH PeakStaking/PeakReward)
```

* Funds are **cycle-based managed funds** (fork of the Betoken design): `cyclePhase=true` = management
  phase (global 27 d / NFT 85 d), `false` = investor sell phase (global 3 d / NFT 5 d). Anyone may call
  `nextPhase()` once the phase expires.
* Deposits (`depositUSDC`) mint shares at NAV = `totalFundsInUSDC / share totalSupply`; withdrawals
  (`withdrawUSDC`, sell phase only) burn shares at NAV. No deposit/withdrawal fee.
* Each phase transition: dev fee = 0.1 % new shares minted to the dev account; commissions are settled
  out of investor capital into a manager pool and a referral pool (accounting only — no USDC moves).
* `owner()` / `proxyAdmin()` are EOAs (`0xEff81b47…`, `0x5D386539…`); `nextVersion()==0`; the current
  implementation chain **does not implement the admin functions** — they resolve to empty fallbacks.

---

## 4. Live-state assessment (all reads at ETH block 26,186,172 / BSC block 127,472,371, 2026-10-13)

### 4.1 Balances & accounting identity (proven in PoC test A)

| | Global Fund | NFT Fund |
|---|---|---|
| USDC balance | 51,248.642016 | 58,985.681365 |
| `totalFundsInUSDC` (investor capital) | 35,298.925965 | 27,705.453559 |
| `totalCommissionLeft` (manager pool) | 13,546.478915 | 0 |
| `peakReferralTotalCommissionLeft` | 2,403.237136 | 31,280.227706 |
| share token | `0x4D1f4532…` "PEAKDEFI Fund Shares" 84,191.674639 | `0x506ed0B6…` "NFT Share" 125,697.286174 |
| cycle / phase | 18, manage (start 2026-10-08) | 5, manage (start 2026-10-01) |
| owner / proxyAdmin | `0xEff81b47…` / `0x5D386539…` (EOAs) | `0xbC8bDC1c…` / `0x5D386539…` |

`balance == investor + managerPool + referralPool` holds exactly (global) / within 0.0001 USDC dust (NFT).
`REP` (manager control token, 377.84 supply) is held by exactly 3 EOAs; NFT REP supply = 0.

### 4.2 Attack surfaces tested — all closed

| # | Surface | Result (fork-verified) |
|---|---|---|
| 1 | `changeProxyAdmin`, `developerInitiateUpgrade`, `migrateOwnedContractsToNextVersion`, `transferAssetToNextVersion`, `changeDeveloperFeeAccount/Rate`, `listKyberToken`, `listCompoundToken`, `setProxy` | **callable but no-ops** — state unchanged after every call (empty fallback in the live impl chain). No takeover. |
| 2 | `initOwner()` / `init()` / `transferOwnership` / `renounceOwnership` | revert (gated / already initialized) |
| 3 | `nextPhase()` | permissionless, flips phase; **pays the caller nothing** (despite `NEXT_PHASE_REWARD=1e18`) |
| 4 | deposit → withdraw round trip | priced at NAV both ways; phase-transition fees make it a **net loss** (measured: 1,000 in → 978.19 out incl. remaining shares) |
| 5 | sybil referral farming (A refers B, B holds shares through a transition) | A accrues ~0.74 % of B's holding as *raw* commission, redeems 50 % in cash; B's NAV dilution exceeds it → **net −$20 on a $2k position** |
| 6 | `registerWithUSDC()` (become manager) | reverts — manager registration closed |
| 7 | manager pool claim (`redeemCommission` / `redeemCommissionForCycle`) | all 3 REP holders: `commission == 0` for **all** cycles; redemptions pay 0; pool unchanged |
| 8 | referral pool claim by a fresh address | `peakReferralCommissionBalanceOf == 0`; redeem reverts |
| 9 | referral pool claim by an **entitled** legacy referrer | works in sell phase — paid out (H-O proof): `0xB4238F7C…` received 226.60 USDC; NFT `0xafb12c7c…` received 10,690.59 USDC for cycle 1 |
| 10 | `sellLeftoverToken`, `withdrawTokenAdvanced`, `depositTokenAdvanced` with attacker-crafted calldata | revert — no arbitrary-call escape |
| 11 | `burnDeadman` | burns an inactive manager's REP; pays the caller nothing |
| 12 | BSC `stake()` mint-farming (referral bonus mints 3 %+10 % of interest immediately) | **closed**: `mintedPeakTokens = 274,999,999.999` vs cap 275,000,000 → headroom 0.000809 PEAK; any ≥1 PEAK stake reverts ("reached cap") |
| 13 | BSC staked PEAK | `withdraw(stakeIdx)` is staker-only; no admin/withdraw-all function; stakes are locked until maturity |

### 4.3 Roles / authority

* `owner()` (both funds) and `proxyAdmin()` are EOAs; the live implementation ignores their authority for
  fund movement (admin entry points are no-ops). No privileged path to the USDC was found either.
* PEAK token `mint()` requires `MINTER_ROLE` (held by staking/reward contracts); `burnFrom` requires
  `DEFAULT_ADMIN_ROLE`; public `burn()` only burns the caller's own tokens. All four mint caps are
  ≥99.4 % exhausted (staking BSC 99.999997 %, staking ETH 99.999998 %, rewards BSC 99.41 %, rewards ETH 99.85 %).

---

## 5. What an attacker can / cannot do (exact call paths)

**Cannot:**
* Move fund USDC: every candidate path is either gated (`onlyOwner`-style requires that revert) or a
  silent no-op (admin selectors resolve to an empty fallback in `0xef4eF84d`'s dispatch).
* Profit from share round-trips: `depositUSDC(amount, ref)` mints `amount·1e18/NAV` shares; `withdrawUSDC`
  burns at the same NAV; the phase transition only subtracts fees (dev 0.1 % shares + commission
  settlement), so a round trip is a guaranteed small loss.
* Claim pools without entitlement: `peakReferralRedeemCommission()` pays `msg.sender`'s accrued balance
  only (0 for fresh addresses); `redeemCommission()` pays `msg.sender`'s manager balance (0 for everyone).
* Farm referral commissions: only legacy referrers with accrued balances can claim; sybil farming is
  net-negative because the commission is charged pro-rata to all holders including the attacker's downline.
* Mint PEAK: all caps exhausted; `stake()` reverts before minting.
* Use arbitrary calldata: `*Advanced`/`sellLeftover*` paths revert.

**Can (harmless / H-O for others):**
* `nextPhase()` — advance a stalled cycle (caller gets nothing).
* `depositUSDC()` — buy shares at NAV (a cost, not a gain).
* `withdrawUSDC()` during the sell phase — sell own shares at NAV.

---

## 6. Verdict

**E-U = $0.00, high confidence.** The two funds' $110,234 USDC and the BSC staking pool are reachable
only by entitled parties (share holders / referrers / stakers), and $13,543 of manager commissions has
no claim path at all. Nothing was left un-tested that an unprivileged attacker could call for profit.

**Residual / latent risk**
1. **Stranded manager pool** ($13,543): if the team ever deploys a v33 implementation and re-points the
   proxy chain (currently impossible via the exposed surface), the pool could be migrated. Monitor.
2. **Referral pools are first-come-first-served and under-collateralised**: global pool $2,403 vs
   $15,613 of accrued raw balances; NFT pool $31,280 vs ~$26,194 identified. Early claimers win; late
   claimers may find the pool empty. NFT residual (~$12.4k) has no identified entitled claimer.
3. **PEAK exit liquidity is ~$4k** (PancakeSwap PEAK/WBNB + PEAK/BUSD), so the $10.4k of staked PEAK is
   not realisable at mark even by its owners.
4. Anyone can wake the funds with `nextPhase()`; after that, sell-phase withdrawals/claims open. No
   attacker profit, but the state will drift.

**Blockers/frozen paths:** withdrawals and pool claims are sell-phase-only (next global sell window
opens when someone calls `nextPhase()` after 2026-11-04); manager registration is closed; all mint caps
exhausted.

---

## 7. PoC / fork verification

`poc/` — Foundry project (forge-std vendored). **9/9 tests PASS** (local run + CI, see `ci-out/`).

| Test | Claim proven |
|---|---|
| `test_A_live_state_accounting_identity` | balance = investor + manager + referral pools (both funds) |
| `test_B_admin_surface_noop_and_gated` | all admin/upgrade calls leave state unchanged; init/ownership gated |
| `test_C_fresh_attacker_cannot_claim_pools` | fresh address: 0 balances, redemptions revert |
| `test_D_nextPhase_permissionless_and_entitled_claim` | nextPhase callable by anyone, pays caller 0; entitled referrer paid 226.60 USDC |
| `test_E_manager_pool_unclaimable` | manager commission 0; redeem pays 0; pool unchanged |
| `test_F_deposit_withdraw_not_profitable` | 1,000 USDC deposit → 978.19 USDC total return (loss) |
| `test_G_nft_fund_permissionless_deposit` | NFT fund accepts deposits despite `isPermissioned=true` |
| `test_H_bsc_mint_cap_exhausted_closes_staking` | headroom 0.000809 PEAK < interest of a 1 PEAK/10 d stake |
| `test_I_bsc_fresh_stake_reverts` | fresh address staking 1 PEAK reverts |

CI: `bash ci/ci-run.sh peakdefi` → **`artsbykriss/ca-zombie-ci`** run URL: see `ci-log.txt` / §Files.

Fork blocks: ETH 26,186,139–26,186,147 (CI may use newer), BSC ~127,472,000. All tests fork from public
RPCs (`FORK_RPC_URL` / `BSC_RPC_URL`); no transactions on real networks.

---

## 8. Methodology & sources

* **Ground truth:** direct `eth_call` reads on public RPCs at pinned blocks; `debug_traceCall`
  (drpc) for the delegatecall chain; anvil fork for state-mutating simulations; Etherscan V2 for verified
  source (PeakStaking/PeakReward/PEAK token/oracle) and tx history; GoldRush for holder lists; 4byte +
  heimdall decompilation of the unverified fund implementation `0xa1dFf47E…`; the verified
  `IPeakDeFiFund` interface recovered from the `ProtectionStaking` source (`0xead98f44`, public repos).
* **Cross-checks:** DefiLlama TVL ($110,200) matches the fund balances; corpus triage ($119,787) matches
  to 0.7 %. The triage's CI probe bug (USDC priced with 18 decimals → "$0") was identified and corrected.
* **Negative results recorded:** `sellLeftoverToken`/`*Advanced` arbitrary calldata revert; `burnDeadman`
  pays nothing; `baseRiskStakeFallback` is a 0-returning view; `rankUp` mints to the user, not the caller.
* Corpus note: `zombie_hunt/FINDINGS.md` lists PEAKDEFI as "deadUrl" — on-chain reality is two live funds
  with $110k USDC and a live staking contract; the website/API being dead does not imply drained custody.

**Caveats:** (1) The fund implementation is unverified; behaviour was established by tracing + fork
simulation of every tested path, not by reading source. (2) The manager-pool commission formula is opaque;
"no claim path" is based on exhaustive testing of every redemption entry point with all 3 REP holders.
(3) H-O amounts assume the entitled parties still control their keys. (4) PEAK valuation uses market price;
realisable value is bounded by ~$4k of DEX liquidity.

**Files**
```
peakdefi/
├── README.md                     # this report
├── summary.json                  # machine-readable summary
├── analysis/                     # state-dump.json, decompiled impls, sources, selectors, docs, txlists
├── poc/                          # Foundry project (src/IPeakDefi.sol, test/PeakDefi.t.sol, test/PeakDefiBsc.t.sol)
├── ci-out/local-forge-test.log   # local 9/9 PASS log
├── ci-log.txt / ci-artifacts/    # CI run (artsbykriss/ca-zombie-ci)
```
