# AGLHook — fee / delta mechanism, and why it is not exploitable

All line references are to the verified source of `0xA61d74D6…E0CC` (`src/AGLHook.sol`,
`src/LaunchFee.sol`) and to the deployed Uniswap v4 PoolManager `0x…08A90`
(`src/PoolManager.sol`, `src/libraries/Hooks.sol`, solc 0.8.26).

## 1. What the hook is allowed to do

`AGL_HOOK_FLAGS = BEFORE_INITIALIZE | BEFORE_SWAP | BEFORE_SWAP_RETURNS_DELTA | AFTER_SWAP |
AFTER_SWAP_RETURNS_DELTA` = `0x20CC`. The deployed address carries exactly those bits
(`uint160(hook) & 0x3FFF == 0x20CC`, asserted in `test_1`). The constructor also reverts if the bits
are wrong. So v4 calls `beforeInitialize`, `beforeSwap`, `afterSwap` — and nothing else. The other
`IHooks` functions are `pure` stubs whose flags are unset.

The hook **can alter the swapper's BalanceDelta** (the two `…RETURNS_DELTA` bits). That is the only
power that matters, and it is used solely to take a fee.

## 2. Fee schedule

`feeBps(isBuy)` = `LaunchFee.buyFeeBps(agl.launchTs(), block.timestamp)` for buys, `LaunchFee.sellFeeBps()`
for sells. `launchTs = 1790852411` (2026-10-01 11:00:11 UTC) is **write-once** (guarded by
`if (launchTs != 0) revert AlreadyLaunched()` in `AGL.openTrading`). Now (2026-10-23) both directions
are at the floor: `feeBps(true) == feeBps(false) == 1000` (**10 %**), asserted in `test_4`.

`LaunchFee` helpers:
- `feeOn(amount, bps)   = amount * bps / 10_000`      (gross → fee)
- `feeOnNet(net, bps)   = net * bps / (10_000 - bps)` (net → fee, so fee = 10 % of gross)

## 3. Two-callback settlement

`isBuy = params.zeroForOne` (currency0 is ETH, so ETH→AGL is zeroForOne). `exactInput =
params.amountSpecified < 0`. Exactly one of the two branches fires per swap:

| shape | ETH side | charged in | formula |
|---|---|---|---|
| buy, exact-in  | specified | `beforeSwap` | `feeOn(ethIn)` |
| sell, exact-out| specified | `beforeSwap` | `feeOnNet(ethOut)` |
| buy, exact-out | unspecified | `afterSwap` | `feeOnNet(ethIn)`, `ethIn = \|swapDelta.amount0()\|` |
| sell, exact-in | unspecified | `afterSwap` | `feeOn(ethOut)`, `ethOut = swapDelta.amount0()` |

`ethIsSpecified` and `ethIsUnspecified` are logical complements, so a swap is never charged twice and
never skipped. The `afterSwap` branch reads the ETH leg off the **settled** delta, not
`amountSpecified` (which denominates AGL in those two shapes) — the correct choice.

## 4. How v4 applies the returned delta (deployed PoolManager)

`mint(to,id,amt)` → `_accountDelta(currency, -(amt.toInt128()), msg.sender)` **and** `_mint(to,id,amt)`.
So `_collect(fee)` debits the hook's currency delta by `fee` and gives it `fee` ERC-6909 ETH tokens.

The hook then returns a delta:
- `beforeSwap` → `toBeforeSwapDelta(int128(fee), 0)` ⇒ `hookDeltaSpecified = fee`; the PoolManager
  sets `amountToSwap += fee` and, after `afterSwap`, computes `swapDelta = rawSwapDelta - hookDelta`
  with `hookDelta = (fee, 0)`.
- `afterSwap` → returns `int128(fee)` as the *unspecified* delta; `Hooks.afterSwap` maps it to
  `amount0` (ETH) for both afterSwap shapes and again does `swapDelta -= hookDelta`.

