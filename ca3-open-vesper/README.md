# CA3 OPEN-1 — Vesper V2 fleet (23 pools, Ethereum + Base + Optimism)

**Date:** 2026-11-10 · **Chains:** Ethereum 1, Base 8453, Optimism 10 · **Status:** read-only research. Every claim below is an `eth_call` / `eth_getStorageAt` / static source read at the pinned block, plus Foundry tests that run **only on a local fork**. No transaction was signed or broadcast; no key was used; no secret is stored in this folder.

**Scope:** every pool in the three Vesper **prod** registries — `api.vesper.finance` (14 Ethereum), `api-base.vesper.finance` (5 Base), `api-optimism.vesper.finance` (4 Optimism) — their 44 registered strategies, pool accountants, proxy admins, keepers and governance. This is the OPEN-1 coverage gap from `ca3-recon`, which listed 19 pools (ETH+Base) and noted that prior work (`ca3/research/defillama-new.md` §4.7) had inspected **2** of them. **The Optimism leg was missing from the reconciliation and is included here.**

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed / open | Latent risk |
|---|---:|---|---|
| **23-pool fleet, principal** | **$0** | every value path is gated: pool `reportEarning/reportLoss` require a registered strategy (accountant `onlyPool` + `active`), `migrateStrategy`/`sweepERC20`/`pause`/`shutdown`/`update*` are `onlyGovernor`/`onlyKeeper`, strategy `withdraw` is `onlyPool`, `rebalance`/`sweep`/`swapToCollateral`/`claimAndSwapRewards` are `onlyKeeper`, UUPS upgrade is `onlyGovernor`. Fork-proven on all 23 pools and 44 strategies. | A 3-of-6 Safe key compromise (P) drains everything. |
| **Yield-JIT / pending-profit dilution** | **≈ $1,250 per fleet-wide rebalance cycle** (fork-measured) | Deposit is instant and fee-free (`externalDepositFee = 0`), `pricePerShare` is book value, so a searcher can park a deposit in front of a keeper `rebalance()` and exit behind it. Measured: +313.19 FRAX on a 30M FRAX deposit around a 325.56 FRAX profit report. Ceiling = the profit actually realised in that tx. | If the 4 currently-reverting strategies (StakeDao ×2, Convex, Aave-Xy) could be rebalanced the mark-to-market gap is ≈$106k — but they cannot. |
| **vaDAI phantom debt** | $0 to an outsider | `Rari_Dummy_DAI` is booked as active with **74,130.56 DAI** of debt and `tvl() = 0`; unwithdrawable, so NAV is overstated **97.34%**. | Holders race to exit; last out eats ~$74.1k. |
| **Optimism vaUSDC / Sonne** | $0 to an outsider | Books **$835,477**, but the Sonne USDC market is **47% owned by the strategy, `getCash() = 0`**, the strategy holds 0 idle USDC.e, and `withdraw()` transfers nothing. Only ~$44.2k (an AaveV3 position) is realisable. | **$791.3k is stuck**; holders can only recover ~5.3% of NAV. |
| **Legacy v2 `sweepErc20`** | ≈ **$0.005** | Public on the 2020 vETH/vUSDC/vWBTC pools, but the only non-reserved token held is 1 HEX. | Any future reward-token claim could be sandwiched (`amountOutMin = 1`). |

**Total live extractable now: $0 principal + ~$1.25k per full rebalance cycle of MEV/JIT income.** Confidence **high** on the $0 (fork-proven on every pool), **medium** on the $1.25k.

---

## 2. The fleet — 23 pools, $77.53M booked

`totalValue()` is the pool's own book value (`totalDebt + tokensHere`). USD at DefiLlama spot prices (`coins.llama.fi`, 2026-11-10). Blocks: **ETH 26,381,372 · Base 55,427,996 · OP 159,339,279**.

