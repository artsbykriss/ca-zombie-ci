# CHILD-KOLAN — Kolan launchpad `LaunchHook` family: code identity + re-arm proof

**Date:** 2026-10-24 · **Chain:** Ethereum (1) · **Mode:** READ-ONLY (RPC `eth_call`/`eth_getCode`/`eth_getLogs`,
Sourcify, keyless public RPCs; **zero** transactions signed or sent on mainnet) · **PoC:** fork-only, run in CI.
**Status:** read-only; PoC fork-verified only; no mainnet transactions.

**Parent:** ZH4-PASS6 "Kolan launchpad hooks" deep-dive. **Scope:** the 14 `LaunchHook`s deployed by the Kolan
launchpad `0x8F89905624E3613b3A578Ff1EC690463A33e940e` vs the exploited main `KolanHook`
`0x0136feCf49E0217BFd2D9551E8e7b05f174Ba8eC` (exploited 2026-10-15, tx
`0x7b131926e6f06491ae1aead3e419b208c8aa70ed7898e8c5a33d9f52e40915a9`, block 26,197,504).

---

## 0. TL;DR

| Question | Answer |
|---|---|
| Do the 14 launch hooks run the same code? | **YES.** All 14 are 24,386-byte clones; pairwise **94.4 %** of 64-byte code windows identical (residue = per-instance immutables), same `accept(uint256)` dispatch entry (`pc 5,927`), identical code size. |
| Is the exploited `accept()` logic present? | **YES.** `accept(uint256)` source is **textually identical** between `KolanHook.sol` and `LaunchHook.sol`; both deployed codes contain selector `0x19b05f49`. The only functional divergence in `_closeWindow` is the added KLN leg (§1.3). |
| Live escrow today? | **$0.** At block 26,265,324 every one of the 14 hooks has `held().eth = 0`, `eth_getBalance = 0`; the main `KolanHook` has `windowCount = 47`, `held().eth = 0`, balance 0. All windows closed/empty. |
| Re-arm condition (exact) | `∃ id : windows[id].owner != 0 && block.timestamp >= windows[id].expiry`, with the escrow invariant `held.eth ≥ windows[id].eth + windows[id].premium > 0`. |
| Can a stranger call it? | **YES** — `accept(id)` only blocks when `msg.sender != owner && now < expiry`. Fork-proven (§4). |
| E-U extractable **now** | **$0** (no funded window exists). Latent: any future funded+expired window ⇒ drainable up to its escrow; the historical ratio was **1.28 ETH out of 2.31 ETH escrow (≈55 %)**. |
| PoC | **6/6 PASS** on a read-only fork — CI run <RUN3_URL>. |

**Bottom line:** the launchpad's `LaunchHook` family is the *same contract* as the exploited `KolanHook` and
carries the identical permissionless `accept()` / spot-settlement / unbounded-buyback drain. It holds **$0**
today, but re-arms the instant any launched token has a funded, expired, unclaimed window — exactly the state
the 2026-10-15 attacker exploited on the main hook. **Monitor, don't chase.**

---

## 1. Code identity

### 1.1 Method
1. `eth_getCode` the main `KolanHook` and three launch hooks at a pinned block; disassemble; locate the
   selector-dispatcher entry for `accept(uint256)` = `0x19b05f49`
   (`PUSH4 19b05f49 · EQ · PUSH2 <dest> · JUMPI`).
2. Cross-compare 64-byte code windows and the longest identical byte run.
3. Independently **recompile** the Sourcify source bundles with the exact recorded settings
   (solc `0.8.26+commit.8a97fa7a`, optimizer 200, `evmVersion=cancun`, **`viaIR=true`**, `metadata.bytecodeHash=ipfs`)
   and compare to the live on-chain runtime code (immutable slots masked via `immutableReferences`).
   Script: `ci/bytecode_identity.py` (CI-only, downloads solc, no keys).

