# INDEPENDENT VERIFICATION — Morpho wSPYx/AUSD donation-inflation "E-U = $0" claim

**Verifier:** independent child subagent (ZH4-PASS7, TIER 3 LOW #1).
**Date:** 2026-10-25. **Chain:** Ethereum (1). **Fork head:** block ≈ 26,272,1xx.
**Status:** read-only on mainnet; fork-only PoC; no mainnet tx signed/sent; no secrets written.
**Artifact:** `poc/test/VerifyIndependent.t.sol` (written from scratch — nothing copied from
`MorphoWspyxOracle.t.sol`), imports `../src/Interfaces.sol` only.
**Local run:** `cd poc && FORK_RPC_URL=<public eth rpc> forge test --match-path 'test/VerifyIndependent.t.sol' -vv`
→ **6 passed; 0 failed** (forge 1.8.5). (CI run intentionally not performed — parent owns CI.)

---

## 0. Verdict

**CONFIRM the parent's claim.** The donation-inflation primitive is real and reproducible, and I
could not construct any profitable external-unprivileged path. Independent re-derivation, a new
flash-buy-existing-shares attack, a deflation→liquidation attack, a Pyth-leg attack, a rounding/
`maxWithdraw` attack and an independent analytic sweep **all fail to produce a positive net**.
**E-U = $0**, hard cap = the market's free liquidity **$1,306.985484** (AUSD).

Two *non-material* wording corrections to the parent README are noted in §7.

---

## 1. Independent price-formula re-derivation (test_1) — exact match

From `MorphoPythOracle.sol` (verified source in `analysis/src/oracle/`):

```
price = SCALE_FACTOR.mulDiv( BASE_VAULT.getAssets(sample) * Pyth(BASE_FEED_1) * Pyth(BASE_FEED_2),
                             QUOTE_VAULT.getAssets(sample) * Pyth(QUOTE_FEED_1) * Pyth(QUOTE_FEED_2) )
```

Live on-chain params (my own `cast` reads): `BASE_VAULT = wSPYx`, `BASE_VAULT_CONVERSION_SAMPLE = 1e6`,
`QUOTE_VAULT = 0`, `BASE_FEED_1 = SPY/USD`, `BASE_FEED_2 = QUOTE_FEED_1 = QUOTE_FEED_2 = 0`,
`pyth = 0x4305FB66…`, `PRICE_FEED_MAX_AGE = 3600`. Since the quote vault and the three zero feeds
short-circuit to `1`, the denominator is `1` and `price = SCALE_FACTOR · convertToAssets(1e6) · Pyth(SPY)`.

I re-derived `SCALE_FACTOR` **from the constructor formula**, not by reading it:

```
SCALE_FACTOR = 10**(36 + quoteTokenDecimals + qFeed1Dec + qFeed2Dec
                       - baseTokenDecimals - bFeed1Dec - bFeed2Dec)
               * quoteVaultConversionSample / baseVaultConversionSample
             = 10**(36 + 6 + 0 + 0 - 18 - 8 - 0) * 1 / 1e6 = 10**16 / 1e6 = 1e10
```

Measured at fork head:

| quantity | value |
|---|---|
| re-derived `SCALE_FACTOR` | `10,000,000,000` (1e10) |
| on-chain `SCALE_FACTOR()` | `10,000,000,000` — **exact** |
| `convertToAssets(1e6)` | `1,004,710` |
| Pyth SPY (`getPriceUnsafe`, expo −8) | `76,407,999,997` |
| expected `1e10 · 1,004,710 · 76,407,999,997` | `767,678,816,769,858,700,000,000,000` |
| `oracle.price()` | `767,678,816,769,858,700,000,000,000` — **exact** |

`getPriceNoOlderThan(FEED, 3600)` returns the same value as `getPriceUnsafe` (feed fresh).
→ The parent's formula and `test_A` are **independently reproduced**.

## 2. NEW variant: flash-buy-existing-shares + donate (test_2) — net −$76,636

The parent only tested **mint-then-donate**. I tested the distinct **buy-existing-shares** path:
impersonate real free holders (`H1 0x6fe89E70…`, `H2`, `H3`, Uniswap-V4 PoolManager) and `transfer`
shares to the attacker (no mint → `totalSupply` unchanged), then donate flash-borrowed SPYx, supply
the bought shares, borrow the max, and try to redeem leftover shares to repay.

| step | value |
|---|---|
| shares bought `x` | `2.000000000000000000` (2 shares, from `H1`) |
| fair cost of shares (pre-donation) | `2.009420864047286177` SPYx |
| donation `D` (flash-borrowed) | `100` SPYx |
| borrowed AUSD | `1,306.985484` (== free liquidity; cap hit) |
| **net USD** | **−$76,636.37** |
| free float (non-Morpho shares) | `43.729380932862787593` = **6.577 %** of supply |
| redeeming the bought shares after donation | `2.310216765941706618` SPYx **< 100 SPYx** donated |

The attacker **cannot repay the flash loan**: redeeming returns `x·(A0+D+1)/(S0+1)`, which is
`< D` whenever `x < S0` (always true here). Without minting the attacker can own at most the free
float, `43.73/664.90 = 6.577 %`, which is `< 100 %` and `< 1/LLTV = 116.28 %`. To make the donation
self-financing you would need to own ≥ `1/LLTV > 1` of the supply — impossible. → **CONFIRM**.

## 3. NEW variant: deflation → liquidation (test_3) — HF unchanged, ≫ 1

I forced the maximum possible deflation an external actor can cause: **every free holder exits the
vault** (8 largest free holders: PoolManager, H1–H3, Angle, H4–H6; 92 % of the free float).

| quantity | before | after |
|---|---|---|
| SPYx redeemed by free holders | — | `40.447440840188033821` |
| `totalAssets` | `668.034654525510862109` | `627.587213685322828292` |
| `convertToAssets(1e6)` | `1,004,710` | `1,004,710` (**unchanged**) |
| `oracle.price()` | `7.676788167698587e26` | `7.676788167698587e26` (**unchanged**) |
| BIG borrower `0x2Eb5162A…` HF | `315.44×` | `315.44×` |
| LOW-HF borrower `0x03951709…` HF | `2.2097×` | `2.2097×` |

**Why deflation is impossible:** an ERC-4626 `redeem` is *fair-value*: it burns `r` shares **and**
removes `r·(A+1)/(S+1)` assets, leaving `(A'+1)/(S'+1) = (A+1)/(S+1)` (rounding slightly *favours*
the remaining holders). An attacker can only *add* assets by donation; they cannot remove assets
without burning the matching shares. Hence `convertToAssets` — the exact oracle input — cannot be
pushed **down**, and no borrower can be pushed below HF = 1. → **CONFIRM**.

## 4. Pyth-leg manipulation (test_4) — infeasible

| check | result |
|---|---|
| feed age at fork | `2,354 s` (inside the oracle's `PRICE_FEED_MAX_AGE = 3600`) |
| `getPriceNoOlderThan(FEED, 3600)` | succeeds, == `getPriceUnsafe` |
| `getPriceNoOlderThan(FEED, age−1)` | **reverts `StalePrice`** (guard active) |
| `updatePriceFeeds([bogus])` | **reverts** (`InvalidUpdateData`); forging needs the Pyth accumulator + Wormhole Merkle proof signed by Pyth publishers |
| `getValidTimePeriod()` (deprecated) | `120` — *not* used; the oracle passes `3600` explicitly |

Source read from the deployed implementation `0x3f38404a…` (`PythUpgradable`/`Pyth`): the writer is
`PythSetters.updateLatestPriceIfNecessary`, which updates **only if `info.publishTime > stored`**.
So a signed *older/cheaper* price can never regress the stored feed (and a *newer* one needs Pyth
publisher signatures). → **CONFIRM** (with the §7 wording nit).

## 5. Other inflatable reads of the vault (test_5) — value-neutral

- `totalAssets() == asset.balanceOf(vault)` — confirms the donation-inflatability source.
- A `100 SPYx` donation moves `convertToAssets(1e6)` `1,004,710 → 1,155,108` (the oracle input **rises**)
  but moves `convertToShares(1e6)` `995,311 → 865,719` (**falls**). The asymmetry is value-destructive
  for the attacker: the donation raises the *price* of existing shares but makes *new* deposits get
  fewer shares. No rounding direction is extractable.
- The donor mints **0 shares** and `maxWithdraw(donor) = 0` — the donation cannot be pulled back.

## 6. Independent general no-profit bound (test_6) — agrees

Let the attacker hold fraction `f` of post-state shares (`f ≤ 1`) and donate `D`. Collateral is
oracle-valued at `f·(A0+D)`, borrow `B ≤ min(free, LLTV·f·(A0+D))`, outlay `C = f·A0 + D`:

```
net = B − C ≤ LLTV·f·(A0+D) − f·A0 − D = −(1−LLTV)·f·A0  +  D·(LLTV·f − 1)
```

Both terms are `≤ 0`: the first is the LLTV haircut on the attacker's own capital (`LLTV = 0.86 < 1`);
the second is negative for **every** `f ≤ 1` because `LLTV·f − 1 ≤ 0.86 − 1 = −0.14 < 0` (the donation
is shared pro-rata with all holders, and the attacker can never own more than all of them). So
`net < 0` for any attack with capital or any donation. My 35-point analytic sweep (f ∈ {0.1 %, …, 100 %},
D ∈ {0, 1, 10, 100, 668} SPYx) confirms it: **best (least-negative) net = −$71.46**, and it only
approaches $0 as `f → 0` (i.e. as the attack shrinks to nothing). → **CONFIRM**.

## 7. Corrections / caveats (non-material)

1. **Parent wording:** README §5 says the Pyth contract *"rejects non-monotonic publishTime"*. In fact
   `updateLatestPriceIfNecessary` **silently ignores** an older/equal `publishTime` (it does not
   revert). The security conclusion is identical — a stale signed price cannot regress the feed.
2. **Parent's "best −$110.46"** is grid-dependent. The true least-negative loss is not a fixed floor;
   it approaches $0 as the collateral shrinks (borrow → 0). The claim "always negative / E-U = $0"
   still holds; only the *tightest* number differs. My finer grid finds −$71.46.
3. **Minor:** README §2 says the single borrower is at HF ≈ 50×; the largest borrower
   `0x2Eb5162A…` is actually **315.4×**, the lowest-HF borrower `0x03951709…` is **2.21×**, and the
   market-wide HF ≈ 59.5×. All ≫ 1, so the conclusion is unaffected.
4. The attack is *capital-limited by the market*, not by the primitive: free liquidity is only
   **$1,306.99**, so even a hypothetical free oracle would cap extraction at that amount — and the
   donation makes the attacker lose money before reaching it.
5. Fork-local only. Live re-read at block ≈ 26,272,1xx. SPY/USD Pyth feed was fresh (`2,354 s`);
   the test warps to the feed's `publishTime` only if it is stale, so it stays deterministic.

## 8. Test matrix

| test | what it attacks | result |
|---|---|---|
| `test_1_priceFormulaReDerivedFromRawReads` | re-derive `SCALE_FACTOR` + `price()` from raw reads | **PASS** (exact) |
| `test_2_flashBuyExistingSharesDonateCannotRepay` | buy existing shares + donate + borrow + redeem-to-repay | **PASS** (net −$76,636) |
| `test_3_deflationCannotLiquidateBorrower` | redeem all free shares to deflate oracle → liquidate | **PASS** (price & HF unchanged) |
| `test_4_pythManipulationInfeasible` | staleness / non-monotonic / forged update | **PASS** |
| `test_5_otherInflatableReadsAreValueNeutral` | `totalAssets`, `convertToShares`, `maxWithdraw` | **PASS** |
| `test_6_generalNoProfitBound` | analytic no-profit sweep | **PASS** (best −$71.46) |

**6/6 PASS locally.** No counterexample to `E-U = $0` found.