| # | Chain | Pool | Asset | Ver | `totalValue` | USD | Strats |
|---:|---|---|---|---|---:|---:|---:|
| 1 | ETH | `0x4C73F025a1947ec770327B9956Fc61f535F72C22` vamsUSD | msUSD | 5.1.0 | 31,951,088.19 | $25,975,853 | 3 |
| 2 | ETH | `0xCa7c607C590ad16007CCBbba9D26f4df656a36C2` vamsETH | msETH | 5.1.0 | 13,585.02 | $25,086,330 | 3 |
| 3 | ETH | `0x4Dbe3f01aBe271D3E65432c74851625a8c30Aa7B` vaSTETH | stETH | 5.0.2 | 6,296.06 | $13,400,447 | 4 |
| 4 | Base | `0x913Ece180df83A2B81A4976F83cA88543a0C51b8` vamsETH | msETH | 5.1.0 | 3,298.74 | $6,091,500 | 1 |
| 5 | ETH | `0xd1C117319B3595fbc39b471AB1fd485629eb05F2` vaETH | ETH | 5.0.1 | 956.80 | $2,035,151 | 7 |
| 6 | OP | `0xdd63ae655b388Cd782681b7821Be37fdB6d0E78d` vawstETH | wstETH | 5.1.1 | 468.5584 | $1,243,017 | 3 |
| 7 | ETH | `0x103cc17C2B1586e5Cd9BaD308690bCd0BBe54D5e` vETH (legacy) | WETH | 2.0.0 | 455.55 | $968,982 | 1 |
| 8 | OP | `0x539505Dde2B9771dEBE0898a84441c5E7fDF6BC0` vaUSDC | USDC | 5.1.1 | 835,476.96 | $835,330 | 2 |
| 9 | ETH | `0xa8b607Aa09B6A2E306F93e74c282Fb13f6A80452` vaUSDC | USDC | 5.0.1 | 488,409.43 | $488,289 | 1 |
| 10 | Base | `0x82562507429876486B60AF4F32390ef0947b3d13` vaETH | ETH | 5.1.0 | 195.65 | $416,164 | 2 |
| 11 | ETH | `0x4B2e76EbBc9f2923d83F5FBDe695D8733db1a17B` vWBTC (legacy) | WBTC | 2.0.0 | 4.0801 | $306,295 | 1 |
| 12 | OP | `0xCcF3d1AcF799bAe67F6e354d685295557cf64761` vaETH | ETH | 5.1.0 | 120.93 | $256,993 | 1 |
| 13 | ETH | `0x0C49066C0808Ee8c673553B7cbd99BCC9ABf113d` vUSDC (legacy) | USDC | 2.0.0 | 188,223.38 | $188,177 | 1 |
| 14 | ETH | `0x0538C8bAc84E95A9dF8aC10Aad17DbE81b9E36ee` vaDAI | DAI | 5.0.1 | 76,152.93 | $76,148 | 2 |
| 15 | ETH | `0xDD9F61a85fFE73E41eF889817972f0B0AaE6D6Dd` vaRETH | rETH | 5.0.2 | 19.85 | $49,543 | 3 |
| 16 | ETH | `0x01e1d41C1159b745298724c5Fd3eAfF3da1C6efD` vaWBTC | WBTC | 5.0.1 | 0.5238 | $39,325 | 1 |
| 17 | ETH | `0xc14900dFB1Aa54e7674e1eCf9ce02b3b35157ba5` vaFRAX | FRAX | 5.0.1 | 24,229.48 | $23,979 | 1 |
| 18 | ETH | `0xef4F4604106de23CDadfEAE08fcC34602cB475C1` vaLINK | LINK | 5.0.1 | 2,081.45 | $22,165 | 1 |
| 19 | Base | `0x1e41238aCd3A9fF90b0DCB9ea96Cf45F104e09Ef` vaUSDC | USDC | 5.1.0 | 22,060.32 | $22,055 | 2 |
| 20 | Base | `0x46fb68Eb2b1Fc43654AbaE5691D39D18D933E4b4` vawstETH | wstETH | 5.1.0 | 1.2841 | $3,406 | 0 |
| 21 | ETH | `0x650CD45DEdb19c33160Acc522aD1a82D9701036a` vaCBETH | cbETH | 5.1.0 | 0.8175 | $1,989 | 1 |
| 22 | OP | `0x19382707d5a47E74f60053b652Ab34b6e30Febad` vaOP | OP | 5.1.0 | 6,116.78 | $618 | 1 |
| 23 | Base | `0x3899a6090c5C178dB8A1800DA39daD0D06EeEFBE` vacbETH | cbETH | 5.1.0 | 0.1357 | $330 | 0 |
| | | | | | **23 pools** | **$77,532,087** | **44** |