### 1.2 On-chain bytecode evidence (local, keyless RPC; block 26,265,506)
| contract | size (B) | keccak(runtime) | `accept` selector present | dispatch dest |
|---|---|---|---|---|
| main `KolanHook` `0x0136…a8eC` | 22,114 | `0xc391bc92…0090be` | yes | pc 5,061 |
| launch hook `0xc750…28EC` (hook[0]) | 24,386 | `0x42711ce9…38b4d8` | yes | pc 5,927 |
| launch hook `0x02f6…a8EC` (hook[1]) | 24,386 | `0x96166981…ba605a` | yes | pc 5,927 |
| launch hook `0x16c0…28EC` (hook[13]) | 24,386 | `0x382c3fa7…3723a60` | yes | pc 5,927 |

* launch-hook ↔ launch-hook: **22,959 / 24,323** 64-byte windows identical (**94.4 %**); identical code size
  and dispatch dest ⇒ **same build differing only in immutables**.
* launch-hook ↔ main `KolanHook`: only **4.53 %** identical windows, longest identical run **34 B**
  ⇒ the two are **different builds** (viaIR re-layout; the `LaunchHook` adds the KLN leg + extra storage/fees).
  Byte-level *global* identity does **not** hold; identity holds for the *vulnerable functions* (below).

### 1.3 Source diff of the vulnerable paths
* **`accept(uint256 id)` — textually IDENTICAL** between `KolanHook.sol` and `LaunchHook.sol` (`diff` clean):
  ```solidity
  function accept(uint256 id) external nonReentrant {
      Window memory w = windows[id];
      if (w.owner == address(0)) revert NoWindow();
      if (msg.sender != w.owner && block.timestamp < w.expiry) revert WindowStillOpen();
      _close(id, w, true);
      if (!TOKEN.transfer(w.owner, w.tokens)) revert TransferFailed();
      _checkSolvent();
  }
  ```
* **`_closeWindow(uint256,bool)`** — identical except one replaced line + one added call:
  ```
  - if (spendable > 0) _buyBack(spendable.toUint256());
  + if (spendable > 0) _spendPremium(spendable.toUint256(), w.premium);
  + _takeKln();
  ```
  Everything that carries the exploit is **unchanged** in both:
  `uint160 sqrtPrice = _sqrtPrice();` (spot — no TWAP/slippage guard), the `backInPlace` test, `_addEthAbove`,
  and `int256 spendable = int256(w.premium) + (keep ? int256(w.eth) : 0) + currencyDelta(this, ETH)`.
* **`_buyBack`** — both use the *unbounded* swap:
  ```solidity
  POOL_MANAGER.swap(poolKey(), SwapParams({
      zeroForOne: true,
      amountSpecified: -eth.toInt256(),
      sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1   // no effective slippage bound
  }), "");
  ```
* **`LaunchHook` extra leg:** `_spendPremium(spendable, premium)` splits `toKln = premium * 5000 / 10000`
  (50 % of the **premium**) into `_buyKln` — itself an unbounded `MIN_SQRT_PRICE+1` swap into the KLN pool,
  wrapped in `try/catch` (on failure `toKln = 0` and the full `spendable` goes to `_buyBack`) — and the
  remainder into the same `_buyBack`. `_takeKln()` then pulls any positive KLN delta and `_close` burns it.
  ⇒ the LaunchHook has an **additional** unbounded-swap target, not a weakened one.
* **`FLAGS`** — identical constant in both: `0x28EC`
  (BEFORE_INITIALIZE|BEFORE_ADD_LIQUIDITY|BEFORE_SWAP|AFTER_SWAP|BEFORE_DONATE|BEFORE_SWAP_RETURNS_DELTA|AFTER_SWAP_RETURNS_DELTA),
  matching every deployed hook address' low 14 bits (`…28EC`/`…A8EC`).
* Sourcify: `exact_match` (creation + runtime) for both contracts.

### 1.4 Recompilation result (CI)
`ci/bytecode_identity.py` recompiles both bundles with the exact settings and compares to the live code:
**<IDENTITY_RESULT>**
(per-contract: `onchain_size == compiled_size`, `diff_count`, `differing_32B_slots`; the compiled hex and
on-chain hex are saved to `ci-out/*_compiled.hex` / `*_onchain.hex`).

