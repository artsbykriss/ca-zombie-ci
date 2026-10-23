# ZH4-PASS5 · P5-04 — Uniswap StablePairHook / VolatilePairHook family (UUPS v4 hooks)

**Date:** 2026-10-23 · **Chains:** Ethereum (1), Arbitrum (42161) · **Mode:** read-only on mainnet
(no transactions signed or sent); exploit PoC is **fork-only** (local anvil fork of mainnet).
**Finding ID:** `ZH4-PASS5-P5-04` · **Verdict:** **$0 extractable by an unprivileged attacker (high confidence)** —
the corpus "same-block fee-cache → 0-fee swap" primitive is **real and reproduced**, but it is **LP fee-loss,
not a drain**: a self-contained round-trip is net-negative, fees cannot go negative, and the hook has no
return-delta power.

---

## 1. TL;DR

| Target | Live pooled TVL (ceiling) | Live extractable (unprivileged, E-U) | Why closed | Latent risk |
|---|---|---|---|---|
| `0x0000113d…fcC0` StablePairHook (ETH) | $9,085,966 | **$0** | fee-only hook, no return-delta, pool-init/config role-gated, 0-fee swap still trades at AMM price | stale-cache LP fee-loss (bounded, self-heals next block) |
| `0x000022Ec…3Cc0` VolatilePairHook (ETH) | $1,741,865 | **$0** | fee-only hook, no return-delta; fees always ≥ baseline (never 0 by cache) | none found |
| `0x630e9CaC…1Bcc0` StablePairHook (ARB) | $1,005,830 | **$0** | same as ETH stable | stale-cache LP fee-loss |
| **Family total** | **$11,833,661** | **$0** | | UUPS upgrade key = privileged DoS/brick risk (P) |

> The `$11.83M` is the **pooled LP TVL ceiling** (the corpus's `$11.71M`, re-measured). It is **not the prize**:
> no unprivileged path to that principal was found.

**Total live extractable now (unprivileged): $0.00** · **Confidence: high.**

---

## 2. The mechanism in exact terms

The family is a pair of **dynamic-fee** v4 hooks (UUPS upgradeable, `BaseUUPSHook` → `BaseDynamicFeeHook`).
`beforeSwap` returns a v4 **LP-fee override** (`lpFeeOverride = feeE6 | 0x800000`); the hook returns
`BeforeSwapDelta = ZERO` and all four **return-delta permission bits are OFF**, so the hook can never alter a
swapper's BalanceDelta — it can only set the LP fee (which is paid **to the pool / LPs**, never to the hook).

### 2a. StablePairHook price cache (the documented primitive)

`StablePairHook._loadPrice` (verified source, `src/stable/StablePairHook.sol:105-117`) caches the
start-of-block sqrt price in `feeState[poolId]` on the **first swap of a block**; same-block swaps reuse it.
The fee direction is then `lpFeeE12 = (ammPriceBelowRP == zeroForOne) ? 0 : decayingFeeE12`
(`StablePairHook.sol:187`). The source itself documents the accepted manipulation:

> *"with zero active liquidity the price moves for free, so the cache can sit on the opposite side of the
> reference and a same-block corrective swap is charged 0. Needs a same-block mint, and self-heals next block."*

⇒ a **0-fee swap primitive** for a same-block searcher. Reproduced live on a fork (§5, test 10): a corrective
swap that pays **835 E6 (0.0835%)** with a fresh cache pays **0 E6** with a stale cache.

### 2b. Why it is not a drain

* A 0-fee swap **still executes at the AMM curve price** — the attacker gets no more output than the pool math
  allows. The only thing removed is the LP fee.
* The fee is a `uint24` and `toFeeE6` **clamps to `MAX_FEE_E6 = 999998`** (99.9998%) and rounds **up**, so a fee
  can never be 0-by-rounding-down, negative, or > 100% (`StableFeeCalculation.sol:42-45`). No negative-fee path.
* A **self round-trip is net-negative** (fees + price impact), verified: −750,001 µUSDC on a 50,000 USDC round
  trip (§5, test 8).
* To monetise a 0-fee corrective swap the attacker needs an **external** arbitrage (pool price off-market); the
  hook manipulation only removes the fee, which is the **LPs' loss**, bounded by the fee rate (~0.08% observed;
  clamped ≤ 99.9998% in an extreme depeg) and self-heals next block.