DefiLlama quotes **$87.36M** for the same protocol ($78.36M ETH + $6.54M Base + $2.34M OP). The gap is valuation, not custody: DefiLlama marks msETH/msUSD at/above par, while the live secondary market has msUSD at **$0.813** and msETH at **$1,846.6** (13.2 % below ETH). $25.98M of the $77.53M is msUSD and $31.18M is msETH. **The pool's own `pricePerShare` uses book value, not this market price**, which is the exposure described in §5.3.

The three legacy 2.0.0 pools are a different architecture (immutable `Controller 0xa4F1671d3Aee73C05b552d57f2d16d3cfcBd0217`, one `VesperBridgeStrategy` each); they are enumerated separately but counted.

Full per-pool/per-strategy dump: `analysis/state-{1,8453,10}.json`, table in `analysis/fleet-table.md`, CI copy in `ci-out/fleet.json`.

---

## 3. Access-control map (fork-proven, not inferred)

Pool implementations are `VPool` v5.0.1 / v5.0.2 / v5.1.0 and `VETH`/`VUSDC`/`VWBTC` for the legacy pools (Etherscan-verified: `0x3ceddef5…`, `0xd948ba1b…`, `0x91f92f75…`, Base `0x67006c2e…`/`0x097f419a…`, OP `0x65595214…`/`0x5c39cd35…`/`0x44edc69f…`/`0xffa0075c…`), behind `TransparentUpgradeableProxy`. Accountants are `PoolAccountant` v5.0.0 (`0x95561370…`, `0xd5fba168…`).

### 3.1 Pool level

| Function | Who can call it | What a fresh EOA gets (live fork) |
|---|---|---|
| `deposit` / `depositAndClaim` / `depositWithPermit` | anyone | succeeds, user-scoped |
| `withdraw` / `withdrawAndClaim` / `whitelistedWithdraw` | anyone | succeeds, user-scoped (`whitelistedWithdraw` is a **deprecated alias with no whitelist** in 5.0.x) |
| `transfer` / `transferFrom` / `approve` / `permit` / `multiTransfer` | anyone | user-scoped |
| `reportEarning(profit,loss,payback)` | **must be a registered active strategy** | `revert "16"` (`STRATEGY_IS_NOT_ACTIVE`) on **11/11** ETH pools and **4/4** OP pools |
| `reportLoss(loss)` | **must be a registered active strategy** | `revert "16"` |
| `migrateStrategy(old,new)` | `onlyGovernor` | `revert "not-governor"` |
| `sweepERC20(token)` | `onlyKeeper` | `revert "not-a-keeper"` |
| `pause` / `unpause` / `shutdown` / `open` | `onlyKeeper` | `revert "not-a-keeper"` |
| `updateUniversalFee` / `updateMaximumProfitAsFee` / `updateMinimumDepositLimit` / `updatePoolRewards` / `setup` | `onlyGovernor` | `revert "not-governor"` |
| `transferGovernorship` / `acceptGovernorship` | `onlyGovernor` / proposed governor | revert |
| `addKeeper` / `removeKeeper` / `addMaintainer` / `removeMaintainer` | `onlyKeeper` | `revert "not-a-keeper"` |

The critical nuance: **`VPool.reportEarning` has no modifier at all**. It takes `_strategy = _msgSender()` and forwards to `PoolAccountant.reportEarning`, whose first statement is `require(strategy[_strategy].active, "16")`; `PoolAccountant.reportEarning` is itself `onlyPool`. The strategy whitelist is the *only* gate — and it holds on every pool. It also enforces `token.balanceOf(strategy) >= profit + payback`, so a strategy cannot book profit it does not hold.

### 3.2 Strategy level (v6.0.x `Strategy` base, UUPS)

| Function | Gate | Fork result |
|---|---|---|
| `withdraw(amount)` | `onlyPool` | `Unauthorized()` |
| `rebalance(minProfit,maxLoss)` | `onlyKeeper` | `Unauthorized()` |
| `sweep(token)` | `onlyKeeper` (and the destination is `feeCollector`) | `Unauthorized()` |
| `swapToCollateral` / `claimAndSwapRewards` / `approveToken` | `onlyKeeper` | `Unauthorized()` |
| `addKeeper` / `removeKeeper` / `updateFeeCollector` / `updateSwapper` | `onlyGovernor` (= pool governor) | revert |
| `upgradeToAndCall` | `onlyProxy` + `_authorizeUpgrade` `onlyGovernor` + governor-invariance check | revert |

