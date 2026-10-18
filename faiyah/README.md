# ZH4-05 · Faiyah Staking (Xphere) — commingled principal, unfunded rewards, first-mover race

**Date:** 2026-10-18 · **Chain:** Xphere mainnet, chainId **20250217** · **Status:** read-only; fork-verified only; **no mainnet transactions**
**Target:** factory proxy [`0x95c8853e6bD1DBCE2428Aa6953eb7680261F22fe`](https://xpherescan.io/address/0x95c8853e6bD1DBCE2428Aa6953eb7680261F22fe) → impl `0xb4f7dea2fc421f0e0088ce1e99aa0a802c5628f3` (UUPS, AccessManager `0x09f716B0d2d3AD90Ad47b04481508573b6cd847c`)
**Pool template:** gen-2 `0x18Bb3E727210bda426E34ca0F5ac18d573f3BeDE` (EIP-1967 proxies owned by the factory) · **Token:** XEF `0x80252c2d06bbd85699c555fc3633d5b8ee67c9ad` @ **$0.00452386** (DefiLlama, ts 1792281184)
**Latest state:** block **51,464,337** (ts 1,792,282,865, 2026-10-18 00:07 UTC) for claimable; block **51,464,301** for the all-pool scan; block **51,464,314** for the math verification. CI blocks cited inline.

> **Bottom line.** The reward index is exact and there is **no over-credit**: 13/13 recent settlements and 25/25 live views are wei-exact to `floor(amount·apr·elapsed / (10⁴·31,536,000))`. What is broken is the *funding*: every same-token pool has one commingled balance `balance = totalStaked + totalReward − rewardDebtTotal`, and the payout guard is only `payout ≤ current balance` (`NotEnoughReward`, selector `0xc9d2c178`) — **not** `payout ≤ balance − totalStaked` and **not** `payout ≤ funded reward bucket`. Earlier claimants are paid their entitled rewards out of other stakers' principal; the last movers revert. **E-U = $0. H-O first-mover = $354.06 available today + a $476,602.48 unfunded pot at the 2027 unlock** (current accrued snapshot $148,366.91; the 1-year claim lock means it grows to the full-year cap, ≈$478,768.27 one-time). The fresh-attacker path (stake → claim → unstake in #42) pays only the advertised 5%/yr, locks principal for 180 days into an already-underfunded pool, and is negative-EV / principal-at-risk — not an extraction.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why | Latent / H-O |
|---|---|---|---|
| Faiyah factory + 46 pools | **$0 E-U** | No over-credit, no double-claim, no on-behalf claim, no free stake, no admin path. Reward math wei-exact 13/13 + 25/25. | — |
| Pool **#41** `0xca3a…ccd9` (XEF 2%) | $0 beyond entitlement | 12.8M XEF staked; balance **28,264.65 XEF below** `totalStaked`; funded bucket 0; claims succeed while insolvent and deepen the hole. | **$332.26** of accrued rewards claimable now (12,424 stakes); total shortfall ≈ $460.13 (already-paid + pending). |
| Pool **#42** `0x895b…af4e` (XEF 5%, open) | $0 beyond entitlement | balance below principal by **116.05 XEF** after a 650 XEF donation; accrued claims exceed the buffer. | **$21.80** claimable now; fresh staker is structurally late (180-day lock). |
| Pools **#33/#37/#44/#45** (XEF 10%, locked to 2027) | $0 today | 1.055B XEF principal, **32.995M XEF accrued today → 105.553M XEF at the 2027 unlock** (1-year `interestTime` cap = 10%/stake), balances = principal + only a 200k XEF buffer on #33. | **$476,602.48** net unfunded at unlock (current accrued snapshot $148,366.91); **≈$478,768.27** is the one-time accrual to the 2027 unlock (pools ended, no new stakes), not a perpetual rate. |
| Pool **#21** (RWA4 10%, open) | unpriced | 42M RWA4 principal, 1M RWA4 buffer, 1.943M RWA4 accrued today → 4.2M at the 2027-05-02 unlock; no observable USD price. | H-O in RWA4 terms; excluded from USD headline. |
| Pool **#9/#32/#10** (deployer-owned) | **$0 E-U** | #9: claim 31,451 USDT vs 1,299.58 held → both claim and unstake revert `NotEnoughReward` (live endgame). #32: first claim succeeds, second stake's claim/unstake revert. #10: 5 ETH with zero stakes. | **S ≈ $13,638** (#10 5 ETH + #9 1,299.58 USDT + #32 353.10 USDC residual; #32's owner can extract 202.89 USDC through stake 1 first): the `ownerPool` EOAs **cannot** call `emergencyWithdraw*` (tested: `OwnableUnauthorizedAccount(ownerPool)`); the pool `owner()` is the factory and `cancelPool` is governance-gated / `InvalidPoolStatus` on live pools. Recoverable only by a governance UUPS upgrade. |

**Total live E-U: $0.00 (high confidence).**
**Total H-O first-mover: ≈$476,956.54 (claimable now + unfunded 2027 pot at unlock; excludes unpriced RWA4).**
**Latent 2027 accrual: ≈$478,768.27 one-time** to the unlocks, essentially all unfunded.

---

## 2. The mechanism, exactly

### 2.1 One balance, two liabilities

For a same-token pool (`stakingToken == rewardToken`, e.g. XEF/XEF):

```
accrued(id,t)  = floor( amount(id) · apr · (t − stime(id) − interestDelay) / (10⁴ · 31,536,000) )
claimable(id,t)= max(0, accrued(id,t) − claimed(id))          // floor on the TOTAL, then subtract paid
claim          → transfer claimable to stake.owner; claimed += paid; rewardDebtTotal += paid
unstake        → transfer (claimable + principal) in ONE transfer; mark stake settled (w4 = t)
```

The pool keeps **one** token balance. Its accounting identity, verified live on every funded pool, is:

```
balance = totalStaked + totalReward − rewardDebtTotal + directDonations
```

`totalReward` is the cumulative funded-reward bucket; `rewardDebtTotal` is the cumulative rewards already paid.
The *funded* bucket is `totalReward − rewardDebtTotal`; the *deficit* is its negative. `directDonations`
is 0 on #41/#9/#32, 650 XEF on #42, 200,000 XEF on #33 and 1,000,000 RWA4 on #21 (token transfers that did
not go through `depositReward`).

