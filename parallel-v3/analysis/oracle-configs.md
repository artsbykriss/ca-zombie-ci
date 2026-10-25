# Parallel V3 — oracle configuration & live values

Block **26,271,789** (Ethereum, ts 1792956311 = 2026-10-25 ~20:05 UTC), keyless `ethereum-rpc.publicnode.com`.
Diamond `0x6efeDDF9269c3683Ba516cb0e2124FE335F262a2`. Raw dump: `live-state-dump.txt`, `../ci-out/live-state.json`.

`OracleReadType`: 0=CHAINLINK_FEEDS, 1=EXTERNAL, 2=NO_ORACLE, 3=STABLE, 4=WSTETH, 5=CBETH, 6=RETH,
7=SFRXETH, 8=MAX, 9=MORPHO_ORACLE. `OracleQuoteType`: 0=UNIT, 1=TARGET.

## Per-collateral `getOracle()` decode

| collateral | symbol | oracleType | targetType | oracleData | targetData | deviation (hyperparams) |
|---|---|---|---|---|---|---|
| `0xCAcd6fd266aF91b8AeD52aCCc382b4e165586E29` | frxUSD | **0 CHAINLINK_FEEDS** | **3 STABLE** | `(feed=[0x9B4a96210bc8D9D55b1908B465D8B0de68B7fF83], stalePeriod=90000, multiplied=1, decimals=8, quote=UNIT)` | empty | 5e14 / 5e14 (0.05 %) |
| `0xcf62F905562626CfcDD2261162a51fd02Fc9c5b6` | sfrxUSD | **9 MORPHO_ORACLE** | **8 MAX** | `(0x0Cb7dEE76aA916a3666f50b044f16051C325b3e2, normalizationFactor=1e6)` | `1215352748153780000` (1.2153527) | 5e14 / 5e14 |
| `0x4c9EDD5852cd905f086C759E8383e09bff1E68B3` | USDe | **0 CHAINLINK_FEEDS** | **3 STABLE** | `(feed=[0xa569d910839Ae8865Da8F8e70FfFb0cBA869F961], stalePeriod=90000, multiplied=1, decimals=8, quote=UNIT)` | empty | 5e14 / 5e14 |
| `0x9D39A5DE30e57443BfF2A8307A4256c8797A3497` | sUSDe | **0 CHAINLINK_FEEDS** | **8 MAX** | `(feed=[0xFF3BC18cCBd5999CE63E788A1c250a88626aD099], stalePeriod=90000, multiplied=1, decimals=8, quote=UNIT)` | `1252264000000000000` (1.252264) | 5e14 / 5e14 |

## `getOracleValues()` (mint, burn, ratio, minRatio, redemption) — all 1e18

| collateral | mint | burn | ratio | minRatio | redemption |
|---|---|---|---|---|---|
| frxUSD | 1.0000000 | 1.0000000 | 1.0 | 1.0 | 0.99989692 |
| sfrxUSD | **1.2153527** (= MAX target) | 1.217082568 | 1.0 | 1.0 | 1.217082568 |
| USDe | 1.0000000 | 1.0000000 | 1.0 | 1.0 | 0.99981367 |
| sUSDe | **1.2522640** (= MAX target) | 1.254426110 | 1.0 | 1.0 | 1.254426110 |

> Note mint for the **MAX** collaterals equals the stored target (strictly below the raw oracle):
> `readMint` returns `min(oracleValue, targetPrice)`. For STABLE collaterals the target is `$1`.

## Chainlink feeds (freshness at the fork block)

| feed | description | answer (8dp) | updatedAt | age |
|---|---|---|---|---|
| `0x9B4a96210bc8D9D55b1908B465D8B0de68B7fF83` | frxUSD / USD | 99989692 ($0.99989692) | 1792941697 | 14,614 s ≈ 4.06 h |
| `0xa569d910839Ae8865Da8F8e70FfFb0cBA869F961` | USDe / USD | 99981367 ($0.99981367) | 1792929831 | 26,480 s ≈ 7.36 h |
| `0xFF3BC18cCBd5999CE63E788A1c250a88626aD099` | sUSDe / USD | 125442611 ($1.25442611) | 1792875253 | 81,058 s ≈ 22.52 h |