Verified on **25 v5/v6 Ethereum strategies + 6 Base + 7 Optimism** (plus the 3 legacy bridge strategies, probed via their own `onlyKeeper`/`onlyController` gates). Legacy strategies that do not implement the v6 selector revert bare, which is still closed.

### 3.3 Privileged actors

| Role | Address | Form |
|---|---|---|
| Pool governor (11 ETH v5 pools), owner of every ProxyAdmin, owner of the legacy `Controller`, governor of the `Keeper` contract, **and governor of the 4 Optimism pools** | `0x9520b477Aa81180E6DdC006Fc09Fb6d3eb4e807A` | **Gnosis Safe 3-of-6** (`masterCopy 0xd9db270c…`, owners `0xa130…, 0xc790…, 0xb398…, 0xB5Ab…, 0x25FC…, 0xf3e9…`, nonce 1204) |
| Base governor + Base ProxyAdmin owner | `0x32934AD7b1121DeFC631080b58599A0eaAB89878` | same **3-of-6** Safe (same signer set; also the OP pool governor) |
| vaRETH governor | `0x1a32036fe8342143fe198b43cdafd1cc32d78b2c` | **TimelockController** (`impl 0x6bd9d85e…`, admin `0x9b13c013…`) |
| ProxyAdmins | `0xe647951b…` (most ETH), `0xa924b672…` (vaCBETH, vaRETH), `0xa1d7046f…` (vaSTETH), `0x5173c8e2…` (Base) | owned by the Safe/Timelock |
| Keeper router | `0xf7364E230EA0e5CC41E6Cd4E2a30A26Ca1850b73` | `Keeper` proxy (`impl 0xc2f8037a…`); `execute(target,data)` is `onlyKeeper`, `sweep` is `onlyGovernor`. Its 5 keepers are EOAs, one of which (`0xdf826ff6…`) is an **EIP-7702 smart account** delegated to MetaMask `EIP7702StatelessDeleGator 0x63c0c19a…` |
| Strategy keepers (direct) | `0x26d4333e…`, `0x1cbfae03…`, `0x76d266df…`, `0x169e2ffc…`, `0xf5f5195c…`, Base `0x3ed78845…` | EOAs |

No privileged role is reachable without a signature. The 3-of-6 Safe is a real multisig; vaRETH sits behind a timelock.

---

## 4. Economics — what the fork proved

`poc/test/VesperFleetProbe.t.sol` (Ethereum, 13 tests), `poc/test/VesperFleetBase.t.sol` (Base, 2), `poc/test/VesperFleetOptimism.t.sol` (OP, 3). **18 tests, all pass.**

| Test | Setup | Result |
|---|---|---|
| `test_eth_pool_registry_and_state` / `test_base_registry` / `test_op_registry` | read every pool + strategy | matches §2 |
| `test_reportEarning_reportLoss_revert_all_pools` | fresh EOA calls both on 11 ETH + 4 OP pools | **all revert "16"** |
| `test_admin_paths_revert_all_pools` | 8 privileged selectors × 11 pools | **88/88 revert** |
| `test_strategy_paths_revert_all_pools` | 7 privileged selectors × 25 strategies | **175/175 revert** (`Unauthorized()` where v6) |
| `test_base_privilege_paths_revert` / `test_op_privilege_paths_revert` | 5+4 pools, 13 strategies | **all revert** |
| `test_roundtrip_never_profitable_vaETH` | deposit 10 ETH, `withdrawETH` | **exactly 10 ETH back (delta 0)** |
| `test_jit_probe_vaETH_convex` | deposit 10,000 ETH, keeper rebalance, exit | **exactly 10,000 ETH back**; the Convex keeper `rebalance` itself **reverts** |
| `test_donation_attack_unprofitable_vaETH` | deposit 200 WETH + donate 50 WETH, exit | **958.64 WETH back → −41.36 WETH** (donation is value-destructive; mint rounds *up*) |
| `test_inflation_attack_unprofitable_vaWBTC` | mint 0.001, donate 0.02, victim 0.05, exit | **−0.02 WBTC** |
| `test_jit_credit_line_probe_vaFRAX` | deposit 30M FRAX, real keeper `rebalance`, exit | profit reported **325.56 FRAX**, attacker exits **+313.19 FRAX (~$310)** |
| `test_measure_rebalance_profit` | simulate **every** live keeper `rebalance` | table below; total realised ≈ **$1,250** |
| `test_phantom_debt_dummy_strategies` | 4 dummy strategies | `tvl() = 0` on all 4; vaDAI dummy debt = **74,130.56 DAI** |
| `test_op_vaUSDC_sonne_is_illiquid` | Sonne USDC market | **`getCash() = 0`**, strategy idle USDC.e = 0 |
| `test_legacy_sweepErc20_is_public_but_dust` / `test_legacy_rebalance_reverts` | 2020 pools | 1 HEX held; `rebalance()` → `caller-is-not-keeper` |

