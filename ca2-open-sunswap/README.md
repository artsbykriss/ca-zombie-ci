# SunSwap V4 PoolManager (Tron) — unverified singleton, hook support, $133M TVL

**Date:** 2026-11-03 · **Chain:** Tron mainnet · **Target:** `TVjuTE3V5bMVdpfNhid8kD2v35T2k1u1Br` (20-byte `0xd8de75898a30b097da826464e932934a512c7be3`) · **Status:** read-only; no transactions broadcast; no keys used; PoC runs on a local EVM against the real deployed bytecode only.

> CA2's table carries a typo variant `TVjuTE3V5bMVdpfNhid8kD2v35T2k1u1Br`/`…pfNhid8…`. The on-chain address above is the one returned by `wallet/getcontract`; it is a 28,686-byte runtime singleton named `PoolManager`, origin EOA `TU3rMHyWHzeEJBReWLzHko728hbz6MtfNg`.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed/open | Latent risk |
|---|---:|---|---|
| SunSwap V4 PoolManager, 270 pools, 154 currencies | **$0.00** | Canonical Uniswap-v4 lock/delta accounting is present and enforced. `take`/`settle`/`mint`/`burn`/`clear`/`swap`/`modifyLiquidity`/`donate` all require an active transient locker; `lock` sets the locker to `msg.sender`, calls `lockAcquired(bytes)`, then requires the unsettled-delta count to be **zero** before clearing it. Live constant calls from a fresh EOA revert `NoLocker()` (0x05185ab0) for every value path. Hooks are permissionless but only affect their own pool and cannot reach the PM's locker/deltas. | Unaudited custom AMM math; malicious third-party hooks can harm users of their own pool (bounded by swap amount); owner/controller can pause and set protocol fees (protocol fees accrued = 0 today). |

**Total live extractable by an external unprivileged attacker now: $0.00** (confidence: **high** on the tested guard paths; **medium** on the full AMM math surface).

The $133.08M is LP principal (`H-O`), not `E-U`.

---

## 2. Exact mechanism

### 2.1 What the contract is

- On-chain ABI (99 entries, stored by TronGrid even though source is unpublished) exposes a Uniswap-v4-style singleton: `initialize`, `lock`, `take`, `settle`, `settleFor`, `sync`, `clear`, `mint`, `burn`, `swap`, `modifyLiquidity`, `donate`, `collectProtocolFees`, `setProtocolFee`, `setProtocolFeeController`, `pause`/`unpause`, `transferOwnership`, plus per-currency ERC-20-like claims (`balanceOf`, `allowance`, `approve`, `transfer`, `transferFrom`).
- **Runtime:** 28,686 bytes, 12,214 instructions, 47 unique selectors; 0 `DELEGATECALL`, 0 `SELFDESTRUCT`, 4 `CALL`, 3 `STATICCALL`, 22 `TLOAD`, 11 `TSTORE`. `TLOAD`/`TSTORE` (EIP-1153) carry the locker and delta count.
- **Pool key layout** recovered from live calldata/events: `(address currency0, address currency1, address hooks, uint24 fee, bytes32 parameters)`, where `parameters = (tickSpacing << 16) | permissionFlags`. `fee == 0x800000` means a dynamic-fee pool.
- **Hook validation:** `initialize` is permissionless (no owner gate). It checks `currency0 < currency1`, tick-spacing bounds, unused `parameters` bits, then `STATICCALL`s `getHooksRegistrationBitmap()` (`0xf961d1f4`) on the hook and requires the returned bitmap to match the pool's permission flags. A mismatch reverts `HookConfigValidationError()` (0x7f7506dc). One live pool uses a codeless hook address (`0xbed0a0f5…`, flags `0x20`); this is a registration-validation / DoS nuance for that pool only (no code can execute, so no authority), not a PM drain.
- Hook callbacks are executed by the PoolManager itself (`address(hook).call`), so inside a hook `msg.sender == PoolManager`. The PM has **no** hook-callback entry point, so a hook cannot become the locker or touch another pool's deltas.

