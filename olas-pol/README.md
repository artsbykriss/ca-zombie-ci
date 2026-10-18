# ZH4-04 — Olas POL `LiquidityManagerCore` (ETH / Base / OP)

**Date:** 2026-10-18 · **Chains:** Ethereum, Base, Optimism · **Status:** read-only; fork-verified only; **no mainnet transactions**.
**Target class:** live, unfixed published-recipe deployment with **$0 today** → **re-arm monitor**.
**Headline:** external unprivileged attacker can extract **$0.00** right now (high confidence). One funding event plus the owner's first `convertToV3` re-arms a same-block, flash-loanable drain of the newly funded POL position; the deployed bytecode is the **2026-05-12** build (`d1d682e5`), and the **2026-07-03 / 07-14 / 08-14** fail-closed fixes are not in it.

---

## 1. TL;DR

| Target (proxy → impl) | Live value | Unprivileged extraction today | Why closed / open | Latent risk |
|---|---|---|---|---|
| ETH `0x83Adc54B2828E99a6DA3A11263C75E38E0A1a215` → `0x0171D7178fbf3B48E75675DEE2EA3EfecEf775C1` | 0 ETH, 0 OLAS, 0 UniV3 NFTs; no transfers ever; nonce 1 | **$0** | empty + all value-moving functions `onlyOwner`; owner is EOA `0xeb2a22…914e` | first `convertToV3` on a `cardinalityNext==1` pool is same-block sandwichable; later ops on a >30-min-quiet pool use stale slot0 |
| Base `0x2ACD313B892C9922E470e4950e907d5EAa70fC2a` → `0x1D64516E7654F23dB7cE2ddaD00FFb3E765cf5ce` | 0 ETH, 0 OLAS, 0 NFTs; no transfers ever; nonce 1 | **$0** | same, same owner EOA | same core code (OP verified source = deployed commit `d1d682e5`) |
| OP `0x1f84F8F70dE0651C2d51Bf8850FE9D0289Ba3B3A` → `0xCf9B4710fe450Dca52374f28e4917FDCd44F9487` | 0 ETH, 0 OLAS, 0 NFTs; no token/NFT transfers, only creation tx; nonce 1 | **$0** | same | same |
| ETH `BuyBackBurner 0xfAd04813BffD759a308A2BEaAcEf587720ba743F` | 0 ETH/OLAS/WETH/USDC; no V3 pool, no V2 oracle, no slippage | **$0** | `buyBack()` is permissionless but there is nothing to swap and no pool configured | real second-token inflow + `setV3Pools` + `setMaxSlippages` makes `buyBack()` a self-triggered manipulation path |
| Base `0x3FD8C757dE190bcc82cF69Df3Cd9Ab15bCec1426` | 1,575 wei WETH dust (1.575e-15 WETH); no config | **$0** | dust only | same |
| OP `0x4891f5894634DcD6d11644fe8E56756EF2681582` | 8,888 `www.base1.cfd` spam tokens; no config | **$0** | spam only | same |

**Total live extractable now: $0.00 (E-U, high confidence).**
**Latent re-arm:** first LM deposit + first `convertToV3` on a `cardinalityNext==1` pool → same-block sandwich; demonstrated **+1.699 USDC attacker profit on a 5 USDC manipulation**, and **$1,036.38 mark-to-fair LM loss on a $5,183.80 first deposit (20.0%)**. The loss scales with the first deposit; the attacker's immediate sandwich profit is bounded by the attacker's capital, while the LM's mark-to-fair loss is the ceiling an arbitrageur can capture.

---

## 2. The bug, exactly

`LiquidityManagerCore.checkPoolAndGetCenterPrice(address)` is the only price guard for all five V3 POL operations (`convertToV3`, `changeRanges`, `increaseLiquidity`, `decreaseLiquidity`, `collectFees`). The deployed source (Etherscan-verified; the source file is byte-identical by git blob SHA-1 to GitHub commit `d1d682e5`) implements:

1. read `slot0()` → `sqrtPriceX96`, `observationIndex`;
2. read `observations(observationIndex).blockTimestamp` — **the latest observation**, despite the misleading variable name `oldestTimestamp`;
3. **if `latestObsTimestamp + 1800 < block.timestamp` → `return centerSqrtPriceX96;`** — raw slot0, no TWAP, no deviation check (inactive/stale pool);
4. otherwise call `getTwapFromOracle`; **if it fails and `observationCardinality <= 1` → return raw slot0** (fresh pool fail-open); if cardinality ≥ 2 → revert `ObservationFailed`;
5. on success, compare instant slot0 price vs TWAP; revert if deviation > `MAX_ALLOWED_DEVIATION` (**10%** in this build); return the TWAP sqrt.

