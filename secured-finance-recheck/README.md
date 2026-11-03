# Secured Finance — in-block price-ratio collateral inflation (re-check)

**Date:** 2026-11-03 · **Chain:** Ethereum mainnet · **Status:** read-only; fork-verified only; **no mainnet transaction was signed or sent**.
**Prior verdicts:** ZH4-pass6 (2026-10-23) closed Secured Finance as a **false positive** (the historical profit engine was the `cleanUpOrders` FV mint, since fixed). CA2 (2026-11-02) rated the *separate* "in-block price-ratio collateral inflation" vector **LOW / net-negative (2.4 % short on the best book)**.
**This re-check:** the live build is **unchanged**, the vault holds **$112,417.30**, and the **best tradeable book is 3.34 % short** — the attack still loses money at every size. **Not re-armed.**

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---|---|---|
| `LendingMarketController` `0x35e9D8e0…9Fe2` → impl `0x558084fF…202f`; `TokenVault` `0xB74749b2…9393` | **$0.00** | The 125 % liquidation threshold prices a fabricated future-value claim at `1.25 × max(orderPrice, minDebtUnitPrice)`. On the best **tradeable** book (USDC, maturity 1,853,798,400) that is **1.0334 × FV** → a claim of `FV` costs 3.34 % more than it is worth. Draining the whole USDC leg would **lose $636.26** | Re-arms if `minDebtUnitPrice` for USDC is lowered from 8900 to **< 8840** (privileged), or a new order book maturing **after ~2029-02-13** (T > 2.286 y) is opened and made tradeable — then `M < 8000` and `1.25 × M < 10000` |

**Total live extractable now: $0.00** (confidence **high** on the cost side — fork-measured; **medium** on the benefit side, where the most generous assumption still leaves the attack negative).

---

## 2. The mechanism (live code, not the historical exploit)

The September-2026 drain (`0xcd615986…b1da`, block 25,914,192) used `cleanUpOrders` to **mint unbacked future
value** for an unfilled cheap lend; `getMarketUnitPrice` then re-valued that FV at par so it could be withdrawn.
Pass6 verified that the mint is gone on the live build (`OrderStatisticsTreeLib.remove/removeFixup` fix + chunk
tracking). **That is not the vector re-checked here.**

This re-check is the *other* vector: manipulate the same-block unit-price ratio so a **legitimately-created**
cheap lend claim is valued at par.

1. `LendingMarket.executeOrder(id, side, user, amount, unitPrice)` is **permissionless**.
2. `OrderBookLib.getMarketUnitPrice` (unchanged hacked ⇄ live) is a same-block `blockTotalAmount / blockTotalFutureValue`
   ratio with `isReadOnly = true` on the collateral path — no TWAP, no deviation guard. The ±10 % band is
   bypassable by a multi-block ratchet (prior fork work: `mup` driven 10000 → 1000 over 9 blocks at ~$100
   notional per step).
3. A cheap resting **BORROW** at price `p`, filled by the attacker's own **LEND** at `p`, gives the lender a
   claim `FV = amount × 10000 / p`.
4. The debt/collateral valuation floor is **not** `p`. In `FundManagementLogic`:
   `getMinDebtUnitPriceAt(maturity, configured, t) = 9600 − (9600 − configured) × (maturity − t) / 1 year`
   (clamped to ≥ 1), and a negative future value is valued at `max(marketUnitPrice, M)`.
   The *placement* path (`_estimateCollateralCoverage` → `workingBorrowOrdersAmount`) uses the same floor when
   `p < M`.
5. `DepositManagementLogic._isEnoughCollateral` requires
   `totalCollateral × 10000 ≥ totalUsedCollateral × 12500`.

So the cost of a claim of `FV` is **`1.25 × max(p, M) × FV / 10000`**, and the most generous possible benefit is
`FV` (the claim withdrawable at par). Breakeven therefore needs **`max(p, M) < 8000`**.

Live configured floors (`getMinDebtUnitPrice(bytes32)`): **USDC 8900, WBTC 9300, ETH 9100, JPYC 9100**.
USDC/WBTC/ETH each have 9 quarterly maturities; JPYC has 3; USDT/DAI/FIL/USDFC/iFIL/wFIL have **no market**
(`getMaturities` reverts).

---

## 3. Live state (Ethereum block **26,334,697**, 2026-11-03)

| Check | Value |
|---|---|
| Controller proxy impl | `0x558084fFf061196EC4b2a9100c0f6e3fc47B202f` (EIP-1967 slot) — unchanged since block 26,251,756 |
| TokenVault impl | `0x9a1dc892f4ff89ad7332f62b500fc9ad17d792a3` |
| `isTerminated()` / `paused` | false / not paused (same as pass6) |
| TokenVault WBTC | **0.82183653 WBTC** = **$82,119.52** (Chainlink `0xfdFD9C85…BB23` = $99,921.967) |
| TokenVault USDC | **19,063.87754 USDC** = **$19,063.88** |
| TokenVault WETH | **4.9035631596646905 WETH** = **$11,233.90** (Chainlink ETH = $2,290.97) |
| **Total** | **$112,417.30** |
| Balances change since pass6 (Oct 23) | **none** — byte-for-byte identical (0.82183653 / 19,063.87754 / 4.903563) |
| Best **tradeable** book | **USDC, maturity 1,853,798,400** (2028-09-30): `minBorrow = 8075`, `M(now) = 8267`, reference `mup = 9075` |
| Effective valuation price | **8267** (`max(8075, 8267)`) |
| Edge | `1 − 1.25 × 8267/10000` = **−3.337 %** |
| Best untradeable book | USDC 1,861,660,800 (2028-12): `M = 8092`, `minBorrow = 8191` → **−2.39 %**, but `isReady() = false` (`MarketNotOpened`) |
| Other currencies, best tradeable | WBTC −12.9 % (M = 9029), ETH −8.1 % (M = 8648), JPYC −19.1 % (M = 9530) |

