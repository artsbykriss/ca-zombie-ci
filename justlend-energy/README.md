# JustLend Energy Rental (MarketG1) — ZH4 Wave B1 deep-dive

**Date:** 2026-10-18 · **Chain:** TRON · **Target:** `MarketProxy TU2MJ5Veik1LRAgjeSzEdvmDYx7mefJZvd` → impl `TNoHbPuBQrVanVf9qxUsSvHdB2eDkeDAKD` (+ `STRXProxy TU3kjFuhtEo42tsCBtfYUAZxoqQ4yuSLQ5` → `STRXG2`)
**Status:** read-only; **no transaction was signed, broadcast or simulated with state change**. All calls are `triggerconstantcontract` dry-runs or view reads at explicit blocks. No keys or keyed RPC URLs in this folder.

---

## 1. TL;DR

| Question | Answer |
|---|---|
| **Live extractable by an external unprivileged attacker (E-U)** | **$0** |
| **E-U-conditional** (market-funded badDebt branch) | **$0 today** — 0 of 713 live rentals are liquidatable; `BadDebtAdded` = 0 in 7 days; `badDebtGap` = 0. Latent: a keeper can collect the 8 bp fee from the market on an *already abandoned* order whose residual deposit < fee. Upper bound = 0.008% of the rented amount; not profitable to manufacture (the renter must burn ≥ 1 day of rent first). |
| **H-O** (holder-only recoverable) | **≈ $336,861** — 1,011,168 TRX of *effective* security deposits across 713 live pairs, fully backed by the 1,378,329 TRX contract balance. |
| **P** (privileged) | The proxy is a Compound-style `AdminProxy` with **admin = single EOA `TLntW9Z59LYY5KEi9cmwk3PKjQga828ird`** (also admin of JustLend sTRX and owner of SunSwap V4). The admin can `_setPendingImplementation` → `_acceptImplementation` and upgrade the market. P-class over the whole balance ($459k), not an unprivileged path. |
| **S** (stuck) | **$0** identified. Balance (1,378,329 TRX) ≥ stored deposits (1,147,953 TRX); no frozen/blacklisted path. |
| **Contract balance** | **1,378,328.88 TRX ≈ $459,177** at block 87,210,571 (TRX $0.33314, DefiLlama 2026-10-18T07:38Z) |
| **Confidence** | **HIGH** for E-U = $0 (source read + live state + 713-pair scan + dry-run reverts). **MED** for the conditional badDebt keeper path (requires a future abandoned order). |

**The B0 figure needs correction.** The B0 row's “3.46M TRX nominal security deposits (~$1.11M)” is the sum of the **latest `RentResource` event per pair** — it counts deposits that were later returned by subsequent `ReturnResource` events. Reconstructing the latest event across **all** event types in the 7-day window gives **1,147,953 TRX of stored deposits**, and `getRentInfo` gives **1,011,168 TRX of effective (payable) deposits**. The 1.56M TRX “native” figure was the contract balance at the time; it is now **1,378,329 TRX**. Neither is extractable by an unprivileged actor.

---

## 2. The mechanism in exact terms

### 2.1 Product and contracts

JustLend’s Energy Rental market rents **energy** (and bandwidth, disabled) sourced from STRX’s staked TRX. It is a **separate product** from JustLend sTRX (ZH4 already closed sTRX at $0 E-U). The market is a proxy (`MarketProxy`) over `MarketG1`.

| Role | Address |
|---|---|
| Market proxy | `TU2MJ5Veik1LRAgjeSzEdvmDYx7mefJZvd` |
| Implementation | `TNoHbPuBQrVanVf9qxUsSvHdB2eDkeDAKD` (`MarketG1.sol`, tron_v0.8.18, opt 200) |
| STRX proxy (energy supplier) | `TU3kjFuhtEo42tsCBtfYUAZxoqQ4yuSLQ5` → `TUAV6ZSCXtF8KVvDKSeVmAbJEovTBf4HtG` (`STRXG2.sol`) |
| Energy rate model | `TXA2WjFc5f86deJcZZCdbdpkpUTKTA3VDM` (`JumpRateModel`) |
| Admin (proxy + rate model owner) | `TLntW9Z59LYY5KEi9cmwk3PKjQga828ird` (single EOA, no pending admin/impl) |

