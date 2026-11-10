# ETH lane digest — Zenji sibling tests on Ethereum

Read-only, block 26,381,000 (DefiLlama prices 2026-11-10: wstETH $2,654.78, WBTC $74,941.92).
Raw dumps and verified sources: `analysis/children/eth-scan/evidence/`. This digest only records
claims I re-read myself; anything not re-read is marked "child".

| Protocol | Contracts | Keeper path probed | (a) unpermissioned? | (b) pool-priced NAV/LTV? | (c) pool-derived minOut? | Verdict |
|---|---|---|---|---|---|---|
| YieldBasis — 11 live LT markets, $93.08M equity | LTs incl. `0x722FC364…29F9`, `0x651D4b81…5BAa`, `0x771F7290…23Ec`, `0x2B9c9f3B…3cEa`; factory `0x370a449F…00c0` | bytecode selector scan + `eth_call` | **NO** — no `rebalance()` 0x7d7c2a1c, `harvest()` 0x4641257d or `report()` 0x2606a10b; the only permissionless protocol trade is `distribute_borrower_fees()` (accrued interest ≈ $1,809 protocol-wide, donated back to the pool) | **NO** — NAV uses a bounded `price_scale` EMA + LEVAMM invariant, not pool spot; `exchange()` asserts the invariant cannot decrease | only in the sub-$2k fee path | **not-zenji** |
| Fluid Lite (ex-Instadapp Lite) iETHv2 $148.9M, USD v2 $40.46M | vault `0xA0D3707c…Be78` / `0x273DA948…9012`; rebalancer `0x47503517…`; modules `0x44feDC1F…` | `rebalanceFromWeETHToWstETH` / `rebalanceFromWstETHToWeETH` / `updateExchangePrice` | **NO** — `onlyRebalancer`, proven by `eth_call` revert `0x78fb3fe5 = Helpers__NotRebalancer()`; USD vault is `onlyStrategyHandler` | stored `exchangePrice` checkpoint / fixed-rate accrual, not DEX spot | n/a | **not-zenji (strongest funded near-miss)** |
| Gearbox v3 Credit Manager (wstETH CM $7.46M debt, $19.38M protocol) | `0x00689539…3EE5` | `liquidateCreditAccount` | yes in principle (permissionless) | **NO** — Chainlink feeds with staleness checks (`IPriceOracleV3`) | n/a | **not-zenji** |
| Curvance | lending markets | no leveraged-LP keeper | **NO** | money-market oracle | n/a | **not-zenji** |
| LlamaLend leverage zaps / wrappers | stateless zaps | user-supplied call | yes | n/a | caller-supplied | out of class |
| Yearn v3 `report()`, StakeDAO CLM harvest, Beefy `harvest()` | controls | `report`/`harvest` | **YES** (proven in prior passes) | **NO** — no debt, no LTV | n/a | controls |

**Result: 15 candidates + 3 controls; 0 pass all three tests.** The two exact-code Zenji pmUSD vaults (`0xB415bce7…c31F`, `0x45bBa5E1…1595`) pass (a)(b)(c) but hold **$0**. Full detail: `analysis/children/eth-scan/REPORT.md`. The blockers are structural, not
price-dependent: the only permissionless keeper functions belong to contracts that hold no debt
(controls), and every leveraged system either gates its keeper (`onlyRebalancer`, `Access`, role
checks) or prices positions from an oracle the keeper cannot move.

Notes:
- YieldBasis' 11 LT markets are one protocol family but are counted as 11 rows because each is a
  separate leveraged LP contract. Their on-chain debt is material (raw `debt` fields in
  `evidence/yb_markets_live.txt`), but with no keeper entry point the Zenji recipe cannot start.
- Gearbox liquidation is economically a **different** recipe (liquidation bonus), and its collateral
  price is an external oracle; skewing a DEX pool does not move `IPriceOracleV3`.
- Fluid Lite's `onlyRebalancer` is owner-managed; a compromised/rogue rebalancer is a P-class risk,
  not an E-U path.
