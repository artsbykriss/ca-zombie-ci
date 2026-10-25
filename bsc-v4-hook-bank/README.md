# Unnamed BSC "bank" `0x16ceff8d…` — PancakeSwap-Infinity (V4) swap router, not an exploit target

**Campaign:** ZH4-PASS6 (TIER 3 LOW, row 7) · **Date:** 2026-10-24 · **Chain:** BNB Smart Chain (56)
**Status:** **read-only** — no transaction was signed or sent; all on-chain work is `eth_call` / `eth_getCode` / `eth_getBalance` / `eth_getBlockReceipts` at explicit blocks; the only execution is a **local fork** PoC in CI.

> **Scope.** Parent deliverable for the "unnamed BSC V4-hook bank" sub-target. It (a) **identifies** the contract, (b) **decompiles** the four probed entrypoints and their guards, (c) explains **why the 25-bot cluster fails** and whether that failure is an access-control guard or normal swap churn, and (d) **quantifies** the value at risk. Child decompilation/fork work is in `analysis/CHILD-BSC.md` and `poc/`.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---|---|---|
| **BSC "bank"** `0x16ceff8d5a4c8648fcc7293f8bd3ac9ada454219` | **$0.00** (no path found) | The contract is an **unverified operator-run multi-DEX swap router** that executes **PancakeSwap Infinity (V4)** swaps for a **whitelisted bot fleet**. The "probed" selectors are its swap/settlement entrypoints; the cluster's reverts are **downstream swap-parameter failures** (`InvalidSqrtPriceLimit`, `SwapAmountCannotBeZero`, `Error("SPL")`) and, on the operator-gated path, **`Unauthorized()`** — **not** an exploit probe. pass-6's "`f35ca728` reverts `Unauthorized()`" is **not reproducible** with the bots' real calldata. In 120 successful calls **the caller never sends or receives a token** — the bank trades and the output goes to the bank. | Its own 65.47 BNB float; **no caller-controlled payout found**. The `Unauthorized()` gate belongs to the operator/admin functions (`authorize`, `f9125e2c`, `d1e57635`) → **P**, not E-U. |

**Headline: E-U = $0.00** (confidence **HIGH** — fork-proven). The bot-cluster "probe" signal is **MEV/arb churn on a router** — exactly the pass-6 §6 conclusion — and is a **false-positive lead**.

---

## 2. Total live extractable now

**$0.00** — **confidence HIGH (fork-proven)**. No unprivileged path to move the router's **64.79 BNB (≈$47.5 k)** exists: a stranger battery over all 39 selectors + the probed calldatas leaves `BANK.balance` and `BANK_ADDRESS.balance` unchanged; the gated functions are an owner-controlled allowlist (P); the swap callbacks are `OnlyPool`-guarded; and in 120 successful calls the caller never pays or receives a token.

**Value map (BSC block 129592843; BNB = $732.78):**

| holder | address | BNB | USD |
|---|---|---|---|
| **the "bank"** (target) | `0x16ceff8d5a4c8648fcc7293f8bd3ac9ada454219` | **65.4706** | **$47,976** |
| `BANK_ADDRESS` (EOA, code 0) | `0x7817DBF38E9d1c95671625F0052c147864692fe0` | 15.6448 | $11,464 |
| `PCS_V4_VAULT` (PancakeSwap Infinity Vault) | `0x238a358808379702088667322f80aC48bAd5e6c4` | 6,845.63 | $5,016,227 |
| `UNI_V4_MANAGER` | `0x28e2Ea090877bF75740558f6BFB36A5ffeE9e9dF` | 2,906.88 | $2,130,092 |
| `$8.63 M` proxy (prior pass-6 lead) | `0x6aba0315493b7e6989041c91181337b662fb1b90` | 3,476.04 | $2,547,153 |

The bank's balance **grew** across the campaign: **54.5 BNB** (pass-6, 2026-10-23) → **61.56 BNB** → **65.47 BNB** (2026-10-24) — it is **actively accumulating** BNB (≈+11 BNB/day). Bank ERC-20: 0.05 USDT-BSC.

---

## 3. Identification

**Unverified** on Etherscan-V2 (BSC not on the free tier), Sourcify (no match), and BSCScan free. Identification rests on **bytecode ABI + resolved selectors + live behaviour**:

