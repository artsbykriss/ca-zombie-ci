# ZH4 residual deep-dive — 3 "unverified delta" Uniswap v4 hooks

**Date:** 2026-10-23 · **Chains:** Ethereum, Base · **Status:** read-only on-chain analysis + **fork-only** PoC (no mainnet transactions signed or sent)

**Recon source:** `pass5-recon/README.md` §3a **A3** + `zombie-hunt-iv/pass5/v4-hooks.md` §7 blind spot #1. A3 claimed three live, funded v4 hooks with **return-delta power and no verified source or decompile**: ETH `0xfAaad5B7…` ($1.55M), ETH `0xd33398d4…` ($1.03M), Base `0xC90eddF5…` ($0.39M) ≈ **$2.97M pooled**.

---

## 1. TL;DR

| Hook | Chain | Project / pool | Pooled TVL | Return-delta bits | Live unprivileged extractable | Why closed |
|---|---|---|---|---|---|---|
| `0xfAaad5B731F52cDc9746F2414c823eca9B06E844` | Ethereum | **PunkStrategy (PNKSTR)** — ETH/PNKSTR | **$1,556,954** | **afterSwapReturnDelta** | **$0** | delta used to charge a *positive* swap fee; callback auth + pool binding correct; hook holds 0 at rest; round-trip net-negative (fork) |
| `0xd33398d46cB5749c7319AE1FABC498CdeB0F0FC0` | Ethereum | **ELEVATE/USDT** (UUPS proxy → `0x52155399…`) | **$1,028,360** | **none** | **$0** | *no delta bits at all* (A3 grouped it in error); callbacks are validation only. UUPS upgrade key is a **privileged** (P) total-loss vector |
| `0xC90eddF51569270E06270eA98F7EfFF828dDe0CC` | Base | **ETH/VAPI** | **$393,972** | **beforeSwap + afterSwap ReturnDelta** | **$0** | delta used to charge a fee; round-trip net-negative (fork); holds 0 at rest |

**Total live extractable by an external unprivileged attacker right now: $0** (confidence: **medium-high**).
**Pooled TVL that the blind-spot question was about: ≈ $2.98M.**

**Headline correction:** recon A3's "3 delta-returning hooks" is **2**. On-chain `getHookPermissions()` + the hook-address permission bits show `0xd33398d4` has **no return-delta permission**.

---

## 2. The blind spot, in exact terms

`v4-hooks.md` §7: the three hooks are *unverified* (no Etherscan/Sourcify source) and were **not decompiled in-budget**, so "a sign/currency bug in the delta is invisible to the lane's source read." A hook with `afterSwapReturnDelta` / `beforeSwapReturnDelta` can change the swapper's `BalanceDelta`; a sign or gross-up error there lets a swapper pay less than the pool gives (an LP drain).

This deep-dive closes that gap by (a) decompiling the runtime bytecode with **heimdall-rs v0.9.2**, (b) reading the **authoritative on-chain permission bits** (`getHookPermissions()`), (c) checking custody, and (d) **fork-testing a full swap + round-trip** through each live pool.

The three target hooks were identified from the Uniswap Gateway `topV4Pools` index (top-100 per chain) and their exact `PoolKey`s were reconstructed and **verified against the on-chain `Initialize` event**:

- ETH/PNKSTR `PoolId 0xbdb0f9c3…fddc` — `currency0 = ETH`, `currency1 = PNKSTR`, `fee = 0`, `tickSpacing = 60`, `hooks = 0xfAaad5B7…` (PoolManager `Initialize` @ block 23,305,292).
- ELEVATE/USDT `PoolId 0x9103109e…e95d` — `currency0 = ELEVATE (8dp)`, `currency1 = USDT (6dp)`, `fee = 3000`, `tickSpacing = 60`, `hooks = 0xd33398d4…`.
- Base ETH/VAPI `PoolId 0x05da2eb0…5671` — `currency0 = ETH`, `currency1 = VAPI`, `fee = 0`, `tickSpacing = 60`, `hooks = 0xC90eddF5…`.

