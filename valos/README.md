# Z3-H14 · Valos (Monad) — AccountableAsyncRedeemVault async-redeem deep dive

**Date:** 2026-10-16 · **Chain:** Monad (chain id 143) · **Status:** read-only; fork-verified only; no mainnet transactions
**Target:** vault `0x8d3F9f9Eb2f5E8B48EFBB4074440D1E2A34Bc365` ("RWA Backed Lending by Valos" / `vUSD`) — DefiLlama TVL **$105.8M** (largest single fresh-TVL surface screened on Monad)
**Pinned fork block:** 113,775,837 (all state below read at this block unless stated)

---

## 1. TL;DR

| Question | Verdict |
|---|---|
| **Live extractable by a fresh unprivileged attacker (E-U)?** | **$0 — structurally closed.** The vault is `permissionLevel = Whitelist(2)`, set at construction and **immutable** (no setter in source or ABI). Every value-moving entry point (`deposit`, `mint`, `requestRedeem`, `redeem`, `withdraw`, `cancelRedeemRequest`, `transfer`) requires `allowed[account]`, and only the strategy (manager EOA) can add addresses. A fresh attacker cannot deposit, redeem, receive or acquire vUSD shares. |
| **Async-redeem price callback abuse (the Z3-H14 class)?** | **Does not apply to this codebase.** `redeemPrice` is supplied by the strategy at request/settlement time from a NAV that is a pure function of stored state + `block.timestamp` (linear 6.75 % p.a. interest on `outstandingPrincipal`). No oracle, no AMM/pool input, no donation sensitivity, no same-block manipulable term. Both conversion directions floor → round-trips cannot gain (fork-proven). |
| **Instant-fill arbitrage against the queue?** | **Impossible today and value-neutral in general.** Instant fill requires `availableLiquidity ≥ shares × sharePrice` and vault idle cash. Idle cash is **$7,693.02**; `minRedeem` is **$94,319.88** (90,000 shares) — every redeem request therefore queues, and the queue settles later at the same price function. Fork-proven: a permissionless crank converted the full idle cash into a queued user's claim; the crank caller gained **$0**. |
| **Queue state today** | Empty: `totalQueuedShares = 0`, `reservedLiquidity = 0`, `queue() = (next 5, last 4)` — all 4 historical requests fully settled. |
| **Permissionless functions** | `accrueInterest()`, `updateLateStatus()`, `processAvailableWithdrawals()` are callable by anyone but pay the caller nothing (fork-proven); `acceptDefault()` is dead (`_defaultValidAt = 0`). |
| **Dominant live risk (not E-U)** | P-class centralization: a **single EOA** (`0xB83986…fc7C`) is simultaneously borrower + investment manager, holds the vault's vUSD, controls the lender whitelist, can take all idle cash via `borrow()`, and — together with the global securityAdmin (2-of-3 Safe) — can UUPS-upgrade the strategy implementation that the vault trusts for pricing and `releaseAssets`. |
| **Latent / re-arm** | Whitelist additions (manager action), key compromise of the manager EOA, strategy upgrade. See §8. |

**Total live extractable by external unprivileged attacker now: $0.00 (high confidence).**
**Idle cash at risk to the privileged borrower EOA: $7,693.02 (fork-demonstrated).**
**Treasury fee shares not whitelisted: 153,023.85 vUSD ≈ $160,368.78 (recoverable via transfer/whitelist, not stuck).**

---

## 2. Mechanism — the async-redeem flow in exact terms

Deployed code (all verified on Monadscan/Etherscan V2, chain 143):

- **Vault** `0x8d3F9f9Eb2f5E8B48EFBB4074440D1E2A34Bc365` — `AccountableAsyncRedeemVault` (solc 0.8.27, **not a proxy**), ERC-4626 + ERC-7540-style async redeem. Source: `analysis/vault_src/`.
- **Strategy** `0x8dCE15fc6a98484C995Fc702cBfBdA14A30454af` — ERC-1967 **UUPS proxy** → impl `0x62d83e8d579ec3b5911f29e02c70f4130092edd1` = `AccountableOpenTerm` ("credit-vaults-v1-1-0-1.1.0"). Source: `analysis/strategy_src/`.
- **Asset** `0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a` = AUSD (Agora), 6 dp.
- Factory `0xabCCE3f78a591c1C734CB16b6Ea56DFF3985953c`; globals registry `0x6436E1F2edC981B69A3B0F396924ceC01DC617Af`; fee manager `0x0E503d4B0d463855E819D7201f6BD2604d423C4C`.

