# Kolan launchpad ×14 `LaunchHook`s — code-identical to the exploited `KolanHook`

**Campaign:** ZH4-PASS6 (TIER 3 LOW, row 5) · **Date:** 2026-10-24 · **Chain:** Ethereum (1)
**Status:** **read-only** — no transaction was signed or sent; every on-chain read is `eth_call`/`eth_getCode`/`eth_getBalance`/`eth_getLogs` at an explicit block; the only execution is a **local fork** PoC in CI.

> **Scope of this folder.** This is the parent deliverable for the "Kolan launchpad hooks" sub-target of the pass-6 deep-dive. It verifies (a) that the 14 `LaunchHook`s deployed by the Kolan launchpad carry the **same permissionless `accept()` + live-spot settlement** logic that was exploited on the main `KolanHook` (2026-10-15, ~$3.1 k), (b) that **every hook is empty today ($0)**, and (c) the **exact on-chain predicate that re-arms** the drain. Child work (bytecode-identity script, live-state enumerator, monitor, fork PoC) is in `analysis/` and `poc/`.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed today | Latent / re-arm |
|---|---|---|---|
| **Kolan launchpad** `0x8F89905624E3613b3A578Ff1EC690463A33e940e` → **14 `LaunchHook`s** | **$0.00** | every hook has `held().eth = 0` and `eth_getBalance = 0` (no escrow); `windowCount = 0` on 13/14 and the single window on hook #0 is closed (all-zero struct, `accept(1)` → `NoWindow`) | **RE-ARMS** the moment any launch hook has a **window with ETH escrow past its expiry**: `accept(id)` is callable by anyone after expiry and forces a spot-priced buy-back with **no slippage bound** |
| **Main `KolanHook`** `0x0136feCf49E0217BFd2D9551E8e7b05f174Ba8eC` (the Oct-15 victim) | **$0.00** | `held().eth = 0`, `eth_getBalance = 0`; `windowCount = 47` (all windows closed) | same predicate — re-arms on the next funded window |

## 2. Total live extractable now