### 4.1 Measured per-rebalance realised profit (the JIT ceiling)

| Pool | Strategy | Profit realised | ≈USD | status |
|---|---|---|---:|---:|---|
| vaFRAX | `0x56797811…` Fraxlend | 325.56 FRAX | $322 | OK |
| vaUSDC | `0x09d839f7…` Vesper2 | 518.08 USDC | $518 | OK |
| vaETH | `0x91f7e202…` Morpho | 0.1475 ETH | $314 | OK |
| vaETH | `0x30547278…` Vesper2 | 0.02516 ETH | $54 | OK |
| vamsUSD | `0x351567b6…` Morpho | 49.94 msUSD | $41 | OK |
| vaDAI | `0xf2ce6126…` Yearn | 0.2489 DAI | $0.25 | OK |
| vaCBETH | `0xe6d6af59…` Aave | **−19,632 wei** (loss) | −$0.00005 | OK |
| vaSTETH / vaWBTC | Cap / Aave | 1 wei / 1,228 wei | $0 | OK |
| vamsETH / vamsUSD | MorphoV2 ×2 | 0 | $0 | OK |
| **others** | Convex, StakeDao ×2, Aave-Xy, Morpho(msETH), Maker/Aave stETH, LINK, RETH ×3, all dummies | **revert** | — | not harvestable |

**Total per fleet-wide cycle ≈ $1,250.** The four strategies with the largest mark-to-market gap (`tvl() − debt` ≈ $106k combined) are precisely the ones whose `rebalance()` reverts today, so that gap is **not** extractable.

### 4.2 Why JIT is not a drain

A JIT deposit of $D into a pool of size $S raises `tokensHere`, which raises `_availableCreditLimit`; the keeper's `reportEarning` then re-lends the fresh deposit to the strategy (`token.safeTransfer(strategy, creditLine − totalPayback)`). The attacker's exit therefore depends on the strategy's same-tx liquidity. In the vaFRAX test Fraxlend returned 30M FRAX instantly, so the round trip closed; on an illiquid strategy it becomes a partial withdrawal and the attacker eats the shortfall. This is the main reason the path cannot be scaled to principal.

---

## 5. Live-state assessment

### 5.1 Implementations and proxies

| Pools | Impl | ProxyAdmin |
|---|---|---|
| ETH vaUSDC/vaDAI/vaFRAX/vaLINK/vaWBTC | `0x3ceddef5…` VPool 5.0.1 | `0xe647951b…` |
| ETH vaCBETH/vamsETH/vamsUSD | `0x91f92f75…` VPool 5.1.0 | `0xe647951b…` / vaCBETH `0xa924b672…` |
| ETH vaETH | `0xf296b111…` VETH 5.0.1 | `0xe647951b…` |
| ETH vaRETH/vaSTETH | `0xd948ba1b…` VPool 5.0.2 | `0xa924b672…` / `0xa1d7046f…` |
| Base ×4 | `0x67006c2e…` VPool 5.1.0 | `0x5173c8e2…` |
| Base vaETH | `0x097f419a…` VETH 5.1.0 | `0x5173c8e2…` |
| OP vaETH/vaOP/vaUSDC/vawstETH | `0x65595214…` VETH 5.1.0 / `0x5c39cd35…` / `0x44edc69f…` / `0xffa0075c…` | Safe-owned |
| ETH vETH/vUSDC/vWBTC (legacy) | verified 0.6.12, not a proxy | n/a |

