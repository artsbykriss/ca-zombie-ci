# Kava Swap (`x/swap`, kava_2222-10) — zombie-hunt II / L2-25

**Research date:** 2026-10-15 · **Method:** read-only (public LCD/RPC + Osmosis LCD + DefiLlama/CoinGecko prices). No transactions signed or sent.
**State snapshot:** Kava heights **23,035,424 → 23,035,438** (2026-10-15 11:31–11:32 UTC); Osmosis height 72,571,908. All raw reads in `raw/`, machine-readable state in `state.json`, replay math in `sim.py` (`sim_output.txt`).
**Deployed version reviewed:** node reports `0.28.2`, commit `686d591443a1de7c5566bc7d92faf5b56743f25f`; source read at exactly that commit (`x/swap/**`).

## TL;DR verdict

| # | Path | Class | USD | Conf |
|---|------|-------|-----|------|
| A1 | Zombie pool `ibc/B448…(Sifchain-USTC):usdx` — buy USDX at $0.137, sell at ~$0.70 | **H-O** (permissionless for existing holders; needs OTC sourcing for outsiders) | **+$250.07** | high math / med exec |
| A2 | Zombie pool `ibc/B8AF…(Sifchain-LUNC):usdx` (same bundle) | **P** | +$7.74 | high |
| A3 | `swp:usdx` supposedly stale — **not stale** (Osmosis SWP/OSMO pool prices SWP at $0.00156; CoinGecko feed $0.000946 is stale/no-tickers) | **S** | $0 | high |
| A4 | Cross-pair arbitrage among the 8 live pools (~0.68–0.71 implied USDX) | **S** | $0 (best cycle < $0.01) | high |
| A5 | Osmosis pool 1390 (USDX/OSMO, 5% fee) → Kava pools; permissionless | **E-U (dust)** | **+$0.37** one-shot (depth-limited) | high |
| B | Module bugs (share inflation, rounding, fee bypass, claims, module drain) | **S** | $0 | high |
| C | Conditional: extraction capacity if a cheap-USDX source appears (cross-ref C2-57 Mint/Lend, out of scope) | n/a | $70.5K @p=0 · $17.1K @p=0.30 · $3.5K @p=0.50 | high |

**Headline: E-U ≈ $0.4 (permissionless, one-shot); H-O ≈ +$257.81 total live value (zombie USTC/LUNC bundle), contingent on acquiring stranded Sifchain-origin tokens on Kava.** No unrestricted, scalable drain exists today.

Classification legend: **E-U** = permissionless for any funded address (no special access, live on-chain venues only) · **H-O** = real but conditional/hard-operational (precondition outside on-chain markets) · **P** = proven-live but impractical/negligible · **S** = safe/no viable path found.

---

## 1. System facts

- `x/swap` params (raw/kava_swap_params.json): `swap_fee = 0.0015`; 13 `allowed_pools`; **only 12 pools exist** (`uabc:ukava` allowed but never created). **All pools are `<asset>:usdx` — no non-USDX pairs.**
- Swap module account `kava1mfru9azs5nua2wxcd4sq64g5nt7nn4n8s2w8cu` holds **exactly** Σ(pool reserves) for all 13 denoms — no donations, no missing funds (`sim.py` check: **PASS**).
- Pool shares: all 12 pools have positive `total_shares`; initial shares = ⌊√(A·B)⌋; no zero/empty pool, no first-depositor surface.
- Incentive module (`kava1hfny2zh…`) balance = **0 denoms**; `swap_reward_periods = []`, `claim_end = 2026-11-01`; incentive LCD queries return "Not Implemented". Nothing claimable.
- ERC-20 module: `token_pairs` = **0**; GeckoTerminal shows no USDX/SWP/HARD pools on Kava EVM. Pools are cosmos-denom only.
- USDX context (why it is not "worthless"): USDX minting is **disabled** (all CDP `debt_limit = 0`, global 0); 500 CDPs remain with **1,432,146.9 USDX debt** vs ~$6.3M collateral (LR 1.5/1.01) — closers rationally bid for USDX, which is why every live pool prices it ≈$0.70. (Mint/CDP exploit surface = separate campaign finding C2-57, not analyzed here.)
- `usdx` cannot be dumped externally: total USDX bridged to Osmosis (channel-143) is **965.6 units** vs **203,533.7 USDX** held by the 12 Kava pools.

## 2. Pool table (height 23,035,424–38; external prices 2026-10-15 11:30 UTC)

`impliedUSDX` = implied USD value of 1 USDX from pool ratio at external prices.

