# PT-sUSDe-25SEP2025 — true value vs the stale $0.999 oracle

Read-only analysis on HyperEVM (chain 999). All on-chain reads at **block 49,509,740**
(ts `1792954832` = 2026-10-25 19:00:32 UTC), public RPC `https://rpc.hyperliquid.xyz/evm`.
`now` ≈ 2026-10-25 19:32 UTC.

## TL;DR

| Item | Value |
|---|---|
| **True value of 1 PT-sUSDe-25SEP2025** | **1 USDe ≈ $0.9995–$0.9998** (best estimate **~$0.9996**) |
| Redeemable today? | **YES** — actively redeemed (last redemptions 2026-10-11) |
| Redemption output | **0.79692 sUSDe** per PT (→ sellable ≈ $1.00) |
| Secondary market / AMM | **None live.** Pendle market expired 2025-09-25, swaps disabled, ~0 liquidity |
| HyperLend oracle price for PT | **$0.99904247** (stale feed, 127.4 d old) |
| **Verdict** | Stale oracle is **LOW vs true value by ~0.05–0.07% (~$0.0005–$0.0007/PT)**. No over-borrow exploit. |

---

## 1. PT-sUSDe-25SEP2025 `0xb7379d395F3c83952ad794896205f7E33E358735`

Verified source = `PendlePrincipalToken` v0.8.28 (`src/pt/.../YieldContracts/PendlePrincipalToken.sol`).

```
isExpired()    -> true
expiry()       -> 1758758400   (2025-09-25)
SY()           -> 0xcFAa9540332afA3974BceeD79BDD24D86C5Fd4ee
factory()      -> 0x523eCB8501C14507bCa56d4752dA1991c6176758
name/symbol    -> "PT Ethena sUSDE 25SEP2025" / "PT-sUSDE-25SEP2025"
totalSupply()  -> 322.782252055381245255 PT
```

**Redemption path:** The PT contract itself exposes only `mintByYT`/`burnByYT` (`onlyYT`),
`isExpired`, `SY`, `YT`, `factory`, `expiry` — **no `redeemAfterExpiry`, no pause, no `burn`**.
Post-expiry redemption is done through the **YT** (`redeemPY`) which burns PT via `burnByYT`.
There is **no pause** on the PT (`paused()` reverts — function does not exist).

- `PT.YT()` = `0x92b8dEFe476F0D5ee957533F5B2f509190d12921` (PendleYieldToken, v0.8.28).
- `YT.redeemPY(receiver)` → `_redeemPY`: `PT.burnByYT(this, amount)` then
  `syToUser = SYUtils.assetToSy(pyIndexCurrent, amountPY) = amountPY / index`.
- **A PT holder CAN redeem TODAY** (verified empirically, §5).

## 2. SY `0xcFAa9540332afA3974BceeD79BDD24D86C5Fd4ee` (TransparentUpgradeableProxy, impl `0x43d03031fab845065e9cefe89dd122d63f72011f`)

Impl = `PendleSUSDEL2SY` (`PendleERC20SYUpg`).

```
yieldToken()          -> 0x211Cc4DD073734dA055fbF44a2b4667d5E5fE5d2  (sUSDe)
usde()                -> 0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34  (USDe = accounting asset)
assetInfo()           -> (TOKEN, USDe, 18)
getTokensIn/Out()     -> [sUSDe]
exchangeRate()        -> 1254832790000000000   (1.25483279e18)  == sUSDe/USDe rate
exchangeRateOracle()  -> 0x4e5De6339FC7Ef63c176f9A7e7a8B2aC21744B8D
totalSupply()         -> 424.532066911736314602 SY
balanceOf(sUSDe)      -> 424.532066911736314602 sUSDe   (exactly fully backed, 1 SY = 1 sUSDe)
paused()              -> false
```

`exchangeRate()` delegates to `IPExchangeRateOracle.getExchangeRate()`. It equals Ethena's own
`sUSDe.convertToAssets(1e18)` on Ethereum = `1254842993693936988` (`1.254843e18`) — i.e. the SY rate
is the **sUSDe→USDe exchange rate**, confirming the SY's "asset" is **USDe**.

**sUSDe per PT = 1 / exchangeRate = 1 / 1.25483279 = 0.796918 SY = 0.796918 sUSDe.**

## 3. Current sUSDe / USDe price on HyperEVM

| Source (address / call) | Value | Age |
|---|---|---|
| HyperLend reserve oracle for sUSDe `0x573BB572049ff50156E94823BB99920D406e96F8` (RedStone "sUSDe / USD") `latestRoundData` | **$1.25441703** | ~55 min (fresh) |
| DefiLlama `hyperevm:0x211Cc4…` | $1.25510900 | fresh |
| DefiLlama `ethereum:0x9D39…` (sUSDe) | $1.25437055 | fresh |
| Chainlink **USDe/USD** push feed (Ethereum) `0xa569d910839Ae8865Da8F8e70FfFb0cBA869F961` | $0.99981367 | fresh |
| HyperLend reserve oracle for USDe `0x5d3a1Ff2…` `getAssetPrice` | $0.99966867 | fresh |
| DefiLlama `hyperevm:0x5d3a1Ff2…` (USDe) | $0.99964829 | fresh |