### 2.2 Accounting

Per `(renter, receiver, resourceType)` the market stores one packed `RentalInfo {uint64 amount; uint64 securityDeposit; uint128 rentIndex;}`. `amount` is the rented TRX-equivalent (the delegation size), `securityDeposit` is the renter’s TRX held by the proxy. Rent is charged by a global per-resource index:

```
rental       = amount * (globalIndex - rentIndex) / 1e18      // _updateUserRentIndex
securityDeposit -= rental                                     // if rental > deposit -> badDebt += gap
globalIndex += (now - lastUpdate) * rate / 1e18               // rate from JumpRateModel
```

At `rentResource` the market requires:

```
securityDeposit > amount * rate * (1 days + liquidateThreshold) / 1e18 + fee
fee = max(minFee, amount * feeRatio / 1e18)                    // 20 TRX, 0.008%
```

so **at creation the deposit is always strictly greater than the fee**.

`liquidate(renter, receiver, type)` (permissionless, caller ≠ renter/receiver):

1. accrues rent and charges the deposit;
2. requires `deposit <= fee + oneDayRent + threshold` (with `liquidateThreshold = 0`);
3. `_internalRepayForLiquidate` computes `dirtyRent` from `receiver.checkUnDelegateResource(amount, type)` (TRON TIP-467 precompile `0x1000011`), caps it at `deposit - fee`, undelegates, sets `amount = 0`, `deposit = 0`; if `deposit < fee`, `badDebt += fee - deposit`; else `sendBack = deposit - fee`;
4. pays `fee` to `msg.sender`, `sendBack` to the renter, books `dirtyRent` as market income.

`returnResource` (renter) and `returnResourceByReceiver` (receiver) share `_returnResource`:

* `canReturn` requires `rentals(...).amount >= amount > 0`;
* `_internalRepayForReturn` charges `dirtyRent = (dirty*restoreTime*0.75 + amount*3) * rate / 1e18`, caps it at the deposit, undelegates, and — **only if the remaining amount reaches zero — refunds the remaining deposit**. It does **not** charge the `fee`; the fee is a liquidation penalty, not a rental fee.

### 2.3 The two B0 hypotheses, tested

**H1 — return-after-liquidate double refund.** Closed. After `_internalRepayForLiquidate`, `setRental` stores `{amount: 0, deposit: 0, rentIndex: current}`. A subsequent `returnResource` hits `canReturn` → `"resource return: no enough rental resource"`; a second `liquidate` hits `_liquidateCheck` → `"liquidate: no resource to liquidate"`. Verified on **two real liquidated pairs** (see §5).

**H2 — badDebt branch pays the fee while the deposit is short.** The branch is real (code lines 888–910) but **not profitable for the actor who creates the order**. With the live parameters:

* minimum viable deposit `D = fee + oneDayRent + ε`;
* to reach `D_eff < fee`, the order must accrue **≈ 1 day of rent** (`oneDayRent = 3.73 bp` of `amount`);
* on liquidation the attacker (renter) receives 0 and the accomplice (liquidator) receives `fee = 8 bp`;
* **net = fee − D = −oneDayRent ≈ −3.73 bp**. The `badDebt` that the market books (`fee − D_eff`) does not accrue to the attacker; it is a receivable against future rent.

The only positive E-U is a **third-party keeper** liquidating an order that a *different* renter has already abandoned (`D_eff < fee`): the keeper receives `fee`, the market books `fee − D_eff`. That requires an abandoned order; it cannot be manufactured profitably because creating the order costs ≥ `oneDayRent > 0` and the attacker’s own net is negative.

---

## 3. Live-state assessment (block 87,210,571 / 87,210,442, 2026-10-18)