**$0.00** (zero) — **confidence HIGH** for the *state* (all 14 hooks + the main hook read at Ethereum block **26265171**/**26265324**: `held.eth = 0`, balance `0`); **confidence HIGH** for the *code* (both contracts are **Sourcify `full_match`** verified, solc **0.8.26**, and `accept()` is textually identical — see §4).

**Latent (conditional) risk:** *unbounded* in principle — bounded only by how much ETH future buyers escrow into a launch hook. See §6 for the exact re-arm predicate and the monitor in `analysis/monitor.sh`.

---

## 3. The incident being mirrored (context)

- **2026-10-15 · KolanHook** `0x0136feCf49E0217BFd2D9551E8e7b05f174Ba8eC` · ~$3.1 k net (1.279 ETH).
- **Attack tx** `0x7b131926e6f06491ae1aead3e419b208c8aa70ed7898e8c5a33d9f52e40915a9` at block **26197504** (gas used **2,937,548**, gasPrice 157.07 gwei ⇒ **≈0.461 ETH gas**; the tx deployed the attacker contract, `to = null`, input 14,922 B; attacker `0x8df735014eab81905e76b87ef0c069bd8e0ae382`).
- **Root cause:** `accept(uint256 id)` is ungated once `block.timestamp >= windows[id].expiry` (only `msg.sender != owner && now < expiry` is rejected), and `_closeWindow(id, keep=true)` settles escrowed ETH at the **live pool `_sqrtPrice()`** with **no TWAP / slippage guard**, running an **unbounded buy-back** `_buyBack(spendable)` with `sqrtPriceLimitX96 = MIN_SQRT_PRICE + 1`. An attacker who moves the pool price first and then closes an expired window forces the hook to trade the escrowed ETH at the manipulated price.
- Defimon reported the loss as **~$3.0 k**; DeFiHackLabs PoC `src/test/2026-10/KolanHook_exp.sol`.

---

## 4. Code identity — the launch hooks carry the exploited logic

**Both contracts are Sourcify `full_match` verified** (deployed bytecode == compiled source), solc **0.8.26+commit.8a97fa7a**:

| contract | address | Sourcify `compilation.name` | source file |
|---|---|---|---|
| `KolanHook` (victim) | `0x0136feCf49E0217BFd2D9551E8e7b05f174Ba8eC` | `KolanHook` | `src/KolanHook.sol` |
| `Launchpad` (deployer) | `0x8F89905624E3613b3A578Ff1EC690463A33e940e` | `Launchpad` | `src/Launchpad.sol` |
| `LaunchHook` (template) | (CREATE2 per token) | — | `src/LaunchHook.sol` |

Fetched via `https://sourcify.dev/server/v2/contract/1/<addr>?fields=sources,compilation` (saved in `analysis/KolanHook.sol`, `analysis/LaunchHook.sol`, `analysis/Launchpad.sol`).

**`accept()` is textually identical** in `KolanHook.sol` and `LaunchHook.sol`:

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

**The exploitable property is preserved** in the launch hook:
- `_closeWindow(id, true)` still reads the **live** `_sqrtPrice()` and either restores the cuts or calls `_addEthAbove(...)`, then settles `spendable = premium + w.eth + currencyDelta(ETH)` at spot.
- The launch hook replaces the direct `_buyBack(spendable)` with `_spendPremium(spendable, premium)`, which splits the premium 50/50 (`KLN_SHARE_BPS = DEV_SHARE_BPS = 5_000`): half buys **KLN** via `_buyKln` (`sqrtPriceLimitX96 = MIN_SQRT_PRICE + 1`) and the rest runs `_buyBack` — **both legs are still unbounded spot swaps**. The settlement price is still the live slot0 price with no TWAP.
- Identical dispatch entry `accept(uint256) = 0x19b05f49` and identical custom-error selectors (`WindowStillOpen() = 0xa41bfbc7`, `NoWindow() = 0xee15c1d2`, `Insolvent() = 0xfc220038`) are present in every deployed hook.

**Bytecode level.** `analysis/bytecode_compare.json` / `analysis/bytecode_compare.py` and the parent script `/tmp` extractor show: all **14 launch hooks have identical deployed runtime code size (24,386 B)** and were **CREATE2-deployed by the same Launchpad from a single stored creation template** (`Launchpad` stores `type(LaunchHook).creationCode` in `CODE_A`/`CODE_B` and re-uses it for every launch — see `Launchpad.sol` `_store`/`_read`/`initCode`), so they are necessarily the same implementation modulo per-token immutables (`TOKEN`, `POOL_ID`, `DEV`, `KLN`). The `accept(uint256)` dispatch target resolves to the same function in all 14 hooks. *(Honest note: the parent's opcode-level `accept` body of `KolanHook` vs a `LaunchHook` shares the same checks, error selectors and call sequence but differs by one stack-scheduling `SWAP1` instruction — a compiler artifact of the two different compilation units, **not** a logic difference. The identity claim rests on the **verified source identity**, which is decisive.)*

**Deployment link.** The launchpad's `KLN_HOOK()` = `0x0136fecf49e0217bfd2d9551e8e7b05f174ba8ec` — i.e. the launchpad routes its KLN buy leg through the **same contract that was hacked**. `TREASURY()` = `0xfc3bc010bc455d38789fd05ecec9c0aa16de29a2` (the Kolan deployer); `POOL_MANAGER()` = `0x000000000004444c5dc75cB358380D2e3dE08A90` (canonical Uniswap V4 PoolManager).

---

## 5. Live-state assessment (Ethereum block 26265171 / 26265324)

**Launchpad** `0x8F89905624E3613b3A578Ff1EC690463A33e940e`: `launchCount() = 14`, `SUPPLY = 1e24`, `OPEN_TICK = 124330`, `TAX_BPS = 100`, `REFERENCE_PREMIUM = 0.05 ETH`, `BASE_WINDOW = 21600`, `MIN_WINDOW = 1800`, `MAX_WINDOW = 604800`, `MAX_PREMIUM_BPS = 3000`.

**14 launch hooks** (from `hooksBetween(0,14)`) — **all** `held().eth = 0`, `eth_getBalance = 0`, code size 24,386 B:

| # | hook | windowCount | held.eth | balance |
|---|---|---|---|---|
| 0 | `0xc75059b9e101483ca3261ca3fdd65bf85a1528ec` | 1 (window closed) | 0 | 0 |
| 1 | `0x02f6bc027e5bca0c733b08711e1378c13cdaa8ec` | 0 | 0 | 0 |
| 2 | `0x00507e62845a03db2d652258e8fa1328d5fae8ec` | 0 | 0 | 0 |
| 3 | `0x6178f64ac4ea1f4ab2f6934f60ef1a1abb5c28ec` | 0 | 0 | 0 |
| 4 | `0x4f447f6f8c416d9b401639fc2fea25bc48e7a8ec` | 0 | 0 | 0 |
| 5 | `0xb0c320e1d4bd9e4051ee84e288075cf233b868ec` | 0 | 0 | 0 |
| 6 | `0xe16ce34cb14ededa706c30846d53339091fda8ec` | 0 | 0 | 0 |
| 7 | `0x860bf7bea785d3b66cd59850355fd19e0bbee8ec` | 0 | 0 | 0 |
| 8 | `0x4b100f6d77e7493fd4432b2fcc4254db224fa8ec` | 0 | 0 | 0 |
| 9 | `0x631d31b25bffa9aacf5a2bebb9dc9132012fe8ec` | 0 | 0 | 0 |
| 10 | `0xd51c92b1dca71af729d5270ad3ba01b47eece8ec` | 0 | 0 | 0 |
| 11 | `0xee9e5e292d7d1f5a5d79d9d54c47244cf2bae8ec` | 0 | 0 | 0 |
| 12 | `0x943745abc7a6106bb47958906d2b91cd4be6e8ec` | 0 | 0 | 0 |
| 13 | `0x16c0ce33576ca3da876fb926ff8dc664cdaa28ec` | 0 | 0 | 0 |

Raw JSON: `analysis/parent-kolan-probe.json`, `analysis/live_state.json`.

**Hook #0** `windows(1)` = `(owner 0x0, expiry 0, cuts 0, eth 0, tokens 0, premium 0)` ⇒ the only window it ever opened is closed; `accept(1)` from a stranger reverts **`NoWindow()`** (proved by `cast call`). So even the one hook with `windowCount = 1` is not armed.

**Historical proof the family arms (from `analysis/window_events.json`):** hook #0's window 1 was opened at block **26,167,731** with `owner 0x46ad135a…`, `eth = 0.0228`, `premium = 0.006831`, `tokens = 3,159.43`, `expiry = 1,791,706,834`, then **cancelled by its owner** at block 26,167,961. Had it been abandoned, it would have held **0.029631 ETH** of escrow and re-armed the drain at expiry — the fork PoC (`test_03`) drains exactly that state.

**Main KolanHook** `0x0136feCf49E0217BFd2D9551E8e7b05f174Ba8eC`: `windowCount = 47`, `held() = (0, 0)`, `eth_getBalance = 0`, code 22,114 B. Not armed.

---

## 6. What an attacker can / cannot do — the exact re-arm predicate

**Cannot** do anything today: there is no escrow (`held.eth = 0`) and no open window on any of the 14 hooks or on the main hook.

**The drain re-arms** iff, on some hook `H`, there exists a window `id` such that:

```
windows[id].owner != 0            // a window exists (created by buy())
AND held(H).eth > 0               // ETH is escrowed in H
AND block.timestamp >= windows[id].expiry     // window is expired (stranger-callable)
```

(Equivalently, for a window the attacker *owns*, `accept(id)` is callable at any time — but the profit comes from forcing the hook's unbounded spot buy-back, so the attacker does not need to own the window.)

**Attacker recipe (the Oct-15 recipe, unchanged):**
1. Buy/create (or simply wait for) an expired window with ETH escrow on a launch hook — `held.eth` = `cost + premium`.
2. Flash-borrow ETH, **move the pool spot** (the hook's own ETH/TOKEN pool) so that `_closeWindow`'s `backInPlace` test fails and the forced buy-back executes at a manipulated price.
3. Call `accept(id)` on the expired window (permissionless); the hook burns/settles and runs `_buyBack` / `_spendPremium` with `sqrtPriceLimitX96 = MIN_SQRT_PRICE + 1` (no slippage bound).
4. Reverse the spot move through the liquidity the hook just injected; net = manipulated-price spread − gas/flash fees.

**Timing / size.** `windowFor(premium) = premium * BASE_WINDOW / REFERENCE_PREMIUM = premium * 21600 / 0.05 ETH`; the minimum window is `MIN_WINDOW = 1800 s (30 min)` at a minimum premium of `0.05 * 1800/21600 = 0.004167 ETH`; the maximum premium is `MAX_PREMIUM_BPS = 3000` (30 % of cost). A single `buy()` therefore creates an armed-after-30-min window with escrow `cost + premium`. Profitability scales with `held.eth` (the Oct-15 extraction netted 1.279 ETH against ≈0.46 ETH of gas at a 157-gwei peak — so a few ETH of escrow is the practical floor).

**Monitor:** `analysis/monitor.sh` (keyless, `cast`-only) prints `windowCount`, `held.eth`, balance and a `RE-ARMED` flag for the launchpad + all 14 hooks + the main hook.

---

## 7. PoC / fork-verification

**CI run:** `https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40141052545` (workflow `poc.yml`, branch `kolan-hooks`) — **Foundry `forge test`: 6 passed; 0 failed; 0 skipped** (finished in 6.53 s). Harness: read-only Ethereum fork, vendored `forge-std`. Full write-up: `analysis/CHILD-KOLAN.md`.

| test | fork block | result | key numbers |
|---|---|---|---|
| `test_01_originalKolanHook_drain_reproduces` | 26,197,503 | **PASS** (gas 3,046,024) | deploys the *exact* historical attacker creation bytecode; main `held.eth` 2.309861 → 0; **attacker net = 1.279914 ETH** |
| `test_02_mainHook_accept_is_permissionless_after_expiry` | 26,197,503 | **PASS** (gas 898,099) | stranger `accept(10)`: `held.eth` 2.309861 → 0.259861 ETH |
| `test_03_launchHook0_stranger_accept_drains` | 26,167,732 | **PASS** (gas 636,339) | hook[0] `held.eth` **0.029631 → 0**; owner received 3,159.4334 TOKEN; window closed **by a stranger** |
| `test_04_liveLaunchpad_freshHook_rearms_and_drains` | head | **PASS** (gas 8,335,864) | launches a *new* token on the live Launchpad (salt-mined for the `0x28EC` hook bits), funds window 1 via `buy()`, warps past expiry, stranger `accept(1)` consumes the escrow |
| `test_05_currentState_all_empty` | head | **PASS** (gas 251,363) | Σ launch-hook `held.eth` = 0, main `held.eth` = 0, main balance 0 |
| `test_06_currentState_accept_reverts_NoWindow` | head | **PASS** (gas 33,891) | `accept(1)` on hook[0] reverts (all windows closed) |

**This is decisive:** the mechanism is reproduced **byte-faithfully** on the historical main hook (to the wei), and then shown firing on a **launchpad `LaunchHook`** — both the *historical* hook #0 (which really did escrow 0.0228 ETH in window 1 at block 26,167,731, later cancelled by its owner) and a *freshly launched* hook on the live Launchpad.

*(Caveat: the child's optional `ci/bytecode_identity.py` recompilation step failed in CI on a `403` downloading `solc` from `binaries.soliditylang.org`; the code-identity claim therefore rests on the verified-source identity + the on-chain bytecode analysis (`analysis/bytecode_structural.json`: all 14 hooks 24,386 B, identical `accept` dispatch dest pc 5,927, 94.4 % identical 64-byte windows pairwise) + the 6/6 fork PoC, not on a recompile.)*

---

## 8. Verdict and residual risk

- **Verdict:** **$0 live extractable today.** The launch hooks are code-identical to the exploited `KolanHook` but hold **no escrow**; there is nothing to drain.
- **Category:** **E-U = $0** now; **H-O = $0** (no user escrow); **P = $0**; **S = $0**. The hooks are *armed-but-empty*.
- **Residual / latent risk:** **HIGH severity, LOW likelihood today** — the code is **immutable and unaudited** ("tested and not audited"), and re-arms automatically the instant a single `buy()` escrows ETH into a launch hook whose window later expires. **Trigger:** any launch hook `held().eth > 0` (or an expired window with escrow). Then the proven `accept()`/spot-settlement drain applies unchanged.
- **Blockers to extraction today:** no escrow; no open windows; `accept()` on hook #0's stale window reverts `NoWindow()`.
- **What would change the verdict:** any new `WindowOpened` on any of the 14 hooks (watch `held().eth`).

---

## 9. Methodology, sources, caveats, files

**Method.** Sourcify v2 `full_match` source fetch; `eth_getCode`/`eth_getBalance`/`eth_call` at pinned blocks via `https://ethereum-rpc.publicnode.com`; selector resolution (`cast sig`, 4byte/OpenChain); linear EVM disassembly for the `accept` dispatch/body; on-chain enumeration via `launchCount()`/`hooksBetween()`/`windowCount()`/`held()`/`windows(id)`; read-only.

**Sources.** Sourcify verified sources (`KolanHook.sol`, `LaunchHook.sol`, `Launchpad.sol`, `LiquidityBook.sol`, `KolanToken.sol`); DeFiHackLabs `src/test/2026-10/KolanHook_exp.sol`; ExVul/Defimon incident reports; pass-2/5/6 corpus (`zombie-hunt-iv/pass{2,5,6}/*.md`).

**Caveats.** (1) The launch-hook `accept()` is **source-identical** to `KolanHook.accept()` and the exploitable settlement path is preserved, but the launch hook's premium leg is split 50/50 with a KLN buy (`_spendPremium`) — magnitudes differ per window, the *property* does not. (2) Bytecode-level `accept` bodies differ by a single stack-scheduling opcode across the two compilation units (no logic difference). (3) Point-in-time **2026-10-24**, block 26265171/26265324; re-read `held()` before acting. (4) Nothing here is an instruction to transact.

**Files.** `README.md` (this file) · `summary.json` · `analysis/{parent-kolan-probe.json, live_state.json, bytecode_compare.json, bytecode_compare.py, monitor.sh, KolanHook.sol, LaunchHook.sol, Launchpad.sol, CHILD-KOLAN.md}` · `poc/` · `ci/run.sh` · `ci-out/` · `ci-log.txt`.
