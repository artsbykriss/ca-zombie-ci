# univ4-hook-harbinger checklist — Fables (Robinhood Chain, 4663)

Targets (all verified non-proxy, immutable, solc 0.8.26):

| hook | address | runtime | pools | role |
|---|---|---|---|---|
| FablesRamp | `0x08E52564Bad99E05a694b4809F397edcA417A080` | 32,997 B | 37 | flat-fee + poke, ERC20 pools |
| FablesRWA | `0x5Eb87F69bE00Df39981622Fd60A8De4b7837e080` | 42,039 B | 11 | calendar/session fee, ERC20 |
| FablesRampETH | `0x594e8e6281eDf2d363a0293a50004Cf868E7a080` | 34,326 B | 9 | flat-fee + poke, NATIVE currency0 |
| FablesRWAETH | `0xca89f079AF00f752bfD3C345358Dc38d4d73e080` | 43,368 B | 2 | calendar fee, NATIVE |
| 8× per-pool FablesRWA | `0x66622f77…`, `0xa0e8fbff…`, `0x79576fba…`, `0x70a9a884…`, `0x67d86050…`, `0xb608a787…`, `0xa4570c37…`, `0x8af95932…` | 31–36 KB | 1 each | older revisions |
| FablesRampETH **OLD** | `0x06a889870C8f83640D6816319f72e2aA579b6080` | 28,189 B | 1 | **pre-fix revision** |

Shared: PoolManager `0x8366a39CC670B4001A1121B8F6A443A643e40951` (stock v4-core, sources diff-equal to the
vendored `lib/v4-core` the hooks were compiled against) · AccessManager `0xA362D98B33A7bb5B5E2180a05f995A70FB404f30`
(OpenZeppelin AccessManager, verified) · claim-fee sink `0x9F887B9930E9e716286333Bd8e291f64a8710F6f`
(Safe v1.4.1, 3 owners / threshold 2).

---

## 1) Address permissions and deployed identity

- Permission bits decoded from the hook addresses (low 14 bits): all three main hooks end in `…a080`/`…e080`
  → `0x2080` = **bit 13 `beforeInitialize` + bit 7 `beforeSwap`**, nothing else. No `*ReturnDelta` bits.
- Implemented callbacks (`_hookPermissions`) = `beforeInitialize`, `beforeSwap`. **Match.** `Hooks.validateHookPermissions`
  runs in the constructor, so the CREATE2-mined address cannot drift from the callback set.
- `beforeSwap` returns only `(selector, BeforeSwapDeltaLibrary.ZERO_DELTA, fee | OVERRIDE_FEE_FLAG)` — no delta flags,
  no custom accounting in the swap path. Verified on-chain: `beforeSwap` is `onlyPoolManager` (test T11).
- No proxies anywhere in the hook set (`Proxy: 0` on every verified record); no EIP-1967 admin slot; no upgrade path.
- The 8 single-pool FablesRWA instances and the old FablesRampETH are **older revisions**, not patched copies
  (see §7). They are immutable too — drift cannot be fixed in place.

## 2) Authentic PoolManager, forged context

- `unlockCallback` is `if (msg.sender != address(poolManager)) revert NotPoolManager();` — fork-verified: a fresh
  EOA calling it reverts (T11).
- `beforeSwap` / `beforeInitialize` are `onlyPoolManager` — fork-verified revert (T11).
- `FablesNativeETH.receive()` is allowlisted to the PoolManager — fork-verified revert from a stranger (T11).
- `hookData` is ignored by the hook entirely (no callback consumes it).
- `sender` is never treated as the economic user: deposits pull principal from `msg.sender`, withdrawals burn
  `msg.sender`'s ERC-6909 receipts, `_syncRange` uses `user = address(this)` with `liquidityDelta == 0` (no principal).
- A hostile pool cannot be created: `beforeInitialize` + `_checkKey` both require `maxFee[poolId] != 0`, and
  `maxFee` is written only by `restricted` `setPoolConfig`; `_checkOwnPool` refuses a key whose `hooks` is not the
  calling hook. Fork-verified: deposit with a foreign `hooks` address and with an unconfigured key both revert (T12).