---

## 3. Live-state assessment (read-only; fork-tested)

### 3.1 Permission bits vs implemented callbacks (the ToB "flag bypass" class)

The v4 hook-address low-14 bits are the ground truth the PoolManager dispatches on. `getHookPermissions()` (selector `0xc4e833ce`) returns a `Hooks.Permissions` struct whose field *i* maps to address bit **(13 − i)**. For all three hooks the **declared permissions equal the address bits** — no mismatch (verified on-chain and asserted in the PoC `test_permissions_match_address`).

| Hook | address bits | decoded permissions |
|---|---|---|
| `0xfAaad5B7` | `0x2844` | beforeInitialize, beforeAddLiquidity, afterSwap, **afterSwapReturnDelta** |
| `0xd33398d4` | `0x0fc0` | beforeAddLiquidity, afterAddLiquidity, beforeRemoveLiquidity, afterRemoveLiquidity, beforeSwap, afterSwap — **no delta** |
| `0xC90eddF5` | `0x20cc` | beforeInitialize, beforeSwap, afterSwap, **beforeSwapReturnDelta, afterSwapReturnDelta** |

### 3.2 Callback auth (decompiled + asserted)

Every callback body begins with `require(msg.sender == PoolManager)`:
- Ethereum hooks → `0x000000000004444c5dc75cB358380D2e3dE08A90`
- Base hook → `0x498581fF718922c3f8e6A244956aF099B2652b2b`

The PoC `test_callback_auth_reverts` calls `afterSwap`/`beforeSwap` on the hooks from an EOA and they revert. A fresh caller **cannot** invoke a hook callback directly to forge a delta.

### 3.3 Custody

`eth_getBalance` on all three hooks = **0**; `balanceOf` for PNKSTR/ELEVATE/VAPI on each hook = **0**. The PNKSTR hook *takes* the fee and forwards it in the same transaction (`PNKSTR.addFees{value:…}` + a deposit contract), so its at-rest balance is 0. There is **no hook-held value to steal** — consistent with `v4-hooks.md` §0.

### 3.4 Delta settlement (fork-tested)

| Hook / pool | swap | result |
|---|---|---|
| ETH/PNKSTR | 1 ETH → PNKSTR | 198,649.26… PNKSTR out; hook takes a positive ETH fee and forwards it |
| ETH/PNKSTR | round-trip | 100.000000 → **99.809759 ETH** (net **−0.1902 ETH**) |
| Base ETH/VAPI | 1 ETH → VAPI | 35,789.24… VAPI out |
| Base ETH/VAPI | round-trip | 100.000000 → **99.940900 ETH** (net **−0.0591 ETH**) |

A round-trip is net-negative in both cases: the delta is charged **to** the swapper (positive fee), never **to** the pool. No E-U.

### 3.5 Public (non-PoolManager) entry points probed

