# Hover — live-state summary (Kava EVM 2222)

**Block:** 23,034,510 (chain ts 1792058644 = 2026-10-15 ~10:00 UTC), re-verified at 23,035,488.
**Prices (DefiLlama, at chain ts):** KAVA $0.0685086 · ATOM $1.6864362 · USDT $0.9991027 · HOV/esHOV/xHOV: **no price** (unlisted).

## Roles & admins

| Actor | Address | Notes |
|---|---|---|
| Comptroller (Unitroller) | `0x3A4Ec955a18eF6eB33025599505E7d404a4d59eC` | impl `0xb618fb7c9921fb35a75fddf5ee1bbdf19080020c` (slot 2) |
| Admin (of comptroller, 3 markets, oracle, allowlist) | `0xcecC934494adED6c0c82C52656a845862176ceeE` | **Gnosis Safe v1.3.0, 2-of-8**; `pendingAdmin = 0` |
| Liquidator allowlist | `0x49AE3cc17eD67c9Bc9cd11E4d799c329bC90203F` | 2 entries; `allow()` owner-only |
| — entry 0 | `0x9b9FB7e3291C43F3146A9F590a421aC3C0377709` | liquidation bot #1 (unused) |
| — entry 1 | `0x608cB0F61c1e574025D3e8168078d13e2320781D` | liquidation bot #2 (used historically) |
| Bot owner / `profitWallet()` (both bots) | `0xbA6f82F77fCf03d33150fceC7384644AC12F4DD5` | EOA; last acted Nov-2025 |
| Oracle | `0xE8Ae943de7f036Cfa505127641Eee7c5b6606878` | Pyth asset-config oracle; owner = Safe |
| Pyth | `0xa2aa501b19aff244d90cc15a4cf739d2725b5729` | v1.3.0, `singleUpdateFeeInWei = 0` |

## Markets

| Market | Type | totalSupply (cTokens) | exchangeRateStored | cash | borrows | reserves | CF | mint paused | borrow paused |
|---|---|---|---|---|---|---|---|---|---|
| hKAVA `0xb51eFaF2…` | CNativeDelegator → `0x39c18a98…` (CNativeDelegate) | 2,224,575.2330 | 2.0075707062e26 | **28,572.1724 KAVA** ($1,957.48) | 18,113.00 KAVA ($1,240.94) | 2,025.244 KAVA ($138.75) | 0.60 | ✅ | ✅ |
| hATOM `0x1Bf92bE6…` | CErc20Delegator → `0x5c598741…` | 8,601.0235 | 2.1451412131e14 | **179.0266 ATOM** ($301.88) | 5.48 ATOM ($9.24) | 0.002913 ATOM | 0.35 | ✅ | ✅ |
| hUSDT `0xcE86EBc6…` | CErc20Delegator → `0x5c598741…` | 333,655.7787 | 3.0934965701e14 | **0.00001 USDT** | 12,103.44 USDT ($12,092.58) | 1,781.81 USDT ($1,780.21) | 0.85 | ✅ | ✅ |

Comptroller params: `closeFactor = 0.5`, `liquidationIncentive = 1.05`, `pauseGuardian = 0x0`, `transferGuardianPaused = false`, `seizeGuardianPaused = false`, `maxAssets = 0` (unused), markets = 3, `liquidatorsWhitelistVerifier = 0x49AE3cc1…`, `protocolTokenAddress = esHOV`, reward tokens `[esHOV, native, HOV]`, all reward speeds `= 1 wei/s` (emissions effectively off).
Comptroller reward pot (unclaimed): **673.99 KAVA + 15.97 HOV + 9.71 esHOV**.

## Total live value

| Class | Amount | USD |
|---|---|---|
| Cash in markets (holder-redeemable) | 28,572.17 KAVA + 179.03 ATOM + 0.00001 USDT | **$2,259.36** |
| Reserves (admin-only) | 2,025.24 KAVA + 1,781.81 USDT + dust | $1,918.96 |
| Borrows outstanding (receivables) | 18,113 KAVA + 12,103.44 USDT + 5.48 ATOM | $13,342.76 |
| Underwater debt (shortfall) | | $10,365.81 |
| Collateral of underwater positions | 41,922.82 KAVA (hKAVA cTokens) | $2,872.08 |
| Max gross liquidation bonus available (whitelisted bots only, needs oracle refresh) | | **≈$136.77** |
| CToken claims (totalSupply × exchangeRate) | hKAVA 44,659.4 KAVA + hATOM 184.50 ATOM + hUSDT 10,321.6 USDT | $13,683.20 |

