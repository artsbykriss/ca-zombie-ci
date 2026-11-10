# CA3 — Zenji recipe sibling hunt

**Date:** 2026-11-10 · **Chains:** Ethereum (1), Optimism (10), Base (8453), Arbitrum (42161)
**Status:** read-only research. No mainnet transaction was signed or broadcast. Every on-chain value is a point-in-time read at the stated block; every exploit reproduction ran on a local anvil fork (GitHub Actions, public run log linked in §7).

**Question.** Zenji (Ethereum, 2026-11-08, ~$4.9k) lost funds to a *permissionless* `rebalance()` that valued its Curve-LP strategy and its LTV from the **same** crvUSD/USDT StableNG pool it then exited through, with a `minOut` floor computed from that same manipulable quote. Both Zenji vaults are dust today. This dossier asks: **is the recipe live anywhere else, and how much can an unprivileged attacker extract right now?**

**Answer.** **$0.00 extractable today.** The recipe is real and reproduces to the cent (+4,951.40 USDT on the pre-exploit fork), but the only contracts that implement it are Zenji's own four vaults: two were drained to **$161.74** of holder-owned dust and two were never funded. A 37-candidate cross-chain sweep of leveraged vaults, LlamaLend wrappers, StakeDAO strategies, Curve-LP-collateral vaults and ERC-4626 leveraged farms found **no other live contract that passes all three tests**. The residual risk is *latent*: the drained vaults are still open for deposits (`depositsPaused() = false`) and the deployed code is unpatched, so a returning depositor re-arms the exact exploit — quantified in §7 at **$15.1k–$143.8k per transaction** against a simulated $238k deposit.

---

## 1. TL;DR