Live parameters: `maxSlippage = 1000` (10%), `MAX_ALLOWED_DEVIATION = 1e17` (10%), `SECONDS_AGO = 1800`. Note the repo deployment globals record `liquidityManagerMaxSlippage: 500` (5%), but the proxy constructor args call `initialize(1000)`; the live deployment is **looser than the recorded config** (10% amount-space slippage + 10% price deviation). The fixed build tightens the deviation to 2% (`02b3aa9a`).

The two fail-open returns are the live issue. They are exactly what commit `ec4a90ce` (2026-07-03) removes:

```solidity
// deployed d1d682e5
(uint32 oldestTimestamp,,,) = IUniswapV3(pool).observations(observationIndex);
if (oldestTimestamp + SECONDS_AGO < block.timestamp) {
    return centerSqrtPriceX96;                    // <-- raw slot0
}
...
if (!success || returnData.length == 0) {
    if (_getObservationCardinality(pool) <= 1) {
        return centerSqrtPriceX96;                // <-- raw slot0 (fresh pool)
    }
    revert ObservationFailed(pool);
}

// fixed ec4a90ce
(uint32 latestObsTimestamp,,,) = IUniswapV3(pool).observations(observationIndex);
if (latestObsTimestamp + SECONDS_AGO < block.timestamp) {
    revert NotEnoughHistory(pool);                // <-- fail closed
}
...
if (!success || returnData.length == 0) {
    revert NotEnoughHistory(pool);                // <-- fail closed
}
```

**Important correction to the wave-1 shorthand.** The deployed build is **not** the audited pre-fix code:
- the H-02 *variable overwrite* (“deviation check compares TWAP with itself”) is **already fixed** in the deployed build (`twapSqrtPriceX96` is separate; commit `c8ca1d80`, 2026-04-13);
- the H-02 *Path 2* `observe()` failure was made fail-closed by `b1542dae` (2026-04-21), but the deployed commit `d1d682e5` (2026-05-12) **re-added the `cardinality <= 1` exception** (“fresh pools fall back to slot0 — the same tolerance the original code had”);
- the *stale/inactive pool* fail-open (H-08 Path 1) was never fixed until `ec4a90ce`.

So the live gap is: **fresh-pool fail-open (`cardinalityNext == 1`) + inactive-pool fail-open**, not the dead-code deviation check. The latter is fixed live; the deployed guard does reject >10% deviations on pools with real history. The fixed build also tightens `MAX_ALLOWED_DEVIATION` to 2% (`02b3aa9a`) and adds the V2→V3 removed-ratio cross-check (`ef24d24b`), neither of which is deployed.

### Source/build identification (exact)

| Item | Value |
|---|---|
| Deployed `LiquidityManagerCore.sol` bytes | 46,669 |
| Git blob SHA-1 of deployed core | `dd559b988fe1d13107432b20daa2f53bd87b3867` |
| Matching GitHub commit | **`d1d682e57085` — 2026-05-12**, `deploy(pol): re-anchor cardinality to mid-volume V3 precedent; clarify deviation/slippage co-existence` |
| ETH impl / proxy creation | block 25,121,756 / 25,121,761 (2026-05-18) |
| Base impl / proxy creation | block 46,157,584 / 46,157,692 (2026-05-18) |
| OP impl / proxy creation | block 151,753,124 / 151,753,148 (2026-05-18) |
| OP verified source core blob | `dd559b98…` — same deployed commit |
| Base impl runtime | 21,215 bytes, same selector fingerprint as OP (source is not on Sourcify; bytecode length/fingerprint match) |

Runtime selector fingerprint (all three impls): `ObservationFailed(address)` **present**; `NotEnoughHistory()`, `_getPoolPriceFacts(address)`, `RatioDeviation(uint256,uint256)` **absent**; `MAX_ALLOWED_DEVIATION()` present (returns `1e17`); `SECONDS_AGO()` present (1800). This independently confirms the verified source is the code that is actually executing.

### Fix commits absent from the deployed build