---

## 3. Live state (read-only, at explicit blocks)

| item | value | how / block |
|---|---|---|
| ETH block | **26253709** | `eth_blockNumber` |
| ARB block | **517464049** | `eth_blockNumber` |
| ETH StablePair proxy | `0x0000113dCf4ADd69999Fad8F20F2b63F979bfcC0` | `eth_getCode` 135 bytes |
| → EIP-1967 impl | `0x5f216d21b1c81346938eddc1df7e0111a0f64000` | slot `0x360894a1…2bbc`, 18,263 bytes |
| ETH VolatilePair proxy | `0x000022Ec4eBD6b12294396E852E4C3876b253Cc0` | 135 bytes |
| → EIP-1967 impl | `0x1ddbf7215be4f8a7623b9b1b0255c6e1e3f6c000` | 19,055 bytes |
| ARB StablePair proxy | `0x630e9CaC0ffF557Bd3A01DAa111ed253c771Bcc0` | 135 bytes |
| → EIP-1967 impl | `0x424e2f8d89eeab51af10669d149fbd4beb090000` | 18,263 bytes |
| EIP-1967 admin slot | `0x00…00` (unused) | UUPS: auth is in-contract |
| `poolManager()` | ETH `0x000000000004444c5dc75cB358380D2e3dE08A90`; ARB `0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32` | `eth_call` |
| `getHookPermissions()` | `(bI,aI,bAL,aAL,bRL,aRL,bS,aS,bD,aD,bSD,aSD,aALD,aRLD) = (1,1,1,1,0,0,1,1,0,0,0,0,0,0)` → flags `0x3cc0` | matches deployed address bits on all 3 |
| **return-delta bits** | **all 4 OFF** | `getHookPermissions` |
| `UPGRADE_INTERFACE_VERSION` | `5.0.0` | `eth_call` |
| `proxiableUUID()` | reverts `UUPSUnauthorizedCallContext` **when called through the proxy** (OZ `notDelegated` modifier) — expected, not a bug | `eth_call` |

### 3a. Roles (from `RoleGranted` logs + `hasRole` at head)

| role | Ethereum | Arbitrum |
|---|---|---|
| `DEFAULT_ADMIN_ROLE` (controls UUPS upgrade) | `0x1a9C8182C09F50C8318d769245beA52c32BE35BC` (Etherscan name **Timelock**) | `0x2bad8182c09f50c8318d769245bea52c32be46cd` |
| `CONFIG_MANAGER_ROLE` | same timelock | same |
| `POOL_INITIALIZER_ROLE` | `0xfc43582532e90fa8726fe9cdb5fad48f4e487d27` | `0x3dd872203e8fc405622ddc02a69de3bd9d52c4f8` |
| attacker (fresh EOA) | **none** | **none** |

Grant blocks: ETH stable/volatile `25947644` / `26219917`; ARB `51263120`. No `RoleRevoked` events.

### 3b. Live pools, `getFee`, liquidity

| chain | pool | poolId | pair | `getFee` (zeroForOne, oneForZero) | TVL (Gateway) |
|---|---|---|---|---|---|
| ETH | StablePair | `0x2b21c6…9f634` | USDC/USDT | (15, 0) | $5,562,349 |
| ETH | StablePair | `0xeda62d…b7edb` | USDC/USDG | (0, 100) | $3,523,617 |
| ETH | VolatilePair | `0x98316e…a3eea` | ETH/USDC | (713, 87)* | $1,741,865 |
| ARB | StablePair | `0x52b42d…bee41e6` | USDG/USDC | (100, 0) | $1,005,830 |

\* volatile fees move block-to-block (0.04%–0.08%); the corpus's `(15,0)` on USDC/USDT is confirmed.

---

## 4. What an attacker can / cannot do