- Callback argument/return encoding matches v4-core (the vendored `IHooks`/`PoolKey`/`BalanceDelta` sources are
  byte-identical to the deployed PoolManager's own copies).

## 3) Pool isolation and lifecycle

- State keys: `_ranges[rangeId]`, `_rangeKeys[rangeId]`, `_positions[rangeId][owner]`, `pokeOf[poolId]`,
  `maxFee[poolId]`, `_asym[poolId]`, `_poolClaimFee[poolId]`; fee pots are keyed by **currency** only
  (`distributorOwed`, `claimFeeOwed`) — shared across pools on the same hook (documented).
- `rangeId = keccak256(poolId, tickLower, tickUpper)`; the stored descriptor is written on first deposit and the
  withdraw path re-derives the same id from the caller's key — the key is bound to the id by the hash.
- `donate` is an independent accounting ingress with **no hook callback** (`beforeDonate`/`afterDonate` bits are
  off). Fork-verified: a 100 USDG donation leaves the donor and is not recoverable by any permissionless call (T7).
- Repeated/attacker-controlled initialization is impossible (config gate + v4 one-shot `initialize`).
- Zero-liquidity modifications: `_syncRange` (delta 0) is a collect-only touch; the zero-amount doors that used to
  be free syncs (`transfer`/`transferFrom`/`unstake` with 0) now revert (`ZeroShares`); fork-verified for `unstake` (T5).
- Partial/full removal and pause: `withdraw` is deliberately **not** pausable — fork-verified under a real PAUSER
  pause (role 4 impersonated): `deposit` reverts `LedgerPaused` while `withdraw` still succeeds (T14).

## 4) Deltas, custom accounting and settlement

- The hook takes **no deltas**; all principal/fee settlement goes through `IPoolManager.unlock` with either
  `Action.MODIFY` (modifyLiquidity + fee credit + principal resolve) or `Action.PAYOUT` (burn ERC-6909 claim + take).
- Fee claims are minted (`poolManager.mint`) for the full collected fee and split into: staked cut → `distributorOwed`,
  claim-fee cut → `claimFeeOwed`, remainder → `accFee{0,1}X128` (unstaked holders). `payout` burns claims and `take`s
  real tokens, so **a payout can never exceed the claims the hook actually holds** (burn reverts).
- Live backing check (all 13 hooks × all currencies): `hook ERC-6909 claims >= claimFeeOwed + distributorOwed`
  for every pair — 0 under-backed pairs (T10 + `analysis/value_enum.json`).
- `_resolvePrincipal` for a negative delta does `sync` → `settle{value:}` (native, prepaid by the depositor with
  `msg.value >= amount0Max`) or `safeTransferFrom(user, poolManager, owed)`; for a positive delta `take(currency, user, …)`.
  `user` is `msg.sender` (deposit), `address(this)` (delta-0 sync) or the caller-supplied `to` (withdraw) — and
  v4's amount math guarantees a removal has a non-negative principal, so the `safeTransferFrom(user, …)` branch is
  unreachable with a third-party `to`.
- `_checkBound` enforces the caller's per-currency ceiling (deposit) / floor (withdraw); fork-verified that a
  deposit that costs more than the stated ceiling reverts `PrincipalAboveMax`.
- int128 casts: `feesAccrued` is cast from int128 (non-negative by construction); `principal` casts widen before
  negating. `settleUser`'s `uint128(...)` narrowing is bounded by the telescoping argument in-source (a holder can
  never be credited more than the range collected) — documented, not attacker-reachable at these denominations.

## 5) Dynamic fees, JIT penalties and time state

- Fee resolution: `_resolveFee` = autonomous fee + direction premium, overridden by a TTL-bounded poke, then floored
  at `max(configuredFloor, min(preFee, cap)/2)` and clamped to `cap <= ABSOLUTE_MAX_FEE` (50,000 pips = 5% on the
  main hooks; fork-verified `cap <= ABSOLUTE_MAX_FEE <= 10%`, T16).