**Flow (vault `AccountableAsyncRedeemVault`, `AccountableWithdrawalQueue`, `AccountableVault`):**

1. `requestRedeem(shares, controller, owner)` — modifier `onlyAuth(owner, controller)` → `_isVerified` (Whitelist ⇒ `allowed[account]`), plus `_checkOperator` / `_checkController` / `_checkMinAmount` / `_checkShares`.
2. Vault calls `strategy.onRequestRedeem(vault, shares, controller, owner)` (strategy: `onlyVault`, `whenNotPaused`, `nonReentrant`). The **strategy supplies `(canFulfill, price)`**:
   - `price = _sharePrice()` = `(vault.totalAssets() + outstandingPrincipal×scaleFactor/1e36 − feeAssets) × 1e36 / totalSupply`; during the (long past) deposit period it is exactly `1e36`; in `Repaid`/`InDefaultClaims` it is `assetShareRatio` (cash-only).
   - `canFulfill = _isInstantRedeem()` (only in `Repaid`/`InDefaultClaims`) **or** `_getAvailableLiquidity() ≥ shares×price/1e36`.
3. If `canFulfill`: vault `_fulfillRedeemRequest(0, …)` — `assets = floor(shares×price/1e36)`, requires `assets ≤ _liquidity()` (idle AUSD minus `reservedLiquidity`; `accruedAssets == 0` for OpenTerm), then `reservedLiquidity += assets`, per-controller `maxWithdraw/redeemShares += …`, and `redeemPrice = floor(maxWithdraw×1e36/redeemShares)`, `withdrawPrice = ceil(...)`.
4. Else: shares pushed to the withdrawal queue (`_push`, per-controller request id; queue depth `totalQueuedShares`).
5. Settlement: `redeem(shares, receiver, controller)` pays `floor(shares×state.redeemPrice/1e36)` and decrements the per-controller claim by the **ceil** amounts (`_updateRedeemState`) — conservative for the vault. `withdraw` mirrors it with the ceil price. Shares are burned from the vault's pooled custody (`address(this)`).
6. Queue processing is **strategy-only on the vault** (`processUpToShares` / `processUpToRequestId` / `fulfillRedeemRequest`), but the strategy exposes a **permissionless crank** `processAvailableWithdrawals()` that processes queued requests at the current `sharePrice()` using idle cash (`totalAssets − reservedLiquidity`); payouts go to the queued controllers, never to the caller.
7. `accrueInterest()` / `updateLateStatus()` are permissionless; interest is linear at `interestRate` (6.75 % p.a., `interestInterval` 30 d) and fee shares (3 % performance, 0 % management, `managerSplit = 0`) are minted to `managerFeeRecipient` / treasury.

**Manipulability audit of the price path (source-level, exhaustive):** every term in `_sharePrice` is either (a) stored state only the borrower/manager can change (`outstandingPrincipal`, `netPrincipal`, `interestRate`, terms), (b) monotone time-based accrual (`_previewAccruedInterest`, `_previewFeeAssets`), or (c) the vault's own token balances/supply. There is **no external oracle, pool or callback input**; `publishRate` is dead (`dvnPublisher == 0`); `priceOracle` is unset; `rollbackRate` is disabled (`operationsAdminEnabled == false`). A donation of AUSD raises `totalAssets` (and thus `sharePrice`) only by an amount ≤ the donation, and both deposit and redeem price at the same function — no net gain (and a fresh attacker cannot deposit anyway).

---

## 3. Live-state assessment (block 113,775,837)

### Vault
| Field | Value |
|---|---|
| `permissionLevel()` | **2 = Whitelist** (immutable; no setter in the 65-function ABI) |
| `transferableShares()` | `true` (but transfers require `allowed[to]`) |
| `precision()` / `decimals()` | `1e36` / `6` |
| `totalAssets()` (idle AUSD) | **$7,693.02** |
| `totalSupply()` | 101,036,240.141419 vUSD |
| `sharePrice()` | 1.047998623657482529446686438135257711 |
| `convertToAssets(totalSupply)` | **$105,885,840.61** (the DefiLlama TVL claim) |
| `totalQueuedShares()` / `reservedLiquidity()` | 0 / 0 |
| `queue()` | nextRequestId 5, lastRequestId 4 (all settled) |
| `assetShareRatio()` | 7.614e31 (= idle only, 7.6 bps of NAV) |
| `signer()` | 0 (KYC path unused) |