| pool | reserves | implied USDX | other-side USD | recent trades* | stale? |
|---|---|---|---|---|---|
| bnb:usdx | 13.940956 BNB + 14,250.529283 USDX | 0.7047 | $10,043 | 5 | no |
| btcb:usdx | 0.072744 BTCB + 8,525.34186 USDX | 0.6912 | $5,893 | 2 | no |
| busd:usdx | 54,507.375829 BUSD + 77,266.361336 USDX | 0.7049 | $54,468 | 18 | no |
| hard:usdx | 3,945,865.887811 HARD + 2,641.237829 USDX | 0.6851 | $1,810 | 0 | quiet |
| ibc/0471…(OSMO):usdx | 18,859.699484 OSMO + 1,160.080022 USDX | 0.6835 | $793 | 23 | no |
| ibc/27394…(ATOM):usdx | 3,725.55805 ATOM + 8,945.005042 USDX | 0.7056 | $6,312 | 46 | no |
| ibc/799F…(AKT):usdx | 12,438.330276 AKT + 11,550.188614 USDX | 0.6916 | $7,988 | 25 | no |
| **ibc/B448…(Sif-USTC):usdx** | 32,982.702034 USTC + **1,173.795833 USDX** | **0.1373** | $161 | **0** | **stale (mispriced)** |
| **ibc/B8AF…(Sif-LUNC):usdx** | 943,319.020978 LUNC + **126.693745 USDX** | **0.3494** | $44 | **0** | **stale (mispriced)** |
| swp:usdx | 9,471,857.057007 SWP + 20,731.72451 USDX | 0.7108 | $14,737 | 0 | fairly priced vs Osmosis |
| ukava:usdx | 418,006.335972 KAVA + 40,402.848352 USDX | 0.7100 | $28,685 | 48 | no |
| usdx:xrpb | 8,938.714199 XRPB + 16,759.925045 USDX | 0.6981 | $11,701 | 9 | no |

Total pool-side value at external prices ≈ **$142,634** (liquid IBC exits: ~$43,778). DefiLlama reports $165,129 — same order; difference is USDX-leg/feed valuation (USDX has no price feed; stale CoinGecko SWP price).

\* recent trades = swaps in the last 100-swap RPC sample (heights 23,016,060–23,033,183). A wider sample (526 swap events, heights 22,980,209→23,033,183 ≈ 84 h) shows **active two-way trading** in the 8 live pools by ~20 addresses (top: `kava1ks55ncel…` 646 swaps, `kava1eufgf0w9…` 436, `kava1rw4nvat…` 226) and **zero trades in the USTC/LUNC/SWP pools**.

## 3. Path A — stale/mispriced pools

### A1+A2. Sifchain-origin USTC & LUNC zombie pools — **real, live, ≈ +$257.81**

Chain of custody (denom traces from Kava LCD):
- `ibc/B448C0CA…` = `transfer/channel-4/uusd`; `ibc/B8AF5D92…` = `transfer/channel-4/uluna`; **channel-4's client is `sifchain-1`** (connection-4 → 07-tendermint-5 → chain-id `sifchain-1`).
- Sifchain has been dead for years (RPC/LCD endpoints dead; chain halted; ERC-20 ERWAN ≈ $0). Its escrow channel holds zero; **the Sif-origin tokens on Kava are stranded receipts that can only re-enter via the dead Sifchain** — no permissionless source exists. (Osmosis has no pools for those two denoms either; the all-3658-pool scan found none. 109.19 USTC / 170,419 LUNC of these denoms sit in Osmosis wallets, reachable only by OTC.)
- Kava-side supply outside the pools: **~698k Sif-USTC, ~68.2M Sif-LUNC** — i.e., the tokens do exist on Kava, held by legacy LPs/wallets.

Mispricing: both pools were last traded when LUNC/USTC were ~2–3× higher (≈ early 2023) and USDX ≈ $0.70–1.00; the embedded price is now 2–5× below the 8-pool consensus (~$0.70). **No trade has occurred in them in the entire indexed window** (pool-level `tx_search` returns 0 txs; they also show 0 in the 526-event sample), i.e., the free lunch sits unlooted.

Exact exploit (module math, `sim.py`; fee 0.0015; integer flooring as deployed):

| step | Sif-USTC leg | Sif-LUNC leg |
|---|---|---|
| buy USDX: swap USTC (resp. LUNC) in, USDX out (pool `ibc/B448…:usdx`) | in **40,536 USTC** ($198.05) → **646.76 USDX** | in **394,076 LUNC** ($18.49) → **37.29 USDX** |
| sell USDX: swap USDX in, KAVA out (pool `ukava:usdx`) | → **~6,576 KAVA** | → **~385 KAVA** |
| value after 0.7% KAVA→USD exit haircut (IBC→Osmosis pool 730, ~$400K TVL, swap→USDC) | $448.13 | $26.23 |
| **net profit** | **+$250.07** (gross $253.24) | **+$7.74** (gross $7.92) |