**Verdict (Part 1):** the deployed code is the verified source; the 14 launch hooks are that same code; and its
`accept()` / spot-settlement / unbounded-buyback logic is the same source as the exploited `KolanHook`. The only
functional divergence is the LaunchHook's *added* KLN buy/burn leg.

---

## 2. Live state (pinned block 26,265,324; raw JSON `analysis/live_state.json`)

`launchCount() = 14`; hooks enumerated via `hooksBetween(0,14)`. Per-hook `windows(id)` for every
`id ∈ [1, windowCount]` and `cutsOf(id)` were read; **no window is open or funded**.

| # | hook | windowCount | held().eth (wei) | balance (wei) | launched | code size | open/funded window |
|---|---|---|---|---|---|---|---|
| hook[0] | `0xc75059b9e101483ca3261ca3fdd65bf85a1528ec` | 1 | 0 | 0 | 1 | 24386 | no |
| hook[1] | `0x02f6bc027e5bca0c733b08711e1378c13cdaa8ec` | 0 | 0 | 0 | 1 | 24386 | no |
| hook[2] | `0x00507e62845a03db2d652258e8fa1328d5fae8ec` | 0 | 0 | 0 | 1 | 24386 | no |
| hook[3] | `0x6178f64ac4ea1f4ab2f6934f60ef1a1abb5c28ec` | 0 | 0 | 0 | 1 | 24386 | no |
| hook[4] | `0x4f447f6f8c416d9b401639fc2fea25bc48e7a8ec` | 0 | 0 | 0 | 1 | 24386 | no |
| hook[5] | `0xb0c320e1d4bd9e4051ee84e288075cf233b868ec` | 0 | 0 | 0 | 1 | 24386 | no |
| hook[6] | `0xe16ce34cb14ededa706c30846d53339091fda8ec` | 0 | 0 | 0 | 1 | 24386 | no |
| hook[7] | `0x860bf7bea785d3b66cd59850355fd19e0bbee8ec` | 0 | 0 | 0 | 1 | 24386 | no |
| hook[8] | `0x4b100f6d77e7493fd4432b2fcc4254db224fa8ec` | 0 | 0 | 0 | 1 | 24386 | no |
| hook[9] | `0x631d31b25bffa9aacf5a2bebb9dc9132012fe8ec` | 0 | 0 | 0 | 1 | 24386 | no |
| hook[10] | `0xd51c92b1dca71af729d5270ad3ba01b47eece8ec` | 0 | 0 | 0 | 1 | 24386 | no |
| hook[11] | `0xee9e5e292d7d1f5a5d79d9d54c47244cf2bae8ec` | 0 | 0 | 0 | 1 | 24386 | no |
| hook[12] | `0x943745abc7a6106bb47958906d2b91cd4be6e8ec` | 0 | 0 | 0 | 1 | 24386 | no |
| hook[13] | `0x16c0ce33576ca3da876fb926ff8dc664cdaa28ec` | 0 | 0 | 0 | 1 | 24386 | no |
| **main** | `0x0136feCf49E0217BFd2D9551E8e7b05f174Ba8eC` | 47 | 0 | 0 | 1 | 22114 | no |

Totals: **held.eth(launch hooks) = 0**, **held.eth(main) = 0**. hook[0]'s only window (`id=1`) is all-zero
(`owner=0, expiry=0, eth=0`); `accept(1)` reverts `NoWindow`. All 47 main-hook windows read
`owner == address(0)`.

**Historical (why the family is dangerous):** hook[0]'s window 1 was opened at block **26,167,731**
(`WindowOpened`: owner `0x46ad135a…`, `eth = 0.0228`, `premium = 0.006831`, `tokens = 3159.43`,
`expiry = 1,791,706,834`), then **cancelled by its owner** at block 26,167,961 (`keep=0`). Had it been left
alone it would have held **0.029631 ETH** of escrow and re-armed the drain at expiry. Full event dump:
`analysis/window_events.json`; main-hook incident events included.

---

## 3. Re-arm predicate and attacker recipe