### 2.2 The only payout guard is the vault's current balance

The deployed code does **not** reserve principal. The claim/unstake path reads the token balance and reverts
with `NotEnoughReward()` (`0xc9d2c178`) only if the requested payout exceeds the **current** balance:

* **Live proof that principal is not reserved:** pool #41 was already **28,241.56 XEF below `totalStaked`** when
  a 57.56 XEF claim succeeded (wave-2 fork; this run re-proves it at 58.29 XEF with a 28,264.65 XEF deficit).
  The claim increases `rewardDebtTotal` by the same amount and decreases the balance — the hole deepens exactly.
* **Live proof that the guard is `payout ≤ balance`:** pool #9 has one stake with 31,451.27 USDT accrued and a
  1,299.58 USDT balance. `claimReward` and `unstake` (which pays principal + reward in one transfer) both revert
  `NotEnoughReward` — the stake is unclaimable and the principal cannot be withdrawn.
* **No cap vs `totalReward`:** on #41 the funded bucket is 0, yet claims are paid. The only thing that stops a
  claim is running out of the commingled balance.

### 2.3 Consequence

Every payout is *entitled* (the math is exact), but it is not *funded*. The pool is a first-come-first-served
queue against one balance:

```
sum of all liabilities = totalStaked + accrued_pending
balance                = totalStaked + totalReward − rewardDebtTotal
shortfall              = accrued_pending + rewardDebtTotal − totalReward
```

