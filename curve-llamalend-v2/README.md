# Curve LlamaLend V2 — fresh-market deep dive (Wave B1)

**Date:** 2026-10-18 · **Chains:** Ethereum (1), Optimism (10) · **Target:** Curve LlamaLend V2 (DefiLlama $42.1M)
**Status:** read-only; no transactions signed or sent; all exploit/negative-path PoCs are local forks only.
**Scope:** every market created by the two V2 LendFactories, deployed controller/AMM/vault/controller-view blueprints, per-market oracle stacks, monetary policies, and the live state of every position.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed / open | Latent risk |
|---|---:|---|---|
| **Curve LlamaLend V2 — all 8 markets (5 ETH + 3 OP)** | **$0** | Vault uses OpenZeppelin virtual shares (`DEAD_SHARES=1000`) and direct token transfers are **not** counted in `totalAssets`; all 8 `users_to_liquidate()` sets are empty at the pinned heads; every live position has `health > 0`; oracles are EMA-damped / Chainlink / ChainOracle; `rate_write` and `configure` are gated | **E-U-conditional:** a market move that pushes a position's health below 0 opens a normal liquidation-keeper path (bonus capped by `liquidation_discount`, 0.6%–11%). Smallest observed health margin: ETH sDOLA market, **0.314%**; OP wstETH/USDC market, **~3.5%**. No position is liquidatable today. |
| Vault first-depositor / donation | $0 | Direct crvUSD transfer to the controller does not change `totalAssets`; fork PoC shows attacker PnL **−1 wei** on the minimum deposit; victim shares are fairly priced | None demonstrated |
| Oracle manipulation (flashloan) | $0 | Four ETH oracles are `ERC4626EMAWrapper` (upside EMA, `min(spot, ema)`); base is `OracleFromCurvePools` reading Curve `price_oracle` EMAs; OP uses `ChainlinkEMA` (20 obs × 30 s) over Chainlink feeds; market 4 chains `StableSwapNG LP EMA Oracle` + capped reUSD feed + crvUSD aggregator | Stale/sequencer-down Chainlink risk (no L2 uptime check); EMA downward pass-through is conservative |
| Permissionless `collect_fees` / `save_rate` / `exchange` | $0 | `collect_fees` pays only `factory.fee_receiver()`; `save_rate` is capped at 300% APY and `rate_write` is controller-only; AMM swaps are fee/dynamic-fee priced | None demonstrated |

**Total live extractable now: $0 (E-U), confidence high.**
The $39.11M of vault assets is **H-O** (lender-owned shares, withdrawable by their owners), not attacker-extractable. No P/S value is claimed.

---

## 2. Enumeration (exhaustive, by factory event)

`NewVault(uint256 indexed id, address indexed collateral_token, address indexed borrowed_token, address vault, address controller, address amm, address price_oracle, address monetary_policy)`

- ETH factory `0x8f6B56ec5DdF1f2691a1059f1D3cd97AC9EAB0Bd`: **`market_count()` = 5**; 5 `NewVault` logs (first at block 25,529,593, last at 26,147,713).
- OP factory `0x5F94073E3f51c1FFf92ffc6b4B06b7Af193B3640`: **`market_count()` = 3**; 3 `NewVault` logs (blocks 152,707,737 / 152,739,328 / 152,739,379).
- No other factory/registry getter exists; `markets(n)` mirrors the same array. All 8 vaults have code and resolve `controller()`/`amm()`; all controllers have code. Blueprints (verified, Vyper 0.4.3): AMM `0xc8ac252738e1ece3f69cf77649c266c4e893cf41`, controller `0x47b6df6494ad62474cdf365b90a56c648778a75d`, vault `0x2c3822264dcbd18d910c7834b1de8a70f368375b`, view `0x7259efd886e3a717a9206c604e0156e720871b2c` (ETH factory `amm_blueprint()/controller_blueprint()/vault_blueprint()/controller_view_blueprint()`).
- Factory admin = Curve DAO agent `0x40907540d8a6c65c637785e8f8b742ae6b0b9968` (ETH) / `0x28c4a1fa47eee9226f8de7d6af0a41c62ca98267` (OP). Factory `paused()=false`.

