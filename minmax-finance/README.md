# MinMax Finance (IoTeX) — zombie-hunt II, L2 Phase-2 deep dive

**Date:** 2026-10-14 · **Chain:** IoTeX (chain id 4689) · **Status:** read-only; all PoC computations are
`eth_call`-based simulations against live state at a pinned block; **no transactions were sent, no keys used**.

**Triage row:** L2-triage-b rank #19 — "MinMax Finance", live $111,352.47 (DefiLlama-priced), IoTeX block
53,270,907 (2026-10-11).

---

## 1. TL;DR

| Target | Live value (market-priced) | Extractable by a fresh unprivileged attacker? | Why |
|---|---|---|---|
| **P1** `0x89963FCD…` ioBUSD/ioUSDC/ioUSDT/ioDAI | ≈ $29.0k | **No** ($0) | StableSwap at equilibrium: best spot edge +0.62% < 0.66% round-trip market fees |
| **P5** `0x09A1B7d9…` BUSD-bsc/USDC_b/USDT_b | ≈ $32.2k | **No** ($0) | Best spot edge +0.51% < fees |
| **P9** `0xdab7B4D2…` DAI-matic/USDT-matic/USDC-matic | ≈ $37.1k | **No** ($0) | Best spot edge +0.55% < fees |
| **P2/P6/P11** XIM metapools | ≈ $70 (XIM≈$0.036) | **Micro** ($0.011) | Cross-family imbalance; XIM has no liquid exit |
| **P7** `0x074ec23e…` ioUSDT/USDT_b/USDT-matic | ≈ $6.2 | **Micro** ($0.009) | Cross-family imbalance, capped by 0.38 USDT-matic reserve |
| **A8D** `0xA8D60c35…` ioBUSD/ioUSDC/ioUSDT (early pool, different owner) | ≈ $3.0 | **Micro** ($0.024) | ioUSDT-scarce pool pays a premium |
| **P4/P8/P10 + 5 more metapools** (8 paused) | ≈ $50 + XIM | **No** | `paused`; only proportional `removeLiquidity` (holder-only, H-O) |
| Admin fees inside all pools | **$1,818** | **No** | `withdrawAdminFees()` is `onlyOwner` (EOA, dormant 2 years) — P |
| **Total** | **≈ $98.5k live** | **≈ $0.04–0.05** | |

## 2. Total live extractable now (fresh attacker)

> ### **E-U ≈ $0.044** (11.674 WIOTX; sum of best single cycles per pool; confidence **high** on the order of magnitude, **medium** on the exact cents)
> ### H-O ≈ $96.7k (LP-token redemptions by holders) · P = $1,818 (admin fees, owner EOA) · S = 0

The triage's $111,352 was **DefiLlama-priced**. DefiLlama's own adapter (`projects/minmax-finance/index.js`,
commit `f99db7b813`) maps the Ethereum-bridged `io*` tokens to their **Ethereum underlyings** (USDT → $1.00,
DAI → $1.00), which overstates live value by ~2x for the impaired io-tokens (see §5.2). At **actual market
prices** the same contracts hold ≈ **$98.5k**, and only **~$0.04** of that is extractable by an outside attacker.

## 3. Architecture (verified on-chain)