Earlier claimants take their full entitlement; the last claimants find the balance below their payout and revert.
This is the H-O first-mover race, not an over-credit bug.

---

## 3. Live state (block 51,464,337, ts 1,792,282,865)

All reads are raw `eth_call` at a pinned block; token amounts are decimal-adjusted; USD at XEF $0.00452386,
USDT $0.999144, USDC $0.999806.

| Pool | Token / APR | `totalStaked` | `balance` | `rewardDebtTotal` | funded bucket | realized deficit | pending claimable | locked accrued |
|---|---|---|---|---|---|---|---|---|
| **#41** `0xca3a…ccd9` | XEF 2% (ended 2026-10-03) | 12,800,038.839 | 12,771,774.190 | 28,264.649 | **0** | **−28,264.65 XEF ($127.87)** | **73,447.01 XEF ($332.26)** | 0 |
| **#42** `0x895b…af4e` | XEF 5% (ends 2027-01-03) | 454,981.427 | 454,865.381 | 766.046 | 0 (650 donation) | **−116.05 XEF ($0.52)** | **4,818.45 XEF ($21.80)** | 0 |
| **#33** `0xc9ee…e989` | XEF 10% (ended 2026-06-29) | 680,558,784.273 | 680,758,784.273 | 0 | +200,000 buffer | 0 | 0 (locked) | **23,307,680.79 XEF ($105,434)** |
| **#37** `0x5287…02b9` | XEF 10% (ended 2026-07-31) | 316,296,461.520 | 316,296,461.520 | 0 | 0 | 0 | 0 (locked) | **8,661,139.19 XEF ($39,183)** |
| **#44** `0x0a1f…0090` | XEF 10% (ended 2026-09-04) | 44,950,482.860 | 44,950,482.860 | 0 | 0 | 0 | 0 (locked) | **899,021.96 XEF ($4,067)** |
| **#45** `0x56b5…37dc` | XEF 10% (ended 2026-09-30) | 13,724,847.250 | 13,724,847.250 | 0 | 0 | 0 | 0 (locked) | **127,213.65 XEF ($575)** |
| **#21** `0x7d89…756a` | RWA4 10% (ends 2027-04-30) | 42,000,000 | 43,000,000 | 0 | +1,000,000 buffer | 0 | 0 (locked to 2027-05-02) | **1,942,939.12 RWA4** (no price) |
| **#9** `0x2a2e…64ad` | USDT 5000% (ended 2026-04-29) | 1,299.99997 | 1,299.57823 | 0.42174 | 0 | −0.42174 USDT | 31,451.27 USDT — **reverts** | 0 |
| **#32** `0x8542…1e5e` | USDC 600% (ended 2026-05-11) | 556.000 | 555.993889 | 0.006111 | 0 | −0.006111 USDC | 1,311.51 USDC > balance — **reverts**; 146.89 claimable | 0 |
| **#10** `0xffa3…bd2d` | native 0.2% (ended) | 0 | **5 ETH ($11,986.52)** | 0 | +5 ETH | 0 | 0 (no stakes) | 0 (owner-recoverable) |

**Locked columns are today's snapshot.** The four 2027 pools' "locked accrued" values (23.31M / 8.66M / 0.90M /
0.13M XEF) are what has accrued *so far*. Claims are blocked until `stime + 365d`, and `interestTime = 1yr`
caps the accrual exactly at the unlock date, so each stake will owe 10% of principal then: **105,553,057.59 XEF
total (3.2× the snapshot)**. #21 RWA4 similarly grows from 1.943M to 4.2M RWA4 at its 2027-05-02 unlock.

**Identity check:** `balance + rewardDebtTotal == totalStaked + totalReward + donation` on every pool above
(`idDelta` = 0 for #41/#9/#32, +650e18 for #42, +200,000e18 for #33, +1,000,000e18 for #21 — direct token
transfers, not `totalReward`).
**Pool count:** 46 (`idCounter = 46`), all enumerated; 30 pools carry a non-zero balance/funding (most are tiny test pools), the material ones are below.