All upgradable pools are initialized (non-zero supply, correct accountant, `initialize()` consumed). No pool is `paused`, none has `stopEverything = true`.

### 5.2 Accountants

One `PoolAccountant` per pool, all `TransparentUpgradeableProxy` over `0x95561370…` (v5.0.0) or `0xd5fba168…` (5.1). **`externalDepositFee = 0` on all 20 v5 pools** — no deposit cost, which is what makes the JIT path free to enter.

### 5.3 Booked NAV vs realisable backing — `analysis/backing.py`

For each pool: `tokensHere + Σ strategy.tvl()` (v6) or `Σ strategy.totalValue()` (v3-era) vs `totalValue()`, with an explicit illiquidity override for the Sonne position.

| Pool | Booked | Realisable | Shortfall |
|---|---:|---:|---:|
| **vaDAI (ETH)** | 76,152.93 DAI | **2,022.61 DAI** | **97.344 %** |
| **vaUSDC (OP)** | 835,476.96 USDC | **44,167.77 USDC** | **94.713 %** |
| vaLINK | 2,081.45 LINK | 2,075.98 LINK | 0.263 % |
| vaETH (ETH) | 956.80 ETH | 1,079.81 ETH | −12.85 % (over) |
| vaSTETH | 6,296.06 stETH | 6,346.46 | −0.80 % (over) |
| all others | — | at or above par | ≤0.13 % |

**Dead strategies still booked as active with debt** (`tvl() = 0`, `debt > 0`):

| Strategy | Pool | Debt | `lastRebalance` | `debtRatio` |
|---|---|---:|---|---:|
| `0x084aFb5e91A043C2959E70739B346416ea7F6f7F` `Rari_Dummy_DAI` | vaDAI | 74,130.56 DAI | 2026-09-17 | 0 |
| `0xa407da5ad1802C7807d40c64aB5B33A1C7D65D59` `Sommelier_Dummy_ETH` | vaETH | 5.798 ETH | 2026-07-20 | 0 |
| `0xaDcE6FDdD868E865E4D56000832791fdeb29eeda` `Euler_Dummy_ETH` | vaETH | 1.486 ETH | 2023-10-01 | 0 |
| `0x8F454223C6c59df903812a0C0d9375eDb6089d5F` `Maker_Dummy_STETH` | vaSTETH | 3.392 stETH | 2024-08-09 | 0 |

Only the vaDAI one is **unbacked**; the vaETH/vaSTETH dummies are absorbed by excess in sibling strategies.

### 5.4 The Optimism vaUSDC / Sonne hole

`Sonne_USDC 0x64Ef984FDaA7D13d71AaDeEe50E5826a69B33c76` (v5.1.0, `lastRebalance 2025-04-12`, `debtRatio 0`) holds **7,492,099,806,525,099 sUSDC = 47 % of the entire Sonne USDC market** (`totalSupply 1.593e16`). `exchangeRateStored = 2.195e14` marks it at **1,644,557 USDC**, but:

- Sonne USDC `getCash() = 0` (the market has no lendable cash),
- `totalBorrows = 3.5M USDC`, `totalReserves ≈ 2k USDC` — the book is dominated by bad debt,
- the strategy's idle USDC.e balance is **0**, and
- calling `strategy.withdraw(1000e6)` **as the pool** succeeds while transferring **nothing**.

So the pool's `totalValue()` of 835,476.96 USDC is backed by 498,058 wei of idle USDC.e plus a 44,167-USDC Aave position. **$791.3k of OP vaUSDC is stuck (S)**, and the pool's `pricePerShare` (1.104389) is ~18× its realisable backing.

### 5.5 Legacy v2.0.0 pools

- `vETH 0x103cc17C…` — 455.55 WETH; strategy `VesperBridgeStrategy 0x99BFef73…` holds `vETH2 0x951397286E4b78aE5827502ed494d7902D3CCA8C`, `totalLocked = 455.55`, `isUpgradable() = false`.
- `vUSDC 0x0C49066C…` — 188,223.38 USDC; strategy `0x6D7d6DB9…` holds `vUSDC2 0xc1eFBeE3…`.
- `vWBTC 0x4B2e76Eb…` — 4.0801 WBTC; strategy `0x4f1d2b92…` holds `vWBTC2 0xd25ee850…`.
- `Controller 0xa4F1671d…` is `Owned`; `owner() = 0x9520b477…` (the 3-of-6 Safe). `updateStrategy`, `executeTransaction(s)` and `addPool` are `onlyOwner`.
- `sweepErc20(address)` is **permissionless** and swaps any non-reserved token to the collateral via Uniswap V2 with `amountOutMin = 1`. Live non-reserved balance: **1 HEX** (~$0.005) plus two worthless spam tokens.
- `rebalance()` is permissionless at the pool but always reverts (`caller-is-not-keeper`) because the pool is not a keeper on its own strategy. `withdrawByStrategy` is gated by `feeWhiteList`.

