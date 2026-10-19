# OpenFour / four.meme tax-token swap — real missing `minOut`, but $0 extractable at live flow

**Status:** read-only assessment, BSC block 128,636,158 (2026-10-19). No transactions signed/sent.

## TL;DR

| Item | Value |
|---|---|
| Target | four.meme V9 tax tokens (OpenFour stack) on BSC |
| Bug | tax dispatch calls `swapForQuote(to, amountToken)` / `swapForQuote(token, router, quote, to, amountToken)` with **no `minOut`** — the protocol swap accepts any price |
| Permissionless trigger | yes — any wallet-to-wallet transfer (or a sell) runs `_dispatchFee`/`_dispatchTax`; no role/whitelist |
| Live tax tokens | 15 of the top 40 V9 tokens have `feeRate > 0`; **only 2** have accrued tax ≥ `minDispatch` |
| Largest triggerable tax swap | **$29.25** (CHIM, 0.72% of a $3.3k pool) · **$1.51** (bibi Pro, 0.07% of a $2.2k pool) |
| Largest pending (below min) | $271–$285 (SPX001, 0.53–0.74% of a $38–67k pool) |
| Sandwich break-even | tax swap must be **>~2% of pool quote depth** (2×0.25% DEX fee + gas); no live token is close |
| **E-U now** | **$0** (HIGH for current flow) |
| Principal | **$0** — FeeRouter 23.65 WBNB is caller-unreachable (pass-2 §C); no principal path |
| Latent | monitor for `accrued tax value / pool quote reserve > 2%` on any tax token with a non-burn allocation |

## 1. The code path (verified source)

Two tax-token generations are live under the OpenFour/four.meme stack:

**A. `Token5` / `FourERC20` (e.g. 4Ball `0xd6423f99863e13b0a3fa00b5e1e5597792f74f8c`, verified
Sourcify full match, `Token5.sol`)**

```solidity
address public constant TOKEN_HELPER_5 = 0x1d09D9979CB6f7A1c80D4B1604e3F4cE2130e41b;

function _dispatchFee() internal {
    uint256 amountTotal = feeAccumulated;
    if (amountTotal < minDispatch) return;
    feeAccumulated = 0;
    ...
    _quoteHolder = _swapForQuote(address(this), amountHolder);   // if rateHolder > 0
    ...
    _quoteFounder = _swapForQuote(founder, amountFounder);       // if rateFounder > 0
    ...
    _addLiquidity(amountLiquidity);                              // if rateLiquidity > 0
}

function _swapForQuote(address to, uint256 amountToken) private returns (uint256) {
    _swapping = true;
    _approve(address(this), TOKEN_HELPER_5, amountToken);
    uint256 amountQuote = ITokenHelper(TOKEN_HELPER_5).swapForQuote(to, amountToken); // no minOut
    _swapping = false;
    return amountQuote;
}
```

`Token5._transfer` calls `_dispatchFee()` when `to == pair` (a sell) **and** on any
wallet-to-wallet transfer where `from != pair && to != pair` (after the transfer). So the dispatch
is triggerable by anyone with a 1-wei transfer.

**B. `DividendLaunchToken` (implementation `0x5Dcde21B513F331E918a42FAc045959f4c46f043`,
clone example `0x7FaF…9999`)**

```solidity
function _dispatchTax() internal {
    uint256 total = _accruedTax;
    if (total < minDispatch) return;
    ...
    if (toRecipient > 0) {
        _approve(address(this), liquidityHelper, toRecipient);
        ILiquidityHelper(liquidityHelper).swapForQuote(
            address(this), dexRouter, quoteToken, taxRecipient, toRecipient); // no minOut
    }
    if (toDividend > 0) { ... swapForQuote(..., address(this), toDividend); }
    if (toLP > 0) { ... addLiquidity(...); }
}
```

`_update` calls `_dispatchTax()` on any `launchedTransfer` with `from != pair` (sells and
wallet-to-wallet transfers).