| Commit | Date | What it changes |
|---|---|---|
| `ec4a90ce36e8` | 2026-07-03 | fail-closed guard: `NotEnoughHistory` on **both** inactive pool and cardinality≤1/observe failure; removes `_getObservationCardinality`; soft-priced `decreaseLiquidity` exit floor; scoped `collectFees` burn; `increaseLiquidity` anchored to TWAP |
| `c79186a2` | 2026-07-03 | exit `amountMin` derived from gated slot0, not TWAP |
| `f562a454` | 2026-07-14 | always-on exit gate; extracts `_getPoolPriceFacts`; de-dups amount helpers |
| `ef24d24bd4bb` | 2026-08-14 | replaces source-side TWAP oracle with V2-removed-ratio vs V3-slot0 cross-check (`_checkRemovedRatioAgainstV3` / `RatioDeviation`) |
| `02b3aa9a` | 2026-08-14 | `MAX_ALLOWED_DEVIATION` 10% → 2% |

C4 report: <https://code4rena.com/reports/2026-01-olas> (published **2026-05-18**), H-02 (“Variable Overwrite … Dead-Code Deviation Check”) and H-08 (“Critical Logic Inversion in Price Guard …”). H-01 in the same report is the separate Uniswap **V2** oracle `validatePrice()` issue, not this V3 guard.

---

## 3. Who can move value? (the unprivileged-path test)

Every value-moving entry point is `onlyOwner` in the deployed core:

| Function | Guard |
|---|---|
| `convertToV3`, `changeRanges`, `increaseLiquidity`, `decreaseLiquidity`, `collectFees` | `if (msg.sender != owner) revert OwnerOnly(...)` |
| `transferPositionId`, `transferToken`, `changeOwner`, `changeImplementation`, `changeMaxSlippage` | `onlyOwner` |
| `initialize(uint16)` | one-time (`owner != 0` → `AlreadyInitialized`) |
| `checkPoolAndGetCenterPrice`, `getTwapFromOracle` | `view` |
| `onERC721Received` | returns selector, no state |

Owner on all three LM proxies: **`0xeb2a22b27c7ad5eee424fd90b376c745e60f914e`**, an **EOA** (`eth_getCode` length 0; nonce 1312; 99 OLAS; 0.2336 ETH). This is the deployer, not the Olas timelock (`0x3C1fF68f…95fE`, which owns the ETH `BuyBackBurner`).

Therefore an external attacker cannot call the LM to move its funds. The exploit is an **MEV sandwich / front-run of the owner's transaction**, not a standalone drain:

- **Fast path (same block, flash-loanable):** the owner's **first** `convertToV3` on a pool whose `observationCardinalityNext == 1`. The attacker swaps the pool before the owner's tx. The swap writes the single observation slot but leaves cardinality at 1; the guard's `observe()` fails and the `cardinality <= 1` fallback returns the manipulated slot0. The LM mints its entire first position centred on the attacker's price. The attacker unwinds in the same block. This is exactly the H-08 “new pool / fail-open” path, and it is the **one-shot critical window**.
- **Slow path (stale price):** after the first mint the LM raises `observationCardinalityNext` to 120/300; the next swap grows cardinality and the same-block path reverts (`ObservationFailed` / deviation). However, if the pool has **no swap for >30 min**, the guard returns raw slot0 again. An attacker can pre-manipulate, wait out the 30-min window, and let the owner's next op use the stale manipulated price. This path is not a same-block flash loan and requires the manipulated price to persist; it is still live and is what `ec4a90ce` closes.
- **BuyBackBurner (permissionless):** `buyBack(address,uint256,uint256)` has **no owner check** and swaps the *contract's* second-token balance using the LM guard. If a burner is funded with a real second token and has `mapV3Pools[token] != 0` and `mapTokenMaxSlippages[token] > 0` (or a V2 oracle configured), an attacker can call `buyBack` themselves inside the manipulation transaction. Today all three burners have zero config and only dust/spam.

---

## 4. Live-state assessment ($0 proof)

All reads at explicit blocks: **ETH 26,215,810**, **Base 52,746,673**, **OP 158,341,970**. Raw values: `analysis/live_state.json`.

### 4.1 LM proxies (all three)

The current Olas deployment record (`scripts/deployment/pol/globals_*_mainnet.json`) lists exactly three LM proxies: Ethereum, Base and Optimism. Celo, Gnosis, Polygon and Arbitrum have empty `liquidityManagerProxyAddress` / `liquidityManagerAddress` entries and are out of scope here.