- Messages needed: two `MsgSwapExactForTokens` + one IBC transfer (no signing done here). Slippage params attacker-chosen; both pools open (`allowed_pools` includes both; reserves positive; no pause logic in `x/swap`).
- Sensitivity: break-even purchase price for the Sif-USTC leg ≈ **$0.0111/USTC** (2.3× Binance USTC market); at 1.5× market the profit is ≈$153. Total bundle break-even ≈ $0.0116.
- Why H-O, not E-U: an outside attacker must first **acquire the stranded Sif-USTC/LUNC on Kava (OTC with existing holders — no DEX/CEX/IBC venue exists)**. Anyone who already holds those denoms on Kava can loot it permissionlessly right now. Value is hard-capped by the two pools' USDX sides (~1,300 USDX total).
- Confidence: math exact (recomputed with deployed integer math); price feeds Binance-listed USTC/LUNC; execution depends only on the OTC counterparty.

### A3. `swp:usdx` — checked, **fairly priced** (negative result)

- The pool implies 456.9 SWP/USDX; its USDX side 20,731.7. A scalper bot (`kava1rw4nvat…`) trades it both ways (7 tiny trades in the window).
- **Osmosis pool 1631** (SWP/OSMO, 49/51 weights, fee 0.05%): 39,848.43 SWP + 1,534.91 OSMO → spot SWP = **$0.001560**; pool-implied SWP (at USDX=$0.706) = **$0.001545** — a 1% gap, below costs. Buying SWP on Osmosis and dumping into Kava: **$0 profit** (best −$0.00).
- CoinGecko's `kava-swap` price $0.000946 is stale (no tickers; `market_data` empty) — do not use it. Total SWP bridged to Osmosis = 46,080.20 (= 39,848.43 in pool 1631 + wallets); Kava pools hold 9.47M SWP.

### A4. Live-pool cross-rate scan — **no profitable cycle**

All ordered pairs `assetA_in → USDX → assetB_out` at external prices (KAVA/ATOM/OSMO/AKT exits with 0.7% haircut), optimized by exact module math: best non-zombie result **< $0.01**; the only positive cycles found are the A1/A2 zombie legs. The 8 live pools are mutually arbitrage-consistent at ≈$0.69–0.71 per USDX, updated by ~20 bot addresses.

### A5. Osmosis USDX → Kava (permissionless, dust)

- Osmosis pool 1390 = USDX/OSMO 50/50: 473.196269 USDX + 7,030.317991 OSMO → spot $0.6263; **5% swap fee** → effective buy ≈ $0.659. Selling the USDX into `ukava:usdx` nets ≈ $0.69–0.70 less slippage.
- Exact optimum: buy 15.71 USDX for 254 OSMO ($10.68) → net **+$0.37** after all fees and 0.7% exit haircut. The pool's shallowness (473 USDX) caps the whole route at ≈$0.4.
- Osmosis pool 792 (USDX/USDC.axl) is dust (629 / 479 raw units). Total USDX on Osmosis = 965.60 units — no scalable external supply exists.

### A6. Value-at-risk vs a hypothetical cheap-USDX source (conditional)

Per-pool profit for an attacker who can obtain USDX at price `p` **in unlimited size** and dump it into each Kava pool (exact math, market marks, no exit haircut). Sum row = total extractable from the module:

| p (USDX cost) | $0 | $0.10 | $0.30 | $0.50 | $0.6263 (Osmosis marginal) |
|---|---|---|---|---|---|
| TOTAL | **$70,542** | $50,635 | $17,137 | $3,503 | $454 |