**External-unprivileged extractable: $0.00.**

## Gate snapshot (verified by eth_call, block 23,035,488)

| Gate | Value | Evidence |
|---|---|---|
| mint paused (all markets) | true | `mintGuardianPaused(m) = true`; `hUSDT.mint(1e6)` → revert `Error("MP")` |
| borrow paused (all markets) | true | `borrowGuardianPaused(m) = true`; `hUSDT.borrow(1e6)` → revert `Error("BP")` |
| oracle live | **no** | all `getUnderlyingPrice` revert `0x19abf40e` (`StalePrice`); Pyth publishTime 1774775979 (~2026-03-29, ≈200 d stale) |
| liquidation open to outsiders | **no** | `liquidateBorrowAllowed(hUSDT,hKAVA,0x1111…,borrower,1e6)` → **1** (`UNAUTHORIZED`); whitelisted bot → reverts `StalePrice` |
| direct `seize()` | blocked | `seize()` → 3; `seizeAllowed(hKAVA, outsideCaller, …)` → **9** (`MARKET_NOT_LISTED`) |
| non-member redeem bypass | open | code path `redeemAllowedInternal` skips liquidity if `!accountMembership[redeemer]` |
| `_reduceReserves` | admin-only | returns 1 for outsider / 0 for Safe |
| `sweepToken` | admin-only | revert `"CErc20Delegator::sweepToken: only admin may call"` |
| GenesisPool `emergencyWithdraw` | admin-only | revert `"admin only"` (each pool holds its cTokens + esHOV) |
| reward claim | holder-only | `claimReward(1, attacker)` moves nothing; `rewardAccrued = 0` |

## Positions (19 with debt; 4 underwater)

See `borrowers.csv` (all 160 all-time borrowers, per-market snapshots). Key rows:

| Borrower | Collateral | Debt | Shortfall | Max repay | Gross bonus |
|---|---|---|---|---|---|
| `0x5b484cf225cc252918034653d5ff92cf979e6cb2` | 30,341.41 KAVA | 7,743.51 USDT | $6,489.37 | $1,979.67 | $98.98 |
| `0xf9c3ffa841a7618ea1c09499b4b3153bed2ee626` | 11,581.41 KAVA | 4,115.92 USDT | $3,636.17 | $755.65 | $37.78 |
| `0xb622a77180563067908549717fe5eb696c44a9df` | — | 234.84 USDT | $234.63 | $0 | $0 |
| `0xb9b6c87943f8c18e1268e481ebcd7ecf411b7e5b` | dust | 68.50 KAVA | $4.69 | ~$0 | ~$0 |
| `0x319bf294a4bfb391618890df725d7186f5debe23` (healthy) | 9,259.25 USDT | 17,637.88 KAVA | 0 | – | – |

## GenesisPools (cToken staking, esHOV rewards)

| Pool | Proxy | impl | Pool token held | esHOV held | `emergencyWithdraw` |
|---|---|---|---|---|---|
| hKAVA | `0x5450c389…` | `0xBdDB4e8B…` | 104,978.09 hKAVA cTokens (raw 10,497,809,267,083) | 68,643.55 | admin-only |
| hATOM | `0x4d06a0d5…` | `0x1C780EC2…` | 223.14 hATOM cTokens (raw 22,313,665,000) | 55,243.84 | admin-only |
| hUSDT | `0xb399cdcc…` | `0x9D7319e5…` | 26,036.79 hUSDT cTokens (raw 2,603,678,934,999) | 91,499.82 | admin-only |

`GenesisPool.totalSupplies()` = the pool's cToken balance; stakers redeem their own stake (`redeem`), rewards via `claimRewards()` (0 for outsiders). Admin for all three = the Safe.