### Live markets (block **ETH 26,217,523 / OP 158,352,276**; health re-check at ETH 26,217,798 / OP 158,353,940)

| # | Chain | Collateral | Borrow | Vault | Controller | AMM | Oracle | Fee | A | loan_disc / liq_disc | total debt | vault totalAssets |
|---|---|---|---|---|---:|---:|---|---|---:|---:|---:|
| E0 | ETH | sDOLA `0xb45ad160…7305` | crvUSD `0xf939e0a0…1b4e` | `0x2b5a321c…7eba` | `0xc77d97cf…40c0` | `0xbf6f64b7…7442` | `0x0117ba42…1003` | 0.20% | 285 | 1.30% / 1.00% | 9,128,064.11 crvUSD | 12,174,944.13 crvUSD |
| E1 | ETH | sfrxUSD `0xcf62f905…c5b6` | crvUSD | `0x3da0f110…300a` | `0x3cd4d86a…1bbe` | `0x63791be4…2d1f` | `0xea1b9812…8c2b` | 0.20% | 285 | 1.30% / 1.00% | 15,560,447.84 crvUSD | 20,123,399.41 crvUSD |
| E2 | ETH | syrupUSDC `0x80ac24aa…cc0b` | crvUSD | `0xd0d347e1…0e6c` | `0x2fb54c8e…2675` | `0x0b7e89ea…2971` | `0xb799322c…a840` | 0.90% | 312 | 3.50% / 0.60% | 4,089,776.33 crvUSD | 6,085,669.99 crvUSD |
| E3 | ETH | svZCHF `0xe5f13025…f6b0` | crvUSD | `0xcb6e2c3d…e2fd` | `0xfd85e847…f043` | `0xc8c469e3…40a3` | `0xa44b313a…1951` | 0.05% | 180 | 4.80% / 2.80% | 218,483.04 crvUSD | 555,268.61 crvUSD |
| E4 | ETH | reusdsfrx `0xed785af6…a441` | crvUSD | `0xfe33bb53…ca40` | `0x4922995d…adb1` | `0xa305ff5f…00e5` | `0xf9f3beac…6078` (ChainOracle) | 0.91% | 440 | 3.00% / 2.50% | 2.50 crvUSD | 5.00 crvUSD |
| O0 | OP | wstETH `0x1f32b1c2…9ebb` | WETH `0x4200…0006` | `0x638ef785…19f7` | `0x745422bf…f8c9` | `0xf621ae3e…26d0` | `0xdeb4aafa…6794` | 0.50% | 186 | 3.40% / 1.50% | 15.7196 WETH | 15.7223 WETH |
| O1 | OP | WBTC `0x68f180fc…2095` | USDC.e `0x0b2c639c…ff85` | `0xff9a3085…ea24` | `0x9fc15ac3…56de` | `0x86372d28…4c72` | `0x63284d83…03bd` | 0.08% | 96 | 8.00% / 5.00% | 64,890.997 USDC | 76,330.667 USDC |
| O2 | OP | wstETH | USDC.e | `0xab504518…9436` | `0xb5ec7a3d…bcaa` | `0x1c605654…c9dc` | `0x7d81eda6…b315` | 1.40% | 83 | 14.0% / 11.0% | 98,834.391 USDC | 98,823.635 USDC |

*Full 40-hex addresses and per-getter raw values: `analysis/markets_live.json`, `analysis/enumerate.py`.*

**Live vault assets (USD):** ETH crvUSD vaults **$38,898,292** (38,939,282 crvUSD @ $0.998947); OP **$213,002** (15.7223 WETH @ $2,409.44 = $37,882 + 76,330.667 USDC @ $0.999806 + 98,823.635 USDC). **Total $39,111,295.** Prices: DefiLlama `coins.llama.fi/prices/current`, timestamp **1792306624 = 2026-10-18 ~07:17 UTC**.