### Strategy (`AccountableOpenTerm` proxy)
| Field | Value |
|---|---|
| `loanState()` | **3 = OngoingDynamic** |
| `paused()` | false |
| `scaleFactor()` | 1.049677651176433282597666159309994290 |
| `outstandingPrincipal` (debt shares) | 100,867,309.956010 → **debt = $105,878,161.00** |
| `netPrincipal()` | 100,657,842.670744 |
| Loan terms | `minDeposit` $100,000 · `minRedeem` **$90,000 (94,319.88 in USD at NAV)** · `maxCapacity` $200,000,000 · `interestRate` 67500 (6.75 %) · `interestInterval` 30 d · `withdrawalPeriod` **0** · `reserveThreshold` **0** · `depositPeriod` 5 d (started 2026-02-06, long past) · `lateInterestPenalty` 0 · `lateInterestGracePeriod` 35 d |
| `borrower()` = `investmentManager()` | `0xB83986E9F33a6De4624B18DA69cb474F6f94fc7C` — **plain EOA** |
| `safetyModule()` / `dvnPublisher()` / `proofSigner()` / `priceOracle()` | 0 / 0 / 0 / 0 (unset) |
| `securityAdminEnabled()` / `operationsAdminEnabled()` | true / false |
| `globals` securityAdmin = operationsAdmin = treasury | `0x4B07AaA370189E5603DF56C84f59c5A59181BFB1` — **Gnosis Safe 1.4.1, threshold 2-of-3** (owners `0x25e170E3…`, `0x66415E41…`, `0xFCb0CBc1…`) |
| `accruedAssets(vault)` | 0 (OpenTerm override) |
| `maxDeposit(vault, any)` | $99,334,464.30 (capacity headroom) |
| Fee manager | `performanceFee` 3 %, `managementFee` 0, `establishmentFee` 0, `managerSplit` 0 |

### Custody & ecosystem (all verified)
| Holder | vUSD shares | Note |
|---|---|---|
| **Euler EVK vault** `0xd8ec5b49…305D` ("EVK Vault evUSD-2", asset = vUSD) | 75,876,065.20 (**$79.5M**) | whitelisted contract; evUSD shares are normal ERC-20s |
| **Curvance** `0x42369afe…836C` ("Curvance RWA Backed Lending by Valos", cvUSD, asset = vUSD) | 24,745,177.56 (**$25.9M**) | whitelisted contract |
| Borrower EOA `0xB83986…fc7C` | 11,969.61 | whitelisted |
| **Treasury Safe** `0x4B07AaA3…BFB1` | 153,023.85 (**$160,368.78**) | **NOT whitelisted** — fee shares; recoverable via `transfer` to a whitelisted address or manager whitelisting |
| Morpho Blue singleton `0xd5d960e8…1AEE` | 250,003.00 | whitelisted; collateral of two small Morpho markets |
| 7702-delegated EOA `0x6d3da13b…BCE8` (delegate `0x63c0c19a…`) | 0.92 | whitelisted |
| AUSD balances | vault $7,693.02 · strategy 0 · borrower $12,703,241.22 | |

**Whitelist (23 addresses, all `allowed=true`, from `AllowedSet` events; no removals):** borrower EOA; 16 EOAs (`0x01041189…`, `0x9016a515…`, `0x1ecb6d03…`, `0x6d3da13b…` [7702], `0x42369afe…` [Curvance], `0x3a58f20d…`, `0x8dad3d89…`, `0x8beaae02…` (largest historical lender), `0x29a66a82…`, `0x2eddabf6…`, `0x4144a68c…`, `0x27656350…`, `0x440e8dd1…`, `0x40717a33…`, `0x5bc157f9…`, `0x725ab8ca…` [Morpho GeneralAdapter1], `0xd5d960e8…` [Morpho], `0xb81d50d5…`, `0xd8ec5b49…` [Euler EVK], `0xec0d6af5…`, `0xb47c72be…`, `0x9c76e91b…` [BlueBundlesV1]) — several are permissionless Morpho/Euler/Curvance infrastructure contracts, but all of them are gateways that still require the caller to own vUSD (which no fresh attacker can obtain).

### Activity history (from events; full log `analysis/decoded_events.txt`)
- 43 deposits totalling **$115,550,994.75**; **40 borrows totalling the same $115,550,994.75** (the borrower drew every deposit within minutes — release events in the same blocks as deposits).
- 7 repayments totalling **$14,893,152.11**, timed to fund the lender `0x8beaae02…`'s redeem requests ($2.09M, $3.05M, $2.59M, $1.70M, $3.43M, $2.03M in Jul–Sep).
- 4 `RedeemRequest`, 9 `RedeemClaimable`, 6 `Withdraw` — all fully settled; queue empty today. The pattern shows the intended institutional flow: lender requests → borrower repays → `processAvailableWithdrawals` (or repay hook) settles at NAV.