| Target | Chain | Live E-U today | Why closed / open | Latent risk |
|---|---|---:|---|---|
| Zenji `zenWstETH-LL-USDT` `0x23F1…Dd2c` | Ethereum | **$0.00** | No loan (`loanExists()=false`), strategy LP = 0, `rebalance()` reverts `RebalanceNotNeeded()`; 0.009065 wstETH dust is holder-owned (H-O) | **HIGH** — unpatched, deposits open; re-funding re-arms the recipe |
| Zenji `zenWBTC-LL-USDT` `0x18E2…3f74` | Ethereum | **$0.00** | Same; 0.00183694 WBTC dust (H-O) | **HIGH** — same |
| Zenji pmUSD vaults `0x45bb…1595`, `0xb415…c31f` | Ethereum | **$0.00** | Never funded (`totalAssets = 0`, `totalSupply = 0`); pmUSD pool retired | LOW — same code, no users |
| Extra Finance `VeloVaultPositionManager` | OP + Base | **$0.00** | All three keeper paths disabled (`permissionLess*Enabled() = false`) *and* caller-whitelisted (revert `"20"`); minOut is caller-supplied | MEDIUM if owner flips two switches (forced-liquidation recipe, not Zenji's) |
| Contango V2 | ARB + Base + OP | **$0.00** | `trade`/close are owner-or-approved (`Unauthorised`); no on-chain liquidation entry point | none in class |
| Extrafi XLend MetaMorpho vaults | Base | **$0.00** | `allocate/reallocate` allocator-only; Morpho-oracle priced, no LP leg | none in class |
| YieldFi, Gloop, Beefy (control) | Base/ARB | **$0.00** | No debt+LP keeper path; Beefy `harvest()` is permissionless but holds no debt and prices nothing from a manipulable pool | none in class |
| Fluid Lite **iETHv2** (ex-Instadapp Lite) | Ethereum | **$0.00** | **$148.9M live but every rebalance is `onlyRebalancer`** (`Helpers__NotRebalancer()` 0x78fb3fe5); NAV is a stored checkpoint, not pool spot | P-class only |
| YieldBasis (11 LT markets) | Ethereum | **$0.00** | No `rebalance`/`delever`/`harvest` in the LT bytecode; valuation uses a bounded `price_scale` EMA, not spot; the only permissionless pool trade is `distribute_borrower_fees()` (~$1,809 accrued interest, paid back to LPs) | LOW |
| Gearbox v3, Curvance, Fluid USD, LlamaLend zaps, Zunami, StakeDAO recovery | Ethereum | **$0.00** | Chainlink/`IPriceOracleV3` pricing or role-gated keepers; zaps stateless (hold 0) | none in class |

**Total live extractable now (E-U): $0.00** (confidence: **high**).
**Holder-recoverable (H-O): $161.74** — the two vaults' idle dust at block 26,381,000 (wstETH $2,654.78, WBTC $74,941.92, DefiLlama 2026-11-10).
**Verified historical recipe:** **+4,951.40 USDT** (16/16 fork tests PASS, CI run 42738506283).

---

## 2. The mechanism, in exact terms

### 2.1 Deployed code

| Contract | Address | Notes |
|---|---|---|
| Vault wstETH (proxy → 45-byte EIP-1167) | `0x23F189dE34EED95f6303CfF1C77f7676F211Dd2c` | `ZenjiWstEthLlamaUsdtStakeDao`, 70,978-byte impl embedded in the delegator |
| Vault WBTC | `0x18E2F4F2E6565187fce73ECC707579E5F7933f74` | `ZenjiWbtcLlamaUsdtStakeDao` |
| Loan manager wstETH | `0xCf9f54218666a32BE9da1d60BC81412BA86730C7` | `LlamaLoanManager`, LlamaLend controller `0x100dAa78…` |
| Loan manager WBTC | `0x45dE3acb04C571136790f07eA114E922346d13d5` | `LlamaLoanManager`, controller `0x4e595413…` |
| Strategy wstETH | `0x8bD4d875E2Cf1174e282B532Fa534b6633F59B5f` | `CrvUsdLpStakeDaoStrategy` |
| Strategy WBTC | `0x596fE8c8a61446AE2c5703fdC31b8F63390626E4` | `CrvUsdLpStakeDaoStrategy` |
| Swappers | `0x079B605f…0367`, `0x4F095C3E…d3B6` | `UniswapMixedCurveSwapper` |
| Curve StableNG pool | `0x390f3595bCa2Df7d23783dFd126427CCeb997BF4` | coin0 = USDT, coin1 = crvUSD |
| StakeDAO reward vault | `0xF980f195A93577DcCe48e91e98124D3B71C4a066` | LP staked here |
| Morpho Blue (flash lender) | `0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb` | 0-fee USDT flash loans |
| Deployer / gov / strategist / strategy owner | `0x74DE73F2C586ba6Ed7B154c5460A7Ef42e8194cE` | single EOA |

### 2.2 The three tests — all three pass

**(a) The keeper path is external and unpermissioned.** `Zenji.rebalance()` (`src_Zenji.sol:593`) is `external nonReentrant` with **no role check**. `accrueYieldFees()` and `harvestYield()` are likewise public. The fee/bounty is paid to `msg.sender`, so the attacker is the keeper.

**(b) Valuation reads the pool the caller can trade.** The strategy's `balanceOf()` (the vault's `strategyToDebtRatio()` and its `getTotalCollateral()` NAV) is:

```solidity
// BaseCurveStakeDaoStrategy.balanceOf() (verified source at 0x596fE8… / 0x8bD4d8…)
uint256 vpBased   = (lpTokens * _getSafeUnitValue()) / PRECISION;         // get_virtual_price(), clamped
uint256 exitBased = lpPool.calc_withdraw_one_coin(lpTokens, lpCrvUsdIndex); // SAME pool, spot
uint256 lpAssetValue = exitBased < vpBased ? exitBased : vpBased;          // min() — conservative in
                                                                           // one direction only
```
`_getSafeUnitValue()` is `get_virtual_price()` clamped ±MAX_VP_DEVIATION around a cached value (and the clamp is bypassed after `MAX_VP_STALENESS`). `calc_withdraw_one_coin` is raw pool spot. Anyone can move it with a Curve `exchange` in the same pool.

**(c) The slippage floor is the same manipulable quote.** `_removeLiquidity`:

```solidity
uint256 expectedOut = lpPool.calc_withdraw_one_coin(lpAmount, lpCrvUsdIndex); // manipulated state
uint256 minOut     = (expectedOut * (PRECISION - slippage)) / PRECISION;      // 1% below the same quote
crvUsdReceived     = lpPool.remove_liquidity_one_coin(lpAmount, lpCrvUsdIndex, minOut);
```
and the vault's own check is `minReceived = toWithdraw * (1 - maxSlippage)` with `maxSlippage = 1e16` (1%). There is **no independent oracle, TWAP or off-pool floor** anywhere on the exit path. The vault's *loan* pricing is Chainlink-based, but the strategy valuation and the exit floor are both the pool.

