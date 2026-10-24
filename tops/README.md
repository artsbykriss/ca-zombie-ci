# TOPS (BSC) — NEM-class "burn-from-pair + `sync()`" gate resolution

**Date:** 2026-10-23 (initial) · **Recheck:** 2026-10-24 · **Chain:** BSC (56) · **Target:** TOPS token `0x842B1BFa825Cf6673fD2D98E573FdD267C3Fd588`
**Pair:** PancakeV2 TOPS/USDT `0xbeDebAC3788171DC769893242a53b881041EDf29`
**Status:** read-only; PoC fork-verified only; **no mainnet transaction was signed or sent**. Finding id **ZH4P5-TOPS** (row #10 of `zombie-hunt-iv/pass4/skim-burn.md`).

---

## 0. UPDATE 2026-10-24 — live state changed; verdict re-confirmed at HEAD

The 2026-10-23 analysis (block **129 280 478**) rested on **three** barriers. Two of them were
*state-dependent* and have since changed on-chain. A head-fork recheck (`poc/test/TopsRecheck.t.sol`,
fork head **129 586 140**) shows:

| Barrier | Block 129 280 478 | HEAD 129 586 140 | Effect |
|---|---|---|---|
| (a) price-state gate | **CLOSED** (`priceRose2Percent=true`) | **OPEN** (`priceRose2Percent=false`; `realTimePrice` 0.12292 < `trackedPrice`·1.02 = 0.12753) | recycle *can* now fire |
| (b) `buyEnabled` entry block | **false** | **true** | outsiders *can* now buy TOPS |
| (c) self-defeating fee re-swap | holds | **holds (fork-proven at HEAD)** | reserve1 still never collapses |

**Barrier (c) is the load-bearing one and is unaffected.** Recheck fork results at HEAD:

- `test_R3b` — an unprivileged sell of **100 000 TOPS** fires `TokensRecycled` (burn = **10 000 TOPS**) and yet
  **Δreserve1 = +90 000 TOPS** (reserve1 *grows*), Δreserve0 = −11 019.99 USDT. The NEM-class "collapse one
  reserve" is structurally impossible because the 20 % sell fee is re-swapped **into the same pair**.
- `test_R2` — a buy now succeeds (30 % buy tax measured), so entry is open; `test_R4` — a **20 000 USDT
  buy→sell round trip returns 10 335 USDT = −9 781 USDT (−48.9 %)**.
- `test_R3` — a *20 000 USDT buy* raises spot >2 % over `trackedPrice`, so the subsequent sell takes **zero**
  recycle events: acquiring TOPS at a size that would matter itself closes the gate.
- `test_R5` — LP `removeLiquidity` now **succeeds** (was blocked while `buyEnabled=false`); the pair is no
  longer frozen.
- `test_R6` — token cost to drain reserve1 ≈ **$95 910** vs a maximum reward of **$95 862** → net negative.

**Verdict unchanged: E-U = $0.00 (high confidence).** The 2026-10-23 "closed price gate / buys disabled"
reasoning is superseded; the correct reason is the structural one: the recycle can only ever remove
`≤ sellAmount/10` from the pair while `20 %` of the sell amount is re-added, so `reserve1` cannot collapse.

---

## 1. TL;DR

| # | Target | Live E-U extractable | Why closed | Latent risk |
|---|--------|----------------------|------------|-------------|
| 1 | TOPS token `0x842B…f588` / pair `0xbeDe…df29` ($95,862.06 USDT + 777,926.30 TOPS ≈ **$191,724 TVL**) | **$0.00** | **(structural) the burn-from-pair + `sync()` is self-defeating**: it removes only `≤ sellAmount/10` from the pair while the 20 % sell fee is re-swapped *into the same pair*, so `reserve1` **grows** on every sell (fork: 100 000 TOPS sell → burn 10 000 but Δreserve1 = **+90 000**); the price-state gate and `buyEnabled` that also closed it on 2026-10-23 have since **re-opened** (HEAD: `buyEnabled=true`, gate open) — yet a 20 000 USDT round trip still loses **−9 781 USDT** and the token cost to drain reserve1 ($95 910) exceeds the reward ($95 862) | Low. The primitive is live and unprivileged-reachable; it is not monetisable at any size because fee ≥ 2×burn and the fee re-enters the pair |

---

## 2. Total live extractable now

**$0.00 — confidence HIGH** (external unprivileged, E-U).

- **E-U (external unprivileged): $0.00**
- **E-U-conditional**: **$0.00** — the recycle is structurally unprofitable whether or not the state gate is open (fork-proven at HEAD where both `buyEnabled=true` and the gate is open).
- **H-O (holder self-service): $0.00 trapped** — LP redemption is now **open** at HEAD (`removeLiquidity` succeeds; it was blocked at block 129 280 478 while `buyEnabled=false`). The pool is ordinary market liquidity, not trapped value; a TOPS holder can sell at market (normal trading).
- **P (privileged): $0.00 directly** — owner/`tradeController` `0xf6370D9F…` can flip `buyEnabled`/`sellEnabled` and set fees, but cannot unilaterally seize the pair's USDT.
- **S (permanently stuck): $0.00** — nothing is bricked.

At block 129 280 478 the ~$192.8k in the pair was frozen for non-privileged parties (buys **and** LP exits blocked). **That is no longer the case**: at HEAD (129 586 140) `buyEnabled=true` and LP exits work, so the pair is a normal, tradeable AMM pool.

---

## 3. The mechanism, exactly

The token is verified on **Etherscan V2** (chainid 56), contract name `Token`, `solc 0.8.28`, `optimizer runs = 1`, `viaIR = true`, `evmVersion = cancun`. Sourcify has **no** match. Full source in `analysis/src/contracts__v2__token.sol` (962 lines). It is a fee-token (`AbsToken`) with a `sync()` call in a **sell hook**:

```solidity
// contracts/v2/token.sol:729
function _handleSellRecycle(address seller, uint256 sellAmount) private nonReentrant {
    uint256 currentPrice = getTokenPrice();
    uint256 trackedPrice = priceTracker.currentPrice;
    if (currentPrice == 0 || trackedPrice == 0) return;            // gate 1
    uint256 pairBalance = balanceOf(mainPair);
    if (pairBalance == 0) return;
    bool priceRose2Percent = currentPrice >= trackedPrice * PRICE_RISE_THRESHOLD / PERCENTAGE_BASE; // 10200/10000
    if (!priceRose2Percent) {                                       // gate 2  (!!)
        uint256 recycleAmount = sellAmount;
        uint256 maxRecycleAmount = pairBalance / MAX_RECYCLE_RATIO; // /3
        uint256 actualRecycleAmount = recycleAmount >= maxRecycleAmount ? maxRecycleAmount : recycleAmount;
        uint256 distributorAmount = actualRecycleAmount * RECYCLE_DISTRIBUTOR_PERCENTAGE / PERCENTAGE_BASE; // /10
        if (distributorAmount > 0) {
            _balances[mainPair] -= distributorAmount;               // remove-from-pair, sized by balanceOf(pair)
            _takeTransfer(mainPair, address(tokenDistributor), distributorAmount);
            ISwapPair(mainPair).sync();                             // 0xfff6cae9  <-- the NEM-class primitive
            emit TokensRecycled(seller, recycleAmount, distributorAmount);
        }
    }
}
```

Called only from `_tokenTransfer` (line 510) **when `isSell` is true**, i.e. when the transfer recipient is `mainPair` and `takeFee` holds:

```solidity
_balances[sender] -= tAmount;
if (takeFee) {
    (uint256 feeAmount, bool isSell) = _calculateAndApplyFees(...);
    totalFeeAmount = feeAmount;
    if (isSell) { _handleSellRecycle(sender, tAmount); _swapTokenForCake(); }   // <-- burn, then swap the fee back in
}
_takeTransfer(sender, recipient, tAmount - totalFeeAmount);
```

`_swapTokenForCake()` (line 536) claims the sell fee tokens from the fee distributors and swaps **the same amount of TOPS back into the very same pair** via `swapExactTokensForTokensSupportingFeeOnTransferTokens([TOPS,USDT], …)`. Therefore, for a fee-bearing sell:

```
Δreserve1 = −burn + fee    where burn = min(amount, pairBal/3)/10 and fee = floor(amount/10000)·2000
```

and `fee ≥ burn` for every `amount ≥ 10 000` (verified numerically below), so **`reserve1` never collapses**. The NEM-class shape (collapse one reserve, drain the other) is **structurally unreachable** in this token.

### The one rounding hole (and why it is not exploitable)

`_calculateSellFees` computes each component as `amountDividedByBase * rate` with `amountDividedByBase = amount / 10000`. So for `amount < 10 000` wei the **entire** sell fee is `0`, while `_handleSellRecycle` still burns `amount/10` wei from the pair. That burn is unopposed (no fee ⇒ `_swapTokenForCake` early-returns on `totalAmount == 0`). But:
- max free burn = **999 wei** per call (`amount = 9999`);
- the sender's `amount` becomes pair *excess* that **cannot be recovered** — `skim()` is itself blocked (§6.3) — so the attacker loses 9999 wei to remove 999 wei (≈ **10 : 1 loss**);
- moving 2 % of `reserve1` this way needs ≈ **1.56 × 10¹⁹** calls.

### Enumerated value-moving selectors and their gates

Only these non-view functions exist (full ABI in `analysis/abi.json`, 68 functions):

| Function | Gate |
|---|---|
| `transfer` / `transferFrom` | none (but the sell hook is a side-effect of a transfer *to* the pair) |
| `approve` | none |
| `setBuyEnabled` / `setSellEnabled` | `onlyTradeController` (`owner`/`tradeController`) — live revert `"Not authorized"` |
| `setFeeWhiteList` / `batchSetFeeWhiteList` / `setSwapPairList` / `setSwapRouter` / `setMiner` / `setNode` / `setStrictCheck` / `setReleaseRate` / `setLPRewardCondition` / `setLPCondition` / `setTokenLPRewardCondition` / `setTokenLPCondition` / `setExcludeLPProvider` / `setNodeRewardCondition` / `setRewardGasLimit` / `renounceOwnership` / `transferOwnership` | `onlyOwner` |
| **burn-from-pair + `sync()`** | **no external function** — reachable *only* as the sell-hook side-effect above; gate = `sellEnabled ∧ ¬priceRose2Percent ∧ caller holds TOPS` |

Bytecode confirms exactly **one** `0xfff6cae9` (`sync()`) immediate and **no** `skim`/`getReserves`/`flushLpSellRecycle`/`burnFromPool`/`recycle`/`flush` immediate (`analysis/selector_scan.txt`).

---

## 4. Live-state assessment (block **129280478**, BSC) — plus HEAD 129586140

Full dumps: `analysis/livestate.json`, `analysis/livestate_reads.txt`, `analysis/livestate.py`, `ci-out/livestate_ci.json`.

| Item | Value |
|---|---|
| `token0` / `token1` | `0x55d3…7955` USDT / `0x842B…f588` TOPS |
| `getReserves()` | **96 379.620011969867575726 USDT** / **779 740.163185866451959983 TOPS** |
| `USDT.balanceOf(pair)` / `TOPS.balanceOf(pair)` | **exactly equal** to reserves → no excess, `skim()` returns 0 |
| `pair.totalSupply()` (LP) | 274 195.010174370908430336 |
| `TOPS.totalSupply()` | 210 000 000 |
| `name`/`symbol`/`decimals` | TOPS / TOPS / 18 |
| spot `router.getAmountsOut(1e18 TOPS)` | 0.123295621430803540 USDT |
| `owner()` = `tradeController()` | `0xf6370D9F937c59b00938CBFB8efa5b617D260D6d` (EIP-7702 delegated EOA → `0x63c0c19a…dae32b`) |
| **`blockConfig()`** | **`(buyEnabled = false, sellEnabled = true)`** |
| `priceTracker()` | `currentPrice = 118 773 020 285 185 430`, `historicalHigh = 123 295 621 430 803 540`, `lastDay = 20749`, `lastUpdateBlock = 129 222 188` |
| recycle threshold `trackedPrice·1.02` | 121 148 480 690 889 138 → **`currentPrice ≥ threshold` ⇒ gate CLOSED** |
| `feeConfig()` | buy 3000 (30 %); sell 300+300+400+200+800 = 2000 (20 %) |
| `feeWhiteList` | `pair = false`, `liquidityRemover = true`, `marketing = true`, `0x0 = true`, `0xdead = true`, `token = true` |
| `swapPairList[pair]` / `swapRouters[router]` | `true` / `true` |
| `liquidityProvider()` | `0x302E512867ce3Fa3599976AadA4dEA645F607F51` — **USDT balance 0 → buyback path dead** |
| `liquidityRemover()` | `0x4aC4Dcc85895c762dF28726f52484dDE83789CD1` (owner `0x39488c63…`, `paused = false`, **LP held = 0**) |
| `miner()` / `node()` | `0x55fdB962…` (342.28 USDT) / `0x0b36FFA5…` |
| USDT in fee sinks | lp 50.35 + silver 42.19 + gold 41.42 + diamond 11.62 + market 42.03 ≈ **187.6 USDT** |
| code | token 19 713 B, pair 14 981 B; **no EIP-1967 proxy slots** on the token |
| deployment | token & pair both first have code at block **128 614 640** (ts 1792440094, ~3.5 days before the analysis block) |
| verification | Etherscan V2 ✅ (`Token`, v0.8.28); Sourcify ❌ (`match: null`) |

**Changed at HEAD (block 129 586 140):**

| Item | 129 280 478 | HEAD 129 586 140 |
|---|---|---|
| `getReserves()` | 96 379.62 USDT / 779 740.16 TOPS | 95 862.06 USDT / 777 926.30 TOPS |
| `blockConfig()` | `(false, true)` | **`(true, true)`** — buys re-enabled |
| `priceTracker.currentPrice` (tracked) | 118 773 020 285 185 430 | 125 029 487 828 786 344 |
| `getPriceInfo().realTimePrice` (spot) | 123 295 621 430 803 540 | 122 919 462 309 859 790 |
| threshold `tracked·1.02` | 121 148 480 690 889 138 | 127 530 077 585 362 070 |
| `priceRose2Percent` (true ⇒ recycle skipped) | **true (gate CLOSED)** | **false (gate OPEN)** |
| LP `removeLiquidity` (largest LP `0x555EFdd0…`) | reverts (`not allow to remove`) | **succeeds** |

---

## 5. What an attacker can / cannot do

**At the 2026-10-23 block (129 280 478) — barriers that have since changed:**

**Cannot (at 129 280 478):**
1. **Buy TOPS.** `buyEnabled = false` ⇒ the buy branch in `_calculateAndApplyFees` reverts `"Buy is disabled"`. Router buy reverts `"Pancake: TRANSFER_FAILED"` (the pair's `_safeTransfer` masks the token reason); a direct `pair.swap(0, topsOut, attacker, "")` also reverts. Fork-proven (`test_02`, `test_02b`, `test_03`).
2. **Sell without already owning TOPS.** `transfer(pair, x)` from a zero-balance EOA reverts `"BNE"` (`test_04`).
3. **Recover pair excess via `skim()`.** `pair.skim(to)` sends TOPS out of the pair ⇒ same blocked outbound path ⇒ reverts (`test_07`: the attacker's balance goes to 0).
4. **Redeem LP.** `router.removeLiquidity` reverts `"not allow to remove"` (masked to `"Pancake: TRANSFER_FAILED"`), because the pair pays USDT first (`balanceOf(pair) < reserve0`) which flips `_isRemoveLiquidity() > 0` into the `removeLiquidity` branch, which then requires `feeWhiteList[recipient]` while `buyEnabled == false`. Fork-proven with the largest LP holder `0x555EFdd0…` (`test_10`).
5. **Trigger the burn now.** `currentPrice (0.1232956) ≥ trackedPrice·1.02 (0.1211485)` ⇒ `priceRose2Percent = true` ⇒ `_handleSellRecycle` returns early (`test_01`).

**At HEAD (129 586 140) — the state gates are open; only the structural one remains:**

6. **Can buy** (`test_R2`: 10 000 USDT → 51 322.95 TOPS, 30 % buy tax measured) and **can sell** (`test_R3b`).
7. **The recycle fires unprivileged** (`test_R3b`: 100 000 TOPS sell → 1 × `TokensRecycled`, burn **10 000 TOPS**) — **but `reserve1` rises by +90 000 TOPS** (Δreserve0 = −11 019.99 USDT). This is the decisive structural barrier: the burn removes `≤ sellAmount/10` while the 20 % sell fee is re-swapped **into the same pair**, so the pair's TOPS side **never collapses** and the NEM-class "drain the other reserve" shape is unreachable.
8. **Acquiring size closes the gate.** A 20 000 USDT buy moves spot >2 % above `trackedPrice`; the subsequent sell then emits **zero** `TokensRecycled` events (`test_R3`). To fire the recycle the attacker must already hold TOPS (or buy <~2 % of the pool), which caps the burn at a tiny fraction.
9. **Cannot profit.** A 20 000 USDT buy→sell round trip returns 10 335 USDT ⇒ **−9 781 USDT (−48.9 %)** (`test_R4`); token cost to drain `reserve1` ≈ **$95 910** vs max reward **$95 862** (`test_R6`).
10. **Cannot drain the pool via the recycle.** Best-case cost to burn `reserve1` is ≈ `reserve1` in sell fees (≈ **$95 910**) against a reward of `reserve0` (**$95 862**) ⇒ net negative before gas (`test_R6`).

**Can (but gains nothing):**
- If the attacker *already* holds TOPS (e.g. an existing holder), a sell is accepted (`sellEnabled = true`) and (at HEAD, gate open) the recycle fires (fork-proven, `test_R3b`: `TokensRecycled` emitted, `burn = 10 000 TOPS` for a 100 000 TOPS sell) — **but `reserve1` then *increases* by 90 000 TOPS** because `_swapTokenForCake` re-swaps the 20 000 TOPS fee back into the pair, and `reserve0` *falls* by 11 019.99 USDT. A `transfer→skim` loop destroys 100 % of the attacker's TOPS (`test_07`).

---

## 6. PoC / fork verification

Project: `poc/` (Foundry, vendored `lib/forge-std`). Two suites:
- `test/Tops.t.sol` — historical suite pinned at fork block **129280478** (11 tests).
- `test/TopsRecheck.t.sol` — **head-fork recheck** (7 tests) run 2026-10-24 after the state changed.

Run with `bash /home/heisenberg/CA/ci/ci-run.sh tops`.

**Historical suite: 11 / 11 tests PASS** (CI, GitHub Actions `artsbykriss/ca-zombie-ci`):

| Test | Proves | Gas |
|---|---|---|
| `test_01_live_state_and_gate_status` | live state; `buyEnabled=false`; recycle gate **CLOSED**; buyback unfunded | 284 617 |
| `test_02_buy_via_router_reverts` | router buy reverts (`Pancake: TRANSFER_FAILED`) | 232 185 |
| `test_02b_buy_gate_exact_reason` | raw reason **`Buy is disabled`** | 78 675 |
| `test_03_direct_pair_swap_buy_reverts` | direct `pair.swap` buy reverts | 192 482 |
| `test_04_sell_without_tokens_reverts` | `transfer(pair,·)` with 0 balance reverts **`BNE`** | 36 310 |
| `test_05_recycle_fires_when_gate_open` | mechanism is **unprivileged**; `TokensRecycled` fires; **`Δreserve1 = +10 000e18`** (no collapse), `Δreserve0 = −2 434.81e18` | 1 881 712 |
| `test_06_zero_fee_rounding_free_burn` | `amount<10 000` ⇒ 0 fee but burn = `amount/10`; max 999 wei/call; 2 % of `reserve1` needs 1.56e19 calls | 885 516 |
| `test_07_loop_economics_net_loss` | `transfer→skim` loop: attacker loses **100 %** of TOPS; `reserve1` **rises** | 1 397 409 |
| `test_08_drain_cost_exceeds_reserve` | cost $96 427 > reward $96 379 | 35 412 |
| `test_09_lp_removal_requires_lp_tokens` | no LP ⇒ no removal | 52 302 |
| `test_10_lp_exit_blocked_by_buy_gate` | real LP holder blocked with inner revert **`not allow to remove`** | 256 975 |

**Head-fork recheck suite: 7 / 7 tests PASS** (`TopsRecheck.t.sol`, local fork head 129586140):

| Test | Proves |
|---|---|
| `test_R1_live_state_head_gate_is_OPEN` | HEAD: `buyEnabled=true`, `sellEnabled=true`, price gate **OPEN** (`realTime 0.12292 < tracked·1.02 0.12753`), no excess |
| `test_R2_buy_now_succeeds` | entry OPEN: 10 000 USDT → 51 322.95 TOPS, buy tax **2999 bp (30 %)** |
| `test_R3_sell_recycle_no_reserve_collapse` | a 20 000 USDT buy pushes spot >2 % over tracked ⇒ subsequent sell emits **0** recycle events; `Δreserve1 = +134 007` |
| `test_R3b_recycle_fires_at_head` | gate OPEN ⇒ 100 000 TOPS sell fires `TokensRecycled` (burn **10 000 TOPS**), yet **`Δreserve1 = +90 000`** (no collapse) |
| `test_R4_roundtrip_pnl_negative` | 20 000 USDT buy→sell = **−9 781 USDT (−48.9 %)** |
| `test_R5_lp_exit_status_head` | LP `removeLiquidity` now **succeeds** (freeze lifted) |
| `test_R6_drain_cost_exceeds_reserve` | token cost to drain ≈ **$95 910** > reward **$95 862** |

Trace excerpts: `analysis/forge_trace_recycle.txt` (`-vvvv`), `analysis/forge_trace_lp_exit.txt` (`not allow to remove`), `analysis/forge_trace_buy_gate.txt`, full log `analysis/local_forge_test_vv.txt`.

**CI runs:**
- Run #1 (11/11 PASS): https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39956158843
- Run #2 (11/11 PASS, `archive RPC selected: yes`, corrected `ci/run.sh` state dump): https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39957212863
- Run #3 (2026-10-24 recheck, 11 historical + 7 recheck): CI_RUN_URL_TOPS_PLACEHOLDER

Artifacts: `ci-out/livestate_ci.json` (uploaded as `result-tops`), log `ci-log.txt`.

> Note: the CI secret `BSC_RPC_URL` was **empty**, so the fork uses the in-test keyed fallback (`ANKR_API_KEY` → `DRPC_API_KEY` → public). No keyed URL is stored in the repo.

---

## 7. Verdict, residual & latent risk

**Verdict: the NEM-class hypothesis is DISPROVEN for TOPS. External unprivileged extractable = $0.00 (high confidence).**

The gate on "burn-from-pair + `sync()`" is resolved definitively: it is **not** an owner/role/whitelist gate — it is the sell hook `_handleSellRecycle`, gated by `sellEnabled ∧ (currentPrice < trackedPrice·1.02)`. It is unprivileged-reachable (fork-proven at HEAD), but it is worthless for one **structural** reason (the two state barriers that also closed it on 2026-10-23 have since re-opened):

1. **Self-defeating (structural, load-bearing)**: the burn removes only `≤ sellAmount/10` from the pair, while the 20 % sell fee is re-swapped **into the same pair**, so `Δreserve1 ≥ 0` on every sell. Fork-proven at HEAD: a 100 000 TOPS sell burns 10 000 TOPS but `Δreserve1 = +90 000` — the pair's TOPS side **grows**, so the "collapse one reserve" NEM shape is unreachable.
2. **Size closes the gate** (at HEAD): a buy large enough to matter (>~2 % of the pool) raises spot above `trackedPrice·1.02`, so the sell that follows emits **zero** recycle events; only a pre-existing holder (or a <2 % buy) fires the recycle, capping the burn at a tiny fraction.
3. **Cost ≥ reward**: the fee/burn ratio (~2×) makes any drain cost ≥ the reward (≈ **$95 910** vs **$95 862**, `test_R6`), and a 20 000 USDT round trip loses **−$9 781** (`test_R4`).

**Cost accounting (why even the best case loses).** No flash loan is usable: the extraction token is TOPS itself and there is no profitable round-trip to lever. Best case (`amount = 19 999`, i.e. `fee = 2 000`, `burn = 1 999`) the token cost to remove `reserve1` is ≈ `reserve1` TOPS ≈ **$95 910** against a maximum USDT reward of `reserve0` = **$95 862** → **net ≈ −$48** before gas. Gas is negligible by comparison (the heaviest recycle test costs 2.18 M gas ≈ 2.2 × 10⁻⁴ BNB ≈ $0.13 at 0.1 gwei / BNB ≈ $600), so the sign is unchanged. The `amount < 10 000` rounding hole is worse: ~10 wei paid per 1 wei removed.

**Latent risk (low).** The primitive is live and unprivileged-reachable, and the owner can toggle `buyEnabled`/`sellEnabled` at will. It is still not monetisable at any size because fee ≥ 2×burn and the fee re-enters the pair. The 2026-10-23 "freeze" exposure (LP exits blocked while `buyEnabled=false`) is **gone** at HEAD: LP `removeLiquidity` now succeeds.

**Blockers / caveats recorded**
- The **decisive** barrier is structural (`_swapTokenForCake` re-swaps the fee into the pair), not owner-set. The state barriers (`buyEnabled=false`, closed price gate) observed on 2026-10-23 are **no longer present** at HEAD.
- The pair's `_safeTransfer` masks the token's revert reason; exact reasons were obtained via a `to == router` probe (`Buy is disabled`) and a `-vvvv` trace (`not allow to remove`).
- The `miner`/`node` reward contracts were stubbed in the fork tests (irrelevant to the recycle; they only pay out to their own registries) — see `_stubExternalRewardContracts`.
- LP holders were enumerated only partially (5 of the ~274k LP supply); the largest holder was used for the exit test.
- `eth_getLogs` / holder enumeration on BSC public RPCs was rate-limited; GoldRush credits were exhausted, so holder lists come from `balanceOf` probes.
- The recheck forks at **head** (keyless BSC RPCs prune deep historical state); the exact head block is logged by `test_R1` (local: 129 586 140). R2/R3/R3b/R4 self-skip if the owner re-closes the buy gate or the price gate, so the recheck is robust to further state changes.

---

## 8. Methodology & sources

- Verified source: Etherscan V2 `module=contract&action=getsourcecode&chainid=56` → standard-json input (9 sources), reconstructed in `analysis/src/`.
- Bytecode: `eth_getCode` at block 129280478 → `analysis/tops.bc`, `analysis/pair.bc`; PUSH4 selector scan (`analysis/selector_scan.txt`); decompilers `heimdall` / `panoramix` for the adjacent `liquidityRemover` / `miner` / `node` contracts.
- Live state: keyless `cast call` / JSON-RPC `eth_call` at the pinned block over public/keyed BSC archive endpoints (URLs redacted in all artifacts).
- Dynamic proof: Foundry fork tests (`poc/`), CI on GitHub Actions. **No transaction was signed or broadcast**; all interaction was `eth_call` / `eth_getCode` / `eth_getLogs` and fork simulation.

### Files index

```
tops/
├── README.md                     (this file)
├── summary.json                  machine-readable summary (ZH4P5-TOPS)
├── analysis/
│   ├── livestate.json            raw live-state JSON
│   ├── livestate_reads.txt       human-readable live-state dump
│   ├── livestate.py              read-only state reader
│   ├── selector_scan.txt         PUSH4 selector scan of runtime bytecode
│   ├── abi.json                  verified ABI (68 functions)
│   ├── etherscan_source.json     Etherscan V2 getsourcecode response
│   ├── raw_sourcecode.txt        standard-json input
│   ├── src/contracts__v2__token.sol  verified Token source (962 lines)
│   ├── tops.bc / pair.bc / liquidityRemover.bc / miner.bc / node.bc
│   ├── local_forge_test_vv.txt   full local `forge test -vv`
│   └── forge_trace_recycle.txt / forge_trace_lp_exit.txt / forge_trace_buy_gate.txt
├── poc/                          Foundry project (11 tests, pinned fork block)
├── ci/run.sh                     CI state-dump job
├── ci-out/livestate_ci.json      CI artifact (state snapshot)
├── ci-log.txt                    CI log (run #2)
└── ci-artifacts/                 downloaded CI artifacts
```