| Item | Value |
|---|---|
| Proxy TRX balance | **1,378,328.878039 TRX** (sun 1,378,328,878,039) = **$459,177.09** |
| Proxy TRC-20 dust | 111.0 USDT, 39.0 sTRX (not material) |
| `initialized` / energy paused / bandwidth paused | true / **false** / true |
| `minFee` | 20,000,000 sun = **20 TRX** |
| `feeRatio` | 80,000,000,000,000 = **0.008%** (8 bp) |
| `liquidateThreshold` | **0** |
| `usageChargeRatio` | 0.75 |
| `rateRampTime` / `maxRentalScaleLimit` | 21,600 s / 100% |
| `badDebt` / `badDebtCovered` / `badDebtGap` | 481,464,141 / 481,464,141 / **0 sun** (481.46 TRX fully covered) |
| `totalRent` / `rentClaimed` | 903,659,708.29 / 903,659,326.65 TRX (unclaimed 381.64 TRX) |
| `totalDelegatedOfType(1)` | 115,262,554.85 TRX |
| `totalUnfreezableOfType(1)` / `delegatableOfType(1)` | 4,884,776,248.44 / 4,823,312,141.85 TRX |
| `_rentalRate(0,1)` / `_liquidateRate(1)` / `_stableRate(1)` | 4,305,020,538 / 4,305,020,538 / 4,689,315,549 (per sun per second, 1e18) |
| `JumpRateModel` | base 4.122e9, multiplier 7.927e9, jump 3.171e11, kink 0.80 (per second, 1e18) |
| STRX `totalRentIncome` / `totalUnderlying` / exchangeRate | 903,659,326.65 TRX / 9,818,892,048.9 TRX / 1.32064 |
| STRX `market()` | `TU2MJ5Veik1LRAgjeSzEdvmDYx7mefJZvd` (confirmed) |

**Liability reconstruction.** 713 live `(renter, receiver)` pairs were reconstructed from all `RentResource`/`ReturnResource`/`Liquidate` events in the 7-day window (2026-10-11 06:10 → 2026-10-18 06:02). For every pair `getRentInfo` was read at blocks ≈87,210,2xx–87,210,6xx:

| Metric | TRX | USD @ $0.33314 |
|---|---|---|
| **Effective security deposits (payable today)** | **1,011,168.44** | **$336,861.10** |
| Stored deposits (pre-accrual, as stored on-chain) | 1,147,953.48 | $382,429.73 |
| Accrued rent since each pair’s last event (stored − effective) | 136,785.04 | $45,568.63 |
| Contract balance − stored deposits (surplus / older deposits) | 230,375.40 | $76,747.36 |
| **Liquidatable pairs** | **0 / 713** | — |

The balance **covers** all stored deposits and the accrued rent; the market is solvent on the 7-day window. (Older-than-7-day deposits, if any, are bounded by the 230k TRX surplus. A rental’s deposit is consumed by rent in ≈3 days at the current rate; a 7-day-old pair with a normal deposit has zero effective deposit.)

**Activity (7 days):**

| Event | Count | Value |
|---|---|---|
| `RentResource` | 9,782 | 31,148,001 TRX of deposits added (high turnover; 303 are amount-0 top-ups) |
| `ReturnResource` | 5,253 | — |
| `Liquidate` | **106** | amount 32,134,185 TRX; **fees 3,776.74 TRX**; sendBack 11,889.18 TRX; dirtyRent 2,958.62 TRX |
| `BadDebtAdded` | **0** | — |
| `RentClaimed` | 352 | 4,203,461.82 TRX paid to STRX |

**Every one of the 106 liquidations had `sendBack > 0`**, i.e. the renter’s deposit covered the fee; the badDebt branch did **not** trigger. Two addresses performed 98/106 liquidations (`0x59155f50…`, `0x2ef4f6c1…`); `0x2ef4f6c1…` is also the #1 renter by volume — professional energy resellers maintaining the market. The largest pairs churn every ~25 minutes (404 events/week for one pair).

---

## 4. What an attacker can / cannot do

**Cannot:**

* **Double-refund after liquidation** — `rentals.amount = 0`; both entry points revert (§5).
* **Recover more than the deposit** — `sendBack` is computed from `securityDeposit` after `dirtyRent`; `_doTransferOut` pays only `sendBack`/`fee`; there is no path that increases `securityDeposit` other than `msg.value`.
* **Get free energy** — `checkUnDelegateResource` returns the used (dirty) share and the restore time; the return dry-run charged **157.36 TRX** of dirty rent on a 1,042,980 TRX rental (sendBack 1,027.83 < effective deposit 1,185.19).
* **Force liquidations by spiking the rate** — `_liquidateRate = min(stableRate, currentRate)`. To raise the stable rate the attacker must hold a huge rental for the 6 h ramp; at 100% utilization the rate is 7.4e-8/s and 6 h on 4.8B TRX costs ≈7.7M TRX, far above the entire 9,221 TRX fee pool.
* **Drain the balance via the badDebt branch by self-dealing** — net is `−oneDayRent` per cycle (see §5 numbers); the market’s loss is a receivable, not a payment to the renter.