| Check | ETH | Base | OP |
|---|---|---|---|
| `PROXY_LIQUIDITY_MANAGER` slot | `0x0171d717…75c1` | `0x1d64516e…f5ce` | `0xcf9b4710…9487` |
| EIP-1967 impl slot | `0x0` | `0x0` | `0x0` |
| proxy code | 202 bytes, keccak `2a2ec7f1…979a` | same | same |
| impl code | 21,044 bytes, keccak `8bb01917…717e` | 21,215 bytes, keccak `05894301…d5b4` | 21,215 bytes, keccak `18cf37c4…a58d` |
| native balance | 0 | 0 | 0 |
| OLAS balance | 0 | 0 | 0 |
| `positionManager.balanceOf(proxy)` | 0 | 0 | 0 |
| `owner()` | `0xeb2a22…914e` (EOA) | same | same |
| `maxSlippage()` | 1000 (10%) | 1000 | 1000 |
| `observationCardinality()` | 120 | 300 | 300 |
| `nonce` | 1 (creation only) | 1 | 1 |
| OLAS allowance to NPM | 0 | 0 | 0 |
| `mapPoolAddressPositionIds(OLAS/USDC 0.3%)` | 0 | — | 0 |
| `mapPoolAddressPositionIds(OLAS/WETH 1%)` | 0 | — | — |

Transfer history (never funded):
- **ETH:** Etherscan V2 `txlist` = 1 tx (creation `0xa1f4dd9b…`, block 25,121,761); `tokentx` = 0; Alchemy `getAssetTransfers` `to`/`from` = empty for external/internal/erc20/erc721/erc1155; Blockscout token-transfers = 0, NFT = 0.
- **Base:** Alchemy `getAssetTransfers` `to`/`from` = empty for all five categories; nonce 1.
- **OP:** Alchemy `to`/`from` = empty for external/erc20/erc721/erc1155 (internal category unsupported on OP); Blockscout `transactions` = 1 (creation `0x7b28e735…`), token-transfers = 0, NFT = 0; nonce 1.

There is **no pause function** in `LiquidityManagerCore`; the only admin controls are `changeOwner`, `changeImplementation`, `changeMaxSlippage`, `transferToken`, `transferPositionId`. No `Paused`/`pause` selector in the impl.

### 4.2 The guard is fail-open on the live pool right now

Live `eth_call` to the deployed proxy at ETH block 26,215,810:

| Pool | `slot0` sqrt / tick | cardinality / next | `checkPoolAndGetCenterPrice` | Result |
|---|---|---|---|---|
| OLAS/USDC 0.3% `0x795a8C98…4Dfc` | 18,355,655,791,563,235,596,007 / −305,574 | **1 / 1** | 18,355,655,791,563,235,596,007 | **equals slot0** (fail-open) |
| OLAS/WETH 1% `0x18f7b331…f391` | 4,295,128,740 / −887,272 (dead pool, `liquidity=0`) | 41 / 41 (last obs age ≈22 days) | 4,295,128,740 | **equals slot0** (stale fail-open) |

The OLAS/USDC pool is the one that matters: it has live liquidity (`liquidity = 61,805,534,932,668`), **`observationCardinality = observationCardinalityNext = 1`**, and its latest observation is ~6.2 days old. This is precisely the state in which the deployed guard returns manipulated slot0.

### 4.3 BuyBackBurners

| Chain | Proxy | Impl | Native / OLAS / WETH / USDC | `owner` | `liquidityManager` | V3 pool / V2 oracle / maxSlip (WETH, USDC) |
|---|---|---|---|---|---|---|
| ETH | `0xfAd04813…743F` | `0xcf051267…e6e5` | 0 / 0 / 0 / 0 | timelock `0x3C1fF68f…95fE` | ETH LM proxy | all 0 / 0 / 0 |
| Base | `0x3FD8C757…1426` | `0x7db6bb33…1e58` | 0 / 0 / 1,575 wei / 0 | bridge mediator `0xE49C…C8EA` | Base LM proxy | all 0 / 0 / 0 |
| OP | `0x4891f589…1582` | `0x7f69b678…40db` | 0 / 0 / 0 / 0 (+8,888 spam tokens) | bridge mediator `0x87c5…C60c` | OP LM proxy | all 0 / 0 / 0 |

The ETH burner has had **3 transactions ever**: creation (2026-02-06), `changeImplementation` (2026-05-18), `changeOwner` (2026-05-19). No `setV3Pools` / `setV2Oracles` / `setMaxSlippages` ever. The Base/OP burners have the same 3-tx pattern. `V3PoolsUpdated`, `OraclesUpdated`, `MaxSlippagesUpdated` have never been emitted. The V3 path is disabled by zero config; the V2 path has no oracle. Only dust/spam has ever arrived.