`users_to_liquidate(0, 1000)` returned **length 0 for all 8 markets** at the re-check heads. Every individually read `health(user,true)` is positive; all 29+26+21+11+1 ETH positions and 7+11+5 OP positions are healthy.

---

## 3. Mechanism review (deployed code)

### 3.1 Vault — empty-market / donation (closed)
`Vault.vy` (blueprint `0x2c3822…375b`):
- `DEAD_SHARES = 1000`; shares = `(totalSupply + 1000) * assets * precision / (totalAssets * precision + 1)`; assets = `shares * (totalAssets*precision+1) / ((totalSupply+1000)*precision)`. This is the OpenZeppelin virtual-share defence (plus an explicit `+1` asset).
- `totalAssets = controller.available_balance() + controller.total_debt() - controller.admin_fees()`.
- `LendController.available_balance()` returns a **stored** `_available_balance`, updated only by `on_borrowed_token_transfer_in/out`, which assert `msg.sender == VAULT or self`. A plain `crvUSD.transfer(controller, X)` is therefore invisible to `totalAssets` — the classic donation cannot inflate the share price.
- `deposit` requires `totalAssets + assets >= MIN_ASSETS = 10,000` and `to_mint > 0`.
- Fork result: direct 1,000,000 crvUSD transfer → `totalAssets` unchanged. First-depositor + 100 crvUSD donation + 1,000 crvUSD victim deposit → attacker redeems 9,999 of the 10,000-wei minimum deposit: **net −1 wei**, victim shares fairly priced. (Tests 1–2.)

### 3.2 Controller — soft-liquidation / partial repay / liquidation (closed)
`controller.vy` + `LendController.vy`:
- `create_loan`/`borrow_more`/`repay`/`add/remove_collateral` all require `_has_approval(_for)` (self or explicit `approve`); no third-party grief path.
- `liquidate` is permissionless **only when `health < 0`**; a healthy user can only be liquidated by themselves/an approved address (`approval=true` sets `health_limit=0`, no bonus). Test 3/4 revert at the exact gate `"Not enough rekt"`.
- Liquidation splits `frac` of debt, withdraws `f_remove = ((1+h/2)/(1+h)*(1-frac)+frac)*frac` of the position (h = `liquidation_discount`), repays `ceil(debt*frac/WAD)` and pays the liquidator `xy[1]` collateral + any `xy[0]` excess; `final_debt==0` forces `f_remove=1`. This is the v1 LLAMMA accounting; the bonus is bounded by the configured discount and there is no unbounded `frac` path (`_frac <= WAD`, `debt > 0`).
- Partial repay: if the position is not underwater (`ns[0] > active_band`) it withdraws/re-deposits the full collateral and asserts `xy[0]==0`; if underwater it only reduces the debt and leaves bands untouched (`_shrink=false` requires `callbacker == empty`). Rounding is conservative: user debt uses `ceil`, shares use `+1`/`DEAD_SHARES` offsets, and `sub_or_zero` is used on all subtractions. No path was found to repay less than the debt decrease or to withdraw more collateral than deposited.
- `_update_user_liquidation_discount` refuses any action that would end unhealthy (`_health >= 0`), except a full liquidation (`new_debt == 0`), and `_health` is computed with the AMM's adiabatic `get_x_down` (not a spot balance).

### 3.3 AMM — swap / soft-liquidation (closed)
`AMM.vy` (blueprint `0xc8ac25…cf41`) is the v1 LLAMMA curve with `MIN_FEE=1e-12`, `MAX_FEE=min(4/A,10%)`, `PREV_P_O_DELAY=120s`, `MAX_P_O_CHG≈1.26`, per-band dead shares, and `deposit_range/withdraw` admin-gated to the controller. `exchange` is permissionless but priced from the oracle via `limit_p_o` + `get_dynamic_fee`; no caller can move `bands_*` outside the curve. The only stateful oracle write is `price_w` inside `exchange`, which updates the same EMA the market uses.