**Realized loss already taken from principal:** #41 28,264.65 XEF + #42 116.05 XEF = **$128.39**
(third-party pools). The #9/#32 deficits are the deployer's own test stakes.

**Locked 2027 pot — current vs at-unlock.** Today's accrued liability is **32,995,055.59 XEF** ($149,271.68
gross; $148,366.91 net of #33's 200,000 buffer). It is **not claimable today**: `claimReward` and `unstake`
revert `InvalidTimeRange` (0x536a71af) until `stime + 365d` (verified for #33/#21 stakes by `eth_call`).
Because `interestTime = 31,536,000`, accrual caps at exactly one year, and every stake's 1-year unlock is
`stime + 365d`; at that moment each stake has accrued the full **10%** (`apr = 1000`). Therefore the
**at-unlock liability is 105,553,057.59 XEF = $477,507.25 gross / $476,602.48 net** of the 200k buffer —
3.2× today's snapshot. The cap is not an assumption: pools #12/#14 (`interestTime = 86,400`) settled at the
capped formula wei-exact (0.136986301369863 XEF for #12 stake 0, 136.986301369863 for #14), not the uncapped
0.954/932.9 values.
**First unlock dates:** #33 2027-05-29, #37 2027-06-30, #44 2027-08-04, #45 2027-09-08
(`min(stime) + claimDelay`, 365 days). At that point `claimable = accrued − claimed` and the balance is
principal + only the #33 buffer, so the first claims are paid from principal and the tail reverts.
**Accrual:** 10%/yr on 1,055,530,575 XEF + 2%/5% on #41/#42 = **105.83M XEF/yr ≈ $478,768/yr**;
of that, ~105.55M XEF (~$477.4k) is on the four locked pools with zero/200k funding — a one-time accrual to their 2027 unlocks on existing stakes (the pools are ended, so no new stakes), not a perpetual rate contingent on deposits.

**RWA4 (#21):** 1,942,939.12 RWA4 accrued, 1,000,000 buffer, 4.2M RWA4/yr accrual; no observable USD price
(Tamsa price 0, DefiLlama has no `xp:` feed). Excluded from USD totals; it is the same H-O structure in kind.

---

## 4. What an attacker can and cannot do

### 4.1 E-U — all falsified on the fork / by `eth_call`

| Candidate path | Result | Evidence |
|---|---|---|
| Over-credit / rounding / index manipulation | **No.** 13/13 live settlements and 25/25 views wei-exact | `analysis/verify_math.json`; §5 |
| Double-claim / re-claim after checkpoint | **No.** second claim returns `(true,0)` / pays 0 | fork test `test_fresh_attacker_42_no_overcredit` |
| Claim someone else's stake | **No.** `NotAuthorized()` `0xea8e4eb5` | fork `test_cannot_touch_other_stakes` |
| Unstake someone else's stake | **No.** `NotAuthorized()` | same |
| Free stake / minted credit | **No.** `TransferFromFailed()` `0x7939f424` with 0 balance | fork `test_no_free_stake` |
| Stake after `endTime` | **No.** `InvalidTimeRange()` `0x536a71af` | fork `test_cannot_stake_in_ended_pool_41` |
| Claim an amount greater than entitlement | **No.** payout is exactly `accrued − claimed` | 13/13 + 25/25 |
| Claim when `claimable > balance` | **Reverts** `NotEnoughReward`; no partial payout | live #9; fork |
| Unstake when `principal + claimable > balance` | **Reverts** `NotEnoughReward` | live #9; fork #32 stake 2 |
| Pool admin (`emergencyClose`, `emergencyWithdraw*`) | **No.** `OwnableUnauthorizedAccount(address)` `0x118cdaa7` | fork `test_pool_admin_gates` |
| Factory admin (`setPoolImplementation`, `upgradePool`, `cancelPool`, `upgradeToAndCall`) | **No.** `NotAuthorized()` (wave-2 + this run) | wave-2 fork; re-read code paths |
| Fresh stake → claim → unstake (#42) | **No over-credit**; max +2.47% over 180 days (advertised 5%/yr), principal locked and exposed | fork `test_fresh_attacker_42_no_overcredit` |
| Reentrancy via native transfer | No value: the only native pool with balance and no stake is #10 (owner-only, 0 stakes); #2 holds 0.000000711 ETH | state scan |

### 4.2 The fresh-attacker test, in numbers

The only material pool still open for staking is **#42** (XEF 5%, ends 2027-01-03; `claimDelay` 1 day,
`unstakeDelay` 180 days, min/max = 0/0). Fork sequence:

1. Attacker is funded with 200,000 XEF from a real public holder (`0xc22A…961f`, 1.74M XEF) via impersonation.
2. `stake(#42, 10,000 XEF)` → principal moves in; `totalStaked` and pool balance each +10,000.
3. `claimableReward(newId)` = `(false, 0)`; claiming before 1 day reverts.
4. At `stime + 86,401`: `claimable` = **exactly** `floor(10,000·500·86,401 / (10⁴·31,536,000))`; the claim pays
   that exact amount, fee 0; a second claim returns 0.
5. `unstake` before `stime + 15,552,000` reverts (180-day lock).
6. At maturity: `unstake` pays principal + exact residual accrual; **net = +246.58 XEF = +2.47%**,
   which is only the advertised 5%/yr for 180 days. It is not over-credit, and it is paid from the commingled
   balance (which is already 116 XEF short and carries $21.80 of prior claims).
7. If existing stakers exit first, the attacker is the last mover and `unstake` reverts `NotEnoughReward`
   (the exact endgame is demonstrated deterministically on #32: claim stake 1 succeeds; stake 2's claim and
   unstake revert; stake 1 can still unstake).

**Verdict:** the fresh path is capital-locked, principal-at-risk, and yields only the promised APR. It is not an
unprivileged extraction; it is the same H-O queue, with the attacker structurally *behind* 17,100 existing stakes.

### 4.3 Costs

Fork gas is not representative of Xphere gas price; the path is a handful of `stake`/`claimReward`/`unstake`
calls (≈3 transactions over 180 days). No flash loan is useful: the payout is capped at the attacker's own
accrual, which is linear in principal and time; borrowing principal only increases both the yield and the
principal at risk one-for-one, and the 180-day lock makes flash capital unusable.

---

## 5. PoC / fork verification

* Fork: Xphere mainnet via `https://en-bkk.x-phere.com`, **latest block** (the public RPC is a full, non-archive
  node; pinning an old block fails with `missing trie node`). The test logs `fork block` / `fork timestamp`;
  public keyless endpoint only.
* Project: `poc/` (Foundry, solc 0.8.24, via-ir), vendored `forge-std`.
* Tests: **10/10 PASS** (CI run PENDING).
* Key assertions:
  * `test_live_deficit_identity` — identity + #41 deficit > 28k XEF + #42 below principal.
  * `test_claim_pays_from_principal` — claim of stake 1 (#41) pays 58.29 XEF while the pool is 28,264.65 XEF
    below `totalStaked`; balance −= payout, `rewardDebtTotal` += payout, deficit grows by the payout.
  * `test_pool9_claim_and_unstake_revert` — 31,451.27 USDT accrued vs 1,299.58 held; both paths revert
    `0xc9d2c178`; balance unchanged.
  * `test_pool32_first_come_first_served` — stake 1 claim succeeds; stake 2 claim and unstake revert;
    stake 1 still exits.
  * `test_fresh_attacker_42_no_overcredit` — exact day-1 accrual, exact residual, <3% 180-day gain,
    principal locked, identity holds.
  * `test_view_math_exact_41` — live view equals the floor formula at the fork timestamp.
* Off-chain verification: `analysis/verify_math.py` → `verify_math.json`: **13/13 settlements, 25/25 views
  exact**. Full enumeration: `analysis/enumerate_claims.py` → `ci-out/claims_4142.json` and
  `ci-out/claims_locked.json`.
* CI artifacts: `ci-out/` (scan, claims, verify, monitor); logs in `ci-artifacts/`.

---

## 6. Verdict, residual risk, blockers

**Verdict: E-U CLOSED ($0) / H-O OPEN (first-mover, $476,956.54) / P context (governance upgrade power) / S ≈ $13,638.**

* **E-U $0 (high confidence).** The reward index is exact (13/13 + 25/25 wei-exact), all ownership/time/transfer
  checks are present, and no pool balance can be touched by a non-staker. The fresh-stake path is negative-EV
  and cannot mint credit.
* **H-O $476,956.54 (high confidence on amounts, medium on timing).** Entitled stakers can claim
  $354.06 today from balances that are already below principal. At the 2027 unlocks, the first claimants
  can take up to **$476,602.48** of the 1.055B XEF principal (105.553M XEF of full-year rewards; today's
  accrued snapshot is 32.995M XEF = $148,366.91), leaving the tail with reverted `NotEnoughReward`.
  The exact race outcome is ordering-dependent; the *shortfall* is deterministic
  (`accrued_at_unlock + rewardDebtTotal − totalReward`).
* **P context (governance).** The factory is UUPS-upgradable through AccessManager
  `0x09f716B0d2d3AD90Ad47b04481508573b6cd847c`; each pool proxy is owned by the factory. A state-override
  `eth_call` *from the factory address* shows `emergencyWithdrawStakingToken` can move a pool's full balance,
  and governance can upgrade a pool implementation. That is generic admin custody over ~$4.84M of XEF principal
  (plus 43M RWA4), **not** an unprivileged path and not counted as E-U/H-O. No exposed function lets the
  `ownerPool` EOA do it (`OwnableUnauthorizedAccount`), and `cancelPool` returns `InvalidPoolStatus` on live pools.
* **S ≈ $13,638.** #10's 5 ETH + #9's 1,299.58 USDT + #32's residual 353.10 USDC are not reachable by any
  unprivileged user or by the `ownerPool` EOA; the only rescue is a governance UUPS upgrade. (#32's owner can
  first claim+unstake stake 1 for 202.89 USDC, leaving 353.10 stuck.) Classified stuck (S) for the current
  deployed code, with the caveat that governance can recover them by upgrading.

**Residual / latent risk**
1. **2027 cliff:** the at-unlock liability is **105.553M XEF** (10% of principal; today's accrued is 32.995M)
   between 2027-05-29 and 2027-09-08, against zero funding except 200k on #33. First movers win; the tail loses up
   to 105.353M XEF. If XEF price rises, the USD pot rises proportionally.
2. **Accrual continues past `endTime`** (observed on #41: stakes settled after the end accrued past it), so the
   2027 pot keeps growing until each stake is settled. 105.8M XEF/yr ≈ $478.8k/yr.
3. **#21 RWA4** is the same structure with 1.943M RWA4 accrued and 1M buffer; unpriced, so not in the USD total.
4. **New funding** (`depositReward`, `totalReward` increase) would reduce the deficit; monitor it. The pools have
   had no funding since the wave-2 snapshot (debt only grew by claims).
5. **Governance rescue/upgrade:** the factory (AccessManager) can upgrade pool implementations and, from the
   factory address, `emergencyWithdraw*` passes the pool's `owner()` check. The `ownerPool` EOAs cannot. This is
   P; if governance sweeps or upgrades, principal can leave the stakers. Monitor impl changes and upgrade txs.

**Blockers / what would change the verdict**
* A privileged `depositReward` of ≥ the accrued liabilities (≈$148k for the four locked pools, plus #41/#42)
  would close the H-O race; none observed.
* If the factory/pool owner upgrades the implementation to add a `balance − totalStaked` guard, E-U stays $0
  and H-O closes prospectively.
* XEF USD price is DefiLlama-implied (no deep CEX market); a 2× price move doubles the USD pot, not the token
  amounts.

---

## 7. Methodology, sources, caveats, files

**Method.** Enumerated the factory (`idCounter = 46`, `allPools(0..45)`), read every pool's implementation slot,
tokens, `totalStaked`, `totalReward`, `rewardDebtTotal`, delays, status and both token balances at pinned blocks;
reconstructed the identity and deficits; enumerated **all 41,543 stake records** on the value-bearing pools via
`claimableReward(id)` (bool = claimable now, word 2 = accrued/remaining); verified 13 recent `Unstaked` settlements
against the floor formula using the Tamsa decoded event API and on-chain `stakes(id)`; fork-tested the call paths
with impersonation (no mainnet transactions); decompiled the gen-2 pool ABI (heimdall/evmole in wave 2, ABI
re-used here).

**Sources of truth.** Xphere RPC `https://en-bkk.x-phere.com` / `https://rpc.x-phere.com` / Ankr public;
Tamsa API `https://api.tamsa.io/api/v1/address/{addr}/event-logs`; DefiLlama `coins.llama.fi` (XEF, ETH, USDT,
USDC); wave-2 evidence `zombie-hunt-iv/wave2/v13-faiyah.md` (fork runs, 19/19 view reads, blocks
50,986,479–51,337,277); this run's `ci-out/`.

**Caveats.**
* The pool implementation is **not verified** on Tamsa; the ABI/behavior was reconstructed from bytecode and
  fork execution. The `NotEnoughReward` selector `0xc9d2c178` is observed in revert data and used in the PoC.
* `claimableReward` returns `(claimableNow, accruedRemaining)`; for locked pools the first word is 0 while the
  second is the accrued amount. The 2027 pot is the sum of the second word; it is a liability, not a balance.
* XEF price is DefiLlama-implied; RWA4/EL/other tokens have no observable USD price and are excluded.
* `interestTime = 31,536,000` on the 1-year pools could cap accrual at 1 year per stake; the observed #41 accrual
  ran past `endTime`, and the 2027 pot uses the live `claimableReward` values, so any cap is already reflected.
* The #9/#32/#10 balances belong to deployer EOAs, not third-party users; they are P, not H-O. The #41/#42 pools
  are owned by `0x8739…` and hold third-party stakes.

**Files.**
```
faiyah/
├── README.md                     # this report
├── summary.json                  # machine-readable headline
├── analysis/
│   ├── rpc.py                    # read-only JSON-RPC helper (public endpoints only)
│   ├── scan_v2.py                # enumerate all 46 pools + identity/deficit
│   ├── pools_state_v2.json       # full state snapshot (block 51,464,301)
│   ├── enumerate_claims.py       # per-stake claimableReward enumeration
│   ├── claims_small.json         # #33/#37/#44/#45/#21 accrued (local run)
│   ├── verify_math.py            # 13 settlements + 25 views vs floor formula
│   ├── verify_math.json          # 13/13 + 25/25 exact
│   ├── monitor.py                # deficit/funding/new-stake monitor
│   ├── monitor_baseline.json     # baseline for diffing
│   ├── quantify.py               # consolidates ci-out -> quant.json
│   └── pool_impl_gen2_decomp.txt # ABI reconstruction (from wave 2)
├── poc/                          # Foundry fork PoC (vendored forge-std)
│   ├── foundry.toml
│   ├── src/Interfaces.sol
│   └── test/Faiyah.t.sol
├── ci/run.sh                     # heavy CI job (scan + enumerate + verify + monitor)
├── ci-out/                       # CI results (uploaded artifact)
├── ci-artifacts/                 # downloaded artifact
└── ci-log.txt                    # full CI log
```