---

## 5. PoC / fork verification

Project: `poc/` (Foundry, vendored `forge-std`). Tests interact with the **live deployed proxy** and the **live OLAS/USDC 0.3% pool** on an Ethereum fork. No mainnet transactions.

```
poc/test/OlasPolH08.t.sol
  [PASS] test_H08_firstConvert_sandwich_on_live_uniswap_pool()   gas 4,680,209
  [PASS] test_guard_failclosed_after_cardinality_grown()         gas 3,012,926
Suite result: 2 passed, 0 failed
```

Run: `cd poc && forge test --match-test "test_H08|test_guard" -vv` (uses `FORK_RPC_URL`, public fallback). Local log: `analysis/poc_local_run.log`.

**CI (public GitHub Actions):** final run [`39082702325`](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39082702325) (also [`39082539663`](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39082539663)) — both the `custom CI script` and `foundry tests` jobs: **2 passed / 0 failed**; artifact `result-olas-pol` contains `ci-out/poc.log` (also copied to `ci-out/poc.log`). Fork RPC in CI: `https://ethereum-rpc.publicnode.com`.

### Test 1 — first-convert sandwich (the one-shot critical window)

Fork block 26,215,792 (local; CI repeats at 26,215,836 with identical numbers). Synthetic first funding: 50,000 OLAS + 2,500 USDC to the ETH LM proxy (the real first deposit size is unknown; this is a scale model). Attacker: 5 USDC.

1. Fair pool: sqrt `18,355,655,791,563,235,596,007`, tick −305,574, cardinality 1/1.
2. Attacker buys OLAS with **5 USDC**; gets **68.889207985863831884 OLAS**. Manipulated sqrt `24,745,898,842,834,866,333,157`, tick **−299,599**, deviation **8,174 bps vs fair**. Cardinality after the swap is still **1** (cardinalityNext was 1).
3. `checkPoolAndGetCenterPrice(pool)` returns **`24,745,898,842,834,866,333,157`** — exactly the manipulated slot0, no revert.
4. Owner (`vm.prank(0xeb2a22…)`) calls `convertToV3([OLAS,USDC], 0, 3000, [-1200,1200], 0, false)`. It succeeds: position `1385706`, liquidity `133,007,100,228,679,892`, amounts used **25,171.462 OLAS + 2,500 USDC**, range `[-300,840, -298,380]`, range center **−299,610** — centred on the manipulated tick, **5,964 ticks above fair**. The LM then raises `observationCardinalityNext` to 120.
5. Attacker sells the 68.889 OLAS back into the LM’s new position: receives **6.699210 USDC** → **+1.699210 USDC** on 5 USDC (≈34%), before gas. The final price is still near the manipulated level (`−299,602`); the attacker has sold the LM its own high-priced exit liquidity.
6. Mark-to-fair: at the fair sqrt, the whole position is below its range and holds **52,439.089 OLAS + 0 USDC**; the LM also has **24,828.538 OLAS** leftover. Total at fair = **$4,147.42**; deposit at fair = **$5,183.80**; **LM mark-to-fair loss = $1,036.38 (20.0%)**.

Interpretation: the attacker’s *immediate* 5-USDC sandwich profit is small because the attacker only sold 68.9 OLAS; the **$1,036** mark-to-fair loss is the value that a better-capitalized arbitrageur can capture by selling into the mispriced position. The loss scales with the first deposit; the demonstrated configuration is ~20% of the deposit.

### Test 2 — the window closes after the first mint raises cardinality

Fork block 26,215,787. On the same live pool:
- `increaseObservationCardinalityNext(120)` → cardinality 1, next 120;
- one 1 USDC swap → cardinality **120**, next 120;
- `checkPoolAndGetCenterPrice(pool)` **reverts** (`vm.expectRevert()` passes).

This confirms the deployed partial fix: after the LM’s first mint raises `cardinalityNext` and the next swap grows cardinality, the same-block path is fail-closed. The exploitable same-block window is the **first** op on a pool whose `cardinalityNext` is still 1. The stale path (`latest observation + 1800 < now`) remains for later ops.

---

## 6. Re-arm conditions (what converts $0 to CRITICAL)

### A. LM proxies — the one-tx trigger

**Critical window:** first funding + first `convertToV3` on a pool with `observationCardinalityNext == 1`.