- `pokeFee` (role 1, FEE_POKER) is the only hot lever; it is bounded per side by `[floor, cap]`, expires in ≤72 h,
  and is `restricted` (fork-verified revert for a fresh caller, T4). The current revision also clamps the discount
  floor against the **premium-inclusive capped** pre-poke fee (`preFee`), so the 50% discount ceiling holds even
  with a large configured premium — the older revisions use the raw `base` (see §7).
- No oracle: the RWA curve is `block.timestamp` + a fixed market calendar; no external price input, so no
  stale/manipulable oracle surface. `MAX_DESCENT_WINDOW = 6 h` bounds the opening descent; `descentWindow == 0`
  with a non-zero `closedSpike`/`spikeMult` is refused (current revision).
- JIT: no JIT penalty exists in this design and none is needed — fees are flat/session-based, not range-order-based.

## 6) Math, shared custody, callback liveness

- Shared custody: the fee pots are keyed by currency and shared across all pools of a hook; the live backing check
  (above) shows every pot is covered. Un-drawn rounding dust (sub-unit per holder per collection) stays as
  hook-held claims with **no redemption path** — an accounted-for-yet-unreleasable class (S, economically inert).
- The hook's v4 positions are owned by the hook (`modifyLiquidity` sender); only the ledger's `deposit`/`withdraw`
  can move them, both `nonReentrant` and gated by ERC-6909 receipt balances.
- Reentrancy: every external value-moving entry point carries OZ `ReentrancyGuardTransient`; nested
  `poolManager.unlock` reverts (`Lock.isUnlocked()` guard in the deployed PoolManager); token callbacks during
  `take`/`safeTransferFrom` cannot re-enter (`nonReentrant`) nor reach `unlockCallback` (`msg.sender` check).
- Loops are bounded: `claimFeeFor` walks at most `MAX_CLAIM_FEE_WALK = 32` entries; `_setSinks` iterates a
  caller-supplied array (admin path only).
- Native sweeps wrap ETH→WETH inside the sweep call and forward; an unset distributor/recipient parks the accrual
  instead of reverting, so a misconfigured sink cannot block `_settleSinks` rotations (current revision).
- Forced fee-sync griefing: fork-verified that repeated 1-wei deposits into a *foreign* range cost the attacker
  (420,470 wei for 5 syncs) and yield nothing (T15); the only documented edge is front-running a scheduled
  claim-fee rate cut, which moves revenue toward the protocol, never to the attacker.

## 7) Version drift (older revisions — the only place a defect still exists)

Code-only diffs against the current revisions (comments stripped) show the older hooks are earlier iterations:

| difference | current revision | older revision | security effect |
|---|---|---|---|
| `_refundNative` | refunds `balance - preCallBalance` (delta) | **refunds `address(this).balance` in full** | **any ETH park is claimable by any depositor** (fork-proven, T8) |
| `_checkPayoutTarget` | refuses `to == hook` / `to == PoolManager` on withdraw/claimFees | absent | users can silently burn or park their own payout (self-inflicted) |
| `_checkSinkTarget` | refuses PoolManager as an admin sink | absent | admin misconfiguration risk only |
| claim fee | per-pool rate + history, `min`-over-window | hook-wide single rate | revenue attribution only |
| poke discount floor | measured vs capped, premium-inclusive `preFee` | measured vs raw `base` | FEE_POKER can cut deeper (privileged only) |
| per-pool pause | `pausePool`/`setPoolPaused` | hook-wide only | blast radius only |
| native claim-fee sweep | `FablesNativeETH._sweepClaimFee` wraps to WETH | not overridden → raw `take(native)` to the sink | liveness: reverts for an ERC20-only sink |
| `validateDistributor` | rejects EOAs (`code.length`) | relies on the ABI decoder | error-surface only |
| FF-sink guard in `sweepDistributor` | `distributorFF != 0 &&` | missing | inert while `ffFeeSink == 0` |

## Verdict

No unprivileged extraction path exists in the current revisions. The single live defect is the **old
FablesRampETH's full-balance refund**, which converts any ETH that lands in that hook into a race prize for any
depositor — currently **$0** because its balance is 0 wei. Every restricted function maps to a real role
(0/1/2/4/9); there is **no PUBLIC_ROLE mapping on any target** (full selector sweep, `analysis/am_role_sweep.json`).