### Morpho adjacent surface (context)
Two Morpho Blue markets use vUSD as **collateral** with AUSD loans: `0x5fdfdfc0…` (LLTV 94.5 %; $6.4k supply/$1.6k borrow) and `0x1c1312c2…` (LLTV 91.5 %; $146k supply/$134k borrow). Oracle `0xf07e835c4ec57ed880159aef393e8ff9f66e75c0` (`MorphoChainlinkOracleV2`) prices vUSD at **1.048002e36 vs true NAV 1.0479986e36** (accurate). No mispricing; positions tiny.

---

## 4. What an attacker can / cannot do

**Cannot (fork-proven, `test_02`):** `deposit`, `mint`, `requestRedeem`, `redeem`, `withdraw`, `cancelRedeemRequest`, `transfer`, `setAllowed` (vault), `setLenders` (strategy), `onRequestRedeem` (strategy) — all revert `Unauthorized()` for a non-whitelisted caller. vUSD cannot be acquired by a fresh attacker by any route: mint (gated), transfer (recipient gated), or via the Euler/Curvance/Morpho wrappers (their borrow/liquidate/withdraw paths all end in a vUSD `transfer` to the counterparty, which hits the same gate).

**Can (fork-proven, `test_03`):** call `strategy.accrueInterest()`, `strategy.updateLateStatus()`, `strategy.processAvailableWithdrawals()` — succeeds but moves **$0** to the caller (no queue; accrual mints fee shares to manager/treasury only). `acceptDefault()` reverts `TimelockNotExpired` (`_defaultValidAt = 0`).

**Instant-fill headroom (fork-proven, `test_04`):** `minRedeem` ($94,319.88) > idle liquidity ($7,693.02) ⇒ `canFulfill` is always false today; a whitelisted min-size request queues. The permissionless crank then paid the queued Euler vault $7,693.02 at `sharePrice` — value-neutral for the crank caller and for the vault (reserved, then settled).

**P-class demo (fork-proven, `test_06`):** the borrower EOA can `borrow(vault.totalAssets())` — takes the entire idle $7,693.02 instantly (by design of the open-term facility; `reserveThreshold = 0`).

**Cost/benefit for the closest non-gated ideas:** every candidate path (queue-race, crank timing, donation, fee-accrual timing, queue-price arbitrage) either requires whitelisted vUSD or yields ≤ 0 after rounding — no path beats gas.

---

## 5. PoC / fork verification

`valos/poc/` (Foundry, solc 0.8.24, vendored forge-std, `eth_rpc_url = https://rpc.monad.xyz` for Monad EVM instantiation; pinned block **113,775,837**).

| Test | Purpose | Result |
|---|---|---|
| `test_01_live_state` | structural state (whitelist, queue, loan state, NAV math) | PASS |
| `test_02_fresh_attacker_all_entry_points_revert` | every value entry point reverts `Unauthorized` for fresh caller | PASS |
| `test_03_permissionless_cranks_no_profit` | permissionless calls succeed, caller gains $0; default path dead | PASS |
| `test_04_queue_settlement_value_neutral_for_caller` | min-size request queues; crank pays queued user at NAV; caller gains $0 | PASS |
| `test_05_nav_time_driven_and_no_roundtrip_gain` | NAV grows only with time; floor/ceil round-trips lose; single price function | PASS |
| `test_06_p_class_borrower_takes_idle_cash` | P-class: borrower EOA drains idle cash (labeled, not E-U) | PASS |

**Local:** 6/6 PASS. **CI:** see `ci-log.txt` / `ci-out/` (GitHub Actions, `artsbykriss/ca-zombie-ci`, branch `valos`) — run URL in §9. The `ci/run.sh` job additionally re-dumps the live state at run time into `ci-out/live_state.txt|json` (public keyless RPC only).

Key fork outputs: idle `7,693,024,334` (6 dp); `sharePrice 1.04799862…e36`; `scaleFactor 1.04967765…e36`; `convertToAssets(totalSupply) 105,885,840,607,733`; treasury fee shares `153,023,846,146`; crank processed `7,693,024,332` for the queued Euler claim with caller delta `0`.

---

## 6. Verdict & residual/latent risk

**E-U today: $0.00 (high confidence).** The async-redeem price/strategy-callback class **does not fire** on this deployment: (1) the entire user surface is behind an **immutable** whitelist; (2) the NAV function has no external/manipulable input and both rounding directions favor the vault; (3) instant-fill headroom is structurally zero today (min-redeem > idle cash); (4) the queue is empty and permissionless cranks pay only queued (whitelisted) users.