The helper interfaces (`ITokenHelper`, `ILiquidityHelper`) contain **no `minOut`/`amountOutMin`
parameter**. The TokenHelper5 proxy `0x1d09D9979CB6f7A1c80D4B1604e3F4cE2130e41b` (impl
`0x5d6d8ec7852c1a066aec98b8caf1bc371212a23e`) is unverified on Sourcify, but the caller has no
slippage value to pass, so the downstream router call is the only place a bound could exist.
The pass-2 review already established the downstream helper takes no `minOut`; no source-level
counter-evidence was found.

## 2. Live flow — why the missing bound is not worth anything today

Data: four.meme public token list (`type=VOL_DAY_1`, `version=V9`, 40 tokens) + direct BSC reads at
block 128,636,158. `feeRate`, `feeAccumulated`, `minDispatch`, `rateFounder/Holder/Burn/Liquidity`
and the Pancake pair reserves are on-chain; `price`/`day1Vol` are the API’s USD values.

| Token | 24h $ | fee | F/H/B/L % | accrued $ | swap $ (F+H+LP) | min $ | pool $ | swap/pool |
|---|---:|---:|---|---:|---:|---:|---:|---:|
| SPX001 | 4,120 | 1% | 25/25/25/25 | 271.05 | 203.28 | 285.03 | 38,433 | 0.53% |
| 五爷 | 1,068 | 3% | 100/0/0/0 | 114.43 | 114.43 | 290.26 | 48,862 | 0.23% |
| AHA | 379 | 3% | 100/0/0/0 | 104.42 | 104.42 | 431.15 | 43,966 | 0.24% |
| BOBAI | 1,329 | 3% | 100/0/0/0 | 59.79 | 59.79 | 111.54 | 31,917 | 0.19% |
| 快乐小马 | 314 | 1% | 0/100/0/0 | 42.29 | 42.29 | 81.93 | 23,012 | 0.18% |
| PP | 844 | 3% | 100/0/0/0 | 34.47 | 34.47 | 39.33 | 19,271 | 0.18% |
| **CHIM** | 646 | 5% | 60/0/20/20 | 29.25 | **23.40** | 2.46 | **3,271** | **0.72%** |
| 财神殿 | 193 | 3% | 0/67/33/0 | 17.67 | 11.84 | 18.74 | 9,394 | 0.13% |
| 小蝌蚪 | 653 | 3% | 100/0/0/0 | 11.37 | 11.37 | 32.54 | 16,846 | 0.07% |
| willu | 298 | 1% | 100/0/0/0 | 10.75 | 10.75 | 32.10 | 9.29M | 0.00% |
| $Cardio | 3,547 | 3% | 50/0/25/25 | 2.27 | 1.70 | 33.14 | 15,594 | 0.01% |
| **bibi Pro** | 1,220 | 3% | 100/0/0/0 | 1.51 | **1.51** | 1.05 | **2,159** | **0.07%** |
| 4Ball | 1,335 | 3% | 0/0/100/0 | 3.95 | **0** (burn) | 98.45 | 26,924 | 0 |
| others | ≤198 | 3% | mixed | <0.3 | <0.3 | — | — | — |

Pool USD uses BNB ≈ $600 (conservative; at the pass-2 $1,050 the ratios are ~half). The exact
on-chain reserves are in `analysis/`; the API `price` is used only to value the accrued token tax.
The price-independent ratio `accrued tokens / token reserve` is what the fork test checks:
**CHIM 68 bps, bibi Pro 5 bps, SPX001 57 bps** — all below the 200 bps break-even.

**Only CHIM and bibi Pro are above `minDispatch` right now.** Their triggerable swaps are $23.40
and $1.51. Everything else is below the threshold; when it crosses, the swap is bounded by
`minDispatch` (e.g. SPX001 ~$285, AHA ~$431, 五爷 ~$290).

### Sandwich arithmetic

