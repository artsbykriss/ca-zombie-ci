# TOPS (BSC) — NEM-class "burn-from-pair + `sync()`" gate resolution

**Date:** 2026-10-23 · **Chain:** BSC (56) · **Target:** TOPS token `0x842B1BFa825Cf6673fD2D98E573FdD267C3Fd588`
**Pair:** PancakeV2 TOPS/USDT `0xbeDebAC3788171DC769893242a53b881041EDf29`
**Status:** read-only; PoC fork-verified only; **no mainnet transaction was signed or sent**. Finding id **ZH4P5-TOPS** (row #10 of `zombie-hunt-iv/pass4/skim-burn.md`).

---

## 1. TL;DR

| # | Target | Live E-U extractable | Why closed | Latent risk |
|---|--------|----------------------|------------|-------------|
| 1 | TOPS token `0x842B…f588` / pair `0xbeDe…df29` ($96,379.62 USDT + 779,740.16 TOPS ≈ **$192,759 TVL**) | **$0.00** | (a) the burn-from-pair + `sync()` path is **not** a privilege gate but a *price-state* gate that is **CLOSED live**; (b) the only entry to trigger it is a **sell**, and `buyEnabled == false` blocks every pair-outbound TOPS transfer (router buy, direct `pair.swap`, **and `skim()`**); (c) even with the gate open the burn is **self-defeating** — `_swapTokenForCake()` re-swaps the sell fee into the same pair, so `reserve1` *increases*; (d) the only unopposed burn (the `amount < 10 000` rounding hole) is capped at 999 wei/call and is a net loss because the sender's deposit is trapped | Low. If the owner sets `buyEnabled = true` the pair re-opens for trading; the recycle still cannot be made profitable (cost ≈ reward, see §7) |

---

## 2. Total live extractable now

**$0.00 — confidence HIGH** (external unprivileged, E-U).

- **E-U (external unprivileged): $0.00**
- **E-U-conditional** (if the owner re-enables buys): **$0.00** — the recycle is structurally unprofitable regardless of the gate.
- **H-O (holder self-service): $0.00** — LP redemption is *blocked* live (see §5, item 4); a TOPS holder can only sell at market (normal trading, not recovery of trapped value).
- **P (privileged): $0.00 directly** — owner/`tradeController` `0xf6370D9F…` can flip `buyEnabled`, which re-opens buys and LP exits, but cannot unilaterally seize the pair's USDT.
- **S (permanently stuck): $0.00** — nothing is bricked; the owner can unfreeze.

The ~$192.8k in the pair is **frozen for every non-privileged party at this block** (LP holders included) but is *owner-reversible*, hence not a permanent `S`.

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

## 4. Live-state assessment (block **129280478**, BSC)

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

---

## 5. What an attacker can / cannot do

**Cannot:**
1. **Buy TOPS.** `buyEnabled = false` ⇒ the buy branch in `_calculateAndApplyFees` reverts `"Buy is disabled"`. Router buy reverts `"Pancake: TRANSFER_FAILED"` (the pair's `_safeTransfer` masks the token reason); a direct `pair.swap(0, topsOut, attacker, "")` also reverts. Fork-proven (`test_02`, `test_02b`, `test_03`).
2. **Sell without already owning TOPS.** `transfer(pair, x)` from a zero-balance EOA reverts `"BNE"` (`test_04`).
3. **Recover pair excess via `skim()`.** `pair.skim(to)` sends TOPS out of the pair ⇒ same blocked outbound path ⇒ reverts (`test_07`: the attacker's balance goes to 0).
4. **Redeem LP.** `router.removeLiquidity` reverts `"not allow to remove"` (masked to `"Pancake: TRANSFER_FAILED"`), because the pair pays USDT first (`balanceOf(pair) < reserve0`) which flips `_isRemoveLiquidity() > 0` into the `removeLiquidity` branch, which then requires `feeWhiteList[recipient]` while `buyEnabled == false`. Fork-proven with the largest LP holder `0x555EFdd0…` (`test_10`).
5. **Trigger the burn now.** `currentPrice (0.1232956) ≥ trackedPrice·1.02 (0.1211485)` ⇒ `priceRose2Percent = true` ⇒ `_handleSellRecycle` returns early (`test_01`).
6. **Drain the pool via the recycle.** Best-case cost to burn `reserve1` is ≈ `reserve1` in sell fees (≈ **$96 427**) against a reward of `reserve0` (**$96 379**) ⇒ net negative before gas (`test_08`).

**Can (but gains nothing):**
- If the attacker *already* holds TOPS (e.g. an existing holder), a sell is accepted (`sellEnabled = true`). Once the day rolls over, `trackedPrice` resets to spot and the recycle **does** fire (fork-proven, `test_05`: `TokensRecycled` emitted, `burn = 10 000 TOPS` for a 100 000 TOPS sell) — **but `reserve1` then *increases* by 10 000 TOPS** because `_swapTokenForCake` re-swaps the 20 000 TOPS fee back into the pair, and `reserve0` *falls* by 2 434.81 USDT (fee USDT leaves the pool to `mainDistributor`). A 3-iteration `transfer→skim` loop destroys 100 % of the attacker's TOPS (`test_07`).

---

## 6. PoC / fork verification

Project: `poc/` (Foundry, vendored `lib/forge-std`, pinned fork block **129280478**). Run with `bash /home/heisenberg/CA/ci/ci-run.sh tops`.

**11 / 11 tests PASS** (CI, GitHub Actions `artsbykriss/ca-zombie-ci`):

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

Trace excerpts: `analysis/forge_trace_recycle.txt` (`-vvvv`), `analysis/forge_trace_lp_exit.txt` (`not allow to remove`), `analysis/forge_trace_buy_gate.txt`, full log `analysis/local_forge_test_vv.txt`.

**CI runs:**
- Run #1 (11/11 PASS): https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39956158843
- Run #2 (11/11 PASS, `archive RPC selected: yes`, corrected `ci/run.sh` state dump): https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39957212863

Artifacts: `ci-out/livestate_ci.json` (uploaded as `result-tops`), log `ci-log.txt`.

> Note: the CI secret `BSC_RPC_URL` was **empty**, so the fork uses the in-test keyed fallback (`ANKR_API_KEY` → `DRPC_API_KEY` → public). No keyed URL is stored in the repo.

---

## 7. Verdict, residual & latent risk

**Verdict: the NEM-class hypothesis is DISPROVEN for TOPS. External unprivileged extractable = $0.00 (high confidence).**

The gate on "burn-from-pair + `sync()`" is resolved definitively: it is **not** an owner/role/whitelist gate — it is the sell hook `_handleSellRecycle`, gated by `sellEnabled ∧ (currentPrice < trackedPrice·1.02)`. It is unprivileged-reachable in principle (fork-proven), but three independent barriers make it worthless:

1. **Closed live**: the price gate is shut at block 129280478 (`priceRose2Percent = true`).
2. **No entry**: `buyEnabled = false` blocks *every* pair-outbound TOPS transfer (router buy, direct `pair.swap`, `skim`, and LP `burn`) ⇒ no outsider can acquire TOPS.
3. **Self-defeating**: the fee re-swap makes `Δreserve1 ≥ 0`, and the fee/burn ratio (~1–2×) makes any drain cost ≥ the reward.

**Cost accounting (why even the best case loses).** No flash loan is usable: the extraction token is TOPS itself and there is no profitable round-trip to lever. Best case (`amount = 19 999`, i.e. `fee = 2 000`, `burn = 1 999`) the token cost to remove `reserve1` is ≈ `reserve1` TOPS ≈ **$96 427** against a maximum USDT reward of `reserve0` = **$96 379** → **net ≈ −$48** before gas. Gas is negligible by comparison (the heaviest recycle test costs 1.88 M gas ≈ 1.9 × 10⁻⁴ BNB ≈ $0.11 at 0.1 gwei / BNB ≈ $600), so the sign is unchanged. The `amount < 10 000` rounding hole is worse: ~10 wei paid per 1 wei removed.

**Latent risk (low).** The owner can re-enable buys. Even then the recycle is unprofitable and the token is a plain 30 %/20 %-fee token with a dead buyback. The only genuine exposure is a **freeze**: while `buyEnabled = false`, LP holders cannot exit (fork-proven) — an owner-controlled `H-O` lock, not a bug an outsider can monetise.

**Blockers / caveats recorded**
- `buyEnabled = false` is the decisive blocker (owner-set, `onlyTradeController`).
- The pair's `_safeTransfer` masks the token's revert reason; exact reasons were obtained via a `to == router` probe (`Buy is disabled`) and a `-vvvv` trace (`not allow to remove`).
- The `miner`/`node` reward contracts were stubbed in the fork tests (irrelevant to the recycle; they only pay out to their own registries) — see `_stubExternalRewardContracts`.
- LP holders were enumerated only partially (5 of the ~274k LP supply); the largest holder was used for the exit test.
- `eth_getLogs` / holder enumeration on BSC public RPCs was rate-limited; GoldRush credits were exhausted, so holder lists come from `balanceOf` probes.

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