- **Runtime 22,469 B**, **39-entry** dispatch; **no ASCII string literals and no custom-error selectors** in the runtime code (searched: `SPL`, `Unauthorized`, `InvalidSqrtPriceLimit`, `Pool`, … all absent) ⇒ the contract is a **thin router** whose reverts **propagate from called contracts**.
- **Immutables** (read via `cast call`; names resolved by OpenChain/4byte `hasVerifiedContract`):
  - `PCS_V4_MANAGER()` = `0xa0FfB9c1CE1Fe56963B0321B32E7A0302114058b`
  - `PCS_V4_VAULT()` = `0x238a358808379702088667322f80aC48bAd5e6c4` (PancakeSwap Infinity Vault)
  - `UNI_V4_MANAGER()` = `0x28e2Ea090877bF75740558f6BFB36A5ffeE9e9dF`
  - `BANK_ADDRESS()` = `0x7817DBF38E9d1c95671625F0052c147864692fe0` (an **EOA**, code 0, holds 15.64 BNB)
- **Callbacks present:** `unlockCallback(bytes)` `0x91dd7346`, `pancakeV3SwapCallback` `0x23a69e75`, `uniswapV3SwapCallback` `0xfa461e33` ⇒ a **V4 + V3 multi-DEX router**.
- **Role/admin:** `authorize(address)` `0xb6a5d7de` and `f9125e2c(uint256)` both revert `Unauthorized()` (`0x82b42900`) for a stranger **and** for `BANK_ADDRESS`; ~20 `(address)->…` selectors are role/whitelist getters.
- **Confirmed live routing:** every *successful* call emits `Swap(bytes32,address,int128,int128,uint160,uint128,int24,uint24,uint16)` (**topic0 `0x04206ad2b7c0f463bff3dd4f33c5735b0f2957a351e4f79763a4fa9e775dd237`**) from `PCS_V4_MANAGER` `0xa0FfB9c1…` and an ERC-20 `Transfer` **from `BANK_ADDRESS` → `PCS_V4_VAULT`** ⇒ the router executes **PancakeSwap Infinity (V4) swaps**, with the `BANK_ADDRESS` EOA as the settler.
- The `PCS_V4_MANAGER`/`PCS_V4_VAULT`/`UNI_V4_MANAGER` naming family also appears in the verified BSC **"Flap"** launchpad `FlapTaxToken` (`PCS_V4_VAULT`/`UNI_V4_POOL` constructor params) — i.e. it is standard BSC V4-integration nomenclature; **no verified source matches this contract**.

**Best characterisation:** an **unverified, operator-run multi-DEX swap router / "bank"** (V2/V3/Pancake-V3/Uniswap-V3/Pancake-Infinity-V4/Uniswap-V4) used by a **bot fleet**, holding the operator's BNB float.

---

## 4. The bot cluster — forensics (this pass, live)

| metric | value |
|---|---|
| window | 1,500 BSC blocks (~75 min) ending block **129590709** |
| txs to target | **1,501** |
| **successful** | **436 (29 %)** |
| **failed** | **1,065 (71 %)** |
| distinct senders | **25** (nonces ≈1.9 M; all `value = 0`) |
| top selectors | `9e1941ca` 523 · `a3f8ea7c` 409 · `f35ca728` 202 · `d1e57635` 148 · `483bd75e` 114 · `05e85860` 96 · `35230cd8` 73 · `716629d5` 71 · `fad7c5c6` 26 · `e7dd6c65` 17 · `8eb1172f` 14 · `43308267` 6 · `9a462d4a` 3 · `fc102e12` 2 · `d3a57c62` 1 |