Net for every shape: the hook's currency delta is `-fee (mint) + fee (hookDelta) = 0`, the swapper's
delta includes `-fee`, and the hook ends holding `fee` ERC-6909 ETH tokens. **The hook's ERC-6909
balance therefore always equals `owed`** — verified live: `owed() == PoolManager.balanceOf(hook, 0)`
at block 26253656 (`test_15`), and after every swap in `test_6`–`test_9`.

## 5. The int128 casts

`beforeSwap` returns `toBeforeSwapDelta(int128(int256(fee)), 0)` and `afterSwap` returns
`int128(int256(fee))`. If `fee >= 2**127` these truncate to a **negative** delta, which would credit
the swapper instead of charging them. **It is unreachable:** `_collect(fee)` runs first and calls
`poolManager.mint`, whose `SafeCast.toInt128(uint256)` reverts for `x >= 1 << 127`
(`if (x >= 1 << 127) SafeCastOverflow.selector.revertWith();`). `test_14` drives
`amountSpecified = ±2e39` (fee > 2¹²⁷) on the live PoolManager and the swap reverts; `owed` and the
ERC-6909 claim are unchanged.

`afterSwap`'s `int128 ethLeg = swapDelta.amount0()` is already `int128`; its negation is bounded by
the pool's ETH (≤ 282 ETH), nowhere near `type(int128).min`.

## 6. The `sender` in `feeExempt[sender]`

`Hooks.beforeSwap/afterSwap` pass `msg.sender` of `PoolManager.swap`. The only exempt address is the
`AGLBuyback` contract, which calls `PoolManager.swap` **directly** from its own `unlockCallback`
(its own comment documents exactly this: an exempt wallet routed through a router would *not* be
exempt). Reaching that callback requires `AGLBuyback.buyAndBurn`, which is
`if (!isOperator[msg.sender]) revert NotOperator()` — and the only operator is the EOA
`0x6979…e119`. `buyAndBurn` also **burns** the AGL it buys, so even an operator gains nothing.
`test_5` / `test_17` confirm the exemption is unreachable for an unprivileged caller, and a swap
sent through an attacker-controlled router (the test `Swapper`) pays the full 10 %.

## 7. Residual checks (all negative)

- **Pool identity** — `_requireBoundPool` requires `key.toId() == boundPool`; `beforeInitialize`
  refuses any pool once bound, and requires `agl.hook() == hook && agl.launchTs() == 0` (only
  reproducible inside `openTrading`). `test_12`: initialising a foreign pool with this hook reverts.
- **Callback auth** — `beforeSwap`/`afterSwap`/`unlockCallback`/`beforeInitialize` are all
  `onlyPoolManager`. `test_3`: direct calls from a fresh address revert.
- **`claim()`** — permissionless but pays only the immutable `xautFundWallet`; reads the amount from
  `owed` and the destination from immutables, never from calldata. `test_11`: caller receives 0.
- **Reentrancy** — the PoolManager lock (`unlock` reverts `AlreadyUnlocked`) prevents nested unlocks.
- **JIT / LP fees** — pool `lpFee = 0`; there is no LP fee to capture. The launch LP position is
  locked in the AGL token (no function can move it), so the existing liquidity cannot be pulled.
- **P-risk** — the hook has no owner, no proxy, no setters; `AGL.owner` can neither mint, pause, nor
  re-open the pool; the buyback owner can only add operators who can only burn AGL. No privileged
  path to value.

## 8. Conclusion

The fee/delta arithmetic is **correct in all four swap shapes on the live pool** (fee is exactly 10 %
of the gross ETH leg, asserted in `test_6`–`test_9` and fuzzed in `test_18`/`test_19`). The
"must not be deployed" header is a stale documentation artefact: the deployed code already contains
the fixes it describes (the `feeOnNet` gross-up that closes the exact-output sniper route, the
`openTrading`-gated binding, the router-aware fee exemption). **No unprivileged extraction path was
found. E-U = $0.**
