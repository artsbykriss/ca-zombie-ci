# ETH lane — Zenji sibling hunt (Ethereum mainnet, chain 1)

**Status:** read-only research. No transaction was signed or broadcast; no mainnet state was modified. All on-chain values are point-in-time `eth_call`/`eth_getCode` reads at the stated block. Nothing here is an instruction to attack a live protocol.
**Date:** 2026-11-10 · **Lane:** Ethereum only · **Incident under study:** Zenji leveraged LlamaLend vaults drained 2026-11-08 (~$4.95k net) via permissionless `rebalance()` that valued the strategy and LTV from the same crvUSD/USDT StableNG pool it then traded against.

**Bottom line: 15 candidate contracts assessed (+3 class controls). 0 pass all three tests. The exact-code siblings that exist on Ethereum (two additional Zenji `pmUSD/crvUSD` vaults) are live and permissionless but hold $0. The strongest funded live near-miss is Fluid Lite ETH v2 (iETHv2, $148.9M), which fails only test (a): every rebalance path is `onlyRebalancer`.**

---

## 1. The recipe, restated as three tests

The Zenji primitive is the conjunction of:

| Test | Property |
|---|---|
| **a** | A **permissionless** keeper entry point (`rebalance()`/equivalent) that moves the protocol's own leveraged position and/or trades protocol funds — not a user-supplied `minOut` swap of the user's own funds. |
| **b** | The vault/LTV **valuation** of its LP/strategy comes from a pool the caller can trade in the same transaction (spot/virtual-price/`calc_withdraw_one_coin`), so one skew reprices the position. |
| **c** | The keeper path's **slippage floor (`minOut`) is derived from that same pool** (or is zero), so the floor does not protect against the skew. |

All three must hold for the flash-borrow → skew → keeper → unskew capture.

Method: enumerate by verified-contract name (Blockscout `/api/v2/search`), protocol front-end address registries (YieldBasis bundle, DefiLlama adapters), and DefiLlama yields/protocol metadata. Every address used is verified with `eth_getCode` + Etherscan V2 `getsourcecode`; every role/valuation claim is read via `eth_call` at one pinned block; every keeper path is probed by `eth_call --from 0x…dEaD` to separate *auth* reverts from *state* reverts.

**Snapshot block: 26,381,250** (later reads at 26,381,304 differ only where stated). Prices: DefiLlama coins API at 2026-11-10 ~02:1x UTC — WETH $2,124.72, stETH ≈ ETH, WBTC $74,943.43, cbBTC $75,005.92, tBTC $74,806.92, crvUSD $0.99587, USDC $1.00.

---

## 2. Results