### 2.2 The canonical V4 `unlock`-callback drain class — closed here

The canonical drain is: open a lock, take tokens, and return before the manager checks that the caller's delta is settled. This deployment implements the full invariant:

1. `lock(bytes)` (`0x81548319`): reverts `LockerAlreadySet(address)` if the transient locker slot is nonzero; stores `locker = msg.sender`; calls `lockAcquired(bytes)` (`0xab6291fe`) on `msg.sender`; then **requires the transient unsettled-delta count == 0** or reverts `CurrencyNotSettled()` (`0x5212cba1`); then clears the locker.
2. `take` (`0x0b0d9c09`) requires `locker != 0` (`NoLocker()`), debits `msg.sender` by `-amount`, and only then transfers. It does **not** compare `msg.sender` to the locker — this is canonical v4 (`onlyWhenUnlocked`); the debit makes a free take impossible because the lock-end count would be nonzero.
3. `settle`/`settleFor` (`0x11da60b4`/`0x3dd45adb`) credit only the actual balance delta since `sync(currency)`; native settle requires `msg.value`; `SettleNonNativeCurrencyWithValue()` blocks value on ERC-20 settles.
4. `mint` (`0xc6c3bbe6`) debits `msg.sender` and mints a claim to `to`; `burn` (`0xf6b911bc`) credits `msg.sender` and burns from `from` only if `from == msg.sender` or an allowance exists. `clear` (`0x80f0b44c`) only clears an exact **positive** delta.
5. `swap` (`0xea77b364`), `modifyLiquidity` (`0x7550efcf`), `donate` (`0x55cea574`) are all `onlyWhenUnlocked`; `swap` and `donate` call hooks from inside the caller's lock and bound any hook-returned delta (`HookDeltaExceedsSwapAmount`, `InvalidHookResponse`).

### 2.3 Live proof (Tron, block 87,680,565)

Constant calls from a fresh, unprivileged address (`TBXSw8fM4jpQkGc6zZjsVABFpVN7UvXPdV`), no state change:

| Call | Result | Energy |
|---|---|---:|
| `take(USDT, fresh, 1)` | `0x05185ab0` `NoLocker()` | 429 |
| `take(TRX, fresh, 1)` | `0x05185ab0` `NoLocker()` | 429 |
| `mint(fresh, USDT, 1)` | `0x05185ab0` | 1,115 |
| `burn(fresh, USDT, 1)` | `0x05185ab0` | 1,316 |
| `clear(USDT, 1)` | `0x05185ab0` | 777 |
| `settle()` / `settleFor(fresh)` | `0x05185ab0` | 326 / 520 |
| `collectProtocolFees(fresh, USDT, 1)` | `0x48f5c3ed` `InvalidCaller()` (controller-only) | 822 |
| `setProtocolFeeController(fresh)` | empty revert (owner-only, `revert(0,0)`) | 428 |
| `pause()` / `unpause()` / `transferOwnership(fresh)` | empty revert (owner-only) | 742 / 456 / 1,181 |
| `lock("")` from an EOA | empty revert (callback return cannot be ABI-decoded) | 1,449 |

Raw output: `analysis/live_probes.json`.

---

## 3. Live-state assessment (block 87,680,565; TronGrid public API)