For a tax **sell** of quote value `v` into a pool with quote reserve `Q`, a reverse sandwich
(sell token before, buy back after) captures at most ≈ `v²/(4Q)` before fees. Two DEX legs cost
≈ `0.5%·v`; gas ≈ $0.10–0.20. Break-even:

```
v²/(4Q) > 0.005·v   →   v/Q > 2%
```

The live maximum is **0.72%** (CHIM), and the largest pending dispatch is **0.74%** (SPX001).
Even ignoring gas:

| Token | v | Q | gross v²/(4Q) | fees 0.5%·v | net |
|---|---:|---:|---:|---:|---:|
| SPX001 | $285 | $38,433 | $0.53 | $1.43 | **−$0.90** |
| AHA | $431 | $43,966 | $1.06 | $2.16 | **−$1.10** |
| CHIM | $23.40 | $3,271 | $0.04 | $0.12 | **−$0.08** |
| bibi Pro | $1.51 | $2,159 | $0.0003 | $0.008 | **−$0.008** |

There is no positive-EV sandwich on any live token. The protocol is paying the AMM price impact
to LPs, and the tax swap is too small relative to the pool for an outsider to capture more than
the 0.5% fee.

## 3. Principal / other paths

* **FeeRouter proxy `0x7383B244B416Db16Aa9dd0AB7C296Aa60255B9A2`** holds **23.65 WBNB ≈ $24.8k**.
  `claimDevFee`/`claimPartnerFee` are keyed by `msg.sender`; `registerPartner` is `only core`;
  no caller-chosen beneficiary (pass-2 §C, re-verified). **Not E-U.**
* **OpenFourRegistry/Core `0x912C…Ab94` / `0xebe7…27f3`** — role/owner gated; no public sweep.
* **Tax-token principal** — the tax token's own balance is only the accrued tax (`feeAccumulated`);
  the tax is a transfer tax on traders, not a custody pool. No principal at risk.
* **TokenHelper5** — no user funds; it is a swap/liquidity router called only by the token.

## 4. Verdict

| Category | Amount | Notes |
|---|---:|---|
| **E-U now** | **$0** | no positive-EV sandwich; max triggerable swap $29, max pending $431; all <2% of pool |
| **E-U if a tax token’s swap exceeds 2% of pool depth** | up to `v²/(4Q) − 0.005v − gas` | conditional; monitor |
| **H-O / P** | FeeRouter 23.65 WBNB (dev/partner fees), token tax recipients | not caller-reachable |
| **S** | none | — |

**Confidence: HIGH** that the missing `minOut` is real and permissionlessly triggerable;
**HIGH** that the current live flow is economically unprofitable to sandwich (measured across the
top 40 V9 tax tokens at a named block); **MEDIUM** on persistence — a volume surge or a new tax
token with a large `minDispatch`/shallow pool would re-arm it.

**Re-arm condition:** for any tax token, `feeAccumulated × price / pair_quote_reserve > ~2%`
(or a large `minDispatch` relative to pool depth). At that point, compute the exact reverse
sandwich with the pair reserves and current DEX fee; the missing `minOut` then becomes live MEV.

## 5. Evidence

* `analysis/of_live.json` — 40-token live scan: `feeRate`, `feeAccumulated`, `minDispatch`,
  allocations, pair addresses, block.
* `analysis/of_econ.json` — accrued USD, swap USD, pool depth, swap/pool ratio, above-min flag.
* Source: `Token5.sol` (4Ball, Sourcify full match) `_dispatchFee`/`_swapForQuote`;
  `DividendLaunchToken.sol` (impl `0x5Dcde…`) `_dispatchTax`;
  `ILiquidityHelper.sol` / `ITokenHelper` interfaces have no `minOut`.
* Pass-2 `launchpads.md` §C (FeeRouter closed) and lead #1 (unquantified); this note supplies the
  live quantification and the negative result.
* Pools/router: PancakeSwap V2 factory `0xca143ce32fe78f1f7019d7d551a6402fc5350c73`,
  router `0x10ED43C718714eb63d5aA57B78B54704E256024E`.