**CAN (unprivileged):**
1. **Swap on the live pools** via `PoolManager.unlock → swap` (the hook is attached and permissionless to swap
   against) — verified, `Swap` event emitted (test 7).
2. **Obtain a 0-fee swap** in the "away" direction; and, with a **stale cache** (cache on the opposite side of
   the reference), a **same-block corrective swap is charged 0** where a fresh cache charges 835 E6 (test 10).
3. Call `getFee` / `feeConfig` / `feeState` / `hasRole` (views).

**CANNOT:**
1. **Attach the hook to a new pool:** `initializePool` is `onlyRole(POOL_INITIALIZER_ROLE)` (test 3, reverts
   `AccessControlUnauthorizedAccount`); direct `PoolManager.initialize` reverts because `_beforeInitialize`
   unconditionally reverts `InvalidInitializer` (test 4).
2. **Change fee config:** `updateFeeConfig`/`batchUpdateFeeConfig` are `onlyRole(CONFIG_MANAGER_ROLE)` (test 5).
3. **Alter swap amounts / return a delta:** the 4 return-delta flags are OFF (test 1); v4 ignores the hook's
   `BeforeSwapDelta`/`afterSwap` delta.
4. **Push a negative/absurd fee:** `toFeeE6` clamps to 999998 and never underflows (test 9); fees are `uint24`.
5. **Profit from a self round-trip:** net-negative after fees + price impact (test 8).
6. **Drain the hook's own custody:** the hook holds no ETH/stables (the family holds ERC-20s only via the
   PoolManager's internal accounting); confirmed by the corpus and by the design (fees go to the pool).