- **Funding precondition:** OLAS + the quote token transferred to any LM proxy. Anyone can do this; it is not itself exploitable (the LM has no permissionless spend).
- **Trigger:** the owner EOA `0xeb2a22…914e` (or a future keeper/timelock) submits the **first** `convertToV3`/`increaseLiquidity` on a `cardinalityNext == 1` pool. The attacker front-runs it in the same block, moves the pool, and the guard returns the manipulated price. The LM mints its first position at the attacker’s price. The attacker unwinds.
- **Size:** demonstrated ~20% mark-to-fair loss on a $5.18k first deposit. Approximate ceiling = 10–25% of the first deposit, depending on range width, manipulation size, and pool depth. A $100k first deposit ⇒ ~$10k–$25k at risk; $1M ⇒ ~$100k–$250k.
- **Monitor:** proxy `Transfer` inflows (OLAS + quote), `ConvertedToV3` / `PositionMinted` / `TicksSet` events, `mapPoolAddressPositionIds(pool) != 0`, `increaseObservationCardinalityNext` calls on OLAS pools, and the owner EOA’s mempool transactions.
- **Read the exact window:** `slot0(pool).observationCardinalityNext == 1` and `mapPoolAddressPositionIds(pool) == 0`. If both are true and the proxy is funded, the next owner convert is the critical tx.
- **Closure:** `changeImplementation` to an impl whose runtime contains `NotEnoughHistory()` / `_getPoolPriceFacts` / `RatioDeviation` and no `ObservationFailed`; or a new deployment with `MAX_ALLOWED_DEVIATION = 2e16`. Watch the custom slot `0xf7d1f641…12cd` and `ImplementationUpdated`.

### B. Later LM ops — the stale-price path and the 10% tolerance

If the pool has had **no swap for >30 min**, `observations(observationIndex).blockTimestamp + 1800 < block.timestamp` and the guard returns raw slot0. An attacker can pre-manipulate the pool, wait 30+ min (no swaps), and let the owner’s `changeRanges` / `increaseLiquidity` / `decreaseLiquidity` / `collectFees` use the stale manipulated price. This is slower and requires price persistence, but it works on any pool with real history (the fixed build closes it with `NotEnoughHistory`). Monitor owner txs and 30-min pool quiet periods.

Separately, even on an active pool with real history, the deployed tolerance is **10% price deviation + 10% amount slippage**. A same-block move below 10% passes the deviation check and can still shift the LM’s mint/rebalance by up to ~10% of the affected amount; the Aug-14 `02b3aa9a` fix reduces the deviation to 2%. This is a smaller, bounded residual than the cardinality-1 fail-open, but it is live on any funded position and does not require a stale pool.

### C. BuyBackBurner — permissionless self-trigger

`buyBack()` has no owner check. If a burner has:
1. a real second-token balance (ETH/WETH/USDC/etc.), **and**
2. `mapV3Pools[token] != 0` (a canonical pool), **and**
3. `mapTokenMaxSlippages[token] > 0` (otherwise `amountOutMin == olasQuote` and the swap reverts),

then **anyone** can call `buyBack` inside the manipulation transaction and capture the difference. The same guard (LM’s `checkPoolAndGetCenterPrice`) is used. Today: all three burners have zero config and only dust/spam; the V3 path is disabled.
- **Monitor:** real token inflows to the three burners; `V3PoolsUpdated`, `OraclesUpdated`, `MaxSlippagesUpdated`; `changeImplementation`.
- **Note:** the ETH burner is owned by the Olas timelock; Base/OP by the bridge mediators. If they ever wire the V3 path, this becomes a **standalone E-U** path (no owner tx needed), which is worse than the LM sandwich.

### D. Ownership / automation

The LM owner is a plain EOA. If it changes to a keeper/timelock that automates `convertToV3`/`changeRanges`, the attack surface increases (predictable, recurring txs). Watch `OwnerUpdated` / `changeOwner` on all three proxies.

### Monitor quick-reference (event topics)