**Re-arm conditions (exact triggers to monitor):**
1. **`AllowedSet(account, true)` events on the vault** — the only way a new external actor gains access. If the manager ever whitelists an *open* contract (router/vault anyone can call), its callers inherit access. Monitor this event.
2. **Manager/borrower EOA `0xB83986…fc7C` compromise or key misuse** — it can: take idle cash + future deposits via `borrow()`; set the lender whitelist; change `managerFeeRecipient`; propose+approve interest rates (approve has **no upper bound** in code; only `proposeInterestRate` caps at 1000 %); and (with the 2-of-3 Safe securityAdmin) **UUPS-upgrade the strategy** — after which `releaseAssets`/`hooks` semantics are whatever the new impl says. This is the dominant live risk on the deployment (P-class, $105.9M of lender claims).
3. **New deposits** — headroom is $99.33M; every deposit is instantly borrowable by the same EOA (`reserveThreshold = 0`, `withdrawalPeriod = 0` means no forced liquidity for redemptions; lenders exit only when the borrower repays).
4. **`_defaultValidAt` set** (manager/safety-module `defaultLoan()`), then anyone may `acceptDefault()` after 1 day — state transition only, no caller value.
5. If the vault were ever **redeployed open** (`permissionLevel = None`) by the same factory: the redeem math is still not exploitable (time-based NAV, floor/ceil discipline, instant-fill bounded by idle cash) — the classic stale-NAV drain requires an external price source that this codebase does not have. This is a **negative result** worth recording for the 2026 async-redeem class.

**Adjacent-surface caveats (not E-U against the vault, monitored):** vUSD is embedded in Euler EVK (`evUSD-2`, $79.5M), Curvance (`cvUSD`, $25.9M) and two small Morpho markets; wrapper shares (`evUSD`/`cvUSD`) are *not* whitelist-gated, so they could in principle trade on an AMM while their redemption into vUSD is blocked for non-whitelisted holders — no such venue was found and no profit path exists without vUSD. Non-whitelisted keepers also cannot liquidate vUSD-collateral Morpho positions (seizure transfer is gated), which is a keeper-liveness risk for those markets, not attacker profit.

**Blockers / limitations:** Monad tooling is thin; no independent audit; the strategy impl is upgradeable so the code reviewed may change (monitor `Upgraded` events); all numbers are point-in-time at block 113,775,837 and re-verified in CI.

---

## 7. Methodology & sources

- Verified source (Etherscan V2, chain 143): vault `AccountableAsyncRedeemVault` (32 files) and strategy impl `AccountableOpenTerm` (31 files) — saved under `analysis/vault_src/`, `analysis/strategy_src/`, `analysis/holder_0xd8ec_src/`, `analysis/holder_0x4236_src/`.
- Live reads at pinned block via public keyless RPC `https://rpc.monad.xyz` (raw dumps: `analysis/state_dump.txt`, `analysis/strategy_state.txt`).
- Event forensics via Etherscan V2 `getLogs` (43 deposits / 40 borrows / 7 repays / 4 requests / 9 claims / 6 withdrawals / 23 whitelist additions / Morpho `CreateMarket`) — decoded in `analysis/decoded_events.txt` (`analysis/logs_*.json`).
- Foundry fork PoC (6 tests) — local run + CI (GitHub Actions, public repo, keyless).
- Roles: globals Safe decoded on-chain (`getThreshold=2`, `getOwners=3`, VERSION 1.4.1).
- Cross-checks: DefiLlama `protocol/valos` (adapter counts `convertToAssets(totalSupply)`, registry `curators.js`); our NAV matches DL within the day.

**Files index:** `README.md` (this) · `summary.json` · `analysis/` (sources, dumps, decoded events, scripts `read_state.py`, `decode_logs.py`) · `poc/` (Foundry: `src/Interfaces.sol`, `test/ValosLive.t.sol`) · `ci/run.sh` (live-state re-dump) · `ci-out/` · `ci-log.txt`.

---

## 8. CI

- **GitHub Actions:** run URL recorded in `ci-log.txt` header and `summary.json` → `poc.ci_run_urls` (branch `valos` on `artsbykriss/ca-zombie-ci`).
- Artifacts: `ci-out/live_state.txt|json` (fresh-block state re-verification), full `forge test -vvv` log.

*Read-only research. No transactions were signed or sent to Monad or any network; all exploit-style interactions were fork-only simulations.*