| # | Protocol / contract | Address | Keeper function probed | a | b | c | Live USD | Verdict |
|---|---|---|---:|---|---:|---:|---|---|
| C1 | YieldBasis — yb-cbBTC v3 market (LEVAMM + LT) | `0x49F51d7e…B196` / `0x722FC364…29F9` | `distribute_borrower_fees()`; `exchange()` | ✗ | ✗ | ~ | **$29.47M** (market); $93.08M protocol | Not a sibling: no rebalance; valuation is a bounded `price_scale`/self-invariant, and the one permissionless pool trade moves ≈$1.8k of accrued interest, donated back to the pool (mostly the vault's own LP). |
| C2 | Fluid Lite ETH v2 (**iETHv2**, ex-Instadapp Lite) | `0xA0D3707c…Be78` | `rebalanceFromWstETHToWeETH` / `updateExchangePrice` | ✗ | ~ | ✗ | **$148.9M** (70,077.77 stETH) | Not live-exploitable: all keeper paths `onlyRebalancer`; exchange price is a stored checkpoint, not live DEX spot. |
| C3 | Fluid Lite USD v2 | `0x273DA948…9012` | none (pull/push funds) | ✗ | ✗ | ✗ | **$40.46M** (40,470,423 USDC) | No keeper; `pullFunds/pushFunds/updateExchangePrice` are `onlyStrategyHandler`; NAV = fixed-rate accrual over fUSDC. |
| C4 | Instadapp Lite v1 iETH | `0xc383a383…d019` | `leverage()` / `deleverage()` | ~ | ✗ | ✗ | **$1.8k** (0.855 ETH net) | Permissionless 1:1 stETH↔WETH peg swaps with Aave; `rebalanceOne/Two` are `onlyRebalancer`. No pool valuation. Dust. |
| C5 | Instadapp Lite v1 iUSDC | `0xc8871267…57F8` | `leverage()` / `deleverage()` | ~ | ✗ | ✗ | **≈$0** (NAV ≈ 9e-6 USDC) | Same code family as C4; empty. |
| C6 | Gearbox v3 — wstETH Credit Manager | `0x00689539…3EE5` (facade `0xae72924d…6Ea2`) | `liquidateCreditAccount` | ✓ | ✗ | ✗ | **$7.46M** debt in this market; $19.38M protocol | Liquidations are permissionless, but prices are Chainlink feeds with staleness checks; no vault-level rebalance trades against a pool. |
| C7 | Curvance | — | — | ? | ? | ? | — | **Unresolved on Ethereum.** DefiLlama lists Curvance TVL on **Monad only** ($137.2M); the only Ethereum contract surfaced by name search is `CurvanceDAOBonding` (no market/keeper). |
| C8 | Zenji `pmUSD/crvUSD` WBTC vault | `0xB415bce7…c31F` | `rebalance()` | ✓ | ✓ | ✓ | **$0** | Exact Zenji sibling (`ZenjiWbtcLlamaStakeDao`), permissionless `rebalance()`, **empty** (supply 0). |
| C9 | Zenji `pmUSD/crvUSD` wstETH vault | `0x45bBa5E1…1595` | `rebalance()` | ✓ | ✓ | ✓ | **$0** | Same, `ZenjiWstEthLlamaStakeDao`, empty. |
| C10 | ZenjiRebalanceKeeper | `0x4fD5DD13…9495` | `performUpkeep(bytes)` | ✓ | n/a | n/a | **$0** | Chainlink-Automation receiver; calls the already-permissionless `vault.rebalance()`; holds no funds, no price logic. |
| C11 | Curve `LlamaLendLeverageZap` | `0xE1834AF5…4D4E` | none (`callback_deposit/repay`) | ✗ | ✗ | ✗ | **$0** | Stateless leverage zap (Curve.Finance); no rebalance, no keeper; ETH 0, crvUSD 0. |
| C12 | "LlamaLend and crvUSD leverage zap (1inch)" | `0xe61d72cb…005E` | none | ✗ | ✗ | ✗ | **$0** | Stateless zap (Volume Finance); ETH 0, crvUSD 0. |
| C13 | `LlamaLendLevCreate` / `LlamaLendBoost` (DeFi Saver actions) | `0x534b704a…105E` / `0xA21c1cE7…7D85` | none (`executeAction`) | ✗ | ✗ | ✗ | **$0** | Per-user DSProxy action executors; no pooled funds; ETH 0, crvUSD 0. |
| C14 | Zunami `LlamalendCrv{,Usd}StakeDaoERC4626Strat` | `0xF3558b52…6ab73` / `0x8dfcD34b…1Ed47` | none | ✗ | ✗ | ✗ | **$0** | `totalHoldings()=0`; no rebalance/harvest keeper. |
| C15 | Stake DAO CRV LlamaLend Recovery Vault | `0xF221D835…2998` | `claim()` only | ✗ | ✗ | ✗ | 182,848.5 LP (unpriced) | ERC4626 reward wrapper over the recovery StableSwap LP; no leverage, no rebalance, no swap. |

Controls (class checks, one line each): **Yearn v3** — `process_report()` requires `REPORTING_MANAGER` (source line 1644 of the verified `Savings crvUSD` vault) and vaults have no debt against retail LP; **StakeDAO CLM** — permissionless `harvest` exists but the strategy holds its own LP with no borrow/LTV; **Beefy** — permissionless `harvest`, no debt and no LTV. None can be pushed into the Zenji pattern.

---

## 3. C1 — YieldBasis (the largest live levered Curve-LP protocol)

**Contracts (verified, block 26,381,250):**
- Factory `0x370a449FeBb9411c95bf897021377fe0B7D100c0` — `market_count() = 11`, `LEVERAGE() = 2e18`, `min_admin_fee() = 1e17`, `admin() = 0xb8BA33CD1Ccb091a8468572950bD3669723FA5C6`, `STABLECOIN() = crvUSD 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E`, `amm_impl() = 0x6031ef0a2d380423932e043d8187b52e3f82c84e`.
- 11 markets: `markets(i) = (asset, curvePool, LEVAMM, LT, priceOracle, virtualPool, staker)`. Latest (v3) markets: WBTC `LT 0x651D4b81…5BAa`, cbBTC `LT 0x722FC364…29F9`, tBTC `LT 0x771F7290…23Ec`, WETH `LT 0x2B9c9f3B…3cEa`.
- Leveraged-token `LT` is Vyper 0.4.3 (`0x722FC364…29F9`, 23,420 B runtime) holding the Curve LP through a per-market `LEVAMM` (blueprint clone of `amm_impl`).

**Test (a): no rebalance.** `LT`'s 39 external functions contain `deposit`, `withdraw`, `emergency_withdraw`, `distribute_borrower_fees`, `withdraw_admin_fees`, `set_rate`, `set_amm`, `set_killed` — **no `rebalance`, no `delever`, no `harvest`**. Debt is fixed at 2× by construction: `LEVAMM.get_x0()` enforces `MIN_SAFE_DEBT..MAX_SAFE_DEBT` at deposit and `exchange()` asserts the invariant cannot decrease (`assert self.get_x0(...) >= x0, "Bad final state"`, `src_LEVAMM_0x6031ef.sol:999`). The position is only moved by user `deposit`/`withdraw` or by `exchange()` (which is a public AMM swap with a **caller-supplied** `min_out`, i.e. the caller's own funds, not a keeper).