**UUPS upgrade key (P):** `_authorizeUpgrade` is `onlyRole(DEFAULT_ADMIN_ROLE)` (Uniswap governance timelock).
`_validateNewImplementation` **pins** the PoolManager and the hook-permission set to the proxy's mined address
bits — so an upgrade **cannot enable return-delta** and **cannot directly move LP principal**. It can, however,
set fees to ~100% (swappers pay LPs), revert swaps (DoS/brick), or add pools. This is a **privileged DoS /
fee-capture risk, not a proven principal drain** (the corpus's "total-loss vector" is overstated for principal).

---

## 5. PoC / fork verification

`poc/` — Foundry project (vendored `lib/forge-std`; v4-core `FixedPoint96` + solady `FixedPointMathLib` +
`StableFeeCalculation.sol` copied under `src/deps/`). Fork via
`vm.createSelectFork(vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", "https://ethereum-rpc.publicnode.com")))`.
No broadcasts. The swap harness implements `unlockCallback` and settles through the real
`0x000000000004444c5dc75cB358380D2e3dE08A90`.

**Result: 10/10 PASS** (CI, `forge test -vvv`, fork block ≈ 26,253,7xx)

| # | test | what it proves |
|---|---|---|
| 1 | `test_1_flags_and_delta_bits_off` | 6 flags set; **all 4 return-delta bits OFF** |
| 2 | `test_2_roles_and_pool_manager` | admin/config = Uniswap timelock; attacker holds no role |
| 3 | `test_3_attacker_cannot_initialize_pool` | `initializePool` reverts for a fresh account |
| 4 | `test_4_direct_pool_manager_initialize_reverts` | `PoolManager.initialize` blocked by `_beforeInitialize` |
| 5 | `test_5_attacker_cannot_update_fee_config` | `updateFeeConfig` role-gated |
| 6 | `test_6_live_getFee_values` | live `getFee` (USDC/USDT `(15,0)`, USDC/USDG `(0,100)`, ETH/USDC `(713,87)`), all ≤ 1e6 |
| 7 | `test_7_zero_fee_swap_executes` | a **fresh account executes a real 0-fee swap** (`Swap` event `fee = 0`) |
| 8 | `test_8_round_trip_is_negative` | self round-trip loses 750,001 µUSDC on 50,000 USDC → **no attacker profit** |
| 9 | `test_9_fee_math_never_negative_or_over_100pct` | `toFeeE6` clamps to 999998; 0 stays 0; never negative |
| 10 | `test_10_stale_cache_zero_fee_and_self_heal` | **stale cache → corrective swap fee 0**; next block (fresh cache) the same swap pays **835 E6** |

Key numbers (CI run): stale-cache corrective swap `feeE6 = 0`; fresh-cache same swap `feeE6 = 835`
(0.0835%); round-trip PnL = −750,001 µUSDC (−$0.75 on $50k) after two legs.

**CI run URL:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39916215969 (`conclusion: success`,
10 passed / 0 failed). Log: `ci-log.txt`.

---

## 6. Verdict & residual risk

* **E-U (unprivileged extractable): $0.00, high confidence.** The documented 0-fee cache primitive is real and
  reproducible, but it yields **fee avoidance only** — no principal extraction, no negative fee, no delta abuse,
  and a self round-trip loses money. The honest answer is "$0, here is the proof".
* **LP fee-loss (latent, conditional):** during a stale-cache window (zero-liquidity in-block crossing + same-block
  mint) a corrective arb can avoid the LP fee (≤ 0.0835% observed; clamped ≤ 99.9998%). Self-heals next block.
  This is a small, conditional **LP revenue** loss, not attacker principal profit. Worth a monitor, not a payout.
* **P (privileged):** the UUPS upgrade key (Uniswap governance timelock) can brick pools / set ~100% fees /
  add pools. Return-delta and PoolManager are pinned by `_validateNewImplementation`, so **direct principal theft
  is not available**; the exposure is DoS/fee-capture over the $11.83M pooled TVL.
* **H-O / S: $0** — LP exits are unblocked (`before/afterRemoveLiquidity` flags OFF); nothing is stuck.

**Blockers / caveats:** the `$11.83M` is the Uniswap-Gateway pooled TVL (ceiling, not the prize). The stale-cache
state was forced via `vm.store` in the PoC to isolate the mechanism (reproducing the source's own documented
scenario); the natural trigger needs a zero-liquidity crossing, which was not observed live. The volatile hook's
fee is always ≥ its per-side baseline, so the 0-fee cache primitive applies only to StablePair.

---

## 7. Methodology & sources

1. **Live reads** at ETH block 26253709 / ARB 517464049: `eth_getCode`, EIP-1967 impl slots, `getHookPermissions`,
   `poolManager`, `hasRole`, `getFee`, `feeSlot0`/`getLiquidity` via the StateView contracts; `RoleGranted` logs
   via Etherscan V2. Script: `analysis/read-live-state.sh`; dump: `analysis/live-state.txt` / `.json`.
2. **Verified source** (Etherscan V2 `getsourcecode`, chainid 1 & 42161) for `StablePairHook.sol`,
   `VolatilePairHook.sol`, `BaseDynamicFeeHook.sol`, `BaseUUPSHook.sol`, `BaseHook.sol`, `HookRoles.sol`,
   `StableFeeCalculation.sol`, `StableFeeConfiguration.sol`, `VolatileFeeCalculation.sol`, `BlockNumberish.sol`
   and bases — full trees under `analysis/src/`.
3. **TVL** re-measured from the Uniswap Gateway GraphQL `topV4Pools` (`totalLiquidity.value`): `analysis/gw-eth.json`,
   `analysis/gw-arb.json`.
4. **Fork PoC** in CI (GitHub Actions, `artsbykriss/ca-zombie-ci`), 10/10 PASS.

### Files index
```
stablepair-hooks/
├── README.md                 # this file
├── summary.json              # machine-readable (§7 schema)
├── analysis/                 # verified source trees, live-state reads, gateway TVL, ABI/log dumps
├── poc/                      # Foundry project (foundry.toml, src/, test/, lib/forge-std)
├── ci-out/ci-run-url.txt     # CI run URL
├── ci-log.txt                # full CI job log (10/10 PASS)
└── ci-artifacts/
```

**Caveats:** point-in-time 2026-10-23; nothing here is an instruction to transact. Fork-only PoC; no mainnet
transaction was signed or sent. Public keyless RPCs only in all saved scripts.