| Event | topic0 |
|---|---|
| ERC-20 `Transfer(address,address,uint256)` (funding into proxy/burner) | `0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef` |
| LM `ConvertedToV3(address,uint256,address[],uint256[],uint256)` | `0x9218be47e3147affd370a63a35ac072e55fc7f1a0a1dcd108c2d50fde510f58f` |
| LM `PositionMinted(uint256,address[],uint256[],uint256)` | `0xb3767368423a0d151c526a077a43c3ea857a69d740cb6b3135089531e40a2847` |
| LM `RangesChanged(address,uint256,address[],uint256[],uint256)` | `0x68f854c73c4dab9e77cbcb51844b6342b7317ad3e41fd2f240ce60375c0c63ea` |
| LM `ImplementationUpdated(address)` | `0x310ba5f1d2ed074b51e2eccd052a47ae9ab7c6b800d1fca3db3999d6a592ca03` |
| LM `OwnerUpdated(address)` | `0x4ffd725fc4a22075e9ec71c59edf9c38cdeb588a91b24fc5b61388c5be41282b` |
| Burner `V3PoolsUpdated(address[],address[])` | `0xc6e313511933d451185440d1fcf485c4d19574c612d044e1293aecd6129f08ad` |
| Burner `MaxSlippagesUpdated(address[],uint256[])` | `0x3181a803851338c58dfa6d1e5fb867dfae2db0f3fbf4c748b6b94d2acfb50926` |
| Burner `OraclesUpdated(address[],address[])` | `0xf48bc24e434208738ff0902f87f57659b0e85dc38b6dc0d8bca8378dafddf0e8` |

**One-line health check** (read-only): for each LM proxy, `nativeBalance == 0 && OLAS.balanceOf(proxy) == 0 && positionManager.balanceOf(proxy) == 0 && nonce == 1` → still $0. Then for any pool the owner might use, `slot0(pool).observationCardinalityNext == 1 && mapPoolAddressPositionIds(pool) == 0` → the next `convertToV3` is the critical window.

---

## 7. Classification and recommendation

- **E-U today: $0.00** (high confidence). No funds, no NFT positions, no transfer history, no outstanding allowances, all value-moving LM paths `onlyOwner`, burner paths unconfigured.
- **E-U latent: re-arm monitor (one funding + first convert).** The deployed code is live and unfixed; the published recipe is executable as a sandwich of the owner’s first convert on a `cardinalityNext == 1` pool. The stale path remains for later ops.
- **H-O: $0. P: $0 (owner EOA can upgrade/fund; not an external profit path). S: $0.**
- **Recommendation: KEEP as a re-arm monitor.** Do not remove: the finding is a live, published-recipe deployment whose only missing ingredient is a funding event plus the owner’s first op. A single `changeImplementation` to the fixed build, or a first convert on a pool with `cardinalityNext > 1`, changes the verdict; until then, the monitor is the correct state.
- **If the campaign’s rule is “remove all $0 findings”:** this is the strongest exception in the wave — the trigger is a single permissionless funding transfer plus the protocol’s own first convert, and the loss is ~20% of the first deposit in the demonstrated configuration. Keep at least a one-line monitor on the three proxies and three burners.

---

## 8. Methodology, sources, caveats

**Method.**
1. Verified the deployed core source against Etherscan and GitHub by **git blob SHA-1** (`dd559b98…` == commit `d1d682e5`), not just visual diff; verified the OP source from Sourcify matches the same blob; Base impl bytecode length/selector fingerprint matches OP.
2. Read the proxy custom impl slot (not EIP-1967; the proxy uses `keccak256("PROXY_LIQUIDITY_MANAGER")`), EIP-1967 slot, code, nonce, balances, owner, `maxSlippage`, `observationCardinality`, allowances, and position mapping at pinned blocks.
3. Enumerated **all** asset transfers ever for the three proxies with Alchemy `getAssetTransfers` (external/internal/erc20/erc721/erc1155), cross-checked ETH with Etherscan V2 `txlist`/`tokentx` and Blockscout, OP with Blockscout (Alchemy does not support `internal` on OP).
4. Read the three BuyBackBurners: impl slot, owner, `liquidityManager`, native/OLAS/WETH/USDC balances, `mapV3Pools`/`mapV2Oracles`/`mapTokenMaxSlippages` for WETH/USDC, and full transfer history.
5. Live `eth_call` of the deployed proxy’s `checkPoolAndGetCenterPrice` against two live OLAS pools; confirmed equality with `slot0`.
6. Fork PoC against the live proxy and live pool: same-block first-convert sandwich, plus a cardinality-growth control test; 2/2 pass.
7. Pulled the C4 report (H-02/H-08) and the five fix commits from GitHub; diffed `d1d682e5` → `ec4a90ce`/`c79186a2`/`f562a454`/`ef24d24b`; checked runtime selectors for the fix errors.