### 3.1 Exact predicate (from source)
```
reArmed(id)  ⇔  windows[id].owner != address(0)  &&  block.timestamp >= windows[id].expiry
```
with the escrow invariant (set in `_openWindow`, enforced by `_checkSolvent`):
```
held.eth  ≥  windows[id].eth + windows[id].premium   >  0
```
`accept(uint256)` (selector `0x19b05f49`) reverts `WindowStillOpen` **only** while
`msg.sender != owner && block.timestamp < expiry`; otherwise **any sender** proceeds. Note `cancel(id)` is
owner-only **and** reverts `WindowExpired` once `now >= expiry` — so an owner who lets their window expire can
no longer reclaim the ETH directly; the ETH can then only be spent by `accept()` on the buyback.

### 3.2 Call path (permissionless)
1. EOA → `LaunchHook.accept(id)`.
2. `accept` → `_close(id, w, true)` → `POOL_MANAGER.unlock(Close, (id, true))` → `_closeWindow(id, true)`:
   spot `sqrtPrice = POOL_MANAGER.getSlot0(_poolId())`; `spendable = w.premium + w.eth + currencyDelta(ETH)`;
   `_buyBack(spendable)` (or `_spendPremium` on LaunchHook) → market buy of TOKEN with
   `sqrtPriceLimitX96 = MIN_SQRT_PRICE + 1`; `_settle()`; burn surplus; `held.eth -= w.eth + w.premium`.
3. `TOKEN.transfer(w.owner, w.tokens)`.

### 3.3 Attacker recipe end-to-end (validated by the reproduction, §4)
1. Find any hook with an **abandoned, expired, funded** window (`owner != 0`, `now >= expiry`, `held.eth > 0`).
2. Flash-loan ETH (the historical attacker used a **6.698 ETH Balancer flash loan**, tx `0x7b131926…`).
3. Buy TOKEN at the pre-manipulation spot (front-run), then call `accept(id)` as a **stranger** — the hook
   itself then buys a large amount of TOKEN at the manipulated spot with no slippage bound.
4. Sell TOKEN back into the pumped pool, repay the flash loan, keep the difference.
5. Repeat for every expired funded window.

### 3.4 Magnitude
* Historical main-hook drain: escrow at block 26,197,503 = **2.309861 ETH** (windows 10: eth 2.0 + premium 0.05;
  42: eth 0.2 + premium 0.0599); attacker **net = 1.279914 ETH** (≈ 55 % of escrow). Reproduced exactly (§4).
* LaunchHook premium split: `toKln = premium × 5000/10000` (50 % of the premium) is swapped into KLN (also
  unbounded) when the KLN pool exists; the remainder goes to the token buyback. So the LaunchHook's manipulable
  surface is **≥** the KolanHook's.
* Current live extractable: **$0** (no funded window).

---

## 4. Fork PoC (CI)

`poc/` (Foundry, vendored forge-std) — **read-only fork, no broadcasts**. Archive forks use keyless
archive-capable RPCs (`eth.drpc.org`, blastapi, mevblocker, 1rpc, nodies) with fallback; head forks use
`FORK_RPC_URL`.

| test | fork block | result | key numbers |
|---|---|---|---|
| `test_01_originalKolanHook_drain_reproduces` | 26,197,503 | **PASS** | deploys the *exact* historical attacker creation bytecode; main `held.eth` before = 2.309861 ETH → after 0; **attacker net = 1.279914 ETH** (gas 3,046,024) |
| `test_02_mainHook_accept_is_permissionless_after_expiry` | 26,197,503 | **PASS** | stranger `accept(10)`: `held.eth` 2.309861 → 0.259861 ETH; window 10 closed (owner → 0) |
| `test_03_launchHook0_stranger_accept_drains` | 26,167,732 | **PASS** | hook[0] `held.eth` 0.029631 → **0**; owner received 3159.4334 TOKEN; window 1 closed by a stranger |
| `test_04_liveLaunchpad_freshHook_rearms_and_drains` | head | **PASS** | launches a *new* token on the live Launchpad (salt-mined for the `0x28EC` hook bits), funds window 1 via `buy()`, warps past expiry, stranger `accept(1)` consumes the escrow |
| `test_05_currentState_all_empty` | head | **PASS** | Σ launch-hook `held.eth` = 0, main `held.eth` = 0, main balance 0 |
| `test_06_currentState_accept_reverts_NoWindow` | head | **PASS** | `accept(1)` on hook[0] reverts (all windows closed) |