MinMax Finance is a **Saddle Finance v1 StableSwap fork** on IoTeX ("the first next generation stablecoin AMM
on IoTeX", per its DefiLlama description). Verified facts:

* Pool implementation (EIP-1167 clone target, unverified): `0x0e62d07a666691ca2276adb729ca33b03779b2b15`.
  The clones' runtime is `363d3d373d3d3d363d73…0e62d07a…5af43d82803e903d91602b57fd5bf3`.
  `calculateSwap()` on the clones matches a byte-exact Python re-implementation of Saddle v1 `SwapUtils`
  (getD/getY, `A_PRECISION=100`, `FEE_DENOMINATOR=1e10`) to **< 25 wei** on every probe → the deployed math
  is Saddle v1 (`A=200` ⇒ `initialA=20000`, `swapFee=6e6` = 0.06%, `adminFee=5e9` = 50% of fee).
* Pools: **19 live pools** — 9 base pools + 10 metapools (`XIM`/`<base>-LP` and `<stable>`/`<base>-LP`),
  enumerated from (a) the archived frontend bundles `minmax.finance/static/js/main.a1449f6a.chunk.js` (2022)
  and `main.7f473e6d.chunk.js` (2023), (b) the DefiLlama adapter, (c) the L2-triage pool set, and
  (d) an on-chain probe of every IOTEX address in those bundles for the clone pattern / `swapStorage()` ABI.
* `owner()` of every base pool and most metapools = **EOA `0x226f272a2635523b9d50a8d2b481ced204b4d9c2`**
  (last outgoing transaction: **~2 years ago**; holds 581.19 XIM). Early pools `0xA8D60c35…`, `0x3eF1e70e…`,
  `0x9CBab9D5…`, `0x5168529a…` etc. belong to two other dormant EOAs (`0x025eda…`, `0x3f8e52…`) — all are
  part of the same Saddle-family deployment listed in the MinMax frontend.
* Paused pools: `0x8360D306` (XIM/P3-LP), `0x833d89FA` (XIM/P5-LP), `0x7B24cAA6` (XIM/P9-LP),
  `0x22CB23Cb`, `0x55Ce939A`, `0x70CDfb66` (old-XIM/LP), `0x886fA6ca`, `0xA63B7e43`.
* **No permissionless function pays the caller.** The full state-changing ABI is:
  `swap`, `addLiquidity`, `removeLiquidity`, `removeLiquidityOneToken`, `removeLiquidityImbalance`
  (all value-conserving or LP-gated), `withdrawAdminFees`, `setAdminFee`, `setSwapFee`, `rampA`, `stopRampA`,
  `pause`, `unpause` (all `onlyOwner`). `initialize()` is one-shot (clones are initialised at creation;
  a re-init `eth_call` reverts). There is no oracle, no mint, no claim, no upgrade hook on the pools.

## 4. The finding in exact terms

The "zombie" pattern here is **abandoned StableSwap liquidity that is not, however, exploitable**: the pools
still hold ~$98.5k of user/LP liquidity, but the surrounding IoTeX market has already priced every pool at
equilibrium (arbitrage bots run cycles through P1/P5 continuously — see §7). The residual extractable value is
limited to the pools that mix **token families with different real values** (the XIM pools and P7) and to two
tiny early pools — and is capped by their own micro-reserves, not by any bug.

The reason the headline is ~$0.04 and not ~$100k:

1. **The Ethereum-bridged `io*` tokens are impaired.** The ioTube bridge was hacked on 2026-02-21
   ($4.4M, Ethereum-side validator key) and bridge operations remain suspended. `ioUSDC`/`ioBUSD`/`ioUSDT`/
   `ioDAI` are claims on that bridge. Their live market prices (WIOTX-anchored Mimo pools, all balanced at
   equilibrium) are **$0.540 / $0.539 / $0.538 / ~$0.54** — not $1. P1 holds them at par internally, which is
   *correct*: all four are equally impaired, so P1 is fairly priced.
2. **BSC/Polygon-bridged stables are intact**: `BUSD-bsc` $0.999, `USDT_b` $0.995, `USDC_b` ≈ $1,
   `DAI-matic` $0.995, `USDT-matic` $0.996, `USDC-matic` ≈ $1 (WIOTX pairs). P5 and P9 hold only one family
   each → equilibrium.
3. **XIM is effectively worthless** (no market): the three XIM metapools' spot rates independently agree on
   **XIM ≈ $0.036**, and XIM's entire real exit liquidity on IoTeX is the `MAX/XIM` pair, worth **$0.72** in
   WIOTX terms. The explorer's displayed XIM price ($0.609) is derived from stale/paused-pool ratios, not an
   executable market (0 XIM transfers in the last 40k blocks).

## 5. Live-state assessment (all read at pinned blocks, public RPC only)

### 5.1 Pools (balances = `getTokenBalance`, i.e. LP-owned; admin fees tracked separately)

Block **53,359,657** (CI run, 2026-10-14 00:53 UTC) — identical to the local run at block 53,358,839; `ci-out/state_dump.json`.

| Pool | Tokens | Balances | paused | owner | market value |
|---|---|---|---|---|---|
| P1 `0x89963FCD…` | ioBUSD / ioUSDC / ioUSDT / ioDAI | 9,320.19 / 7,922.04 / 18,426.61 / 18,052.33 | no | `0x226f272a…` | ≈ $28,963 |
| P2 `0x2c1B1DE7…` | XIM / ioBUSD / ioUSDC / ioUSDT | 189.67 / 3.358 / 2.926 / 3.219 | no | `0x226f272a…` | ≈ $12 |
| P3 `0xC264ED05…` | ioUSDC / ioUSDT / ioDAI | 28.83 / 31.42 / 61.29 | no | `0x226f272a…` | ≈ $65 |
| P5 `0x09A1B7d9…` | BUSD-bsc / USDC_b / USDT_b | 7,697.29 / 13,100.04 / 11,477.13 | no | `0x226f272a…` | ≈ $32,210 |
| P6 `0xe409587F…` | XIM / BUSD-bsc / USDC_b / USDT_b | 445.57 / 5.098 / 4.777 / 4.769 | no | `0x226f272a…` | ≈ $31 |
| P7 `0x074ec23e…` | ioUSDT / USDT_b / USDT-matic | 10.505 / 0.585 / 0.000384 | no | `0x226f272a…` | ≈ $6.2 |
| P9 `0xdab7B4D2…` | DAI-matic / USDT-matic / USDC-matic | 13,571.57 / 9,652.63 / 13,941.98 | no | `0x226f272a…` | ≈ $37,060 |
| P11 `0x73541e9f…` | XIM / DAI-matic / USDT-matic / USDC-matic | 430.13 / 4.564 / 4.60 / 4.60 | no | `0x226f272a…` | ≈ $29 |
| A8D `0xA8D60c35…` | ioBUSD / ioUSDC / ioUSDT | 2.836 / 2.503 / 0.125 | no | `0x025eda…` | ≈ $3.0 |
| P4 `0x8360D306…` | XIM / P3-LP | 104.85 / 57.19 | **yes** | `0x226f272a…` | ≈ $35 |
| P8 `0x833d89FA…` | XIM / P5-LP | 8.637 / 4.119 | **yes** | `0x226f272a…` | ≈ $4.5 |
| P10 `0x7B24cAA6…` | XIM / P9-LP | 8.671 / 11.05 | **yes** | `0x226f272a…` | ≈ $11.4 |
| 6 further metapools (`0x22CB23Cb`, `0x55Ce939A`, `0x70CDfb66`, `0x5F0273AB`, `0x886fA6ca`, `0xA63B7e43`, `0xEd01d848`) | XIM-old / stable / base-LP | ≤ 11 units each | mostly yes | EOAs above | ≈ $10 |

Admin fees (raw → USD at market prices): P1 $929, P5 $489, P9 $301, P3 $41, P2 $29, P6 $24, P11 $6, others ≈ $0
→ **$1,818 total, withdrawable only by `0x226f272a…` (`onlyOwner`)**.

### 5.2 Market map used (WIOTX = IOTX = $0.0037624, DefiLlama; Mimo V2 fee verified = 0.30%)

| Token | Live price | Anchor (all Mimo V2 pairs vs WIOTX) |
|---|---|---|
| ioUSDC | $0.540 | `0x68bf247e…` 1,740.07 ioUSDC / 249,712.53 WIOTX (balanced) |
| ioBUSD | $0.539 | `0x2a7775e7…` 1,393.10 ioBUSD / 199,507.57 WIOTX |
| ioUSDT | $0.538 | `0xe82b7054…` 4,742.19 ioUSDT / 678,209.62 WIOTX |
| ioDAI | ~$0.54 (no market) | only reachable via MinMax pools (par with ioUSDC/ioUSDT) |
| BUSD-bsc | $0.999 | `0x6bdefe87…` 1,049.00 / 278,480.03 WIOTX |
| USDT_b | $0.995 | `0x9e774a0c…` 24,695.03 / 6,529,895.62 WIOTX |
| DAI-matic | $0.995 | `0xd40bfd9b…` 29,058.06 / 7,685,672.14 WIOTX |
| USDT-matic | $0.996 | `0xb30ddcc6…` 32,299.92 / 8,551,956.61 WIOTX |
| USDC_b / USDC-matic | ≈ $1 (no market) | only reachable via P5/P9 |
| XIM | ≈ $0.036 | implied identically by P2 (0.0664 ioUSDC/XIM), P6 (0.0366 USDT_b/XIM), P11 (0.0361 USDT-matic/XIM); exit = MAX/XIM `0xde7399ec…` (34.4 XIM / 114,078 MAX, MAX itself worth $0.72) |

DefiLlama prices ioUSDT/ioDAI at $0.999/$1.000 because its adapter maps them to the Ethereum underlyings —
that is the single largest reason the triage figure ($111k) exceeds market value ($98.5k).

## 6. What an attacker can and cannot do (exact paths)

**Method.** For every pool and every ordered token pair, the best closed cycle
`WIOTX →(Mimo 0.3%)→ token_in →(MinMax pool, live calculateSwap)→ token_out →(Mimo 0.3%)→ WIOTX`
was computed over a size grid + local refinement (`analysis/extract_sim.py`, run on CI). Positive results:

| Cycle | Optimal input | Profit |
|---|---|---|
| `A8D`: ioUSDT → ioUSDC | 120 WIOTX ($0.45) | **+6.36 WIOTX = $0.024** |
| `P7`: USDT-matic → USDT_b | 25.5 WIOTX | +2.29 WIOTX = $0.0086 |
| `P2`: ioUSDC → ioBUSD | 30 WIOTX | +1.73 WIOTX = $0.0065 |
| `P6`: USDT_b → BUSD-bsc | 45 WIOTX | +1.29 WIOTX = $0.0048 |
| `P11`: DAI-matic → USDT-matic | 1.2 WIOTX | +0.0013 WIOTX = $0.000005 |
| **All P1/P3/P5/P9 pairs** | any size | **negative** (−0.00001 … −0.04 WIOTX) |
| `P2/P6/P11` XIM-out paths (stables → XIM → MAX → WIOTX) | — | **negative**: 500 XIM sells for ≤ 191.8 WIOTX ($0.72) |

Net of IoTeX gas (≈ 550k gas × 1e12 Rau ≈ 0.00055 IOTX ≈ $0.000002/tx) the **total fresh-attacker extraction is
≈ 11.7 WIOTX ≈ $0.044**, dominated by the two early micro-pools. Costs assumed: Mimo 0.30% per leg (empirically
verified from decoded swaps), MinMax 0.06% swap fee, no flash-loan cost needed (inputs are < $1).

**Cannot:**
* extract from P1/P5/P9 — best spot edges (+0.62%/+0.51%/+0.55%) are below the 0.66% round-trip fee cost
  (`0.3% + 0.06% + 0.3%`); the simulation is negative at every size, and the pools' own compositions confirm
  they are arber-maintained (P1 ioBUSD→ioDAI edge is +0.62% vs 0.66% cost — a 0.04% knife-edge).
* sell XIM in any size: the whole XIM market is one $0.72-deep MAX/XIM pool plus dust; xDollar's app is dead
  (DNS) and the XIM token is a plain Ownable ERC20 (no on-chain redemption found); 0 XIM transfers in the
  last 40,000 blocks.
* touch the paused pools: `swap`/`addLiquidity` revert (`whenNotPaused`). Only proportional
  `removeLiquidity` remains and it is gated by LP-token ownership (H-O; Saddle comment: "Liquidity can always
  be removed, even when the pool is paused").
* withdraw the $1,818 of accrued admin fees: `withdrawAdminFees()` is `onlyOwner` (EOA `0x226f272a…`, dormant).
* re-initialise a clone, mint, upgrade, or call any function that pays an arbitrary caller.

## 7. Verification & PoC (CI)

* `ci/run.sh` (runs on GitHub Actions, `artsbykriss/ca-zombie-ci`, workflow `poc.yml`):
  1. `analysis/state_dump.py` — all 19 pools + 10 market pairs at the CI-pinned block (tokens, balances,
     admin fees, pause flags, owners, LP supplies, reserves).
  2. `analysis/extract_sim.py` — the closed-cycle optimiser (live `calculateSwap` + verified constant-product
     math) → `ci-out/extract_sim_out.json`.
  3. `analysis/scan_events.py` — `TokenSwap`/`TokenAddLiquidity`/`TokenRemoveLiquidity` events on all pools
     (liveness evidence; the public RPC rate-limits large parallel scans — the decisive targeted queries are
     recorded in `analysis/live_swap_evidence.json`: **P5 emitted 27 TokenSwap events in a single 2,000-block
     window**, P1 one — the aggregator bot `0x782e8Aa8…` swaps through both daily).
  4. `analysis/lp_data.py` — LP token supplies/admin balances.
* **CI runs:** `https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38492711664` (success; artifacts in
  `ci-artifacts/result-minmax-finance/ci-out/`). Result: A8D +6.36277606 WIOTX ($0.0241), P7 +2.28922016
  ($0.0087), P2 +1.73305500 ($0.0066), P6 +1.28774877 ($0.0049), P11 +0.00133993; all P1/P3/P5/P9 cycles
  negative; XIM exit 191.78 WIOTX ($0.7263) for 500 XIM; IOTX $0.0037870 at run time.
* **No fork PoC is possible for IoTeX**: `anvil --fork-url` fails against every public IoTeX RPC tested
  (`babel-api`, `onfinality`, `thirdweb`, `blastapi`) because the node returns IoTeX-native fields that
  foundry's fork client cannot unmarshal (`failed to unmarshal height … hex string without 0x prefix`), and
  the RPC prunes historical state beyond ~3,000 blocks and ignores `eth_call` state overrides (verified: a
  stateDiff'd `balanceOf` override is silently ignored). The PoC is therefore a **live-state `eth_call`
  simulation** (the pool's own `calculateSwap` does the math) plus the decoded on-chain swaps of the live
  arbitrage bot, e.g. tx `0x4954f267c8f191e8bf6b521bc90dcd65d71dbd4db6498592f1f1575f8765451f`
  (block 53,342,593): a 5-hop cycle `WIOTX → USDT_b → (P5) BUSD-bsc → ioUSDT → (P1) ioUSDC → WIOTX`
  netting **+1.91 WIOTX**, gas 550,463.

## 8. Verdict, residual & latent risk

* **Verdict:** no material live extraction. The 11 pools the triage flagged hold ≈ **$98.5k at real market
  prices**; a fresh unprivileged attacker can take **≈ $0.04** now (micro-arbitrage in two abandoned
  early pools and three imbalanced XIM metapools). Confidence: **high** (three independent anchors:
  WIOTX pairs, the live arbitrage bot's cycle economics, and per-pool spot-rate vs fee-band analysis).
* **Residual/latent risk (not E-U today):**
  * **$1,818 admin fees** (P) — claimable by the dormant owner EOA `0x226f272a…`; if that key ever moves,
    it is an immediate, permissionless-for-the-holder withdrawal.
  * **H-O ≈ $97k** — LP holders can redeem pro-rata; the paused metapools' LP holders can also exit via
    proportional `removeLiquidity`.
  * **If the ioTube compensation/restart materialises** (IoTeX committed to 100% compensation of affected
    bridge users), the io-tokens would re-rate toward $1. P1 would then be a *$36k mismatch* pool
    (io-tokens at par vs market), and the classic depeg-arbitrage against P1 becomes live again — worth up to
    ~$16k minus market impact (bounded by P1's ioUSDT+ioDAI side and the market's depth).
  * **If a XIM market ever appears** (xDollar restart, CEX listing), the metapool extraction flips positive:
    pushing stables into P2/P6/P11 yields XIM at an effective ~$0.036–0.04; at a $0.61 real exit the
    extractable would be ≈ $140–600 (bounded by 1,065 XIM of reserves and by exit depth). Today: $0.
* **Blockers to extraction (why closed):** impaired Ethereum-bridge tokens already priced-in; thin market
  depth (the whole io-token float outside the pools trades in <$5k pools); dead XIM exit; paused metapools;
  `onlyOwner` admin paths; and the pools being arber-maintained within a ±0.2% band.

## 9. Methodology, sources, caveats

**Sources:** L2-triage-b `summary.json`/`results.json` (block 53,270,907); `zombie_hunt/FINDINGS.md`;
DefiLlama adapter `projects/minmax-finance/index.js` @ `f99db7b813` (and its `iotex_cg_stablecoin_mapping.json`);
archived MinMax frontend bundles (2022-01-24, 2023-06-01) from web.archive.org; IoTeXScan (via proxy);
Saddle v1 sources (`saddle-finance/saddle-contract`, master); public IoTeX RPC `babel-api.mainnet.iotex.io`;
Mimo V2 factory `0xda257cbe968202dea212bbb65ab49f174da58b9d` (669 pairs enumerated); DefiLlama prices
(`coins.llama.fi`) for IOTX/USD; Halborn/CoinDesk/Rekt coverage of the 2026-02-21 ioTube hack.

**Caveats / limitations:**
1. The pool implementation `0x0e62d07a…` is **unverified source**; Saddle-v1 equivalence was established by
   byte-exact behaviour matching of `calculateSwap`/`swapStorage`/`getVirtualPrice` (not by source review).
   The pause-modifier semantics (`removeLiquidity` unblocked) are taken from Saddle v1 source, not from a
   fork test (impossible on IoTeX).
2. Historical state on IoTeX public RPCs is pruned (≤3,000 blocks), so all figures are point-in-time at the
   stated block; pool balances drift with LP withdrawals (P1 lost ~4–7% of each token in the 5 days between
   triage and re-check) but the equilibrium structure is stable.
3. The pool set was assembled from the frontend bundles + DL + triage + clone-pattern probing; a pool created
   after 2023 and never listed in any frontend could in principle have been missed (no factory/registry was
   discoverable — the explorer is Cloudflare-gated and no registry ABI exists in the bundles).
4. Micro-arbitrage results depend on the Mimo pool state at the pinned block and are computed against the
   *best single cycle per pool*; combining cycles would only reduce the total (they compete for the same
   reserves). USD conversion uses DefiLlama IOTX at the run time.

**Files:** `analysis/` (scripts + JSON dumps: `saddle_math.py` verified implementation,
`extract_sim.py`, `state_dump.py`, `scan_events.py`, `mimo_scan.py`, `mimo_toi.py`, `union_probe.py`,
`extra_pools.py`, `lp_data.py`, `verify_swaps.py`, `find_factory.py`); `ci/run.sh`; `ci-out/` (CI artifacts);
`summary.json`.