**Can (but it is not protocol-funded E-U):**

* Act as a **keeper** and liquidate a liquidatable order; collect `fee = max(20 TRX, 0.008% × amount)`. This is a transfer from the renter’s deposit. Today there are **0** liquidatable orders. The entire current fee pool at `totalDelegated = 115.26M TRX` is ≈**9,221 TRX (~$3,072)** if every order were liquidated — and the deposits cover it, so it is renter-funded.
* On an **abandoned** order with `effectiveDeposit < fee`, collect `fee` from the market (badDebt). **0 such orders today**; `BadDebtAdded = 0` in 7 days.

**P-class:** the admin EOA can upgrade the proxy and move the balance. That is a key-compromise scenario, not an unprivileged path; it is reported as a caveat, not counted in E-U.

---

## 5. PoC / dry-run verification

TRON is **not EVM-forkable with Foundry**, so the PoC is a pair of read-only methods, both executed in CI:

1. **Live `triggerconstantcontract` dry-runs** against the deployed proxy (no broadcast, no signature) at the latest block, and
2. an **exact arithmetic replay** of the verified `_internalRepayForLiquidate` / `_internalRepayForReturn` formulas with the live parameters (shadow ledger).

Files: `poc/poc.py`, `poc/tronlib.py`, inputs in `poc/inputs/`, results in `poc/results/poc_results.json`.

| Test | Result |
|---|---|
| **T1 double refund** — 2 real liquidated pairs (`TPTUXrhU…/TUVJ8bMZ…`, `TCVRMRpk…/TCVRMRpk…`) | `returnResource` reverts `"resource return: no enough rental resource"`; `liquidate` reverts `"liquidate: no resource to liquidate"`. **2/2 PASS** (a third pair re-rented after liquidation and is excluded). |
| **T2 dirty rent** — live pair `TPWZPDjW…/TS93Z2vg…`, amount 1,042,980.044 TRX | full-return dry-run: `sendBack = 1,027.828748 TRX`, `usageRental = 157.363156 TRX`; `effectiveDeposit − sendBack = 157.363156 TRX` exactly. **PASS** — energy use is charged. |
| **T3 fresh self-liquidation** — min deposit `fee + oneDayRent + 1 sun`; liquidate after 1 block / after 1.2 days | 1-block net ≈ **−0.000012 TRX** (rounding only); 1.2-day net = **−oneDayRent** (−0.371954 TRX per 1,000 TRX; −371.95 TRX per 1M TRX). Market badDebt in the 1.2-day case = 74.39 TRX per 1M order, but the attacker’s net stays negative. **PASS (no positive net)**. |
| **T4 live scan** — 713 pairs, `getRentInfo` | **0 liquidatable**; sum effective deposits 1,011,168.44 TRX. 4 zero-deposit pairs are `amount = 0` and `liquidate` reverts `"no resource to liquidate"` (verified on 2). **PASS**. |
| **T5 badDebt state** | `badDebt = badDebtCovered = 481,464,141 sun`; gap 0; `BadDebtAdded` = 0 in 7 days; 106/106 liquidations had `sendBack > 0`. **PASS** — branch dormant. |

**CI run:** `https://github.com/artsbykriss/ca-zombie-ci/actions/runs/<RUN_ID>` — `ci/run.sh` re-runs T1–T3 and the state check and writes `ci-out/poc_results.json` + `ci-out/verdict.json`; the job fails if `double_refund_closed`, `dirty_rent_charged`, `badDebtGap == 0` or `max_self_liq_net <= 0` do not hold.

---

## 6. Verdict and residual risk

**E-U now: $0.** The market’s 1.378M TRX balance is user deposits + accrued rent, not a pot an unprivileged actor can reach. The two B0 hypotheses are closed:

* return-after-liquidate: **reverts** (2/2 real pairs);
* badDebt branch: **not profitable to create** (net `−oneDayRent`), and **0 live triggers** (0/713 liquidatable; 0 `BadDebtAdded` in 7 days; gap 0).