That combination is the Zenji primitive. All three conditions hold on the live deployed bytecode — the team's current GitHub head contains newer `Ng*` strategy variants with explicit same-block manipulation defences, but the deployed strategies at `0x596fE8…`/`0x8bD4d8…` are immutable and still take both the NAV and the `minOut` from `calc_withdraw_one_coin`, so the on-chain code is the vulnerable shape.

### 2.3 What the attacker does (one atomic transaction)

1. Flash-borrow USDT (Morpho Blue, 0 fee).
2. `exchange(0,1,amount,0)` in the StableNG pool: USDT → crvUSD, draining the pool's crvUSD side (7.19M crvUSD vs 1.83M USDT at the exploit block).
3. `rebalance()` on both vaults. The vault's strategy NAV (`balanceOf`) and exit floor are read from the same depleted pool; the vault either trips the strategy/debt deadband (`rebalanceCoverageUp`) or the LTV deadband and exits at the manipulated mark — burning more LP / receiving less debt asset than a fair exit.
4. `exchange(1,0,allCrvUsd,0)`: crvUSD → USDT.
5. Repay; keep the spread.

Measured on the real transaction: bought 7,138,299.911635911250934175 crvUSD for 7,237,500.000000 USDT, sold the same crvUSD for 7,242,451.395691 USDT → **+4,951.395691 USDT (+6.8 bps)**. The two vaults' NAV fell 0.441808684706228498 → 0.257168710997874052 wstETH and 0.019880545 → 0.011255021 WBTC (−$1,043 at the time); the pool paid out 5,313.55 USDT + 3,787.08 crvUSD for 10,227.22 LP burned — the remaining loss landed on the pool's LPs, which is why a $2.4k-equity vault produced a $4.95k extraction.

The useful corollary for sizing: **the attack size is capped by the pool's crvUSD inventory**, not by the vault's TVL. At the exploit block the pool held 7.19M crvUSD; a 10M or 14M buy reverts (`transfer reverted` — the pool cannot deliver), which our sweep confirms.

---

## 3. Live-state assessment (block 26,381,000, 2026-11-10)

| Item | Vault wstETH | Vault WBTC |
|---|---:|---:|
| `totalAssets()` | 9,065,059,159,379,702 wei = 0.009065059159379702 wstETH (≈ **$24.07**) | 183,694 sats = 0.00183694 WBTC (≈ **$137.68**) |
| `totalSupply()` | 31,014,376,288,130,179 shares | 660,283 shares |
| Idle asset balance | 0.009065059159379702 wstETH | 0.00183694 WBTC |
| `loanExists()` | **false** | **false** |
| `getCurrentDebt()` | 0 | 0 |
| Strategy `balanceOf()` | **0** | **0** |
| LP in StakeDAO reward vault | **0** | **0** |
| `depositsPaused()` | **false** | **false** |
| `emergencyMode()` | **false** | **false** |
| `targetLtv()` / `maxSlippage()` / `rebalanceBountyRate()` | 65% / 1% / 20% | 65% / 1% / 20% |
| `rebalance()` from a random address | **reverts `0x5121f343` = `RebalanceNotNeeded()`** | same |
| `depositCap()` | 0 (unlimited) | 0 (unlimited) |

Pool `0x390f…7BF4` at block 26,381,000: 1,580,626.431257 USDT / 7,988,734.058926 crvUSD, LP supply 9,300,562.153991, `get_virtual_price = 1.028692406595522718`. The pool is *more* crvUSD-heavy than at the exploit block — i.e. the latent setup is unchanged in kind.

