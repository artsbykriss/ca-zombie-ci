# InsureDAO — key evidence citations (address + block + call)

All reads are `eth_call` (read-only) at the stated block. RPCs: keyless public endpoints. No transaction was sent.

## Ethereum (v1) — head block 26,185,830; pinned verification block 26,185,000

| # | Claim | Call | Block | Result |
|---|---|---|---|---|
| E1 | Vault holds 122,292.300439 USDC; par price | `0x131fb74C…144.valueAll()` / `balance()` / `totalAttributions()` | 26,185,000 | 122,292,300,439 / 122,292,300,439 / 122,292,300,439 |
| E2 | Vault controller unset, no debt | `controller()` / `totalDebt()` / `keeper()` | 26,185,000 | 0x0 / 0 / 0x0 |
| E3 | USDC balance (incl. 100 wei donation) | `USDC.balanceOf(vault)` | 26,185,000 | 122,292,300,539 |
| E4 | CDS market holds the largest share | `vault.attributions(0x86c82E8c…)` | 26,185,830 | 59,793,841,027 |
| E5 | PoolProxy fee dust | `vault.attributions(0xF4d046D8…)` | 26,185,830 | 3,215,129 |
| E6 | 29 markets registered | `Registry.getAllMarkets()` | 26,185,000 | 29 addresses |
| E7 | Owner = PoolProxy; admins = 3-of-5 Safe | `Ownership.owner()`, `Parameters.getOwner()`, `PoolProxy.ownership_admin()`, Safe `getThreshold()/getOwners()` | 26,185,300 | 0xF4d046D8… / same / 0x54bE2F27… / 3 / 5 owners |
| E8 | No reporting admin anywhere | `PoolProxy.default_reporting_admin()`, `reporting_admin(m)` ∀29, `get_reporter(m)` | 26,185,830 | 0x0 / 0x0 / 0x0 |
| E9 | All pools Trading & unpaused | `marketStatus()` / `paused()` ∀26 PoolTemplate markets | 26,185,000 | 0 / false |
| E10 | Share price exactly par | `getPricePerFullShare()` | 26,185,306 | 1,000,000 |
| E11 | Market solvency to the wei | `attributions(m) == originalLiquidity(m) + attributionDebt(m)` for all 25 pools | 26,185,000 | exact (see classify.py) |
| E12 | Stale lock on 0x8c494310 | `lockedAmount()` / `insurances(0)` | 26,185,000 | 11,820,670,000 / end 2022-10-23, status true |
| E13 | H-O withdrawal works | CDS `withdraw(20328382)` tx `0x7ae834ac…`, `withdraw(109397189)` tx `0xad5d0236…` | 2026-09-19 / 2026-04-28 | 20.33 / 109.40 USDC paid out |
| E14 | Open template | `Factory.templates(0x1dcd35cf…)`, `reflist(...,0,0x0)`, `conditionlist(...,0)` | 26,185,302 | (true,true,false) / true / 1e9 |
| E15 | Staking LP composition | `UNI-V2.getReserves()` on `0x1b459aec…`, gauge `totalSupply()` on `0xf57882cf…` | 26,185,300 | 0.52094149 WETH + 5,067,155.03 INSURE; gauge 1,582.94016 |
| E16 | vlINSURE frozen INSURE | `INSURE.balanceOf(0xA12ab76a…)` / `lockIncentive()` / `incentiveInsure()` | 26,185,300 | 10,754,075.28 / 0 / 0 |
| E17 | veINSURE lock | `INSURE.balanceOf(0x3dc07E60…)` | 26,185,300 | 5,412,108.29 |

## Fork PoC (12/12 PASS) — GitLab pipeline 2944108622

| # | Test | Key result |
|---|---|---|
| P1 | `test_02_attacker_vault_paths_revert` | 9 attacker vault calls revert with exact gate messages |
| P2 | `test_05_open_template_market_creation` | market created + listed (1,000 USDC), `withdrawCredit` pending = 0, market holds 0 USDC |
| P3 | `test_08_honest_lp_withdraw` | sole holder withdraws exactly 10,000 USDC (H-O) |
| P4 | `test_09_admin_fee_sweep…` | sweep succeeds; allocations 25/50/25; attacker balance 0; `distribute` reverts |
| P5 | `test_10_unlock_expired_policy` | lockedAmount 11,820,670,000 → 0 (public `unlock`) |
| P6 | `test_11_index_premiums` | index pendingPremium = 1,559,027 raw (index-owned) |

## Side chains — blocks 514,519,558 (Arb) / 158,159,954 (OP) / 15,064,424 (Astar)

| # | Claim | Call | Result |
|---|---|---|---|
| S1 | Arbitrum vault | `0x968C9718….valueAll()` / `totalAttributions()` / `totalDebt()` / `controller.managingFund()` | 607,055,148 / 516,450,932 / 0 / 607,055,148 |
| S2 | Optimism vault | `0x54F23d2f….valueAll()` / `totalAttributions()` | 232,764,196 / 204,708,765 |
| S3 | Astar vault (v1 code) | `0x190dA1B9….valueAll()` / `keeper()` / `token()` | 548,239,573 / 0x0 / USDC 0x6a2d262d… (6 dec) |
| S4 | Owner EOA on all 3 chains | `Ownership.owner()` = 0x2c9bc901… (code len 0) | Arb / OP / Astar |
| S5 | Owner EOA attributions | `vault.attributions(0x2c9bc901…)` | Arb 376,475,435 / OP 153,800,391 / Astar 18,863,572 |
| S6 | Market attribution sums | Σ `vault.attributions(market)` over registered markets | Arb 139,975,423 (12) / OP 50,908,348 (37) / Astar 453,672,979 (15) |
