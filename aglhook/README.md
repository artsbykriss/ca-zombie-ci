# AGLHook — deployed despite “must not be deployed”: fork audit of the live ETH/AGL fee hook

**Finding:** ZH4-PASS5 · P5-02 (Tier 2 HIGH) · **Chain:** Ethereum (1) · **Date:** 2026-10-23
**Status:** read-only; PoC **fork-verified only**; **no transaction signed or sent**; no secrets.

---

## 1. TL;DR

| target | live extractable (unprivileged) | why closed | latent risk |
|---|---|---|---|
| **AGLHook** `0xA61d74D6…E0CC` (ETH/AGL v4 pool, ≈ **$1.45 M** pooled) | **$0** | fee/delta math is correct in all four swap shapes on the live PoolManager; every callback is `onlyPoolManager`; the sole `feeExempt` address is operator-gated and only *burns*; `claim()` pays only an immutable wallet; the `int128` casts are SafeCast-guarded by `poolManager.mint` | **P:** none (no owner, no proxy, no setters). **S:** none — the launch LP is locked in the AGL token, so it can only leave via swaps. |

**Total live extractable now: $0** (confidence **high**).
The pooled ≈ $1.45 M is **not** reachable by an unprivileged attacker; it is only reachable by
*selling AGL you already own*, at the hook's 10 % fee.

The premise of the finding — a verified source header that literally reads *“This contract is not
finished and must not be deployed.”* — is **true but stale**. The deployed code already contains the
fixes that header describes: the `feeOnNet` gross-up that closes the exact-output sniper route
(LaunchFee.sol comment), the `openTrading`-gated pool binding (AGLHook.sol `beforeInitialize`
comment), and the router-aware fee exemption (AGLBuyback.sol comment). It is finished code that was
deployed on purpose.

## 2. The finding

`v4-hooks.md` §3② (pass 5) flagged the hook as *“the highest ‘unfinished code + live funds’ signal
in the set”* and asked for a fork test of the two-branch fee. The hook:

- settles a **99 %→10 % decaying buy fee** (flat 10 % sell fee) split across **`beforeSwap`** (when ETH
  is the *specified* side) and **`afterSwap`** (when ETH is *unspecified*),
- grosses up the net side with `LaunchFee.feeOnNet`,
- returns `int128(int256(fee))` deltas and `poolManager.mint`s an ERC-6909 ETH claim to itself,
- has a permissionless `claim()` that pays only the immutable `xautFundWallet`.

Pass 5 could not fork-test it. This subagent does.

## 3. What the hook actually is

ETH/AGL is a Uniswap **v4** pool: `PoolKey = (currency0 = native ETH, currency1 = AGL, fee = 0,
tickSpacing = 60, hooks = AGLHook)`, poolId `0x02a13b05…93bf`. All the token's economics live in the
hook, so the token stays a plain ERC-20. The pool opened one-sided (the entire 1 B supply as AGL) on
**2026-10-01 11:00:11 UTC**; buyers have since swapped in **≈ 282 ETH**, and the hook has paid
**212.1 ETH** of fees to the XAUT fund over 285 claims.

Full mechanism + v4 accounting: [`analysis/mechanism.md`](analysis/mechanism.md).
Live state (every address/role/balance/block): [`analysis/live-state.md`](analysis/live-state.md).

## 4. Live-state assessment (block 26253656 unless noted)

- **Permission bits** — `REQUIRED_FLAGS() = 0x20CC`; `uint160(hook) & 0x3FFF = 0x20CC` ✅
  (`BEFORE_INITIALIZE | BEFORE_SWAP | BEFORE_SWAP_RETURNS_DELTA | AFTER_SWAP | AFTER_SWAP_RETURNS_DELTA`).
  The constructor reverts if the deployed address lacks the bits. **No flag/callback mismatch.**
- **Binding** — `bound = true`, `boundPool = 0x02a13b05…93bf` (recomputed from the key ✅).
  `beforeInitialize` refuses any further pool, and requires `agl.hook() == hook && agl.launchTs() == 0`
  — reproducible only inside `openTrading` (owner-only, one-shot).