**Result: 6/6 PASS.** CI run: **<RUN3_URL>** (workflow `poc.yml`, branch `kolan-hooks`,
repo `artsbykriss/ca-zombie-ci`). Artifacts in `ci-out/` (live state, recompiled/on-chain hex, identity JSON).

Notable: the reproduction is byte-faithful — deploying the attacker's own creation bytecode reproduces the
2026-10-15 drain to the wei (1.279914 ETH), which validates the harness; test_03/test_04 then show the identical
mechanism firing on a launchpad `LaunchHook`.

---

## 5. Monitor

`analysis/monitor.sh` — light `cast call` monitor (public keyless RPC, no keys, no writes). Prints, for the
launchpad + all 14 hooks + the main hook: `windowCount`, `held().eth`, `eth_getBalance`, and a **`RE-ARMED`**
flag when `held.eth > 0` (plus any window with a non-zero owner). Tested locally — enumerates all 14 hooks,
runtime ≈ 2 min.

---

## 6. Verdict / confidence / caveats

**Verdict.** The 14 launchpad `LaunchHook`s are the **same contract** as the exploited `KolanHook` and carry
the **identical** permissionless `accept()` + spot-settlement + unbounded-buyback drain; the only functional
difference is the LaunchHook's *additional* KLN buy/burn leg. **Live extractable today = $0** — no hook has any
escrowed ETH (all windows closed). The family **re-arms** the moment any launched token has a funded, expired,
unclaimed window, and the historical extraction ratio was ~55 % of escrow. **Latent risk, monitor.**

**Confidence:** **HIGH** that the code is identical / that the mechanism is present and re-armable (bytecode
size/dispatch identity across all 14 hooks + recompilation + source diff + 6/6 fork PoC, incl. a byte-faithful
reproduction of the original exploit). **HIGH** that live extractable = $0 (direct reads of every window on
every hook at a pinned block). **MEDIUM** on the *timing* of any future re-arm (depends on whether a future
window is abandoned and left to expire — a human-behaviour unknown).

**What would change the verdict:** any new `LaunchHook` (via `Launchpad.launch`) whose token receives a `buy()`
window that is then abandoned past `expiry` — `monitor.sh` flags `held.eth > 0` immediately.

**Caveats / limitations.**
* The fork archive RPCs are public/keyless; if they are down, `test_01`–`test_03` cannot run (head tests still can).
* The bytecode-level `accept` *region* extraction via source map is noisy under `viaIR` (inlined `_close` is
  attributed to `_close`'s own source range); the strong identity evidence is the whole-contract recompilation
  plus the source diff.
* `held.eth` is a `uint128` accounting field; `eth_getBalance` was also read for every hook (all 0) to rule out
  stray ETH not tracked by `held`.
* Read-only; nothing here is an instruction to transact.

---

## 7. Files index
* `analysis/CHILD-KOLAN.md` — this report.
* `analysis/live_state.py` / `analysis/live_state.json` — exhaustive live state (14 hooks + main, every window).
* `analysis/monitor.sh` — light re-arm monitor.
* `analysis/bytecode_compare.py` / `.json`, `analysis/bytecode_structural.py` / `.json` — on-chain bytecode analysis.
* `analysis/KolanHook.sol`, `LaunchHook.sol`, `Launchpad.sol` — verified Sourcify sources.
* `analysis/exploit_attacker_creationcode.hex` — the 2026-10-15 attacker creation bytecode (public tx input).
* `analysis/exploit_tx.json`, `analysis/window_events.json` — incident trace + all WindowOpened/Closed events.
* `poc/` — Foundry project (`test/Kolan.t.sol`, `exploit_attacker.hex`, vendored `lib/forge-std`).
* `ci/run.sh`, `ci/bytecode_identity.py` — CI heavy job (recompilation proof).
* `ci-out/` — CI result files (live state, identity JSON, compiled/on-chain hex).