---

## 6. What an attacker can and cannot do

**Closed (fork-proven):**

1. `reportEarning` to mint yourself fee shares or inflate debt — the accountant requires `strategy[msg.sender].active`; there is no path to become a strategy without the Safe.
2. `migrateStrategy` to an attacker-controlled strategy — `onlyGovernor`, and the new strategy must already return `pool() == this`.
3. Sweep pool or strategy tokens — `onlyKeeper`/`onlyGovernor`; the strategy `sweep` destination is the `feeCollector`.
4. Upgrade a pool or a strategy — `ProxyAdmin`/`_authorizeUpgrade` both resolve to the Safe (or the vaRETH timelock).
5. Donation / share-price inflation — minting rounds **up**, so the attacker pays more than the victim's rounds-to-zero gain. Measured −41.36 WETH (vaETH) and −0.02 WBTC (vaWBTC).
6. First-depositor capture when `totalSupply == 0` — every pool has non-zero supply; `pricePerShare()` returns 1e18 only when `totalValue == 0`, in which case there is nothing to take.
7. Withdrawal-queue asymmetry — a partial withdrawal burns the *smaller* of requested and proportional shares and pays only what was received; the residual stays in `tokensHere`.
8. Legacy `sweepErc20` abuse — dust only (1 HEX).

**Open but economically negligible:**

9. **JIT yield dilution** around a keeper `rebalance()`. Requires winning the ordering race for that transaction, needs the deposit returned by the strategy in the same block, and the gain is exactly the profit realised in that tx minus the universal fee. Fork-measured ceiling: **≈$1,250 per fleet-wide cycle**, of which ~$840 sits on ETH/USDC/FRAX pools that *are* flash-fundable.

**Latent (P-class, not attacker-reachable):**

10. The 3-of-6 Safe can `migrateStrategy` to a contract it controls, upgrade any pool/strategy, sweep, or mint. One key is not enough; three are.
11. `Keeper.execute` can call anything as the keeper. Its keeper set is 5 EOAs (one a 7702 smart account). Compromise of any one lets an attacker force rebalances and choose `minProfit/maxLoss` — a much stronger JIT position than an outsider's.

---

## 7. PoC / fork verification

- Project: `poc/` (Foundry, solc 0.8.24, `poc/lib/forge-std` vendored). Tests pin a fork to `head − 32` so load-balanced public RPCs cannot disagree.
- Suites: `VesperFleetProbe.t.sol` (13), `VesperFleetBase.t.sol` (2), `VesperFleetOptimism.t.sol` (3) — **18/18 pass**.
- Local run at fork block ~26,381,3xx (ETH) / 55,427,9xx (Base) / 159,339,2xx (OP). No mainnet transaction.
- CI: `artsbykriss/ca-zombie-ci`, branch `ca3-open-vesper`, workflow `poc.yml`; `ci/run.sh` refreshes the three snapshots, renders `ci-out/fleet.json` and `ci-out/backing.json`, and runs a secret scan. Run URLs in §10 and `ci-log.txt`.

---

## 8. Verdict and residual risk

**Verdict: E-U $0 for principal, high confidence.** A fresh EOA cannot move one wei out of the 23-pool, $77.5M fleet. Every pool-level and strategy-level value function was exercised on a fork and rejected on every chain.

**E-U income ≈ $1,250 per full rebalance cycle (medium confidence).** Real and fork-proven, but dilution of already-earned yield, not extraction of principal.

**H-O:** holders can always self-withdraw (no pause, no shutdown). In vaDAI they race over **$2,022.61 of real assets against $76,152.93 of claims**; in OP vaUSDC over **$44,167 against $835,477**.

**P:** 3-of-6 Safe + vaRETH TimelockController + 5 keeper EOAs.

