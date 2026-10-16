# Z3-C3 · Papertrade (HyperEVM/HyperCore) — live BBO-oracle manipulation, re-verified: **economically closed at current caps** ($0 E-U now), conditional re-opening path quantified

**Date:** 2026-10-16 (all live reads 2026-10-15 22:45 – 2026-10-16 01:15 UTC) · **Chains:** Hyperliquid L1 (HyperEVM, chain 999) + HyperCore
**Status:** read-only; no transactions, no signatures, no keys; fork-free PoC (embedded live bytecode) + CI re-verification. **No mainnet transactions.**

---

## 1. TL;DR

| | |
|---|---|
| **Target** | Papertrade synthetic perps (papertrade.xyz): Exchange proxy `0x6cd5661646289fb6e65ea5c032310fded797d0a2` → impl `0x0f3febfc…`, PriceOracle proxy `0xa9B4c7b7…` → impl `0x3997ffc8…`, BatchExecutor `0x233Ff29b…` → impl `0xe0bc9cc7…` |
| **Primitive** | Trades open/close/liquidate at Hyperliquid's **BBO mid** `(bid+ask)/2` read from precompile `0x080e`; **no deviation cap, no TWAP, no lookback** — verified in live bytecode and behaviorally (PoC T2: a +1,018 bp displaced book is accepted; T3/T4: only zero/crossed revert). Unchanged since the Oct-10 incident (oracle impl bytecode hash identical). |
| **E-U (external unprivileged) today** | **$0 net.** At the current instantaneous per-side headroom (BTC $4.3–9.0M, ETH $7.0–8.6M) every manipulation size is **net-negative by 3–10×**: e.g. ETH 15 bp cycle pays $7.7k vs manipulation cost $37–45k; BTC 15 bp pays $10.4k vs $64–90k. Even a zero-slippage, fees-only floor is negative for BTC (−$2k…−$15k) and ≈break-even for ETH (−$0.3k…+$9k). |
| **E-U (conditional)** | The keeper's OI caps **trail OI** (verified: cap ≈ OI + $9M BTC / $7M ETH, refilled in $7–9M steps every 15–30 s). An attacker who accumulates **N ≥ $25–40M/side (ETH) / $40–55M (BTC)** through the refills re-opens the path: **≈ +$15k–180k per cycle** at N=$50–100M (30 bp, ETH), bounded by the **LP bankroll $4,958,944.58** and by team response. Realistic single-session take **$0.1–2M**, hard ceiling **$4.96M**. |
| **H-O / P / S** | $0 / $0 / $0. (Traders' balances and LP claims are user-controlled, not extractable; no stuck value identified.) |
| **Why it is open at all** | The oracle is a raw order-book mid with no breaker (the protocol's own Risk page: *"no maximum-deviation, time-weighted-price, or lookback breaker … residual manipulation and LP-loss risk remain"*), and `tradingPaused=false`. The **hard** non-economic gate is the relayer allowlist: opens/closes can only be submitted by the team's two registered relayer EOAs (owner-only registration), so a fresh attacker must have their signed intents forwarded by Papertrade's own relayer. |
| **Incident** | 2026-10-10/11, ~8 h after launch: ~$20M of HL order flow moved the ETH BBO 10–20 bp while holding Papertrade positions → **$1.28M extracted** (DefiLlama: *Oracle Manipulation / Spot Price Manipulation*). Post-incident mitigation = **OI caps only** (headroom target cut from ~$1B to ~$9M/$7M), plus an off-chain statement about restricting relayers. |
| **Latent risk** | Medium–High. The primitive is unchanged and the trailing caps are a **rate limiter, not a ceiling**: if the keeper ever re-widens the headroom target, or an attacker accumulates through the refills (and the relayer forwards), the same recipe re-applies. Watch: per-side headroom, cap policy, pauseGuardian actions, oracle impl hash, relayer set. |

**Total live extractable now: $0 (verified negative-economics at current headroom; confidence high).**
**Conditional E-U: ~$0.1–2M realistic (≤$4.96M bankroll-bound), confidence medium (depends on relayer policy + keeper refill persistence + hedge feasibility).**

---

## 2. The mechanism, in exact terms

1. **Pricing = raw Hyperliquid BBO mid.** The Exchange settles opens, closes and liquidations at the oracle's mid: `getMid(uint32 asset)` (selector `0xc0182669`) = `(bid+ask)>>1` from the HyperCore BBO precompile at `0x000000000000000000000000000000000000080e` (BTC asset 0, ETH asset 1). Live reads at block 48,648,947: BTC `(821630, 821640)` → mid **$82,163.50** (0.12 bp spread); ETH `(244000, 244010)` → mid **$2,440.05** (0.41 bp spread).
2. **The only guards** (live bytecode `0x3997ffc8…`, 2,475 B, keccak256 `0x75f094dab1fb771fc5ed5953a02be453a5d35dc4878b53a9e6a11c7d9e4e679c`): call success, `bid≠0`, `ask≠0`, `ask ≥ bid` (crossed). `getBBO` (`0xfb466481`) is a raw passthrough with no crossing check at all. There is **no price history storage, no timestamp, no deviation/TWAP/lookback logic** anywhere in the implementation.
3. **Impact-curve payout** (`QueueLib.applyMarketImpact`, docs formula): `adjustedPnl = rawPnl × scale`, `scale = (1−baseRate)/(1 + 1/(m·rateMultiplier) + referenceNotional/(1e6·m·positionMultiplier))`, then a 0.2 bp deadband and a 2% win fee. Live instrument params (block 48,649,491, `instruments(uint32)` `0xdc8a47ef`): BTC mult 814.598 / ETH mult 483.979, rateMultiplier 15000, baseRate 10%, referenceNotional $100k, max leverage 1000×, max position notional $10M, liquidation offset field ≈ 4.8 bp (w5 = 0.000476 BTC / 0.000481 ETH, consistent with the docs' "liquidation fires after a move of about 0.052%"). Payout per $1M notional: ETH 15 bp **$1,102**, 30 bp **$2,408**; BTC 15 bp $1,157, 30 bp $2,471.
4. **The attack** (the Oct-10 recipe): open Papertrade positions in the direction you will push; displace the HL BBO mid with order flow (a sweep, or a marketable limit that consumes asks and rests the residual at the crossed price); close Papertrade while the displaced mid persists; unwind the HL inventory. Net = payout − (round-trip manipulation slippage + HL fees) − (optionally) hedge cost.
5. **The incident validates the model**: ~$1B/side headroom at launch ⇒ 15–20 bp × ~$1B × scale ≈ $1.1–1.5M — the observed $1.28M. The mitigation cut the headroom target ~100× (to ~$9M/$7M), which cuts the single-shot payout to ~$7–11k — **below the cost of moving the book**.

---

## 3. Live-state assessment (block 48,648,947 / CI re-run 48,649,491, 2026-10-16 ~00:10–00:35 UTC)

| Item | Value | Evidence |
|---|---|---|
| Exchange impl (EIP-1967) | `0x0f3febfc94876b0c895f7acecdc8f5c863b549ee` — 23,052 B, keccak `0x9d20287d…` | `eth_getStorageAt` slot `0x360894a1…`, `eth_getCode` |
| PriceOracle impl | `0x3997ffc8cbd281d4fc8d0548e505ae2fbbbd985a` — 2,475 B, keccak `0x75f094da…` **byte-identical to the Oct-15 snapshot** | `eth_getCode` + hash |
| BatchExecutor impl | `0xe0bc9cc7b067060aafccbaa3e250700c9cdd7262` | EIP-1967 |
| `tradingPaused()` | **false** | `0x53e23e2e` |
| `pauseGuardian()` / `marketKeeper()` / `owner()` | `0x69629276…` (2-of-3) / `0x3721476d…` (hot EOA) / `0xB915Fa41…` (7-day timelock) | `0x24a3d622` / `0x21f55a6c` / `0x8da5cb5b` |
| `lpBankrollAvailable()` | **$4,958,944.58** (drifts $4.94–4.99M) | `0x0cdd5fc4` |
| `totalQueued()` / `totalLockedMargin()` / `totalBalances()` | $0 / $9,606,525 / $52,077,287 | `0x53ac4b66` / `0x01ad056f` / `0xa69a2ad1` |
| Exchange HyperCore spot USDC | ~$65.7M (the LP's Core account) | `api.hyperliquid.xyz/info` |
| OI / caps (packed storage, mapping base `0x24`) | BTC long OI 2,672.44 / cap 2,724.98 → **HR $4.32M**; BTC short OI 2,114.93 / cap 2,224.55 → **HR $9.01M**; ETH long OI 54,437.2 / cap 57,308.1 → **HR $7.00M**; ETH short OI 42,190.5 / cap 45,702.7 → **HR $8.57M** | `eth_getStorageAt` + live mid |
| Layout verified | `slot = scale ‖ uint96 shortOI ‖ uint96 longOI`; `slot+1 = uint128 shortCap ‖ uint128 longCap`; keeper `setOiCaps(inst, a=longCap, b=shortCap)` cross-checked **exactly** against storage at block 48,648,990 (`a=2833.9055, b=1993.0627` = stored longCap/shortCap) | storage reads + keeper calldata |
| Headroom series (143 samples, 15 s apart, 23:05–23:45 UTC) | BTC long HR min $0.00M / median $8.9M / max $32.8M; BTC short median $8.9M / max $31.1M; ETH long median $6.8M / max $17.9M; ETH short median $7.0M / max $12.2M | `analysis/oi_poll.jsonl` |
| Keeper refill dynamics | cap **trails OI**: ~$7–9M headroom restored in steps every ~15–30 s once consumed (74 cap changes / 110 samples); refills continue while OI rises (attacker positions included) | same series; examples 23:24:17→23:24:35 (+$8.95M), 23:44:32→23:44:51 (+$8.89M) |
| Relayers | `authorizedRelayers` = exactly `0xc916e55b1909be6582bf1b2f017aaf82ad8eb0b4` and `0xe726b15cfa8808b2b033dd324a61e754dc6c1686`; `setAuthorizedRelayer` is **owner-only** (`NotOwner()`); fresh EOA → `NotAuthorizedRelayer()`; no self-registration | child1 §Q1 (eth_call sims) |
| Open / close entries | open `0xec6783f0`, close `0x2792e706`; both revert unless caller == BatchExecutor (`0xda96f0b6`); valid SessionKeyManager nonce+deadline signature required | child1 §Q2/Q3 |
| Liquidations | `liquidate(uint256)` / `liquidateBatch(uint256[])` are **permissionless**, priced at the same BBO mid | child1 §Q3 |
| Markets paused? | BTC and ETH both listed, not retired (mapping `0x23` = 0) | child1 §Q2.3 |

**Headroom definition:** `cap − OI` on the side that profits from the manipulated direction (long side for an up-push, short side for a down-push). One side per market per cycle; using both markets requires moving both books (cost adds).

---

## 4. What an attacker can and cannot do

**Cannot (hard):**
- Open/close without the official relayer: no self-registration, Exchange gates on `msg.sender == BatchExecutor`, and the BatchExecutor gates on an owner-managed allowlist. A fresh EOA calling the batch entry reverts `NotAuthorizedRelayer()`.
- Trade without a valid user signature (nonce/deadline consumed by SessionKeyManager — replay of real intents reverts `ExpiredDeadline()`).
- Exceed caps instantaneously: an open that would push a side's OI over its cap reverts (OI cap check in the open path).

**Can (with the relayer forwarding a normally-signed intent — the documented "normal user path"):**
- Open up to the current headroom instantly ($4.3–9.0M per side at measurement; median ≈$7–9M and range $0–33M across the 40-min series).
- **Stack positions through the keeper's trailing caps**: after the headroom is consumed, the keeper restores ~$7–9M within ~15–30 s; repeat. Verified in the live series (OI grew $163M→$234M BTC-long in 31 min with caps trailing throughout). The $10M/position limit is not binding (many positions allowed; no per-account count cap).
- Displace the HL BBO mid cheaply relative to notional: measured (child3, live L2 books, mech "cross-and-rest" = marketable limit, residual rests) — **ETH 15 bp: $17.7M swept, round-trip cost $37k @2.25 bp fees / $45k @4.5 bp; ETH 30 bp: $29.3M / $98k–111k; BTC 15 bp: $43.4M / $90k–109k; BTC 30 bp: $57.1M / $164k–190k** (taker-in/taker-out; a patient maker unwind trims ~$10–20k). The book is quoted at a 1-tick spread, so there is no free quote-improvement; displacement always costs crossing.
- Close within the ~1–5 s relayer cadence (batches land every few blocks), so BBO persistence is not the binding constraint.

**Cost/benefit at CURRENT instantaneous headroom** (block 48,648,947; 2.25 bp fee tier; taker unwind):

| market/side | N | 15 bp payout | 15 bp cost | net | 30 bp net |
|---|---|---|---|---|---|
| ETH up | $7.00M | $7,719 | $36,865 | **−$29,147** | −$80,906 |
| ETH down | $8.57M | $9,443 | $27,846 | **−$18,403** | −$52,439 |
| BTC up | $4.32M | $4,996 | $89,535 | **−$84,539** | −$153,819 |
| BTC down | $9.01M | $10,423 | $63,825 | **−$53,401** | −$119,672 |

Even the zero-slippage, fees-only floor (both legs at 2.25 bp) is negative for every BTC cell (−$1.9k…−$15.0k) and only marginally positive for ETH (−$0.8k…+$9.2k) — a floor that the measured book depth rules out (realistic costs are $26–45k for ETH 15 bp). **The prior Z3-C3 figure (≈$10–22k net/cycle) used a fees-only cost model (~$10k) and double-counted the two ETH sides as simultaneously deployable; both are corrected here.**

**Break-even deployable N** (the decisive number):

| market/dir | 15 bp (2.25 bp fees) | 15 bp (4.5 bp fees) | 30 bp (2.25 bp) | 30 bp (slow unwind) |
|---|---|---|---|---|
| ETH up | $33.5M | $40.7M | $40.6M | $24.2M |
| ETH down | $25.3M | $31.4M | $30.4M | $20.6M |
| BTC up | $77.4M | $94.2M | $66.6M | $40.1M |
| BTC down | $55.2M | $69.1M | $57.4M | $40.4M |

**Conditional path (if N is accumulated through the refills)** — ETH up, live costs:

| N | 15 bp net (fast/slow unwind) | 30 bp net (fast/slow) | 30 bp with 3 bp / 9 bp hedge |
|---|---|---|---|
| $50M | +$18k / +$30k | +$23k / +$62k | +$47k / +$17k |
| $100M | +$73k / +$86k | +$143k / +$183k | +$153k / +$93k |

Additional preconditions for this path (all must hold):
1. **Relayer forwards** ~5–12 bursty opens + the close for a fresh address (off-chain policy; the team stated on Oct 11 it was *"tightening up oi caps both onchain and at the relayer level"*; no published screening rules — unverifiable from chain).
2. **Keeper keeps refilling** (mechanical in the observed window; a human could stop it once the burst is noticed).
3. **Survival of the ~4.8 bp fixed liquidation trigger while accumulating** — a single adverse 5 bp move liquidates every open position, so accumulating $25–100M over 3–6 minutes unhedged is a coin-flip; a delta hedge (short HL perps of the same size) removes the risk but costs ~3–9 bp of N round-trip (maker/taker), which is why the hedge columns above are the realistic ones.
4. **Guardian latency**: `pauseMarket(instrumentId)` permanently retires a market (frozen BBO kills the markup) and `setTradingPaused(true)` blocks opens; the Oct-10 precedent shows the team took hours to react.
5. **Aggregate ceiling**: payouts beyond `lpBankrollAvailable` are queued ("real on-chain debt… a delay"), so the LP's **$4.96M** available cash is the hard bound on a single attack; the $65.7M HyperCore balance is not reachable without an owner sweep/upgrade.

**The $1.28M incident** (for scale): headroom then ≈$1B/side ⇒ 15–20 bp × $1B ≈ $1.1–1.5M per cycle, cost maybe $100–300k (≈$52k fees + slippage on ~6.5 cycles of $20M flow). Today's headroom target is ~100× smaller; the same recipe pays $7–11k per shot.

**The team's own framing agrees with the economic reading** (@papertrade_xyz, Oct 11 15:42 UTC): *"in a system like this, a manipulation attack is always possible — whether economically advantageous to attempt is the question. our goal is to set the parameters such that it is almost never profitable, and that the risk is extremely high/-EV at the tail even when it does work."* They also claim the overnight winner *"continued to try again, ultimately donating almost all his profit back to the house via new accounts, without accounting for the cost of manipulating the bbo on hyperliquids side."* The post-incident mitigation is explicitly **parameter-level** ("tightening up oi caps both onchain and at the relayer level") — no oracle change, no TWAP/deviation breaker, no published relayer rule, no public relayer API (third-party frontends must route through Papertrade's relayer; the Bankr integration is a partner arrangement).

---

## 5. PoC / verification

**Fork-free behavioral PoC (7/7 PASS locally; re-run in CI):** `poc/test/OraclePrimitive.t.sol` embeds the **live oracle implementation bytecode** (2,475 B, keccak `0x75f094da…`), etches it at the oracle proxy address and replaces the BBO precompile `0x080e` with a mock:

| test | proves |
|---|---|
| T1 `test_T1_embedded_impl_hash` | embedded bytecode hash == measured on-chain impl hash |
| T2 `test_T2_accepts_arbitrarily_displaced_uncrossed_book` | **+1,018 bp displaced, uncrossed book is accepted** → no deviation breaker of any kind |
| T2b `test_T2b_accepts_ten_percent_displacement` | +10% displacement accepted |
| T3 `test_T3_rejects_crossed_book_in_mid_path` | only `ask < bid` reverts (in `getMid`); `getBBO` is a raw passthrough |
| T4/T4b | zero bid / zero ask revert |
| T5 `test_T5_getBBO_passthrough` | `getBBO` returns the attacker-chosen pair unchanged |

**CI live re-verification** (`ci/run.sh` → `ci-out/`): atomic snapshot (impls, pause, bankroll, OI/caps, BBO, instrument params, oracle impl hash), a 10-minute headroom series, keeper-calldata↔storage cross-check, and the full economics table, all re-computed from live chain reads at run time.
- CI run URL(s): recorded in `ci-log.txt` (GitHub Actions `artsbykriss/ca-zombie-ci`, branch `papertrade`) and mirrored in `ci-out/summary.txt`; the GitHub run URL is also copied into `summary.json` → `poc.ci_run_urls`.

**Real-transaction validation of the payout model (revenue side):** the Exchange's close event emits `(rawPnl, adjustedPnl, fee)`. Decoded from real closes:
- `pid 874527` (BTC long, entry 82,291.5, notional $100,000, block 48,650,231): logged raw **38.157039**, adjusted **22.948697**, fee **0.458974** (= 2% × adjusted). Model prediction: raw = 100,000 × (m − 0.2 bp) with m = 3.815 bp → adjusted = raw × 0.9/(1 + 1/(m_eff·15000) + 100000/(1e6·m_eff·814.598)) = **22.9484** — exact to 6 significant figures.
- `pid 873990` (BTC long, entry 82,299.5, notional $4,266.23): logged adjusted **0.655196** vs model **0.655448** (0.04% off, price rounding).
- `pid 873510` (ETH short, entry 2,441.75, notional $10,000, loss): logged **−1.638169** = full raw loss (no deadband on losses, no scaling) — exact.
⇒ The docs' impact-curve payout is **live and correctly modeled**; the E-U figures in §4 use it (including the 0.2 bp deadband and the 2% win fee).

**Local artifacts:** `analysis/final_snapshot.json` (block 48,648,947), `analysis/oi_poll.jsonl` (143 samples), `analysis/economics.json`, `analysis/child1-access-control.md`, `analysis/child2-web-docs.md`, `analysis/child3-cost-model.{md,json}`.

---

## 6. Verdict and residual/latent risk

**E-U (unprivileged, live, actionable today): $0** — the primitive is fully live but **economically closed at current caps** (net-negative 3–10× at instantaneous headroom; negative even under a zero-slippage fee floor for BTC). Confidence: **high** on the state/primitive; **medium-high** on the negative economics (book-depth model is one snapshot, but it was taken in a *thin, falling* tape — calm-market depth is deeper, i.e. costs would be higher, not lower).

**E-U (conditional):** re-opens if an attacker accumulates **≥$25–40M/side (ETH)** or **≥$40–55M (BTC)** through the keeper's trailing refills with a delta hedge and the relayer's cooperation: **≈+$15k–180k/cycle**, bounded by the **$4.96M LP bankroll**; realistic single-session take **$0.1–2M**. Confidence: **medium** (relayer policy, keeper persistence and guardian latency are unverifiable from chain).

**Latent risk:** the mitigation is a **rate limiter**, not a redesign. The oracle is unchanged and the caps trail OI upward; any widening of the headroom target (e.g. a return toward the launch policy) or a thinner-book regime restores the original economics immediately.

**Blockers/frictions (in order of hardness):** (1) relayer allowlist + off-chain screening; (2) 4.8 bp fixed liquidation trigger forcing hedged accumulation; (3) keeper refill cadence (~$9M per 15–30 s) limits accumulation speed; (4) guardian retirement (permanent, per-market); (5) LP bankroll as the aggregate ceiling; (6) 7-day timelock on owner upgrades (cannot be used reactively).

**Watch triggers:** per-side headroom `cap − OI` (esp. sustained > $35M ETH / > $70M BTC); cap-policy changes by keeper `0x3721476d…`; `pauseMarket` / `setTradingPaused` by guardian `0x69629276…`; oracle impl-slot/hash change; `authorizedRelayers` set changes; `lpBankrollAvailable` / `totalQueued`; any new incident reports.

---

## 7. Methodology & sources

- **Live reads (all recorded with block numbers):** EIP-1967 slots, `eth_call` views, packed OI/cap storage (`mapping base 0x24`, keccak-verified), `instruments(uint32)` (`0xdc8a47ef`), oracle `getBBO`/`getMid`, keeper `setOiCaps` calldata (Etherscan v2, chain 999), HyperCore `spotClearinghouseState`. Public keyless RPC `https://rpc.hyperliquid.xyz/evm`; no keyed URLs or secrets in any artifact.
- **ABI/selector reconstruction:** prior campaign disassembly + OpenChain/4byte mapping; corrected by this pass (open = `0xec6783f0`, close = `0x2792e706`; `instruments` = `0xdc8a47ef`; `authorizedRelayers` = `0x29e295c5`).
- **Side mapping verified empirically:** long opens (decoded from real intents) increase the low-96-bit OI field; a long position (w6=1) liquidated during a price fall; keeper `a`/`b` == stored long/short caps.
- **Cost model:** live HL L2 books (BTC + ETH, 23:10 UTC, plus nSigFigs depth variants to ±2,400/±7,980 bp), mechanism A/B sweep math, taker fees per HL docs (base 4.5 bp; incident-implied 2.25 bp), measured unwind. Child-3 report (`analysis/child3-cost-model.md`).
- **Docs & web:** protocol docs bundle (byte-identical to the Oct-15 extraction — no oracle/TWAP/deviation/screening change documented), Oct-11 X statement, DefiLlama hacks row ($1.28M, Oracle Manipulation), WuBlockchain/crypto.news/altcoinbuzz coverage (child-2 report).
- **PoC:** Foundry 1.7.1, solc 0.8.24 (CI re-run).

**Caveats & limitations**
1. Book-depth costs come from **one 23:10 UTC snapshot in a falling tape**; depths vary ±10–30 % locally and materially by hour; the economics scale linearly with cost, so break-even N moves with them (state the direction: deeper book ⇒ higher cost ⇒ higher break-even).
2. The accumulation path is **modeled, not executed** (no transactions were sent). The keeper's refill persistence under an adversarial burst is inferred from 40 minutes of observation plus the mechanical hysteresis rule; a human intervention is possible at any time.
3. Relayer forwarding policy is **off-chain and unverifiable**; "fresh attacker" is therefore conditional on it.
4. Hedging costs/slippage on HL are modeled at 3–9 bp of N; actual depends on tier and execution.
5. The incident's own per-cycle cost is not observable on-chain (only $52k fees + $231M volume are reported).
6. Historical storage reads on the public RPC are load-balancer-inconsistent (off-by-one-block); all decisive figures are single-block atomic reads at the node's `latest` with keeper-calldata cross-checks.

---

## 8. Files index

```
papertrade/
├── README.md                  # this file
├── summary.json               # machine-readable summary
├── analysis/
│   ├── probe.py, final_snapshot.py, final_snapshot.json      # live state (block 48,648,947)
│   ├── poller.py, oi_poll.jsonl                              # 143-sample headroom/OI series
│   ├── economics.py, economics.json                          # payout/cost/break-even model
│   ├── instruments_live.json                                 # instruments(uint32) re-read
│   ├── oracle_impl_live.hex, exchange_impl_live.hex          # live runtime code + keccak
│   ├── keeper_final.json, es_exchange_recent.json, es_batchexec_recent.json
│   ├── child1-access-control.md (+child1/)                   # relayer gate, entries, oracle checks
│   ├── child2-web-docs.md (+child2/)                         # post-incident statements, docs diff
│   └── child3-cost-model.md/.json (+books/candles)           # HL book-depth manipulation costs
├── poc/                        # Foundry: OraclePrimitive.t.sol (7 tests) + vendored forge-std
├── ci/run.sh, ci/snapshot_ci.py, ci-out/                     # CI live re-verification + artifacts
└── ci-log.txt / ci-artifacts/                                # downloaded after the CI run
```

*No secrets were read, printed or written; no transactions were signed or sent; all interactions were read-only `eth_call`/`eth_getStorageAt`/public APIs and one fork-free local Foundry test.*