`stalePeriod` = **90,000 s (25 h)** for every Chainlink leg; `LibOracle.readChainlinkFeed` reverts
`InvalidChainlinkRate()` when `block.timestamp - updatedAt > stalePeriod`. All three feeds are **fresh**.

## sfrxUSD Morpho oracle — `0x0Cb7dEE76aA916a3666f50b044f16051C325b3e2`

`MorphoChainlinkOracleV2` (verified), immutables:

| constant | value |
|---|---|
| `BASE_VAULT()` | `0xcf62F905562626CfcDD2261162a51fd02Fc9c5b6` (sfrxUSD) |
| `BASE_VAULT_CONVERSION_SAMPLE()` | `1e16` |
| `BASE_FEED_1()` | `0x9B4a96210bc8D9D55b1908B465D8B0de68B7fF83` (frxUSD/USD) |
| `BASE_FEED_2()` | `0` |
| `QUOTE_VAULT()` / `QUOTE_FEED_1()` | `0` / `0` |
| `SCALE_FACTOR()` | `1` |
| `price()` | `1217082956134413888411496` = 1.21708295 (1e24; /1e6 = 1.21708295) |

`price() = convertToAssets(1e16 sfrxUSD) × frxUSD/USD`. **sfrxUSD is a `LinearRewardsErc4626`**
(impl `0xaad4a1d92053a62ce7a787641d8b4e5883e96700`): `totalAssets() = pricePerShare × totalSupply / 1e18`
with `pricePerShare = pricePerShareStored · e^(ppsIncPerSecond·elapsed)` — i.e. **synthetic, time-based
rewards**, *not* `asset.balanceOf(this)`. `deposit/mint/withdraw/redeem` all `revert MintRedeemsDisabled()`.
At the fork block the vault holds **0 frxUSD** while `totalAssets = 4.1536e25` → the Edel/4626
donation primitive **does not apply** (proof: `poc/test/ParallelV3.t.sol::test_D`).

## Mint / burn / redemption formulas (from the verified facets)

- `Swapper._quoteMintExactInput`: `amountOut = readMint(config) × amountIn / 1e18`, then fees.
  `LibOracle.readMint` = `min(oracleValue, targetPrice)`.
- `Swapper._quoteBurnExactInput`: `amountOut = amountIn × ratio / oracleValue`; `readBurn` sets
  `oracleValue = targetPrice` when the oracle is within `burnRatioDeviation` of (or below) the target, so
  the effective burn price is `max(oracleValue, targetPrice)` — protocol-favourable.
- `Redeemer._quoteRedemptionCurve`: for `collatRatio ≥ 1`,
  `out_i = amountBurnt · balance_i · yRedemptionCurve[last] / (stablecoinsIssued · collatRatio)` with
  `yRedemptionCurve[last] = 0.995`. Summed over the basket this returns **0.995×** the burn value at
  raw-oracle prices (proof: `test_G`).
- `LibGetters.getCollateralRatio` values reserves at **raw** `readRedemption` prices (no target cap);
  observed `collatRatio = 1.058154782`, `stablecoinsIssued = 240,554.999… USDp`.

## Permissioning

| function | gate |
|---|---|
| `Swapper.swapExactInput/Output(+Permit/+Auth)` | **none** (only `isMintLive`/`isBurnLive`) |
| `Redeemer.redeem / redeemWithForfeit / redeemWithAuthorization` | **none** (only `isRedemptionLive`) |
| `SettersGovernor.updateOracle` | `isSellerTrusted[msg.sender]` |
| `setOracle / addCollateral / adjustStablecoins / setFees / setStablecoinCap / pause / …` | `restricted` (OZ AccessManager) |
| `Surplus.processSurplus / release` | `restricted` |
| `RewardHandler.sellRewards` | trusted seller / governance |
| `TokenP.mint` | `restricted` (only the Swapper) |