→ **1 PT = 0.796918 sUSDe × $1.25441703 = $0.99952**, equivalently **1 PT = 1.0000 USDe = $0.9996–$0.9998**.
**Accounting asset = USDe** (confirmed by `assetInfo()`, Pendle proSymbol "PT sUSDe (USDe)", and the
adapter wiring in §5/§6).

## 4. Secondary market / Pendle AMM — effectively none

- Pendle market for this PT = **`0xe3765ec51aead35ea0a7f3745c1975a73dca21dc`** (from Pendle API
  `core/v1/999/markets`; `readTokens()` = (SY, PT, YT)).
- `isExpired()` = true (2025-09-25). In `PendleMarketV3`, `swapExactPtForSy`/`swapSyForExactPt`/`mint`
  are `notExpired` → **trading is disabled**; there is no `redeemAfterExpiry` on the market (redemption
  is via the YT/router).
- `_storage()` → totalPt ≈ **10.24 PT**, totalSy ≈ **0.356 SY**, lastLnImpliedRate 0.2856 (last traded
  implied APY ≈ 33%, historical). Pendle API returns `details: null`, `pt.price: null` for this market.
- **No DEX pool** exists for this PT on HyperEVM: DefiLlama `/pools` (15,542 pools) has **no pool**
  referencing `b7379d39` or `e3765ec5`.
- **Conclusion: no live market, no AMM liquidity.** The only exit is post-expiry redemption (§5).

## 5. Empirical redemption check (proves redeemability)

Etherscan V2 `chainid=999 tokentx` for the PT + receipt decode of tx
`0x678b7b639bdd537f641aad74178dbdd75714693b828d8156097a2bca46ba6741` (block **48,342,068**,
ts `1791806248` = 2026-10-11):

```
PT   0xe35ad77e… -> YT 0x92b8dEFe…   70.72755 PT
PT   YT          -> 0x0 (burn)       70.72755 PT
SY   0x92b8dEFe… -> SY contract       56.462471 SY
SY   contract    -> 0x0 (burn)        56.462471 SY
sUSDe SY contract -> 0xe35ad77e…      56.462471 sUSDe   <-- user's payout
```

→ **56.462471 sUSDe for 70.72755 PT = 0.79831 sUSDe/PT** (index at that block ≈ 1.25265). Other recent
redemptions: 40.5805 PT (block 48,234,415, ts `1791700360`), 2.7827 PT, 1.2044 PT, 3.1637 PT.
**Redemption is live and functioning today.** The YT holds `syReserve = 310.025 SY` (its SY balance),
enough to cover all outstanding PT (322.78 PT ÷ 1.2548 ≈ 257.3 SY).

## 6. The stale feed — what it actually is

```
PendlePriceCapAdapter 0x8514D528275025AD9bE6019e6e189DFeF1Db6c5e   (HyperLend reserve oracle source for PT)
  PENDLE_PRINCIPAL_TOKEN()     -> 0xb7379d395F3c83952ad794896205f7E33E358735
  ASSET_TO_USD_AGGREGATOR()    -> 0x6926d2C4f5aecD82192A9faf7B8e09A1d103bf23 (SingleFeedProvider)
  description()                -> "PT Capped sUSDe/USD linear discount 25SEP2025"
  MATURITY()                   -> 1758758400
  getCurrentDiscount()         -> 0        (maturity passed => PT_price = asset price, no cap)
  latestAnswer()               -> 99904247  ($0.99904247)
```

Since maturity has passed, `PT_price = ASSET_TO_USD_AGGREGATOR.latestAnswer()` — the adapter simply
returns the **USDe/USD** feed value.

```
SingleFeedProvider 0x6926d2C4f5aecD82192A9faf7B8e09A1d103bf23
  feedId()          -> 0x000379477abdca006db92300211242ba44479369a15be0ad8d59cabe00e63074
  source()          -> 0x2F81b130ce13337f4eAc9e205E5eA710b492dbA4  (ChainlinkConsumer)
  latestAnswer()    -> 99904247  |  latestTimestamp() -> 1781949599 (2026-06-20 09:59:59 UTC)

ChainlinkConsumer 0x2F81b130ce13337f4eAc9e205E5eA710b492dbA4
  lastDecodedPrice[feedId]     -> 999042471240489700 (0.9990424712404897, 18 dp)
  lastDecodedTimestamp[feedId] -> 1781949599
```

**Feed identity (Chainlink Data Streams discovery API, no auth needed):**
`GET https://api.dataengine.chain.link/api/v1/discovery`
→ feedId `0x000379477abdca…e63074` = **`USDe / USD` DexPrice (Crypto-DEX), status "live"**,
name `Updated-USDE/USD-Streams-DexPrice`, created 2024-07-16. So the "asset" priced is **USDe**, not
sUSDe. (The `sUSDe/USD` stream exists separately; it is not the one used here.)