The prior "2.4 % short" used the 8191 minimum of the **not-yet-open** 2028-12 book. With the live *tradeable*
set the correct figure is **−3.34 %**; the conclusion does not change.

---

## 4. Fork measurement of the cost side (decisive)

`poc/test/SecuredFinanceEconomics.t.sol` — **2/2 PASS**, fork at head:

1. `test_live_best_tradeable_book_is_net_negative` — iterates all USDC maturities, skips `isReady()==false`,
   computes `1.25 × max(minBorrow, M)` and asserts every tradeable book is net-negative and the best effective
   price is **above 8000**. Result: best = **8267** (book 19), edge **−333 bps**.
2. `test_plant_cost_vs_claim` — plants a real resting BORROW on book 19 at the live minimum price **8075**
   for `FV = 19,000 USDC`:
   - required deposit = `1.25 × 19,000 × 8267 / 10,000` = **19,634.125 USDC**;
   - **1 wei short reverts `NotEnoughCollateral()` (`0x34477cc0`)** — the gate is real and exactly 125 %;
   - at the requirement the order is accepted and the vault's own `getCollateralDetail` reports
     `(used × 12500) / collateral = 9,999 bps` (exactly at the 100 % limit);
   - **edge = claim − deposit = −635.1 USDC (−3.34 %)**.

Scale: the whole USDC leg is 19,063.88 USDC → the maximum possible claim is ~19,064, cost ~19,701,
**net loss ≈ $636.26**. To attempt it the attacker must also supply the lend principal (~15,342 USDC) and hold it
across the ~9-block ratchet, so the capital at risk is ~$35 k to lose ~$636 — before gas and ratchet cost.

**Benefit-side caveat (honest):** the −3.34 % figure is the *most generous* case, i.e. it assumes the inflated
claim is withdrawable 1:1 at par. Live `CurrencyController.getHaircut(USDC)` = **0**, so in the solvency path an
*unallocated* claim contributes **zero** collateral (`collateralAmount = maxAllocable + haircut × unallocated`,
`FundManagementLogic.calculateFunds`); the claim only enters the withdrawable-amount branch once the account has
debt. The real benefit is therefore **strictly below FV** and the loss is **≥ 3.34 %** (≥ 20 % if the claim must
be re-pledged at the 125 % threshold). Either way the sign is negative.

---

## 5. Reconciliation with the two prior verdicts

- **pass6 "false positive"** is correct **for the historical exploit**: the `cleanUpOrders` FV mint is fixed on
  Ethereum, Filecoin and Arbitrum, and the exact `SecuredFi_exp.sol` replay mints 0 and fails. This re-check
  does **not** re-open that.
- **CA2 "net-negative"** is correct **for the separate price-ratio vector**, and the live numbers confirm it —
  but the margin is thinner than CA2 stated on the *open* book (−3.34 %, not −2.4 %) and the 2.4 % figure
  belongs to a book that is not yet tradeable.
- **No contradiction:** CA2 never claimed the historical engine worked; pass6 never analysed the pure
  collateral-inflation economics. Both converge on **E-U = $0**.

---

## 6. Verdict and re-arm conditions

**Verdict: closed. E-U = $0.00. Best tradeable edge −3.34 %; max theoretical loss on the USDC leg $636.26. Confidence high on the cost side, medium on the benefit side.**

Flipping conditions (any one):
- `updateMinDebtUnitPrice(USDC, X)` with **X < 8840** (owner `0xccAC3163E54847ae04f192a20DCf2E902C660312`) — privileged.
- A new order book with **maturity > ~2029-02-13** (so `(9600 − 8900) × T / 1yr > 1600` ⇒ `M < 8000`) that is
  made tradeable. The 2028-12 book already computes `M = 8092`; ~2 months more distance flips it.
- Any change that removes/weakens the `minDebtUnitPrice` floor or the 125 % `_isEnoughCollateral` check.

**Blockers/limits:** the benefit side is not fork-verified end-to-end (a full profitable drain is impossible by
construction, so the test measures the binding cost gate); the ratchet's up-leg cost is taken from prior fork
work, not re-measured here; `getCurrentMinDebtUnitPrice` depends on `block.timestamp`, so the edge drifts
~+0.0002 %/day (toward safety) as maturities approach.

---

## 7. Methodology & files

Read-only: EIP-1967 slots, `eth_call` (balances, `getMinDebtUnitPrice`, `getCurrentMinDebtUnitPrice`,
`getOrderUnitPriceRange`, `getOrderBookId`, `isReady`, `getCollateralDetail`), verified sources from Etherscan V2
(`getsourcecode` for the controller, its libraries and the TokenVault), Chainlink on-chain prices. Fork PoC in
Foundry (CI). No keyed URL or key is written to any file.

```
secured-finance-recheck/
├── README.md
├── summary.json
├── analysis/live_state.py     # reproducible dump: balances, floors, per-book edges
├── poc/test/SecuredFinanceEconomics.t.sol
├── ci/run.sh · ci-out/ · ci-log.txt
```