Roles: gov = strategist = strategy owner = deployer = `0x74DE73F2C586ba6Ed7B154c5460A7Ef42e8194cE` (single EOA). That is a P-class risk (it can change `maxSlippage`, the strategy's `slippageTolerance` and rescue tokens), not an E-U path, and it is not claimed as extractable here.

### 3.1 Fleet enumeration (how the 4 vaults were found)

1. **Deployer creation scan** (`0x74DE…94cE`, Etherscan V2 `txlist`, 1,540 txs): four 8-contract deployment batches — two in the pmUSD era (blocks 25,284,727 / 25,284,865) and two in the USDT era (blocks 25,311,189 / 25,318,060). 30 creations after block 25.2M; each batch = viewHelper + swapper + strategy + loan manager + vault (+ helper).
2. **Event scan**: `Rebalance(uint256,uint256,bool)` topic0 `0xd2412c66…383d` over blocks 25,000,000→latest returns **93 logs from exactly two addresses** — the two USDT vaults. No third Zenji vault has ever rebalanced.
3. **DefiLlama `registries/erc4626.js`** lists exactly the same two Zenji vaults.
4. **GitHub**: `NateBrune/ZenSats-contracts` is the only public repo with the Zenji code (`CrvUsdLpStakeDaoStrategy`, `rebalanceCoverageUp`); no public fork exists. The repo's XAUT/Aave runbook (`deployments/xaut_crvusd_usdt_aave.md`, committed 2026-11-08) has **no deployed address**, and no contract with XAUT collateral ever emitted `Rebalance` — the XAUT vault was prepared but not deployed (or never operated).

So the Zenji fleet is **4 vaults / 2 ever funded / 0 funded today**.

---

## 4. Sibling enumeration across the four chains

**Definition used.** A candidate must be a *leveraged* position (debt against a strategy) with a keeper entry point. Three tests as in §2.2. A caller-supplied `minOut` fails (c) — in that case the caller, not the vault, carries the slippage (Extra, Contango and every per-position design).

### 4.1 Summary

| Lane | Families screened | Candidate rows | Pass (a) | Pass (a)+(b) | **Pass all three, live** | Live USD behind a passing path |
|---|---:|---:|---:|---:|---:|---:|
| Zenji fleet (this dossier) | 1 (Zenji) | 4 vaults | 4 | 4 | **4 (drained/empty)** | **$0.00** |
| L2 lane (OP/Base/ARB) — `analysis/children/l2-scan/` | 6 (Extra VPM, Contango, MetaMorpho, YieldFi, Gloop, Beefy control) | 15 | 2 (1 control + 1 self-funded) | 0 | **0** | **$0.00** |
| ETH lane — `analysis/children/eth-scan/` | 8 (YieldBasis 11 LT markets, Fluid Lite, Gearbox v3, Curvance, LlamaLend wrappers, Yearn v3/StakeDAO CLM/Beefy controls) | 18 | 3 controls only | 0 | **0** | **$0.00** |
| **Total** | **14** | **37** | — | — | **0 live** | **$0.00** |

*Row granularity: YieldBasis' 11 live LT markets are counted individually; a "family" is a protocol/contract system. Passing (a) counts only paths proven callable by a random EOA in the child probes.*

Full per-candidate evidence (address, selector, call result, valuation source, minOut source, TVL) is in the two child reports and their JSON: `analysis/children/l2-scan/l2-candidates.json` and `analysis/children/eth-scan/eth-candidates.json` (plus each `evidence/` folder). The tables below are the digest.

### 4.2 L2 lane (Optimism / Base / Arbitrum)

| Candidate | Chain | Keeper entry | (a) | (b) | (c) | Verdict |
|---|---|---|---|---|---|---|
| Extra Finance VPM `0xf9cF…7055` — `liquidateVaultPositionPartially` | OP/Base | whitelist + `permissionLessLiquidationEnabled` | **no** (`"20"` revert; switch false) | spot-priced on 34/54 OP, 75/87 Base vaults | caller `minAmount*` | not-zenji |
| Extra Finance VPM — `closeOutOfRangePosition` | OP/Base | whitelist +`permissionLessRangeStopEnabled` | **no** | pool range stop | caller `minAmount*` | not-zenji |
| Extra Finance VPM — `investEarnedFeeToLiquidity` | OP/Base | whitelist | **no** | n/a | caller route | not-zenji |
| Extra Finance VPM — `newOrInvestToVaultPosition` | OP/Base | permissionless but **own funds only** | yes (self-funded) | n/a | caller | out of class |
| Contango V2 `0x6Cae…C24E` — `trade` (close/delever) | ARB/Base/OP | `validateModifyPositionPermissions` | **no** (`Unauthorised`) | money-market oracle | caller `limitPrice` | not-zenji |
| Extrafi XLend WETH/USDC MetaMorpho | Base | `allocate/reallocate` | **no** (allocator-only) | Morpho oracle | n/a | not-zenji |
| YieldFi yUSD/vyUSD | Base | none exposed | **no** | off-chain basis | n/a | out of class |
| Gloop | ARB | unresolved | not probed | oracle field | unknown | sub-threshold ($26.4k) |
| **Beefy (control)** | Base | `harvest()` | **yes** (proven) | **no debt/LTV** | n/a | control |

Key negative evidence: every Extra keeper switch is `false` and every whitelist is empty at OP block 159,337,708 / Base block 55,418,325, and all three entry points revert `Error("20")` = `VL_LIQUIDATOR_NOT_IN_WHITELIST` even for the protocol owner. All 87 funded Base Extra vaults are `frozen`; `borrowEnabled = true` count is **0** on both chains. TVL (DefiLlama): Base $8.21M, OP $0.50M — but none of it is reachable through a Zenji-shaped path.

### 4.3 ETH lane (Ethereum)

Full table, verified sources and raw dumps: `analysis/children/eth-scan/REPORT.md` + `eth-candidates.json`
(+ `analysis/eth-lane-digest.md` for the independent re-read). Snapshot block 26,381,250.

| # | Candidate | Address | Keeper entry probed | (a) | (b) | (c) | Live USD | Verdict |
|---|---|---|---:|---|---|---|---|
| C1 | YieldBasis cbBTC v3 (of 11 markets) | LT `0x722FC364…29F9` | `distribute_borrower_fees()` / `exchange()` | ✗ | ✗ (bounded `price_scale` EMA, not spot) | ~ (same pool, but fee-only) | **$93.08M** protocol | not-zenji: no rebalance; the only permissionless trade moves ≈$1,809 of accrued interest and donates it back to the pool |
| C2 | Fluid Lite ETH v2 (**iETHv2**) | `0xA0D3707c…Be78` | `rebalanceFromWstETHToWeETH`, `updateExchangePrice` | **✗** `onlyRebalancer` (`0x78fb3fe5`) | ✗ stored `exchangePrice` checkpoint | ✗ | **$148.9M** (70,077.77 stETH) | not-zenji (strongest funded near-miss; P-class role risk only) |
| C3 | Fluid Lite USD v2 | `0x273DA948…9012` | none | ✗ `onlyStrategyHandler` | ✗ fixed-rate accrual | ✗ | $40.46M | not-zenji |
| C4–C5 | Instadapp Lite v1 iETH/iUSDC | `0xc383a383…d019`, `0xc8871267…57F8` | `leverage`/`deleverage` (1:1 peg swaps) | ~ | ✗ | ✗ | $1.8k / ≈$0 | out of class (dust) |
| C6 | Gearbox v3 wstETH Credit Manager | `0x00689539…3EE5` | `liquidateCreditAccount` | ✓ | **✗** Chainlink + staleness | ✗ | $7.46M debt / $19.38M protocol | not-zenji |
| C7 | Curvance | — | — | ? | ? | ? | — | **unresolved on Ethereum** (DefiLlama shows Monad only) |
| C8–C9 | **Zenji pmUSD/crvUSD vaults** | `0xB415bce7…c31F`, `0x45bBa5E1…1595` | `rebalance()` | ✓ | ✓ | ✓ | **$0** (supply 0) | **exact-code siblings, empty** |
| C10 | ZenjiRebalanceKeeper | `0x4fD5DD13…9495` | `performUpkeep(bytes)` | ✓ | n/a | n/a | $0 | Chainlink-Automation receiver; only calls the already-permissionless `vault.rebalance()` |
| C11–C13 | Curve `LlamaLendLeverageZap`, Volume 1inch zap, DeFi Saver `LevCreate`/`Boost` | `0xE1834AF5…4D4E`, `0xe61d72cb…005E`, `0x534b704a…105E` | none | ✗ | ✗ | ✗ | **$0** | stateless zaps / per-user actions |
| C14–C15 | Zunami LlamaLend strategies, StakeDAO CRV recovery vault | `0xF3558b52…6ab73`, `0xF221D835…2998` | none / `claim()` | ✗ | ✗ | ✗ | $0 / LP unpriced | no leverage, no keeper |
| — | Yearn v3, StakeDAO CLM, Beefy (controls) | — | `report`/`harvest` | **✓** | **✗ no debt/LTV** | ✗ | — | controls |

**Result: 15 candidates + 3 controls; 0 pass all three.** The two exact-code Zenji siblings that exist
outside the incident pair are **live and permissionless but empty** — independent confirmation that
the recipe is Zenji-specific, not a reusable pattern deployed elsewhere.

### 4.4 What is new vs passes 3–6

Prior passes covered StakeDAO's curator, LlamaLend, Ajna and the 2026-11 incident cluster. **New here:** (1) the Zenji code family is enumerated exhaustively on-chain (4 vaults, 2 ever funded) and both live vaults are proven empty at the *position* level, not just at `totalAssets`; (2) the recipe is reproduced from scratch to the wei (+4,951.40 USDT) with an independent attacker contract, which calibrates what "sibling" means economically; (3) the *latent re-arm* is fork-quantified for the first time (a returning depositor loses 6%–71% of TVL in one transaction); (4) 37 candidate rows on OP/Base/ARB/ETH are now explicitly excluded with on-chain evidence (switches, whitelists, selectors), so they need not be re-hunted.

---

## 5. What an attacker can and cannot do today

**Can:** call `rebalance()` / `harvestYield()` / `accrueYieldFees()` on both vaults from any EOA. `harvestYield()` succeeds but harvests zero (strategy LP = 0; `balanceOf() = 0`). `rebalance()` reverts `RebalanceNotNeeded()` because `loanManager.loanExists() == false` at `Zenji.sol:595`.

**Cannot:** re-open a loan, mint shares against the vault's dust, move the dust (it belongs to the share holders; `rescueAssets` excludes collateral/debt and is `onlyStrategist`), or make a round trip profitable — the only effect of skewing the pool and calling the keeper path is paying the pool fee twice. Test C proves the full attack reverts and Test D shows a funded-but-healthy vault yields −$1.0k to −$27.0k at 7.8–8.8M sizes unless the size hits the narrow profitable window (§8).

**Costs.** Morpho Blue flash loans are 0-fee for USDT; gas for the historical exploit was 6,792,575 at ~0.1–1 gwei (≈ $2–$20). Capital is therefore not a barrier; **fuel is**.

---

## 6. PoC / fork verification

Foundry 1.8.5, solc 0.8.24, `evm_version = cancun`. All tests fork an archive RPC and never broadcast.

| Test | Scenario | Result |
|---|---|---|
| `test_A_historical_repro` | fork block 26,371,412 (pre-exploit), independent attacker, 7,237,500 USDT flash | **+4,951,395,691 units = 4,951.40 USDT**; both `rebalance()` calls succeed; vault NAVs fall exactly as on-chain |
| `test_B_1M / 2M5 / 5M / 7M24 / 10M / 14M` | size sweep at the same block | −199 / −499 / −999 / **+4,951** / revert / revert (10M+ exceeds the pool's 7.19M crvUSD inventory) |
| `test_C_live_no_fuel` | live block 26,381,000 | `rebalance()` reverts `0x5121f343`; full attack reverts; `loanExists=false`, `debt=0`; dust 0.009065 wstETH + 0.00183694 WBTC |
| `test_D_healthy_*` | live + 100 wstETH third-party deposit at 65% LTV, no price move | −1,055 / **+15,136** / −2,361 / −27,031 at 7.8 / 8.0 / 8.2 / 8.8M |
| `test_E_drawdown_*` | live + 100 wstETH deposit + Chainlink wstETH/USD mocked −10% (LTV 72.2%) | −761 / +2,655 / **+69,082** / **+143,799** at 7.8 / 8.0 / 8.2 / 8.8M; depositor NAV 99.96 → 28.72 wstETH at 8.8M |

**CI:** `https://github.com/artsbykriss/ca-zombie-ci/actions/runs/42738506283` — **16/16 PASS**, 96 s, artifact `result-ca3-zenji-siblings`. Local reproduction of A: identical to the wei. The historical attacker's own tx `0x79fa5b30…d701` netted 4,951,395,691 units, so the model and the fork agree.

Files: `poc/src/ZenjiAttacker.sol`, `poc/test/ZenjiSiblings.t.sol`, `poc/foundry.toml`, `ci-log.txt`, `ci-artifacts/`.

**Reproduce:** `cd poc && forge test -vv` with `BLOCKPI_RPC_URL` (or `HIST_RPC` / `LIVE_RPC`) set. No key is stored in the folder.

---

## 7. Verdict, residual and latent risk

**Verdict: no live sibling.** 37 candidate rows, 4 Zenji-family contracts pass the three tests, 0 have funds. E-U = **$0.00**, confidence **high** (position-level emptiness, not just NAV: strategy `balanceOf()=0`, StakeDAO LP balance 0, debt 0, keeper path reverts).

**Latent risk (not counted in E-U):** both vaults still accept deposits and still run the unpatched code. The fork shows that a **third-party** deposit re-arms the exploit in one transaction:

| Simulated deposit | LTV state | Flash size | Attacker net | Depositor NAV loss |
|---|---:|---:|---:|---:|
| 100 wstETH (~$238k) | 65.0% (no move) | 8.0M USDT | **+$15.1k** | −6.3% |
| 100 wstETH | 72.2% (−10% oracle) | 8.2M USDT | **+$69.0k** | −29.9% |
| 100 wstETH | 72.2% (−10% oracle) | 8.8M USDT | **+$143.6k** | −71.3% |

The profitable window is narrow and non-monotonic (pool-state dependent; sizes outside it lose money), and the upper bound is the pool's crvUSD side (~7.99M), not the vault's TVL. The honest reading: **a returning depositor can lose a large share of principal in a single block, and the attacker's capital is a 0-fee flash loan.** Mitigation is the team's (pause deposits / migrate to the patched strategy); an outside party cannot close it.

**Blockers to an E-U finding, stated plainly:** (1) no borrow position; (2) no LP in the strategy; (3) `rebalance()` reverts before touching the pool. All three are structural, not price-dependent.

---

## 8. Methodology, sources, caveats

- **Enumeration by events/factories, not lists:** deployer creation scan + `Rebalance` topic0 + DefiLlama ERC-4626 registry + GitHub code search (`CrvUsdLpStakeDaoStrategy`, `rebalanceCoverageUp`) — see §3.1.
- **Deployed reality:** `eth_getCode` (45-byte EIP-1167 proxy → 36,536-byte implementation `0x67fe41A9…`), verified sources via Etherscan V2 (`Zenji`, `ZenjiCoreLib`, `LlamaLoanManager`, `CrvUsdLpStakeDaoStrategy`, `UniswapMixedCurveSwapper`), roles and pause flags by `eth_call` at pinned blocks.
- **Values:** exact `balanceOf` / `totalAssets` / `totalSupply` reads; USD from DefiLlama coins API at 2026-11-10 (wstETH $2,654.78, WBTC $74,941.92, USDT $0.99875).
- **Proof:** fork at explicit blocks, independent attacker contract, net after pool fees and (negligible) gas; flash-loan route = Morpho Blue, 0 fee, atomic.
- **Caveats:** (i) the latent table uses a `vm.mockCall` on the Chainlink wstETH/USD feed to simulate a −10% move — labelled hypothetical; (ii) the 100 wstETH deposit is simulated with `deal` on a fork to measure *what a returning depositor would expose*, not a live position; (iii) L2/ETH child verdicts rely on verified source + behavioural `eth_call` probes at the stated blocks; Extra's implementation is unverified (flag-based inference is marked as such in the child report); (iv) gas prices vary, but at any plausible 2026 level gas is <0.5% of the historical net.
- **Corrections to the corpus:** the corpus' "~$8.36K drained from the Curve pool" is directionally right but the precise pool coin deltas are −5,313.55 USDT and −3,787.08 crvUSD for −10,227.22 LP; the attacker's net is 4,951.395691 USDT. The Zenji repo's post-incident `min(VP, calc_withdraw_one_coin)` guard is **not** on-chain: the deployed immutable strategies still use the pool quote for both NAV and `minOut`.

### Files

```
ca3-zenji-siblings/
├── README.md                     # this dossier
├── summary.json                  # machine-readable headline
├── analysis/
│   ├── zenji_state.json          # pre/post-exploit + live state, 4 blocks
│   ├── collect_state.py          # state collector (env-only RPC)
│   ├── evidence/
│   │   ├── exploit_tx.json       # tx, block, attacker, amounts, net
│   │   └── pool_delta.json       # StableNG balance/LP deltas
│   ├── eth-lane-digest.md        # self-verified ETH-lane verdicts
│   └── children/
│       ├── l2-scan/              # OP/Base/ARB lane: REPORT.md, l2-candidates.json, evidence/
│       └── eth-scan/             # ETH lane: REPORT.md, eth-candidates.json, evidence/
├── poc/                          # Foundry project (forge-std vendored)
│   ├── src/ZenjiAttacker.sol
│   └── test/ZenjiSiblings.t.sol  # 16 tests, A–E
├── ci-log.txt                    # CI run 42738506283 log
└── ci-artifacts/                 # downloaded artifact
```