**Staleness:** last on-chain push `1781949599` (2026-06-20) vs now → **127.4 days stale**.
The stream is live in Chainlink's catalogue; the value is simply frozen because nobody has called
`ChainlinkConsumer.verifyReport()` with a fresh signed USDe report for 127 days. (Current USDe/USD
Data-Streams value could **not** be fetched: `GET /api/v1/reports/latest` requires HMAC API-key auth,
HTTP 400 without it. Substituted fresh USDe/USD push feeds + DefiLlama, §3.)

## 7. Verdict — is $0.99904247 HIGH or LOW?

1 PT = 1 USDe. Fresh USDe ≈ **$0.99967** (HyperLend's own USDe oracle) / $0.99981 (Chainlink ETH).
Fresh sUSDe-based value = **$0.99952**. So the true PT value is **~$0.9995–$0.9998**.

| Comparison | Delta |
|---|---|
| Oracle $0.99904247 vs true ~$0.99952 (sUSDe path) | **−0.048%** (oracle LOW) |
| Oracle $0.99904247 vs true ~$0.99967 (USDe oracle) | **−0.063%** (oracle LOW) |

**The stale $0.99904247 oracle is LOW (conservative) vs the true PT value by ~0.05–0.07%
(≈ $0.0005–$0.0007 per PT).** It does **not** over-state the collateral. Confidence: **high** —
confirmed by (a) the adapter wiring, (b) the SY rate = Ethena's sUSDe/USDe rate, (c) a decoded
on-chain redemption paying 0.7983 sUSDe/PT.

## 8. Implication for a 75%-LTV e-mode (cat 3) collateral borrow

e-mode category 3 ("PT-sUSDe / stablecoins"): LTV **75%**, liq. threshold **84%**, bonus **10.5%**;
PT is the sole collateral, borrowable = {wstHYPE, UBTC, USDe}. An attacker supplying 1 PT gets at most
`0.99904247 × 0.75 = $0.74928` of borrow power, against collateral truly worth ~$0.9996. Because the
oracle is **below** true value, the attacker's equity is *not* inflated — they get ~0.06% **less**
borrow power than fair, so **there is no profitable "supply-at-stale-price and over-borrow" attack**;
the staleness errs on the safe side today. The residual risks are (i) the *latent* one: the feed is
frozen at $0.99904247, so if USDe were to depeg **below** $0.99904 the frozen oracle would begin to
**over-value** the PT by the depeg gap, enabling over-borrow/default (currently USDe $0.99967 >
$0.99904, so not active); and (ii) exit/liquidity: the PT has no secondary market, so a liquidated
borrower must redeem via Pendle (works, but yields **sUSDe**, whose direct HyperEVM DEX liquidity is
thin — DefiLlama indexes no sUSDe pool on HyperEVM), implying some slippage/illiquidity on
liquidation. Absolute exposure is negligible anyway: the PT reserve aToken holds only **1.451 PT
(~$1.45)** supplied, with a **1e27 (1e9-token) supply cap**, so even a full mispricing is immaterial.

## Addresses / calls index

| Role | Address |
|---|---|
| PT-sUSDe-25SEP2025 | `0xb7379d395F3c83952ad794896205f7E33E358735` |
| YT-sUSDE-25SEP2025 | `0x92b8dEFe476F0D5ee957533F5B2f509190d12921` |
| SY-sUSDE (proxy / impl) | `0xcFAa9540332afA3974BceeD79BDD24D86C5Fd4ee` / `0x43d03031fab845065e9cefe89dd122d63f72011f` |
| SY exchangeRate oracle | `0x4e5De6339FC7Ef63c176f9A7e7a8B2aC21744B8D` |
| Pendle market (expired) | `0xe3765ec51aead35ea0a7f3745c1975a73dca21dc` |
| Pendle YC factory | `0x523eCB8501C14507bCa56d4752dA1991c6176758` |
| sUSDe (yield token) | `0x211Cc4DD073734dA055fbF44a2b4667d5E5fE5d2` |
| USDe (accounting asset) | `0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34` |
| PendlePriceCapAdapter | `0x8514D528275025AD9bE6019e6e189DFeF1Db6c5e` |
| SingleFeedProvider | `0x6926d2C4f5aecD82192A9faf7B8e09A1d103bf23` |
| ChainlinkConsumer | `0x2F81b130ce13337f4eAc9e205E5eA710b492dbA4` |
| sUSDe price feed (RedStone) | `0x573BB572049ff50156E94823BB99920D406e96F8` |
| HyperLend Pool / AaveOracle | `0x00A89d7a5A02160f20150EbEA7a2b5E4879A1A8b` / `0xC9Fb4fbE842d57EAc1dF3e641a281827493A630e` |
| PT aToken | `0xec2767311eBf57C02de9866fDACdfefAc4AdAe6B` |