### 3.4 Oracles (closed against one-block spot manipulation)
- **ETH E0–E3**: `ERC4626EMAWrapper` over `CrvUSDAggregatorWrapper(OracleFromCurvePools)`. The wrapper reports `min(spot share price, EMA share price)`; upside donations/pumps are smoothed, downside passes through immediately (deliberately conservative for collateral). The base `OracleFromCurvePools` reads `CurveStableSwapNG.price_oracle(i)` / `Twocrypto.price_oracle()` — both are **moving averages** (`last_prices_packed` / `ma_exp_time`), not spot balances.
- **ETH E4**: `ChainOracle` chains `StableSwapNG LP EMA Oracle` (LP portfolio value at `price_oracle(0)` × `min(spot VP, EMA VP)`), `ReusdCrvUSDAdapter` (redemption feed, capped at 1 crvUSD/reUSD), and the crvUSD `AggregatorStablePrice`. No spot reserve read.
- **OP O0–O2**: `ChainlinkEMA` (Solidity 0.8.25, defi.money) over Chainlink feeds `WSTETH/ETH` (`0x524299ab…5a10`), `BTC/USD` (`0xd702dd97…e593`), `WSTETH/USD` (`0x698b585c…58f7`); `OBSERVATIONS=20`, `INTERVAL=30s`, smoothing 0.0952. All feeds updated within ~3 h of the read; answers match DefiLlama (wstETH $2,999.53, WBTC $81,540). No flashloan can move a Chainlink answer.
- No oracle in any of the 8 markets reads a raw pool balance or a spot `get_dy`.

### 3.5 Permissionless state/fund movers
- `collect_fees()`: permissionless; updates debt, then transfers pending admin fees to `factory.fee_receiver()` — not to the caller. No profit.
- `save_rate()`: permissionless; calls `rate_write()` on the monetary policy, which asserts `msg.sender == controller` and is capped by `MAX_RATE = 43,959,106,799` (300% APY). `set_parameters` is factory-admin-only.
- `Vault.deposit/mint/withdraw/redeem` and `AMM.exchange` are the only other value movers; all are priced by the share/oracle math above.
- `Factory.create()` is **permissionless** and accepts a caller-supplied oracle/monetary policy. This creates a brand-new empty vault/controller/AMM pair; it cannot touch an existing market's vault. It is a listing/social-engineering surface, not an E-U path (no shared liquidity).

---

## 4. PoC / fork verification

`poc/` (Foundry 1.8.5, vendored `forge-std`), fork blocks pinned:
- ETH: **26,217,523** (`FORK_RPC_URL`/`ETH_RPC`)
- OP: **158,352,276** (`OP_RPC_URL`, public fallback)

| # | Test | Result | What it proves |
|---|---|---|---|
| 1 | `testDirectDonationNotCounted` | **PASS** | 1,000,000 crvUSD direct transfer to the E1 controller leaves `vault.totalAssets()` unchanged |
| 2 | `testFirstDepositorDonationNoProfit` | **PASS** | minimum deposit 10,000 wei + 100 crvUSD donation + 1,000 crvUSD victim deposit → attacker redeems 9,999 wei, **PnL −1 wei** |
| 3 | `testHealthyEthLoanCannotBeLiquidated` | **PASS** | E0 loan 0 health = `0.0258967e18`; `liquidate(user,0,1e18)` reverts `"Not enough rekt"` |
| 4 | `testHealthyOpLoanCannotBeLiquidated` | **PASS** | O2 loan 0 health = `1.6094557e18` at the pinned block; oracle `3010.679799e18`; `liquidate` reverts `"Not enough rekt"` |

Local: **4/4 PASS**. Gas: 324,050 / 1,110,123 / 630,062 / 670,354. CI run: see below (recorded URL). No mainnet transaction was sent.

---

## 5. Verdict, residual risk, blockers