The only permissionless protocol-initiated trade is `LT.distribute_borrower_fees()` (`src_LT_0x722fc3.sol:1501-1514`): it collects accrued interest and calls `CRYPTOPOOL.add_liquidity([amount,0], min_amount, empty(address), True)` where `min_amount = (1e18-1%)*amount / CRYPTOPOOL.lp_price()`. **This does read `lp_price()` from the same pool (test c ≈ yes)**, but it donates only accrued borrower interest. Measured `accumulated_interest()` across all 11 markets at block 26,381,250: **$0.41–$1,311.53, total ≈ $1,809**; a `distribute_borrower_fees()` call from `0x…dEaD` on the largest market **succeeded** (permissionless, `0x` return), proving the path but also that the value at stake is sub-threshold and the donation accrues pro-rata to the pool's LPs — of which the vault's own AMM is the dominant one.

**Test (b): valuation is not spot.** `LT.pricePerShare()`/`_calculate_values()` values the position from `_price_oracle() = CRYPTOPOOL.price_scale() * agg.price() / 1e18` plus `LEVAMM.get_x0()` (the AMM's own constant-leverage invariant). In the YB `Twocrypto` pool (`0x313698667d7FDD6789a9BC70821309ff891E729A`, 23,498 B), `tweak_price()` recomputes `price_oracle` as an **EMA with `ma_time`** and moves `price_scale` by a bounded `adjustment_step` per operation; the spot price (`last_prices`) is explicitly documented as *"unsafe and can be manipulated"* (`src_Twocrypto_0x313698.sol:1150-1165`) and is **not** what `price_scale()` returns. A one-transaction swap therefore cannot reprice the vault by more than the per-op adjustment step.

**TVL / funds:** protocol equity = Σ market `LEVAMM.value_oracle().value` = **$93.08M** at crvUSD $0.99587 (block 26,381,250). Largest markets: cbBTC v3 $29.47M, WBTC v3 $22.10M, tBTC v3 $17.71M, WETH v3 $13.86M, cbBTC v2 $8.86M. Funds sit as Curve LP inside each LEVAMM plus its allocated crvUSD (`balanceOf(LEVAMM)` ranges from dust to tens of millions; e.g. m7 LEVAMM held 77.85M crvUSD at the snapshot). The factory `flash()` lender is crvUSD `0x26de7861…9ee1` (0-fee ERC-3156).

**Verdict:** **not a Zenji sibling.** Missing (a); (b) fails on inspection of the pool math; (c) exists only in a sub-$2k fee-donation path that pays the pool (including the vault) rather than the caller.

---

## 4. C2–C5 — Fluid Lite (ex-Instadapp Lite)

**C2 — iETHv2 `0xA0D3707c569ff8C87FA923d3823eC5D81c98Be78`** (custom "infinite proxy": per-selector implementations, `getSigsImplementation(bytes4)`), symbol `iETHv2`, asset stETH `0xae7ab9…7fE84`, `totalAssets() = 70,077.774509 stETH` = **$148.9M** at $2,124.72, `exchangePrice() = 1.228447e18`, admin `0x2386DC45AdDed673317eF068992F19421B481F4c`, `vaultDSA() = 0x9600A48e…2745`.

- `rebalanceFromWstETHToWeETH(uint256,uint256,uint256)` / `rebalanceFromWeETHToWstETH(...)` → impl `0x44feDC1F420ffB852e08de5087d7FA87fB1717E5` (`FluidAaveV3WeETHRebalancerModule`), **`nonReentrant onlyRebalancer`** at `src…main.sol:888` and `:969`.
- `swapWstETHToWeETH(...)` / `swapWeETHToWstETH(...)` → impl `0xF95105c0…0c8d` (`AaveV3WstETHWeETHSwapModule`), **`onlyRebalancer`** at lines 2869-2875 / 2976-2982.
- `updateExchangePrice()` → impl `0x47503517…3530` (`RebalancerModule`), **`onlyRebalancer`** at line 464-467.
- `onlyRebalancer` = `isRebalancer[msg.sender] || IProxy(this).getAdmin() == msg.sender`, else `Helpers__NotRebalancer()` (`fluid_rebal_0x475035.sol:1237-1250`).
- Probes from `0x…dEaD`: `rebalanceFromWstETHToWeETH(1,1,0)` and `updateExchangePrice()` both revert **`0x78fb3fe5` = `Helpers__NotRebalancer()`**; `isRebalancer(0x…dEaD) = false`. `deposit(1,dead)` reverts `ALLOWANCE_EXCEEDED` (funds, not auth), i.e. user entry is open but the keeper is not.
- Valuation: `totalAssets() = exchangePrice * totalSupply / 1e18` (`UserModule`, `fluid_user_0xc1bddf.sol:2882`) where `exchangePrice` is a **stored checkpoint** (weekly reconciliation via the rebalancer). Strategy ratios are read from Aave/Compound/Fluid (`getRatioAaveV3Lido`, `getRatioCompoundV3`, `getRatioFluidDex`, …); the vault does hold a Fluid DEX weETH/wstETH NFT, so its NAV is *partly* DEX-sensitive, but the only code that can act on that NAV is `onlyRebalancer`.

**Verdict:** fails (a) alone; a single role separates $148.9M from the recipe. Worth monitoring as latent risk if the rebalancer role is ever made permissionless or a rebalancer key is compromised.

**C3 — Fluid Lite USD v2 `0x273DA948ACa9261043fbdb2a857BC255ECC29012`** (`FluidLiteVaultProxy`, impl `0xe16ccc91…9743`), **40,470,423 USDC** ($40.46M). Functions: `deposit/redeem`, `updateExchangePrice`, `updateConfig`, `pullFunds`, `pushFunds`, `deployIdleUSDC`, `updateRole/updateOwner/upgradeToAndCall`. `updateExchangePrice` (line 737), `pullFunds` (801), `pushFunds` (824), `deployIdleUSDC` are all **`onlyStrategyHandler`**; NAV = `getEffectiveExchangePrice()` = fixed-rate accrual over fUSDC `0x9Fb7b447…1B33` (a Fluid lending position, not a DEX pool). No keeper, no swap.

**C4/C5 — legacy v1 `InstaVault`** `0xc383a383…d019` (iETH, impl `0x79a043f6…fdfc`) and `0xc8871267…57F8` (iUSDC, infinite proxy). `leverage(uint256)` (`main.sol:544`) and `deleverage(uint256)` (`:611`) are **permissionless** but are 1:1 stETH↔WETH swaps against Aave with a fee and ratio guards (no DEX, no oracle-derived minOut); `rebalanceOne/rebalanceTwo` are **`onlyRebalancer`** (`:793-820`). Live value: iETH `totalSupply 54.603e18`, `getCurrentExchangePrice = 1.5664e16` → NAV **0.855 ETH (~$1.8k)** (`netAssets()` returns 80.55 ETH gross, i.e. collateral incl. debt); iUSDC `totalSupply 4,014.318e6`, `getCurrentExchangePrice = 2301` (≈1e18 scale) → **NAV ≈ 9e-6 USDC**. Both are dust.

---

## 5. C6 — Gearbox v3

- Ethereum `AddressProviderV3 = 0x9ea7b04da02a5373317d745c1571c84aad03321d`; DefiLlama compressor `0x81cb9eA2d59414Ab13ec0567EFB09767Ddbe897a` returns **74 credit managers**.
- Active wstETH CM `0x006895396432a631b73EAA6CAd90911eAe0d3EE5`: `version() = 310`, `underlying() = wstETH 0x7f39…2Ca0`, `pool() = 0xA9d17f6D3285208280a1Fd9B94479c62e0AABa64`, `creditFacade() = 0xae72924d7Dc51E4f566b490637419beB0bFb6Ea2`, `priceOracle() = 0x6C10935f56Ec2dcDd36b633d4cFeB1af02083380`.
- `CreditFacadeV3.liquidateCreditAccount` is `public … whenNotPausedOrEmergency nonReentrant` with **no caller restriction** (`gb_facade.sol:308`); `partiallyLiquidateCreditAccount` likewise. `closeCreditAccount` is `creditAccountOwnerOnly(creditAccount)` (`:257`), and there is no `deleverage()` in the facade. A random-address `liquidateCreditAccount(0x…dEaD, 0x…dEaD, [])` reverts (no account / not liquidatable), not with an auth error.
- Pricing: `PriceOracleV3.getPrice()` reads **Chainlink-interface feeds with a staleness period** (`gb_oracle.sol:28, 86, 1922-1950`). WETH feed `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419` (Chainlink ETH/USD, staleness 4500 s); wstETH feed `0x587660D2…3Dc9` (skipCheck = true). Liquidation discounts are oracle-derived, not pool spot.
- Live debt: pool `totalBorrowed = 2,809.421 wstETH` (~$7.46M), `availableLiquidity = 711.442 wstETH`; `paused() = false`. Protocol Ethereum TVL $19.38M (DefiLlama).

**Verdict:** permissionless liquidation (a) with oracle pricing (b ✗) and no minOut-from-pool keeper (c ✗) — the opposite of the Zenji conjunction. Liquidators are exposed to oracle/venue divergence, not to a vault rebalance that misprices its own LP.

---

## 6. C8/C9 — the real Zenji siblings (empty)

A Blockscout verified-name search for `LlamaLend` surfaced **four** Zenji vault tokens: the two 2026-11-08 incident vaults (not touched here, per instruction) and two more that the campaign had not registered:

| Contract | Address | symbol | totalSupply | totalAssets |
|---|---|---|---:|---:|
| `ZenjiWbtcLlamaStakeDao` | `0xB415bce7d24ef95405006e8A1a9381119F7fc31F` | `zenWBTC-LL-pmUSD` | **0** | **0** |
| `ZenjiWstEthLlamaStakeDao` | `0x45bBa5E1A014f9944fC077F5A0a3D4106fA31595` | `zenWstETH-LL-pmUSD` | **0** | **0** |

Both are the **same code family** (`Zenji` Vyper/Solidity vault, 110-function implementation: `rebalance()`, `harvestYield()`, `accrueYieldFees()`, `strategyToDebtRatio()`, `loanManager()`, `yieldStrategy()`, `swapper()`, `emergencyMode()`, `targetLtv()`), targeting the pmUSD/crvUSD LlamaLend markets (`loanManager 0xE0a0975E…65Cb` / `0x9D44BDF5…0c00`; strategy `0x4D177251…CEFC` / `0x78B2D441…2AF3`; swapper `0xf5075272…a86a` / `0x634842f3…8Bb1`). Both have `emergencyMode = false`, `depositsPaused = false`, `targetLtv = 0.65`, `rebalanceBountyRate = 0.20`, `maxSlippage = 1%`.

Permissionless proof (`eth_call --from 0x…dEaD`, block 26,381,250): `rebalance()` on each reverts **`0x5121f343` = `RebalanceNotNeeded()`** — the exact first check in `Zenji.rebalance()` (`if (!loanManager.loanExists()) revert RebalanceNotNeeded();`, source line 595), i.e. the call passed all auth and failed only because the vault has no loan. `harvestYield()` from the same address returns success (`0x`). So the two remaining vaults **do satisfy (a), and by code identity (b)/(c)** — but there is nothing in them.

This is the cleanest possible result for the lane: the recipe is alive in deployed code on Ethereum, and the only instances are empty. (The drained pair held $19 + $137 at last check per `ca3/README.md` §5.1; not re-read here.)

---

## 7. C11–C15 — LlamaLend zaps, DFS actions, Zunami, StakeDAO recovery

- **Curve `LlamaLendLeverageZap` `0xE1834AF57923059B4306B468013262D73F344D4E`** — Vyper 0.3.10, "Creates leverage on LlamaLend via whitelisted Aggregator Routers"; external surface is `FACTORY`, `admin`, `callback_deposit`, `callback_repay`, `is_approved_exchange`, `max_borrowable`, `set_exchange`. No `rebalance`, no keeper; the callbacks run inside the controller's `create_loan_extended` and the swap is user-supplied via a whitelisted router. ETH 0, crvUSD 0.
- **Volume Finance 1inch zap `0xe61d72cb6d30Bc21A623875f160682E6C17B005E`** — same shape, `FACTORIES`, `ROUTER_1INCH`, `callback_deposit/repay`; ETH 0, crvUSD 0.
- **DeFi Saver `LlamaLendLevCreate 0x534b704a…105E` / `LlamaLendBoost 0xA21c1cE7…7D85`** — `executeAction`/`parseInputs`/`registry`/`logger`/`adminVault`/`withdrawStuckFunds`; per-user DSProxy actions; ETH 0, crvUSD 0; no pooled funds and no keeper.
- **Zunami `LlamalendCrvUsdStakeDaoERC4626Strat 0x8dfcD34b…1Ed47` / `LlamalendCrvStakeDaoERC4626Strat 0xF3558b52…6ab73`** — `totalHoldings() = 0`, `depositedAssets() = 0`; functions are deposit/withdraw/withdrawAll/claimRewards/setPriceOracle/setSlippage; no rebalance/harvest keeper.
- **Stake DAO CRV LlamaLend Recovery Vault `0xF221D835…2998`** — `RewardVault` proxy over the `CRV LlamaLend Recovery` StableSwap LP `0x516C3eCf…3Cb5`; `totalAssets = 182,848.5037 LP` (22.8% of the pool's 802,416.1 LP); functions include `claim`, `depositRewards`, `deposit`, `withdraw` — no rebalance, no leverage, no swap. Value left unpriced (the recovery token `0xCeA18a87…f2cA` has no DefiLlama quote); not a candidate on any test.

**Negative search results:** no verified Ethereum contract named `*LlamaVault*` (only "Stake DAO LlamaThena Vault" on BNB); no other Zenji vault token beyond the four above; no live Zenji `RebalanceKeeper` with funds.

---

## 8. C7 — Curvance (unresolved on Ethereum)

DefiLlama protocol `curvance` reports TVL **$137.2M on Monad only** (chains = `["Monad"]`). Ethereum Blockscout name search returns one Curvance contract, `CurvanceDAOBonding 0xFf5c76Abb78cba501aA2c7A1bFfBaBf2b9DeB989` (verified, code present, no market/keeper surface). No Ethereum lending market, no Curve-LP-collateral market, no permissionless keeper was found on chain 1. **Verdict: unresolved for Ethereum — not assessed as a live target, and not a sibling on this chain.**

---

## 9. Controls (class checked, one line each)

| Control | Why it is not the pattern |
|---|---|
| **Yearn v3** | `process_report(strategy)` requires `REPORTING_MANAGER` (`src_Yearn_V3_Vault_0x065597.sol:1644`); vaults lend to strategies, not to a leveraged LP position, so there is no LTV to reprice. |
| **StakeDAO CLM / votemarket strategies** | Permissionless `harvest` exists, but the strategy holds its own Curve LP and has no debt/borrow module; harvest converts rewards, it does not rebalance a levered position against its own price source. |
| **Beefy** | Permissionless `harvest` on single-asset/LP strategies, no debt, no LTV, no keeper that trades against the strategy's valuation pool. |

---

## 10. What would change the verdict

1. **Fluid Lite ETH**: the `isRebalancer` role being granted to a public/keeper contract, or `rebalance*`/`swap*`/`updateExchangePrice` being made permissionless, would move $148.9M into the candidate set — and the vault's Fluid-DEX leg makes (b) plausible. Monitor `updateRebalancer`/`isRebalancer` and implementation changes.
2. **Zenji pmUSD vaults**: any deposit would immediately create a live, exact-code sibling. Monitor `Deposit`/`Transfer` on `0xB415…c31F` and `0x45bB…1595`.
3. **YieldBasis**: a future keeper/rebalance module, or a change of the LT `_price_oracle` to `last_prices` (spot) instead of `price_scale`, would matter. Monitor `set_implementations`, LT/LEVAMM implementation addresses, and the pool's `tweak_price`/policy.
4. **Gearbox**: a switch from Chainlink to a pool-derived price feed would change (b); none of the 74 CMs exposes a vault-level rebalance today.
5. **Curvance**: an Ethereum deployment with Curve-LP collateral + a public keeper would need a fresh review.

---

## 11. Files and reproducibility

| File | Contents |
|---|---|
| `snapshot.py` | one-shot, read-only snapshot script (pinned block; writes `evidence/live_state.json`) |
| `fetch_src.py` | Etherscan V2 `getsourcecode` + `eth_getCode` harvester (key read from `.env`, never written) |
| `evidence/live_state.json` | every value cited above, with `to`/`sig`/raw return, block 26,381,250 |
| `evidence/sources.json` | verified source + ABI for all 40+ addresses used (public code only) |
| `evidence/yb_markets_live.txt`, `evidence/yb_frontend_addresses.json` | YieldBasis market enumeration and app address registry |
| `evidence/gearbox_cm_pools.json` | 71 credit-manager → pool map |
| `evidence/prices.json` | DefiLlama price snapshot used for USD |
| `evidence/dl_*.json`, `evidence/dl_adapter_instadapp_lite.js` | DefiLlama protocol/TVL/adapter evidence |
| `evidence/bs_search_*.json` | Blockscout name-search results (`Llama`, `llamalend`, `Zen`, `Curvance`) |
| `evidence/src_*.sol` / `gb_*.sol` / `fluid*.sol` | extracted verified sources with the cited line numbers |

**Limitations.** (i) Point-in-time: block 26,381,250; the chain moves. (ii) No fork simulation was run in this lane (light-read scope only) — the three tests are decided from live state + verified code, and the only "proof of path" is `eth_call --from 0x…dEaD` on the specific functions cited. (iii) USD values use DefiLlama spot at the stated time; wstETH's quoted $2,654.78 vs WETH $2,124.72 (ratio 1.25) looks rich, so Fluid's stETH-denominated $148.9M uses ETH $2,124.72, not the wstETH quote. (iv) `Zenji`'s two incident vaults were deliberately not read (owned by another worker). (v) An out-of-lane class (Index Coop FLI, f(x) XETH, Contango, Summer.fi) also has permissionless leverage keepers but was not assessed here; FLI/f(x) value from Chainlink-style oracles rather than their execution venue, which is the opposite of test (b), but that is a lead, not a verified negative.

**Confidence:** high that no live Ethereum contract in the assessed set satisfies all three tests at block 26,381,250; high on the two empty Zenji siblings (direct `totalSupply`/`totalAssets` + `RebalanceNotNeeded` probe); high on Fluid's `onlyRebalancer` gate (source + revert selector + `isRebalancer` read); medium-high on YieldBasis's "not spot" valuation (depends on the pool's `tweak_price` bound, verified in source but not fork-tested); unresolved on Curvance (not deployed on Ethereum).