**S:** **$74,130.56 DAI (≈$74,126)** of vaDAI NAV is phantom debt against a `Rari_Dummy_DAI` with `tvl() = 0`; **$791,309 of OP vaUSDC** sits in a Sonne market with zero cash and a strategy that transfers nothing on withdraw. **Total stuck ≈ $865,435.**

**Blockers / caveats:** (a) four strategies are v1/v3/v5.1-era contracts probed by selector rather than line-by-line source audit; (b) JIT numbers are a one-cycle snapshot and depend on keeper cadence; (c) `Cap_wstETH` marks its position in wstETH while pool debt is stETH, so vaSTETH's −0.80% is approximate; (d) the Sonne mark uses `exchangeRateStored`, which may itself be stale — but with `getCash()=0` no mark is realisable; (e) the legacy v2 stack is a chain of book-value claims.

---

## 9. Methodology and sources

1. **Enumerate by registry, not by blog.** Three official API hosts (14 + 5 + 4 = 23), cross-checked against DefiLlama's `currentChainTvls` (Ethereum / Base / OP Mainnet).
2. **Verify deployed reality.** Etherscan V2 `getsourcecode` for every pool, accountant and strategy impl; EIP-1967 impl/admin slots; `cast codesize` for every role; Gnosis Safe `getOwners()/getThreshold()`; EIP-7702 delegation designator decoded from the keeper's code (`0xef0100…`).
3. **Read every money path.** `VPool`/`VETH`/`PoolAccountant`/`Governable`/`Pausable`/`PoolStorage` read in full; every `external` function classified by modifier. The v6 `Strategy` base read in full; 11 strategy families checked for additional externals.
4. **Measure live value.** `totalValue`, `totalDebt`, `tokensHere`, `totalSupply`, `pricePerShare`, per-strategy `debt`/`tvl`/`lastRebalance`/`debtRatio`, `externalDepositFee`; USD via `coins.llama.fi/prices/current`.
5. **Prove on a fork.** Foundry `vm.createSelectFork`, `vm.prank`, `deal`/`vm.deal`; attacker delta measured in the underlying asset.
6. **Separate categories.** E-U / E-U-conditional / H-O / P / S are kept distinct in every number.

**Corrections this pass makes to the corpus:**

- `ca3-recon` S05 lists **19** pools (ETH+Base). The prod registry also has **4 Optimism pools** worth **$2.34M** (`api-optimism.vesper.finance`), which the reconciliation omitted. The fleet is 23 pools / $77.53M booked.
- `ca3-recon` says "ETH $78.46M + Base $6.56M + OP $2.34M". That is DefiLlama's mark. On-chain `totalValue` is **$75.20M ETH + $6.54M Base + $2.34M OP = $77.53M** — the ETH difference is almost entirely the msETH/msUSD mark (DefiLlama at/above par vs spot $1,846.6 / $0.813).
- `ca3/research/defillama-new.md` §4.7's "Vesper V2 — CLOSED" examined the v2 **PeggedToken/Treasury** contracts (`USDv 0xc9ad6ed9…`, `0x025a05f1…`), **not** this 23-pool fleet.
- Two pools are materially broken and were not on any prior watchlist: **vaDAI (97.34% unbacked)** and **OP vaUSDC (94.71% stuck in Sonne)**.

**Files:** `analysis/scan.py` (fleet reader), `analysis/report.py` (USD table), `analysis/backing.py` (booked vs realisable), `analysis/state-*.json` (pinned snapshots), `analysis/prices.json`, `poc/**`, `ci/run.sh`, `ci-out/**`, `summary.json`.

---

## 10. CI

GitHub Actions on `artsbykriss/ca-zombie-ci`, branch `ca3-open-vesper`, workflow `poc.yml`.

| Item | Value |
|---|---|
| Run URL | _filled after the run_ |
| Tests | 18 / 18 pass |
| Artifacts | `ci-out/fleet.json`, `ci-out/backing.json`, `ci-out/fleet-table.txt`, `ci-out/backing.txt` |

**Read-only attestation.** Every check in this folder is `eth_call`, `eth_getStorageAt`, `balanceOf`, a public HTTP GET, a static source read, or a Foundry fork simulation. No key was used, no transaction was signed, no mainnet state was modified.