**Sources.**
- C4 report: <https://code4rena.com/reports/2026-01-olas> (2026-05-18), H-02, H-08.
- Fix commits: `ec4a90ce36e8`, `c79186a287c8`, `f562a4547ea3`, `ef24d24bd4bb`, `02b3aa9a` (GitHub `valory-xyz/autonolas-tokenomics`).
- Deployed commit: `d1d682e57085` (2026-05-12).
- Deployment globals: `scripts/deployment/pol/globals_{eth,base,optimism}_mainnet.json`.
- On-chain: ETH public RPC at block 26,215,810; Base 52,746,673; OP 158,341,970; Etherscan V2 creation/tx data; Alchemy `getAssetTransfers`; Blockscout.
- Price: DefiLlama OLAS $0.054222 (2026-10-18); the PoC uses the pool’s own fair sqrt ($0.053676) for mark-to-fair.

**Caveats / blockers.**
- The PoC uses a **synthetic** first deposit (50k OLAS + 2.5k USDC) because the real first deposit size is unknown; the 20% loss is a scale model, not a live dollar figure.
- The 5 USDC manipulation is sized for the live pool’s ~$28 active depth; a larger first deposit would need a larger manipulation or a deeper pool. The *mechanism* is invariant; the *loss* depends on range width, manipulation size, and pool depth.
- Base/OP pool-level `checkPoolAndGetCenterPrice` was not exercised because the deployed `factoryV3()` on those chains does not expose the canonical Uniswap V3 `getPool` used in the PoC (Base factory `0x5e7bb104…`, OP `0xe13dd1fb…`). The code-level fingerprint and the exact OP source match are the evidence there; the ETH fork proves the shared core. This does not affect the $0 verdict.
- OP internal native transfers could not be enumerated via Alchemy (`internal` unsupported on OP); Blockscout shows only the creation tx and zero token transfers, and the current native balance is 0. A historical self-destruct/internal send of 0 value is not value.
- No mainnet transactions were sent; all state changes are on forks. Whitelisted/blacklisted tokens, sanctions, and MEV competition are out of scope; none affect the $0 verdict.
- The same-block fast path assumes the owner’s first `convertToV3` is visible in a public mempool (or a predictable bundle). If Olas submits it via a private bundle/Flashbots, the fast path is unavailable; the **stale-price path** (`>30 min` quiet pool, raw slot0) remains and is the fallback re-arm.
- The C4 H-08 “mature pool” wording is imprecise: the code reads the **latest** observation (`observationIndex`), so the branch is an *inactivity* check, not a maturity check. The live gap is fresh-pool `cardinality<=1` + inactive-pool, as demonstrated. H-02’s “dead-code deviation check” is fixed in the deployed build; do not re-report it as live.

---

## 9. Files

```
olas-pol/
├── README.md                              # this report
├── summary.json                           # machine-readable verdict
├── analysis/
│   ├── deployed_impl_LiquidityManagerETH_source.sol   # Etherscan source bundle (ETH impl)
│   ├── deployed_impl_bundle.json                      # parsed bundle
│   ├── deployed_impl_abi.json / deployed_impl_meta.json
│   ├── deployed_buybackburner_source.sol / _abi.json
│   ├── extracted/                         # deployed core + libraries
│   ├── gh/                                # core at d1d682e5, ec4a90ce, c79186a2, f562a454, ef24d24b, main, OP
│   ├── diffs/                             # d1d682e5 -> fix diffs
│   ├── live_state.json                    # all chain reads at pinned blocks
│   ├── buybackburner_state.json
│   ├── source_diff.json                   # blob SHA / commit / selectors / fix table
│   └── poc_local_run.log                  # local 2/2 pass log
├── poc/
│   ├── foundry.toml
│   ├── lib/forge-std/                     # vendored
│   └── test/OlasPolH08.t.sol              # 2 tests
├── ci/                                    # optional ci/run.sh
├── ci-out/                                # CI artifacts
└── ci-artifacts/                          # downloaded by ci-run.sh
```

**Bottom line:** the deployed code is the unfixed `d1d682e5` build and the guard is fail-open on the live OLAS/USDC pool today; the proxies and burners are completely empty, so **E-U = $0.00 now**. The finding re-arms on the **first LM funding + first `convertToV3` on a `cardinalityNext==1` pool** (same-block sandwich; ~20% of the first deposit in the demonstrated configuration), and secondarily on **BuyBackBurner funding + V3 configuration** (permissionless `buyBack`). Keep the monitor.