- **E-U: $0, confidence high.** No live unprivileged extraction exists in the 8 markets. All positions healthy; no bad debt; all oracles non-spot; vault donation not counted; liquidation gate intact.
- **E-U-conditional: $0 today.** Conditions that would reopen a path:
  1. **Any position's health crosses below 0** (oracle move or interest accrual). Then a permissionless liquidator earns the configured bonus (1% E0/E1, 0.6% E2, 2.8% E3, 2.5% E4, 1.5% O0, 5% O1, 11% O2 of the liquidated collateral/debt slice, per `_get_f_remove`, not the full discount for partial `frac`). Closest margins: E0 loan `0x82eebbf1…` health **0.314%**; O2 loan `0x823be23f…` health **4.59%** (and O2 `0x...e13a` 3.50%). This is normal keeper economics, not protocol insolvency.
  2. **Chainlink/Sequencer outage** on OP: `ChainlinkEMA` has no L2 sequencer-uptime check and no explicit staleness bound (`_validateAndFormatResponse` only requires `answer > 0`). A stale or frozen feed across a large market move could misprice O0–O2. No such state today; feeds are fresh.
  3. **Factory `create()` social engineering**: a permissionless market with an attacker oracle can be created, but it has its own empty vault — no shared funds. Only depositors who voluntarily enter it are at risk.
- **H-O:** $39.11M of vault assets are lender shares; owners can `redeem` subject to `available_balance` (utilization). No lock/blacklist found on crvUSD, sDOLA, sfrxUSD, syrupUSDC, svZCHF, reusdsfrx, wstETH, WBTC, WETH, USDC.e.
- **P:** factory admin (Curve DAO agent) can pause new markets, set fee receivers, configure markets (oracle/fee/discounts), set borrow caps; configurator can change parameters. Not attacker-accessible.
- **S:** $0 identified. The E4 market has only $5 of assets (test market); no stuck funds beyond dust.
- **Blockers to a stronger claim:** no archive OP RPC locally for deep historical position scans (we read current/pinned state); we did not fuzz the full LLAMMA invariant or run a stateful handler suite (time-boxed); we did not test a live unhealthy position because none exists.

---

## 6. Methodology / sources / caveats

- Enumerated by `NewVault` logs from both factories (Etherscan V2 for ETH; OP public `eth_getLogs` for OP, because Etherscan V2 free tier does not serve chain 10 logs), cross-checked with `market_count()`.
- Read all deployed Vyper/Solidity sources from Etherscan V2 (ETH) and Blockscout (OP): LendFactory, Vault, LendController, controller core, AMM, ControllerView, ERC4626EMAWrapper, ChainOracle, CrvUSDAggregatorWrapper, OracleFromCurvePools, StableSwapNGLPOracle, ReusdCrvUSDAdapter, ChainlinkEMA, HyperbolicMP/HyperbolicDynamicMP.
- Live reads at explicit blocks; `markets_live.json` has raw values. Health/liquidation was re-read at ETH 26,217,798 / OP 158,353,940.
- Prices: DefiLlama `coins.llama.fi/prices/current` (fetch timestamp 1792306624; crvUSD $0.998947, WETH $2,409.44, USDC $0.999806).
- **Caveats:** point-in-time reads; interest accrues continuously, so health drifts down slowly; `totalAssets` includes accrued but uncollected interest; the OP O2 health at the pinned block (1.61) is higher than at the earlier enumeration block (0.042) because the pin is older — the current-margin figure (4.59%) is from the latest read. No mainnet interaction; no private keys used.

## 7. Files

```
curve-llamalend-v2/
├── README.md                       # this report
├── summary.json                    # §7 schema, finding "WaveB1-CurveLlamaLendV2"
├── analysis/
│   ├── fetch_src.py, fetch_all.py  # verified-source downloaders (no keys/URLs embedded)
│   ├── rpc.py, llrpc.py            # env-only read-only helpers
│   ├── enumerate.py                # factory/market/live-state enumeration
│   ├── markets_live.json           # raw live state (ETH + OP, pinned blocks)
│   └── src_*                       # deployed sources (factory, blueprints, oracles, pools, policies)
├── poc/
│   ├── foundry.toml, lib/forge-std # vendored
│   ├── src/Interfaces.sol
│   └── test/LlamaLendV2.t.sol      # 4/4 PASS
├── ci-out/
└── ci-artifacts/ (downloaded by helper)
```

**CI run URL:** _to be filled after `bash /home/heisenberg/CA/ci/ci-run.sh curve-llamalend-v2`._