Largest pools at risk: ukava $14.2K@p0, busd $26.9K@p0 (but BUSD's only exit is this same module → circular mark), swp $7.3K@p0, xrpb $5.8K@p0, bnb $5.0K@p0. If finding C2-57 (Kava Mint/Lend) or any other channel supplies USDX at < $0.30 at scale, this table is the swap-side extraction capacity (out of scope here — no minting/CDP analysis performed).

## 4. Path B — module code review (commit 686d591, `x/swap/**`) — no bug found

- `types/base_pool.go`: exact-in output **floored**, input fee floored (fee = in − ⌊in·(1−fee)⌋ ⇒ fee rounded **up**, min 1 unit, so fee-splitting cannot reduce fees); exact-out input **ceiled** (`calculateInputForExactOutput` L298-318). `assertInvariantAndUpdateReserves` (L340-351) panics if k decreases. `AddLiquidity` (L97-196) mints **min-ratio** shares (truncated) — no inflation; `RemoveLiquidity`/`ShareValue` (L203-218, L323-336) floor and assert shares ≤ total. Rounding direction on every path favors the pool.
- `keeper/deposit.go`: pool creation only via `depositAllowed` (gov `allowed_pools`); L41-105. `keeper/withdraw.go`: share ownership checks; zero-value withdrawals rejected. `keeper/swap.go`: slippage bound is caller-supplied; `commitSwap` re-derives pool state from the store each msg.
- `keeper/invariants.go`: 4 invariants registered — `pool-reserves` compares Σreserves to the module account, `pool-shares` compares Σ depositor shares to `total_shares`, plus record validation. Empirically `Σreserves == module balance` (all 13 denoms, PASS).
- `keeper/msg_server.go`: only deadline + bech32 checks; no permissionless claim path; no privileged setter exposed to users.
- Incentive hooks (`keeper/hooks.go`) only accumulate reward records; module holds **0 funds** → nothing to claim regardless of `claim_end`.
- Not exploitable knobs verified: no pause, no owner withdraw, no donation accounting (swaps use stored reserves), no ERC-20 representation, no new pool creation.

## 5. Who holds the value / supply context

- 100% of pool value sits in the swap module account; LP share records are **not enumerable via LCD** (`/kava/swap/v1beta1/deposits/…` returns "Not Implemented"), and the public RPC index covers only ~2 weeks, so an on-chain LP census was not possible. Observable: recent depositor flow is one micro-LP (`kava1g84nljqdjyudxckw6mywsx9ycfjnc8xja0602a`, 300 deposits, e.g. 64.1 BUSD+0.83 USDX into busd:usdx at h22,870,613).
- USDX supply 9,275,853.4: pools 203,533.7; **x/hard module 3,570,733.5**; community pool 130,000.5; rest with wallets (not enumerable). All non-pool USDX is unreachable to an attacker.
- The `ibc/B448`/`ibc/B8AF` denoms outside the pools (~698k USTC, ~68.2M LUNC) are the A1/A2 feedstock.

## 6. Negative results (evidence)

1. No profitable cycle among live pools (exhaustive ordered-pair scan, exact math) — `sim_output.txt` Route E.
2. `swp:usdx` mispricing theory from DefiLlama/CoinGecko price ($0.000946) is **false** — Osmosis pool 1631 (authoritative) says $0.001560; route nets $0.
3. Osmosis-USDX→Kava route nets $0.37 max (5% fee + 473-unit depth).
4. No Sif-USTC/LUNC pools on Osmosis (all 3,658 pools scanned); Kava channel-4 = sifchain-1, chain dead ⇒ stranded.
5. Swap module balance == Σ reserves exactly; 0 extra denoms.
6. Incentive module empty; claims moot.
7. `uabc:ukava` allowed but no pool created.
8. Kava EVM/erc20 exposes nothing (0 token pairs, no GT pools for USDX/SWP/HARD).

## 7. Reproducibility & files

- `state.json` — snapshot index (heights, all raw payloads by reference, prices).
- `raw/` — 36 raw JSON payloads: pools, params, balances (swap/incentive/cdp/auction/community/hard-module), supply, community pool, escrows (channels 0/1/4/5), denom traces, last-trade probes, 300-swap RPC pages, CDP list, Osmosis pools 792/1390/1631, Osmosis supplies, prices.
- `snapshot.py` — re-fetches everything (read-only). `sim.py` — recomputes every number in this report from `state.json`; output in `sim_output.txt`.
- Key heights: pools/params/balances 23,035,424–23,035,438; swap-activity samples 22,980,209–23,033,183 (526 events) and 23,016,060–23,033,183 (last 100); Osmosis 72,571,908. Node: kava `0.28.2` @ `686d591`.

## 8. Caveats / limitations

- USDX has no independent price feed; "≈$0.70" is the arbitrage equilibrium of 8 actively traded pools backed by dead-mint CDP demand. If every USDX bid vanished, pool values would compress; the A1/A2 profit uses KAVA/USTC/LUNC market prices, not USDX's.
- BEP2-origin assets in pools (BNB/BTCB/BUSD/XRPB) are marked at market in the tables, but their only permissionless exit is this same module (circular); the $142,634 figure should be read with that caveat.
- The A1/A2 profit assumes OTC purchase at market price; it scales down linearly with premium (break-even ≈ $0.0111/USTC).
- LP-share census impossible via public endpoints; share-inflation class checked at code level only (clean) — no on-chain Σ-shares check available to us.