- **Callback auth** — `beforeSwap`, `afterSwap`, `unlockCallback`, `beforeInitialize` are all
  `onlyPoolManager`. Direct calls from a fresh address revert.
- **Immutables** — `poolManager = 0x…08A90` (Uniswap v4), `agl = 0x63401cDd…`, `xautFundWallet =
  0x06fbfb28…` (an **EOA**, immutable, no setter).
- **`feeExempt`** — frozen at construction; the deploy calldata shows exactly **one** entry:
  `0x8CCf65a2…bce5` = `AGLBuyback`.
- **`owed` is fully backed** — `owed() == PoolManager.balanceOf(hook, id=0)` **exactly** at the same
  block. The hook holds **0** native ETH; its fee is an ERC-6909 claim.
- **No admin surface** — no `owner()`, no `admin()`, no `paused()`, EIP-1967 impl slot `0x0`.
- **Pool reserves** — liquidity `192469621223142870118663`, single position ticks `[-887156, 171120]`
  minted to the AGL contract (locked) ⇒ **≈ 282.44 ETH + ≈ 115.95 M AGL**, mid ≈ 362,923 AGL/ETH.
  At ETH **$2,402.65** (DefiLlama) ⇒ AGL ≈ $0.006621 ⇒ **TVL ≈ $1.45 M** (pass-5 said $1.43 M).

## 5. What an attacker can / cannot do

**Cannot:**

1. **Skew the fee.** `feeBps(isBuy)` is a pure function of `agl.launchTs()` (write-once, 2026-10-01) and
   `block.timestamp`; both directions are pinned at the 10 % floor. No setter, no storage. `test_4`.
2. **Get a 0-fee swap.** The only `feeExempt` address is `AGLBuyback`, which calls `PoolManager.swap`
   directly; reaching that call needs `buyAndBurn`, which is `isOperator`-gated (sole operator: the
   EOA `0x6979…e119`) and **burns** the AGL it buys. A swap through an attacker-controlled router
   (the PoC `Swapper`) pays the full 10 %. `test_5`, `test_17`.
3. **Exploit the two-callback split.** `ethIsSpecified` and `ethIsUnspecified` are complements, so a
   swap is charged exactly once. All four shapes charge exactly 10 % of the gross ETH leg — asserted
   `gross/10 == fee` in `test_6`–`test_9` and fuzzed in `test_18`/`test_19`.
4. **Abuse the `int128` casts.** `_collect(fee)` → `poolManager.mint` runs first, and
   `SafeCast.toInt128` reverts for `fee ≥ 2¹²⁷`. `test_14` drives `amountSpecified = ±2e39` and the
   swap reverts with `owed`/claim unchanged.
5. **Mint a claim without paying.** The final swap delta always charges the swapper the fee
   (`swapDelta -= hookDelta`), and `owed == ERC-6909 claim` at all times. `test_15`, `test_16`.
6. **Rebind the hook** to a foreign pool, **call a callback** directly, or **redirect `claim()`**.
   `test_12`, `test_3`, `test_11`.
7. **Extract via round-trip.** Buy-then-sell always loses ≈ 2 × 10 % plus price impact. `test_10`.

**Can (only):** buy or sell AGL at the pool's price **minus the 10 % fee** — i.e. lose money.

**P-risk:** the AGL `owner` (`0x9AfDee…`) can transfer/renounce ownership and add buyback operators;
neither touches balances, fees, or the locked liquidity. The hook itself has **no owner and no
upgrade path**. **S (stuck):** none — `claim()` works live (`test_11` moves `owed` to the XAU T fund).

## 6. PoC / fork verification

Foundry project [`poc/`](poc/) — `vm.createSelectFork` against a live Ethereum RPC, **19/19 tests
PASS** against the real deployed `AGLHook` + real v4 `PoolManager`:

```
test_1_permissionBits              test_11_claimOnlyPaysImmutableWallet
test_2_bindingAndImmutables        test_12_cannotRebindHookToForeignPool
test_3_callbackAuth_onlyPoolManager test_13_poolStateSnapshot
test_4_feeBpsIsTenPercentBothWays  test_14_hugeAmountRevertsNoFreeMint
test_5_feeExemptOnlyBuybackAndOperatorGated  test_15_claimFullyBackedByRealEth
test_6_buyExactInput               test_16_tightLimitStillChargesFee
test_7_buyExactOutput              test_17_buybackCallbackNotReachable
test_8_sellExactInput              testFuzz_18_buyFeeAlwaysExactlyTenPercent
test_9_sellExactOutput             testFuzz_19_sellFeeAlwaysExactlyTenPercent
test_10_roundTripAlwaysLosesMoney
```

Key fork numbers (block ≈ 26253620): poolId `0x02a13b05…93bf`; `slot0 =
0x00000000000000000001f419000000000000025a6e4d7cffb7ff13a431bfeaf2`; liquidity
`192469621223142870118663`; PoolManager AGL balance `115970693873967772938360339`. Every swap in
`test_6`–`test_9` asserts the hook's `owed` increased by **exactly 10 % of the gross ETH leg**; the
buy path's live trace shows `beforeSwap → mint(fee) → FeeCharged`, the sell path's shows
`swap → afterSwap → mint(fee)`.

- Local run: [`analysis/local-fork-test.log`](analysis/local-fork-test.log) — 19 passed, 0 failed.
- CI: [`ci-log.txt`](ci-log.txt), run URL(s) in §9.

## 7. Verdict

**E-U = $0, confidence HIGH.** The hook is correctly implemented and hardened; the $1.45 M pool is
guarded by a working 10 % fee. The “not finished / must not be deployed” header is a stale doc
comment — the deployed bytecode is the post-fix version. No unprivileged attacker can skew the fee,
get a 0-fee swap, mint an unbacked claim, or redirect the fee.

Residual/latent risk: **none that is attacker-reachable.** For completeness, the only non-trivial
economic surface is generic MEV around the `AGLBuyback`'s fee-exempt buys (an operator-timed buy
with a `minAglOut` floor) — a sandwich opportunity against the buyback, **not** a protocol drain, and
it is the buyback's own slippage setting that bounds it.

## 8. Methodology & caveats

- Source: Etherscan V2 `getsourcecode` for the hook, the token, the buyback, and the deployed v4
  PoolManager; the hook was compiled with solc 0.8.37 (a specific v4-core), the PoolManager with
  0.8.26 — the fork tests exercise the **deployed** PoolManager, so the semantics are what matter.
- All reads at explicit blocks; all exploits attempted on a **local fork only**.
- **Caveats:** (a) the exact split of the PoolManager's AGL balance between this pool and the handful
  of other AGL pools opened at launch is inferred from the single-position reserve formula
  (≈ 21 k AGL of 115.97 M is elsewhere) — it does not change any conclusion; (b) ETH price is
  point-in-time DefiLlama; (c) the buy fee's 99 %→10 % decay window is historical (launch 2026-10-01);
  the fork tests validate the current 10 % floor.
- Negative results (do not re-check): fee-exempt path (operator-gated + burns), int128 overflow
  (SafeCast-guarded), pool rebinding (gated), callback auth (`onlyPoolManager`), `claim()`
  redirection (immutable), JIT/LP-fee capture (`lpFee = 0`), round-trip (loses money).

## 9. Files

| path | what |
|---|---|
| `README.md` | this report |
| `summary.json` | machine-readable summary |
| `analysis/live-state.md` | every address/role/balance/block |
| `analysis/mechanism.md` | fee/delta math + v4 accounting + why it is safe |
| `analysis/decode_pool.py` | slot0/reserve decoder (no secrets) |
| `analysis/read_state.sh` | reproducible read-only snapshot (env RPC) |
| `analysis/local-fork-test.log` | local 19/19 run |
| `poc/` | Foundry project (`src/`, `test/`, vendored `lib/forge-std`) |
| `ci-out/`, `ci-log.txt` | CI results + URL |