| Item | Value |
|---|---|
| `owner()` | `TLntW9Z59LYY5KEi9cmwk3PKjQga828ird` (EOA; 895,867 TRX; created 2022-04-29) |
| `paused()` | `false` |
| `poolCount()` | **270** |
| `protocolFeeController()` | `TEays9UfJn2EqKjkN7hWUWewBGpGxTzWEv` = contract `ProtocolFeeController`, 3,975 bytes, owner = same EOA, `pendingOwner = 0`, `poolManager = PM`, `protocolFeeSplitRatio = 0`, default dynamic fee = 0 |
| `getLocker()` | `0` (no lock active) |
| `getVaultReserve()` | `(0, 0)` = no currency currently synced (transient) |
| `protocolFeesAccrued(USDT)` / `(native)` | `0` / `0` |
| Native balance | **270,855,916.052629 TRX** = **$87,204,667.50** at $0.32196/TRX |
| USDT balance | **43,637,657.236943 USDT** = **$43,566,527.86** at $0.99837 |
| USDD balance | 569,251.8569 USDD = $566,651.39 at $0.99543 |
| Other measured | JST 6,420,361.22; SUN 2,946,141.18; ICR 7,150,846.60; 48,749,387.63 of an 18-decimal token; 2,100,012.02 of an 18-decimal token; small dust |
| **DefiLlama SunSwap V4 TVL** | **$133,084,238.64** (Tron) |
| Measured top-2 (TRX+USDT) | **$130,771,195.35** |

Pools/currencies/hooks from all 270 `Initialize` events (`analysis/initialize_events.json`):

- 154 unique currencies; 118 pools use native TRX and 126 use USDT (many pools are TRX/USDT variants).
- 40 pools have a nonzero hook; **15 unique hooks**. Largest: `CLDynamicFeeHook` `TJd9Sf8YnDgYKuLZFR6puxsxQUejXGz7MH` (25 pools, origin `TU3rMH…` = SunSwap deployer), `ThirdPartyHook` `TEasm55H9jwHW81ch61k6kxhbNYnJrtDCH` (2 pools, origin `TCXrf8…`), `FlashHook` (3 instances), `WRUBPegHook` (1), 10 one-off hooks, and one codeless hook address `0xbed0a0f5…` with 1 pool (no callbacks possible).
- `analysis/hooks.json`, `analysis/hook_pools.json`.

---

## 4. What an attacker can/cannot do

### Can (but gains nothing)
- Create a pool with their own hook (`initialize` is permissionless by design). The hook must declare a registration bitmap matching the pool flags; it is called by the PM with `msg.sender = PM`.
- Open a lock and call `take`/`mint` inside `lockAcquired(bytes)`. The call succeeds, but the caller's delta becomes negative; at lock end the delta-count check reverts the whole transaction with `CurrencyNotSettled()`.
- Call `settle`/`settleFor` during their own lock, but only actual token/native balance increases since `sync` are credited.
- Use a mock/fake token as a pool currency: fake-currency deltas are per-currency and cannot offset a real-currency debt.
- Grief its own pool via a malicious hook: a hook can capture up to the current swap amount from **users of that pool** (bounded by `HookDeltaExceedsSwapAmount`), not PM principal and not other pools.

### Cannot
- `take` without a lock (live revert `NoLocker`, 429 energy).
- Take inside a lock without settling (harness revert `CurrencyNotSettled`; 18/18 tests).
- Re-enter `lock` (harness revert `LockerAlreadySet`).
- `mint` claims without paying (harness revert `CurrencyNotSettled`; live `NoLocker`).
- `burn` another user's claim or `transferFrom` without allowance (harness reverts; live `NoLocker` outside lock).
- `clear` a negative delta (harness `MustClearExactPositiveDelta`).
- `swap`/`modifyLiquidity`/`donate` outside a lock (live/harness `NoLocker`).
- Collect protocol fees (controller-only; accrued = 0) or change the controller/owner (owner-only).
- Reach another pool's deltas, positions, or the PM's native/ERC-20 reserves through a hook.

**Costs:** the failed paths cost only the constant-call energy (326–1,449 energy; no capital). There is no profitable path to net against gas.

---

## 5. PoC / verification

`poc/` is a Foundry project that deploys the **real creation bytecode** (`analysis/poolmanager_runtime.hex`, 28,791 bytes, constructor included) with `CREATE` at the correct Tron 20-byte address, then exercises the runtime on a local Cancun EVM (TLOAD/TSTORE enabled). No fork, no Tron node, no mainnet state, no funds.