**Why the bots fail — exact revert reasons (from the bots' *real* calldata):**
- `0xf35ca728` = a **swap** `(address tokenIn, uint256 amountIn, uint256 limit, address tokenOut)` → reverts **`Error("SPL")`** (a price-limit/slippage require).
- `0x9e1941ca` / `0xa3f8ea7c` = **swaps** (8 words, incl. `PCS_V4_MANAGER`) → revert **`InvalidSqrtPriceLimit(uint160,uint160)`** (`0xb5c41efe`, resolved via 4byte) — the caller's sqrt-price limit is out of range.
- `0x716629d5` = the swap that *succeeds*; when replayed at head with a stale limit it reverts **`InvalidSqrtPriceLimit`**, and with a zero amount **`SwapAmountCannotBeZero()`** (`0xbe8b8507`).
- `0xd1e57635` = **role-gated**: a **stranger reverts `Unauthorized()` (`0x82b42900`)** while the bot/owner caller **succeeds** (`OK:0x`) — i.e. it is an operator/whitelist function, **not** a permissionless swap.
- The **successful** selectors execute a PancakeSwap Infinity swap and settle via `BANK_ADDRESS → PCS_V4_VAULT`.

⇒ The 25-EOA "217 failed calls" cluster is **a bot fleet's arb/quote churn**: most swap attempts revert on **downstream price-limit/slippage validation**, and the gated ones revert `Unauthorized()` for non-operators. This is **not** exploit probing.

**Whose funds move — token-flow analysis of 120 successful calls.** Decoding every ERC-20 `Transfer` in 120 successful txs: the flows are **`BANK_ADDRESS → PCS_V4_VAULT` (54)**, **`… → BANK_ADDRESS` (81)** and **`BANK_ADDRESS → …` (17)**. **No transfer ever pays or debits the caller** (zero `→CALLER`, zero `CALLER→`). The bot EOAs only **trigger** swaps; the `BANK_ADDRESS` EOA / bank is the counterparty, and the output flows **to the bank**, never to the caller. ⇒ triggering a swap cannot route value to a stranger.

**Correction to pass-6 (`pass6/probed-protocols.md` T1).** The lane states *"`f35ca728` reverts `Unauthorized()` `0x82b42900`"*. Replaying the bots' actual `f35ca728` calldata at head yields **`Error("SPL")`**, not `Unauthorized()`. `Unauthorized()` (`0x82b42900`) is emitted only by the **operator-gated** selectors (`authorize` `0xb6a5d7de`, `f9125e2c`, and `d1e57635` for a stranger). The prior lane's attribution is therefore **wrong**; the "same custom error as UniswapV4Router04" linkage does not hold, and the V4Router04 non-canonical-offset hypothesis is moot.

---

## 5. What an attacker can / cannot do

**Can:** call the **permissionless** swap entrypoints (`f35ca728`, `716629d5`, `9e1941ca`, `a3f8ea7c`, `483bd75e`, `05e85860`, `35230cd8`, …) — the router's public API, used by the bot fleet. They route swaps to PancakeSwap Infinity / V3 pools and settle via the `BANK_ADDRESS` EOA. (Fork-proven: with a stranger caller these revert on **swap-parameter validation**, and in the bots' own successful calls the caller neither pays nor receives a token — see §4.)

**Cannot (fork-proven):**
- Move the bank's **64.79 BNB** to a caller-controlled recipient. A stranger battery over **all 39 selectors + the 4 probed calldatas + `authorize`** leaves `BANK.balance` and `BANK_ADDRESS.balance` **unchanged** and the stranger with **0** (`test_E`).
- Use the operator-gated functions: **4 selectors revert `Unauthorized()` (`0x82b42900`) for a stranger** while an authorized bot succeeds (`test_A`, `test_C`); the gate is an **owner-controlled allowlist** — `authorize(STRANGER)` as the owner makes the gated `d1e57635` succeed for the stranger (`test_G`), i.e. **P**.
- Abuse the swap callbacks: `pancakeV3SwapCallback`/`uniswapV3SwapCallback` revert **`OnlyPool()` (`0x4b602735`)** for a stranger; `unlockCallback` reverts even when **impersonating `UNI_V4_MANAGER`** (`test_D`, `test_G`). No missing-caller-check drain.
- Use a permissive fallback: `0xdeadbeef` reverts; only **4/39** selectors (the immutables getters) are callable by a stranger (`test_A`).

**Residual uncertainty:** the contract is **unverified** (no source), so identification is by ABI/behaviour; a future **new** selector or a change to the allowlist is the only re-open vector. The linked **$5.02 M PCS V4 Vault** and **$2.13 M UNI manager** are protocol-level custody, not this contract's E-U surface.

---

## 6. PoC / fork-verification

**CI run:** `https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40191791506` (workflow `poc.yml`, branch `bsc-v4-hook-bank`) — **Foundry `forge test`: 7 passed; 0 failed; 0 skipped**. Harness: read-only BSC fork at block **129,592,600** via keyless archive RPC `https://bsc-mainnet.public.blastapi.io` (publicnode/dataseed serve no historical state), vendored `forge-std`.