- PNKSTR hook `0x68e41100` (a permissionless fee-distribution/sweep that pays the caller 0.05 % of the hook's ETH balance) — callable, but with a 0 hook balance the caller gains **0** (`test_public_sweep_no_free_money`).
- Admin functions on all three hooks are `onlyOwner` (PNKSTR hook: owner read from the PNKSTR token; ELEVATE: `0xc5d3c245…`; Base: `0x5b818a1b…`) → **privileged (P)**, not E-U.

---

## 4. What an attacker can / cannot do

**Cannot** (all fork-verified):
- call any delta callback directly (callback auth holds);
- force the hook to return a negative (swapper-favourable) delta — the fee is always positive;
- extract from hook custody (0);
- profit on a round-trip through either delta pool (net-negative).

**Could (privileged only, P):**
- the ELEVATE hook is a **UUPS proxy** (`proxiableUUID 0x52d1902d`, `upgradeToAndCall 0x4f1ef286`, impl `0x52155399…`) — the owner `0xc5d3c245…` can upgrade to arbitrary logic (total-loss vector, exactly the Abracadabra-Rekt-II shape). This is **not** E-U; it is a key-management risk.
- the PNKSTR/Base hooks' owners can change fee/config (privileged).

**Preconditions / costs:** none applicable — no path exists, so there is nothing to price.

---

## 5. PoC / fork-verification

Foundry project at `poc/` (vendored `lib/forge-std`). Tests run against live forks (no broadcasts).

| Test | Result |
|---|---|
| `test_poolKeys_matchGateway` | PASS — reconstructed PoolKeys hash to the on-chain PoolIds |
| `test_permissions_match_address` | PASS — declared permissions == address bits; ELEVATE has no delta bits |
| `test_callback_auth_reverts` | PASS — delta callbacks revert for an EOA |
| `test_hook_charges_positive_fee` | PASS — hook ETH balance 0 before/after (fee forwarded) |
| `test_public_sweep_no_free_money` | PASS — caller gains 0 ETH |
| `test_roundtrip_pnkstr_eth` | PASS — net −0.1902 ETH (no profit) |
| `test_roundtrip_vapi_base` | PASS — net −0.0591 ETH (no profit) |

**7 / 7 PASS.** Run command: `FORK_RPC_URL=<eth> BASE_RPC_URL=<base> forge test -vv`.
CI: see `ci-log.txt` / `summary.json` for the run URL.

Files: `analysis/decompiled/*.sol` (heimdall output), `analysis/bytecode/*.hex`, `analysis/live-state.json`.

---

## 6. Verdict, residual & blockers

- **E-U now: $0** (medium-high confidence). The "unverified delta hook" blind spot is **closed for these three**: the delta logic is a *positive* fee in both delta-enabled hooks; the third has no delta power; callbacks are authenticated; custody is zero.
- **H-O: $0** (LPs can withdraw normally; `removeLiquidity` paths verified to exist for the delta hooks).
- **P:** ELEVATE hook **UUPS upgrade key** (`0xc5d3c245…`) and the other two hooks' owners → privileged total-loss/fee-config risk. **Not** counted as extractable.
- **S: $0.**
- **Blockers / caveats:** heimdall is a heuristic decompiler; the arithmetic was not re-derived line-by-line. However the *behavioural* result (round-trip net-negative, no custody, authenticated callbacks, matching permission bits) is measured directly on a fork and does not depend on the decompiler being exact.

## 7. Methodology & sources

- Enumeration/identification: Uniswap Gateway `topV4Pools(chain, first:100)`; on-chain `PoolManager.Initialize` logs; Etherscan V2 `getsourcecode` (all three unverified).
- Bytecode: `eth_getCode`; decompiler **heimdall-rs v0.9.2** (`--include-sol`).
- Live reads: `eth_call` for `getHookPermissions()`, `owner()`, `balanceOf`, `getSlot0`; `eth_getBalance`.
- PoC: Foundry 1.8.5, forked at explicit blocks (ETH 26,255,3xx; Base 52,984,5xx).
- The `CurrencyDelta` packing (amount0 = **high** 128 bits) was confirmed against `v4-core/src/types/BalanceDelta.sol`.

## 8. Files index

```
delta-hooks/
├── README.md                 (this file)
├── summary.json
├── analysis/
│   ├── live-state.json       machine-readable state + fork numbers
│   ├── bytecode/*.hex        runtime bytecode of the 3 hooks (+ impl)
│   └── decompiled/*.sol      heimdall output (+ abi.json)
├── poc/                      Foundry project (src/V4Swap.sol, test/Hooks.t.sol)
├── ci/                       heavy job (runs the fork suite, writes ci-out/)
├── ci-out/                   CI results
├── ci-log.txt / ci-artifacts/
```

*Read-only; all PoC execution on local forks only. Nothing here is an instruction to transact.*