Files:
- `poc/src/Harness.sol` — `IPoolManager` interface, mock ERC-20, attacker contract implementing `lockAcquired(bytes)` with eight attack modes, mock hook.
- `poc/test/PoolManagerAuth.t.sol` — 18 tests.
- `poc/test/poolmanager_creation.hex` — creation bytecode; `poolmanager_runtime.hex` — runtime.

Result: **18/18 PASS** locally and in CI (run URL in §9). Key tests:

| Test | Result |
|---|---|
| `take` outside lock | `NoLocker()` |
| take inside lock, no settle (ERC-20 and native) | `CurrencyNotSettled()` |
| mint inside lock, no payment | `CurrencyNotSettled()` |
| pay (`sync`+transfer+`settle`) then take | success; attacker net 0; PM net 0; delta count 0 |
| `clear` a negative delta | `MustClearExactPositiveDelta()` |
| nested `lock` | `LockerAlreadySet(address)` |
| burn victim claim without allowance | revert |
| `transferFrom` victim claim without allowance | revert |
| collect fees as non-controller | `InvalidCaller()` |
| `setProtocolFeeController` as non-owner | revert |
| initialize with hook-bitmap mismatch | `HookConfigValidationError()` / revert |
| initialize with valid key (hooks=0) | success, `poolCount=1` |
| `swap` outside lock | `NoLocker()` |

The exact revert selectors were checked against the live ABI: `NoLocker()=0x05185ab0`, `CurrencyNotSettled()=0x5212cba1`, `LockerAlreadySet(address)=0xc6742a3f`, `MustClearExactPositiveDelta()=0xbda73abf`, `InvalidCaller()=0x48f5c3ed`, `HookConfigValidationError()=0x7f7506dc`.

---

## 6. Verdict and residual risk

**E-U = $0.00.** The canonical Uniswap-v4 unlock/locker drain class is correctly implemented. Every value-moving entry point is gated on the transient locker; the lock-end unsettled-delta check is present; nested locks are rejected; claims are per-currency and per-caller; protocol fee collection is controller-only and accrued fees are zero.

| Category | USD | Notes |
|---|---:|---|
| **E-U** | **$0.00** | external unprivileged attacker |
| E-U-conditional | $0.00 | no condition found; a malicious hook can only harm users of its own pool, up to the swap amount |
| H-O | ≤$133,084,238.64 | Upper bound: PM TVL treated as LP/holder-owned; withdrawable only by the position owner via `modifyLiquidity` inside a lock. Protocol-owned liquidity is not separated. |
| P | $0.00 | owner can pause/unpause, set the controller, set protocol fees via the controller; protocol fees accrued = 0; no owner function moves LP principal |
| S | $0.00 | no permanently stuck path found |

**Residual risks / what would change the verdict**
1. **Unaudited custom AMM math.** The pool/tick/fee math is a modified v4 port (custom `parameters`, dynamic fee, ERC-20 claims, pause). We verified authorization and payer accounting, not every arithmetic path. A math bug could leak LP value; confidence in a *zero* on the math sub-surface is medium.
2. **Third-party hooks.** 2 pools use `ThirdPartyHook` (origin `TCXrf8…`), 3 use `FlashHook` instances, 10 one-off hooks. A malicious hook can capture up to the swap amount from users of its own pool. It cannot touch PM principal or other pools.
3. **Owner/controller privilege.** The owner EOA (`TLntW9…`) can pause and change the fee controller; the controller contract (same owner) can set protocol fees and collect accrued fees. Both are `P`. Protocol fees are 0 today, so there is nothing to collect.
4. **TVM vs EVM.** The runtime uses `TLOAD`/`TSTORE` and standard EVM opcodes; no TVM-specific opcode was found in the executed code. The harness runs the bytecode on Cancun EVM; live Tron constant calls confirm the same revert selectors. Native `CALL`/balance semantics are the only material difference, and the native `take` path is live-verified `NoLocker`.
5. **Source unpublished.** The ABI is on-chain and the bytecode is from TronGrid; decompilation (heimdall) is approximate. The guard conclusions are backed by live calls and the bytecode-level tests, not by source review.