| test | result | key evidence |
|---|---|---|
| `test_A_selectorProbe` (gas 3,434,323) | **PASS** | stranger, empty calldata: **only 4/39 selectors non-revert** — the immutables `BANK_ADDRESS` (`0x0a5f7886`), `UNI_V4_MANAGER` (`0x6cfee777`), `PCS_V4_VAULT` (`0xd330ca5e`), `PCS_V4_MANAGER` (`0xee4b1585`). **4 selectors revert `Unauthorized()` (`0x82b42900`) for a stranger while the bot caller succeeds (`OK:0x`)** — operator-gated. |
| `test_B_replayProbed` (gas 686,868) | **PASS** | replaying the bots' real failed calldata at their own historical blocks: `f35ca728` → `Error("SPL")` for stranger/bot/owner; `9e1941ca`/`a3f8ea7c` → `InvalidSqrtPriceLimit`; `d1e57635` → `Error("SPL")` at that block. No `Unauthorized()` on the swap paths. |
| `test_C_guardHolds` (gas 251,432) | **PASS** | `d1e57635`: **stranger → `Unauthorized()`, authorized bot → OK** ("guard holds"). |
| `test_D_callbackGuards` (gas 106,329) | **PASS** | `unlockCallback` (`0x91dd7346`) → stranger reverts (empty); `pancakeV3SwapCallback` (`0x23a69e75`) and `uniswapV3SwapCallback` (`0xfa461e33`) → stranger reverts **`OnlyPool()` `0x4b602735`**. |
| `test_E_noUnprivilegedDrain` (gas 1,572,656) | **PASS** | after calling **all 39 selectors + the 4 probed calldatas + `authorize` as a stranger**, `assertEq(BANK.balance, before)` — bank native **unchanged at 64.793376… BNB**, `BANK_ADDRESS` unchanged, **stranger gained 0**. |
| `test_F_valueAtRisk` (gas 52,691) | **PASS** | at block 129,592,600 — BANK native **64.7934 BNB**; `BANK_ADDRESS` native **20.6448 BNB**; OWNER native 3.5096 BNB; BANK USDT 0.05; BANK USDC 0; BANK WBNB 0.00000825. |
| `test_G_impersonationDiagnostics` (gas 211,179) | **PASS** | even **impersonating `UNI_V4_MANAGER`**, `unlockCallback` reverts (`ok: 0`) ⇒ stricter than caller==manager. **`authorize(STRANGER)` as OWNER → OK, and `d1e57635` then succeeds for the stranger** ⇒ the gate is a genuine owner-controlled allowlist (`authorize(address)`), i.e. **P**. |

**Verdict from the fork:** the probed selectors are the router's swap/settlement API; the gated ones are **owner-controlled allowlist** functions; the callbacks are **`OnlyPool`-guarded**; and a full stranger battery over all 39 selectors moves **zero** native value out of the bank or to the stranger.

---

## 7. Verdict

- **Verdict:** **$0.00 unprivileged-extractable (fork-proven).** The contract is an **operator-run multi-DEX swap router** ("bank") whose bot-fleet traffic generates a **false-positive "probed protocol" signal**. No unprivileged path to its ~64.8 BNB was found.
- **Category:** **E-U = $0**; the bank's float is **P** (owner-controlled allowlist via `authorize`/`d1e57635`); the linked **$5.02 M PCS V4 Vault** and **$2.13 M UNI manager** are protocol-level custody, not this contract's E-U surface.
- **Residual / latent risk:** **LOW** — re-open only if a **new** selector/role is added or the allowlist changes.
- **Blockers:** unverified source (identification is by ABI/behaviour); public BSC nodes serve ~128 blocks of state, so historical replay needs a keyless archive RPC (`bsc-mainnet.public.blastapi.io` was used); the `BANK_ADDRESS` EOA is the settler, not a caller.

---

## 8. Methodology, sources, caveats, files

**Method.** `eth_getCode`/`eth_getBalance`/`eth_call` at pinned blocks (`https://bsc-rpc.publicnode.com`); 1,500-block `eth_getBlockReceipts` scan for txs to the target (status + selector clustering); real-calldata replay via `eth_call`; selector/error resolution (4byte.directory + OpenChain); heimdall v0.9.2 decompile (`analysis/bank_decompiled.yul`) **treated as unreliable for bodies** and cross-checked with a hand-written linear disassembler (`analysis/disasm.py`); immutables via `cast call`; price via DefiLlama (`coins.llama.fi`).

**Sources.** pass-6 `probed-protocols.md` (T1/T3) and `README.md` §4 row 7; BSC RPC; 4byte/OpenChain; GitHub code search (Flap naming family).

**Caveats.** (1) Unverified bytecode ⇒ identification is by ABI/behaviour, not source. (2) Nonce is a proxy for freshness. (3) The 1,500-block window is a sample; the fleet is ongoing (1,705 txs in an earlier 2,500-block window). (4) Point-in-time **2026-10-24**, block 129592843. (5) Nothing here is an instruction to transact.

**Files.** `README.md` (this file) · `summary.json` · `analysis/{parent-bsc-state.json, bank_runtime.hex, bank_decompiled.yul, bank_abi.json, bsc_bank_txs.json, bsc_bank_succ.json, scan_bsc.py, scan_succ.py, sample_tx.py, strings.py, guard_test.py, guard_test2.py, CHILD-BSC.md}` · `poc/` · `ci/run.sh` · `ci-out/` · `ci-log.txt`.