**E-U-conditional (MED):** a keeper can collect the 8 bp fee from the **market** on an already-abandoned order with `effectiveDeposit < fee`. Upper bound per order = `fee` (0.008% of amount; min 20 TRX). This is a subsidy to a third-party keeper, not a self-dealing profit. **Re-arm trigger:** any `getRentInfo` with `liquidatable = true` **and** `securityDeposit < fee`, or any `Liquidate` event with `sendBack = 0`, or `badDebtGap > 0`.

**Re-arm / next check (exact):**

1. Every 6 h read `badDebt()`, `badDebtCovered()`, `badDebtGap()` and crawl `Liquidate` + `BadDebtAdded` events since the last block. Re-open if `badDebtGap > 0` or a `Liquidate` has `sendBack = 0`.
2. Recompute effective deposits as `Σ getRentInfo(...)[0]` over the live pair set; if `balance < Σ effective + accrued rent`, re-open as H-O/S (solvency).
3. Do **not** reuse the 3.46M “nominal” figure: it is the sum of the latest `RentResource` event per pair and overstates live deposits by ~3×. Use the latest event across **all** types + `getRentInfo`.
4. The admin EOA `TLntW9Z5…` remains the P-class overhang; watch `NewPendingImplementation` / `NewAdmin`. (Same EOA admins JustLend sTRX and owns SunSwap V4.)

**H-O:** 1,011,168 TRX ($336,861) of effective deposits, backed by the balance. **S:** $0 identified. **P:** the 1,378,329 TRX balance is upgradeable by the single admin EOA (key-compromise scenario).

---

## 7. Methodology, sources, caveats

* Verified source pulled read-only from Tronscan (`POST /api/solidity/contract/info`) for the proxy, `MarketG1`, `STRXG2` and `JumpRateModel`; decoded into `analysis/src_*/`.
* Live reads via TronGrid `triggerconstantcontract` / `getaccount` / `getnowblock` at block **87,210,571** (state) and per-pair blocks 87,210,2xx–87,210,6xx (scan). No keyed endpoints. No secrets.
* Events via `GET /v1/contracts/TU2MJ5…/events` with `only_confirmed=true`, 7-day window; 9,782 `RentResource`, 5,253 `ReturnResource`, 106 `Liquidate`, 352 `RentClaimed`, 0 `BadDebtAdded`.
* Price: DefiLlama `coins.llama.fi/prices/current/coingecko:tron` = **$0.33314044** (2026-10-18T07:38Z).
* **Caveats:** (i) point-in-time — the market churns every ~25 min; (ii) TRON cannot be forked in Foundry, so the “PoC” is a live dry-run + arithmetic replay, not a state-changing fork; (iii) the verified source exposes 57/58 ABI selectors in the deployed bytecode — the `initialRentRate(uint256)` getter is absent (minor source/bytecode mismatch); all functions used here are present and their behavior matches the source; (iv) the 7-day window may miss a >7-day-old deposit with an unusually large over-collateralisation; the 230k TRX balance-minus-stored surplus bounds that exposure; (v) nothing here is an instruction to transact.

### Files

```
justlend-energy/
├── README.md                      # this file
├── summary.json                   # machine-readable verdict
├── analysis/
│   ├── src_impl/MarketG1.sol      # verified source (impl)
│   ├── src_proxy/MarketProxy.sol  # verified proxy
│   ├── src_strx_impl/STRXG2.sol   # energy supplier
│   ├── src_ratemodel/JumpRateModel.sol
│   ├── tronlib.py                 # read-only TRON helper
│   ├── live_state.json            # block 87,210,442 snapshot
│   ├── live_pairs.json            # 713-pair getRentInfo scan
│   ├── quantification.json        # USD/TRX table
│   ├── events/                    # 7-day event dump (Rent/Return/Liquidate/RentClaimed)
│   └── snapshot.py, read_pairs.py, crawl_window.py
├── poc/
│   ├── poc.py                     # T1–T3 dry-run + shadow ledger
│   ├── tronlib.py
│   ├── inputs/                    # public addresses + live state
│   └── results/poc_results.json
├── ci/run.sh                      # CI job
├── ci-out/                        # CI results
└── ci-log.txt                     # CI log
```