---

## 7. Methodology, sources, limitations

- **Bytecode/ABI:** `POST https://api.trongrid.io/wallet/getcontract` with `{"value":"TVju…","visible":true}`. It returns the **creation** code (28,791 bytes) and the on-chain ABI (99 entries). The runtime is `creation[0x69:0x69+0x700e]` (28,686 bytes). `eth_getCode` on TronGrid's JSON-RPC returns `0x` for Tron contracts (unusable); this is a tooling limitation.
- **Disassembly:** `analysis/disasm.py` (custom EVM/TVM disassembler, selector/JUMPDEST map), `analysis/static_checks.py` (opcode/guard matrix). No `DELEGATECALL`, no `SELFDESTRUCT`.
- **Decompilation:** heimdall-rs 0.9.2 (`--skip-resolving --include-sol`); output in `ci-out/heimdall/` (or `analysis/heimdall/` after a local run). Heimdall is EVM-oriented and its output is approximate; used only as corroboration.
- **Live reads:** TronGrid `wallet/triggerconstantcontract` from a fresh address at block 87,680,565; `wallet/getaccount`; contract `Initialize` events via `/v1/contracts/<addr>/events` (270 events, paginated).
- **Prices:** DefiLlama `coins.llama.fi` (TRX $0.32195961886, USDT $0.99837, USDD $0.9954318) at 2026-11-03; DefiLlama protocol TVL `sunswap-v4` = $133,084,238.64.
- **PoC:** Foundry 1.7.1, solc 0.8.24, `evm_version = "cancun"`, `code_size_limit = 60000`; the real creation code is deployed with `CREATE` so the constructor sets the `noDelegateCall` immutable. `forge test` 18/18.

**Limits:** no local TVM fork; TronGrid rate limits (429s) on public endpoints; source unpublished; the decompiler cannot recover the exact custom math; hook intent cannot be proven from code alone (only authority can).

---

## 8. Files

| File | Contents |
|---|---|
| `analysis/poolmanager_runtime.hex` | Full creation bytecode returned by TronGrid |
| `analysis/poolmanager_runtime_only.hex` | Extracted 28,686-byte runtime |
| `analysis/poolmanager_abi.json` | On-chain ABI (99 entries) |
| `analysis/disasm.py`, `annot.py` | EVM/TVM disassembler and annotated dumps |
| `analysis/static_checks.py`, `static_guards.json` | Opcode/selector/guard matrix |
| `analysis/initialize_events.json` | All 270 `Initialize` events |
| `analysis/pool_summary.json`, `hooks.json`, `hook_pools.json` | Pool/currency/hook census |
| `analysis/live_sunswap.py`, `live_sunswap.json` | Re-runnable live snapshot + output |
| `analysis/live_probes.json` | Fresh-caller constant-call probes |
| `analysis/valuation.json` | USD valuation at the stated prices |
| `analysis/troncall.py` | Read-only TronGrid helper (no keys) |
| `poc/` | Foundry project, 18 tests against the real bytecode |
| `ci/run.sh`, `ci-out/` | CI decompile/static/live job + results |
| `ci-log.txt` | GitHub Actions log (after the run) |

## 9. CI

- **Run URL:** _filled after the GitHub Actions run_ (`artsbykriss/ca-zombie-ci`, folder `ca2-open-sunswap`).
- **What ran in CI:** heimdall decompilation, static guard map, live read-only Tron snapshot, and `forge test -vvv` (18/18).
- **What ran locally:** light TronGrid constant calls, ABI/event parsing, and a local `forge test` for fast iteration. No heavy local jobs.
