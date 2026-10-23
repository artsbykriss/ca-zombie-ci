# UniswapV4Router04 — hardcoded-calldata-offset auth bypass (Ethereum)

**Date:** 2026-10-23 · **Chain:** Ethereum mainnet (chainid 1) · **Target:** `0x00000000000044a361Ae3cAc094c9D1b14Eece97`
**Status:** read-only; PoC fork-verified only; no mainnet transactions signed or broadcast. No secret/keyed RPC URL appears in this folder.

---

## 1. TL;DR

| Target | Live extractable by an unprivileged attacker now | Why open / closed | Latent risk |
|---|---|---|---|
| `UniswapV4Router04` `0x00000000000044a361Ae3cAc094c9D1b14Eece97` (Ethereum) — public `swap(bytes,uint256)` `0xaf2b4aba` | **≈ $2.60** (fork-proven) | **OPEN** (unpatched, still live). Auth gate reads `calldataload(164)` instead of decoding the `bytes` argument → non-canonical ABI offset bypasses it. Residual is small only because of *victim-side* constraints (see §4). | High: any new approval with a *returning* ERC-20 and a liquid v4 pool is immediately drainable. Same bytecode is live on Base / Arbitrum / Optimism / Polygon / Unichain (no approvals there today). |

**Total live extractable now: ≈ $2.60 (USD), confidence medium** — of which **$2.34 is fork-proven end-to-end** and the rest is fork-scope-scanned. Nominal "drainable" (Σ min(allowance,balance) over every approving pair) is **$14.40**; **$11.80 of that is unreachable** for concrete, verified reasons (§4).

---

## 2. The bug, in exact terms

`UniswapV4Router04.swap(bytes calldata data, uint256 deadline)` (selector `0xaf2b4aba`, source line 235) gates the payer with a **hardcoded absolute calldata offset**:

```solidity
// equivalent to `require(abi.decode(data, (BaseData)).payer == msg.sender, Unauthorized())`
assembly ("memory-safe") {
    if iszero(eq(calldataload(164), caller())) {   // <-- hardcoded offset 164 (0xa4)
        mstore(0x00, 0x82b42900) // Unauthorized()
        revert(0x1c, 0x04)
    }
}
return _unlockAndDecode(data);
```

`BaseData { uint256 amount; uint256 amountLimit; address payer; address receiver; uint8 flags; }`.

Under the **canonical** ABI encoding of `swap(bytes,uint256)` the head is `[offset=0x40][deadline]`, so the `data` slice starts at calldata `0x64` and its 3rd word (`BaseData.payer`) lands exactly at `0xa4` = 164. The check is therefore *only* correct for the canonical offset.

The ABI decoder never validates the `bytes` offset word. Setting it to `0xc0` (192):

| calldata | canonical | attacker |
|---|---|---|
| `bytes` offset word (4..36) | `0x40` | **`0xc0`** |
| word at 164 (0xa4) | `BaseData.payer` | **attacker address (free filler)** |
| `data` slice length word | 68 | 196 |
| decoded `BaseData.payer` | 164 | **292 (0x124) = victim** |

`_unlockAndDecode(data)` passes the *shifted* slice through `poolManager.unlock` → `unlockCallback` → `abi.decode(callbackData,(BaseData))`, which reads the **victim** as `payer`. The callback then:

```solidity
inputCurrency.settle(poolManager, data.payer, inputAmount, input6909);   // -> token.transferFrom(VICTIM, poolManager, amount)
outputCurrency.take(poolManager, data.receiver, outputAmount, output6909); // -> swap output to the attacker
```

**Attacker cost: gas only. No capital, no flash loan, no privileges.**

### Deployed-code references (all at Ethereum block 26,253,889)

* `eth_getCode(0x00000000000044a361Ae3cAc094c9D1b14Eece97)` = **10,474 bytes** (code live; matches the parent's codesize).
* Runtime bytecode offset **`0x59a` (1434)**: `PUSH1 0xa4; CALLDATALOAD` — preceded by `CALLER` and followed by `SUB; PUSH2 0x05b2; JUMPI` (i.e. `if (caller - calldataload(0xa4) != 0) goto revert`).
* Runtime bytecode offset **`0x5b2`**: `PUSH4 0x82b42900; DUP3; MSTORE; PUSH1 0x04; PUSH1 0x1c; REVERT` = `Unauthorized()`.
* Selector `0xaf2b4aba` in the dispatcher at offset **`0x17d`** → handler `0x51c`; the handler calls the `bytes` decoder at `0x1c18` (bounds-only: `offset+31` no-overflow, `length <= 2^64-1`, `offset+32+length <= calldatasize` — **no canonicality check**), then reads `calldataload(0x24)` as the deadline, then runs the auth check at `0x59a`.
* Immutables in code: `poolManager = 0x000000000004444c5dc75cB358380D2e3dE08A90` (canonical Uniswap v4 PoolManager), `permit2 = 0x000000022D473030F116dDEE9F6B43aC78BA3`.
* **Not a proxy**: EIP-1967 implementation/admin/beacon slots are all zero; `eth_getStorageAt` at block 26,253,889.
* Verified source: `UniswapV4Router04`, solc `v0.8.26+commit.8a97fa7a`, optimizer runs `9999999`, `viaIR: true`, `evmVersion: cancun`.
* Deployed at block **22,281,170** (tx `0xc2e54c650e1dd4880265b0267f12f2214675681bd1f8852dc7d6d80e523a0880`), creator `0x1c0aa8ccd568d90d61659f060d1bfb1e6f855a20`.

### This is a real, already-exploited bug

DARKNAVY's public write-up *"Uniswap V4 Hook Swap Drain"* (2026-03-03) documents exactly this: on **2026-03-03 (block 24,575,085)** an attacker used `offset = 0xc0` with the attacker at position 164 and the victim's `BaseData.payer` at position 292, draining **42,606.96 USDC** (≈21.198 ETH) from victim `0x65a8f07bd9a8598e1b5b6c0a88f4779dbc077675` via the ETH/USDC 0.05% v4 pool, output sent to EOA `0xd6b7e831d64e573278f091aa7e68fbf2a8fa9916`. My mechanism derivation matches theirs exactly. The historical victim has since revoked **all** approvals (verified: `allowance == 0` for all ~43 tokens they ever approved to this router).

---

## 3. Live-state assessment

Everything below is read at pinned block **26,253,889** (state) and fork-tested at block **26,255,513**.

### 3.1 Approval enumeration (exhaustive)

Method: `eth_getLogs` (50k-block chunks, Nodereal) for `Approval` with `topic0 = 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925` and `topic2 = 0x00000000000000000000000000000000000044a361ae3cac094c9d1b14eece97`, from deployment block 22,281,170 to head, **no `address` filter** (so ERC-6909 claims in the PoolManager and ERC-721 approvals would also be caught). Script: `analysis/scan_approvals.py`.

| metric | value |
|---|---|
| raw `Approval` logs (all ERC-20) | **4,256** |
| ERC-721 / ERC-6909 approvals (4-topic) | **0** |
| distinct `(token, owner)` pairs | **3,284** |
| distinct owners | 623 |
| distinct tokens | 933 |
| pairs with **live `allowance > 0`** | 2,993 |
| pairs with **`allowance > 0` AND `balance > 0`** (drainable) | **26** |

Per-pair live `allowance(owner, router)`, `balanceOf(owner)`, `decimals`, `symbol` were read with batched `eth_call` at block 26,253,889 (`analysis/read_state.py` → `analysis/state_pinned.json`, `analysis/drainable_table.{json,csv}`).

### 3.2 The 26 drainable pairs (nominal value)

Nominal = `min(allowance, balance)` priced with DefiLlama / GeckoTerminal (`analysis/prices_llama.json`, `analysis/gecko_pools_full.json`).

| # | token | symbol | owner | drainable | nominal USD | actually reachable? |
|---|---|---|---|---|---|---|
| 1 | `0xdac17f95…` | USDT | `0x650532b5db628dda2557340e8521b0d11cb240cf` | 5.000000 | $4.99 | **NO** — USDT returns no data from `transferFrom` (§4.1) |
| 2 | `0x61872454…` | SPUNK | `0x64924dddd4bf7ca9659d7d2ceb2ed7618b226dc5` | 35,746.49 | $3.54 | **NO** — token reverts `NotValidRouter()` |
| 3 | `0xb262aff1…` | TEST | `0xf2db99a98b8f36d5a078d43117731f611970faa6` | 626,082,218 | $3.16 | **NO** — only v4 pool has 0 liquidity |
| 4 | `0x69110e7c…` | PNZI | `0x7363cc41220d5d298fd74b4db9d53f59c97718c8` | 971,401.09 | $2.28 | **YES — fork-proven $2.34** |
| 5 | `0x0699253c…` | FR | `0x6dc72beb8289db02dc861804d74bcc03eaea280f` | 97,209.87 | $0.23 | **YES — fork-proven $0.229** |
| 6 | `0x25a77a65…` | DEPHI | `0xd9ee98f3b3b8c6913d76f18286bee504d5bc3ef7` | 2,616.18 | $0.173 | **NO** — token reverts `0x2f352531` |
| 7 | `0xaa60bd51…` | DFYT | `0x792dcd50c5e745b90265ed83b585dd4b57dbc199` | 0.025685 | $0.026 | YES (scope scan) |
| 8 | `0xb56e871b…` | OMPALOMPA | `0x6dc72beb8289db02dc861804d74bcc03eaea280f` | 525.51 | $0.0012 | YES (scope scan) |
| 9–13 | `0x326bf896…` | WOWSTR ×5 | 5 owners | 3.96 total | $0.0004 | **NO** — token reverts `0x2f352531` |
| 14 | `0xc50673ed…` | PNKSTR | `0x618724546cbeb90aca45eb3edf0d65041a5215cb` | 0.0189 | $0.0002 | YES (scope scan) |
| 15 | `0x7bf4c3ea…` | MOONSTR | `0x601f8a2c906141837dfb854774808905b259c4c5` | 0.623 | $0.00004 | YES (scope scan) |
| 16–26 | TST, USDC×2, Lottery, PNKSTRs, PSS, NINTONDO, uPEG, PNKSTR (2nd), DOT, WOWSTR (dust), DEPHI (2nd) | 11 pairs | 11 pairs | < $0.00001 total | dust; uPEG blocked by a hook (`0x90bfb865`) |

**Nominal drainable total: $14.40. Actually reachable: $2.60.**

### 3.3 The two "named" approvers requested

* **`0x650532b5db628dda2557340e8521b0d11cb240cf`** (the active approver; last called `swap(bytes,uint256)` at block **26,141,461**, tx `0x03c13a3cc6a67dedc91bec65d857748bdf0d072c5fc9dbed93546f86f098e471`): live `USDT.allowance(owner, router) = 5,000,000` (5.0 USDT) and `USDT.balanceOf = 36,000,007` (36.0 USDT) at block 26,253,889. Nominal drainable **5.0 USDT ≈ $4.99** — but **not extractable**: USDT returns **no data** from `transferFrom`, and Solidity validates the declared `bool` return even when discarded, so the router's settle step reverts with empty data (§4.1, fork test `test_negative_USDT_settleReverts_emptyReturnData`). This *corrects* the earlier pass-5 figure of "~5.0095 USDT": the allowance is exactly **5.000000 USDT**, not 5.0095, and it is **not** drainable.
* **`0x65a8f07bd9a8598e1b5b6c0a88f4779dbc077675`** (the 2026-03-03 victim, 42,606.96 USDC drained): every one of the ~43 approvals it ever granted to this router now has `allowance == 0` (fully revoked). Residual **$0**.

---

## 4. What an attacker can / cannot do

### 4.1 It works — but only for tokens that return ≥32 bytes

`BaseSwapRouter._unlockCallback` settles the input via `CurrencySettler.settle`, which is a plain Solidity call:

```solidity
IERC20Minimal(Currency.unwrap(currency)).transferFrom(payer, address(manager), amount);
```

`IERC20Minimal.transferFrom` is declared `returns (bool)`. **Solidity validates the 32-byte return even though the value is discarded** — I proved this directly on a fork (`analysis/explore_all_results.txt` and the standalone probe run): a typed `IERC20(USDT).transferFrom(...)` reverts with **empty data** immediately after USDT returns `[Stop]` (0 bytes), while the same call on USDC (returns `0x…01`) succeeds. Consequence:

* **USDT and any other non-returning ERC-20 cannot be drained through the non-Permit2 settle path.** This is why the historical attacker used **USDC** (which returns `bool`), and why the current USDT approval is dead weight. Using the `PERMIT2` flag instead would require a victim signature — unavailable to an unprivileged attacker.

### 4.2 Token-level restrictions close the biggest remaining approvals

* `SPUNK.transferFrom` reverts with `NotValidRouter()` (`0x3d04e56e`) when the router is the caller → 35,746 SPUNK ($3.54 nominal) unreachable.
* `WOWSTR` and `DEPHI` `transferFrom` revert with custom error `0x2f352531` → $0.17 + $0.0004 unreachable.
* `uPEG`'s pool hook reverts `0x90bfb865` → unreachable.

### 4.3 Liquidity constraint

* `TEST` ($3.16 nominal) has exactly one v4 pool (`TEST/PENDLE`, `0xb9c782bd…`) and it holds **0 liquidity**; a fork swap returns **0 output** (verified).

### 4.4 Preconditions for a successful drain

1. An `Approval(owner, router)` with `allowance > 0` and `balance > 0` (satisfied by the 26 pairs above).
2. The input token's `transferFrom` must return ≥32 bytes and not blacklist the router.
3. A **liquid Uniswap v4 pool** must exist for that token (the router only swaps via `PoolManager.swap`), and its hook must allow the swap.
4. Output is delivered to `data.receiver` = attacker; input is pulled from `data.payer` = victim.
5. Cost: **gas only** (measured 143k–163k gas). No flash loan, no capital, no privileges.
6. The attacker can batch all extractions in one transaction via the router's public `multicall(bytes[])` (delegatecall preserves the outer `caller()`, so each sub-call re-passes the gate with its own crafted offset).

### 4.5 Costs / economics

| | PNZI | FR |
|---|---|---|
| gas used (fork) | **163,039** | **149,151** |
| gas price at read | 0.1286 gwei | 0.1286 gwei |
| gas cost | $0.050 | $0.046 |
| extracted | $2.3407 | $0.2292 |
| **net** | **+$2.29** | **+$0.18** |

At the observed gas price (~0.13 gwei) the whole residual is net-positive (**≈ $2.47 net**). The aggregate stays profitable up to ≈ 6 gwei (≈ $1.9/tx); above that only the PNZI leg remains, and above ≈ 12 gwei the residual is sub-gas. **This is a real (if tiny) E-U, not a sub-gas artefact** — but it is small enough that it is only worth acting on as a *latent* risk.

---

## 5. PoC / fork verification

`poc/` — Foundry project (vendored `lib/forge-std`, no network install). Tests drive the deployed router through raw calldata; nothing is compiled from the target.

```
poc/test/UniswapV4Router04.t.sol
```

| test | what it proves | result |
|---|---|---|
| `test_bypass_nonCanonicalOffset_passesAuthGate` | with offset `0xc0`, `BaseData.payer = victim`, an uninitialised pool: the call **passes** the gate and only fails later with `PoolNotInitialized()` (`0x486aa307`), **never** `Unauthorized()` | **PASS** |
| `test_control_canonicalOffset_revertsUnauthorized` | canonical offset + spoofed payer → `0x82b42900` | **PASS** |
| `test_control_fillerMismatch_revertsUnauthorized` | offset `0xc0` but filler ≠ `msg.sender` → `0x82b42900` | **PASS** |
| `test_extract_PNZI_victim` | **full drain**: victim PNZI balance −971,401.09…, attacker +0.00097515625 ETH | **PASS** |
| `test_extract_FR_victim` | **full drain**: victim FR balance −97,209.87…, attacker +0.000095481730711751 ETH | **PASS** |
| `test_negative_USDT_settleReverts_emptyReturnData` | bypass works for USDT but the settle reverts with **empty** data and **no USDT moves** | **PASS** |
| `test_negative_SPUNK_transferFrom_NotValidRouter` | `SPUNK.transferFrom` from the router reverts `0x3d04e56e` | **PASS** |

**7 / 7 PASS.** Fork block recorded in the test log: **26,255,513** (local run). RPC selection follows the brief (`FORK_RPC_URL` → `RPC_URL` → public fallback); the fork is pinned at the head block of the run and the block number is logged. Set `PIN_BLOCK` to force an explicit archive block.

Additional scope scan (12 further candidate pairs, results in `analysis/explore_all_results.txt`) confirmed which additional tokens are reachable and which are blocked.

**CI runs:** see `poc.ci_run_urls` in `summary.json` (GitHub Actions, `artsbykriss/ca-zombie-ci`, workflow `poc.yml`). Logs: `ci-log.txt`; artifacts: `ci-artifacts/`.

---

## 6. Verdict, residual and latent risk

* **Verdict:** the auth bypass is **real and unpatched**, exactly as publicly documented. An external unprivileged attacker can extract **≈ $2.60 today** (fork-proven $2.34 of it) at a gas cost of ≈ $0.10. **Confidence: medium-high** on the mechanism and the two fork-proven legs (high); medium on the small scope-scan legs and on the micro-cap USD prices (±50%).
* **Residual now:** $2.60 (E-U). The nominal $14.40 headline is misleading — $11.80 is blocked by token-level behaviour (USDT no-bool $4.99, SPUNK `NotValidRouter` $3.54, TEST zero-liquidity $3.16, DEPHI/WOWSTR restrictions $0.17, uPEG hook $0).
* **Latent / re-arm risk: HIGH.** The contract is live, unpatched and permissionlessly callable. **Any new approval of a returning ERC-20 with a liquid v4 pool is instantly drainable** — the historical exploit proves the pattern pays ($42,607 in one shot). The correct fix is to compare `abi.decode(data,(BaseData)).payer` against `msg.sender` instead of `calldataload(164)`.
* **Breadth:** the identical runtime code is deployed at the same address on **Base, Arbitrum, Optimism, Polygon and Unichain** (auth pattern at byte 1433, `Unauthorized` selector at byte 282, same 10,474-byte size; only the immutable `poolManager`/`permit2` words differ). Approval enumeration on those chains found **0 drainable pairs** (Arbitrum: 1 approval with `balance == 0`; Unichain: 2 approvals with `allowance == 0`; Base/Optimism/Polygon: none). This is a re-arm note, not a new finding.

---

## 7. Methodology & sources

1. Verified the deployed contract: `eth_getCode`/codesize, EIP-1967 slots, dispatcher + inline-assembly disassembly (`cast disassemble`), constructor args (immutables), Etherscan `getsourcecode`/`getcontractcreation`.
2. Enumerated **every** `Approval(_, router)` log from deployment to head with chunked `eth_getLogs` (no address filter) → 4,256 logs → 3,284 distinct `(token,owner)` pairs.
3. Read live `allowance`/`balance`/`decimals`/`symbol` for all 3,284 pairs at a pinned block via batched `eth_call`.
4. Priced tokens with DefiLlama (`coins.llama.fi`) and GeckoTerminal; checked which tokens have **Uniswap v4 Ethereum** pools and their liquidity.
5. For every candidate, simulated `token.transferFrom(owner, PoolManager, amount)` **from the router** to test the settle precondition, and simulated the full crafted-`swap` call (`analysis/sim_extract.py`).
6. Built a fork PoC that (a) proves the bypass with controls and (b) performs real end-to-end drains; ran it locally and in CI.
7. Cross-checked against DARKNAVY's public post-mortem of the 2026-03-03 incident.

**Sources:** Etherscan V2 (source/ABI/logs/creation), Nodereal + drpc + publicnode RPCs, DefiLlama, GeckoTerminal, DARKNAVY *"Uniswap V4 Hook Swap Drain"* (2026-03-03).

## 8. Caveats & limitations

* Fork tests run at the **head block of the run**, not at block 26,253,889 (public fork RPCs are non-archive). The pinned-block numbers in §3 come from direct `eth_call` at 26,253,889. The two fork-proven drains were re-verified at fork block 26,255,513 with the same values.
* Micro-cap USD prices (PNZI, FR, OMPALOMPA, …) are indicative (±50%); the *token amounts* are exact on-chain reads and the *ETH outputs* are exact fork measurements.
* `0x2f352531` (WOWSTR/DEPHI `transferFrom` revert) could not be matched to a public error name; it is reported by its selector only.
* "Extractable" is gross of gas; the net figures in §4.5 use the gas price observed at the time of the read.
* The `Allowance(owner, router)` universe excludes **Permit2** allowances (the attacker cannot use them without a victim signature) and ERC-6909 claims (none exist for this router).

## 9. Files index

```
uniswapv4router04/
├── README.md                     this report
├── summary.json                  machine-readable summary (schema per brief §7)
├── analysis/
│   ├── scan_approvals.py         paginated Approval-log scanner (RPC from env; no secrets)
│   ├── read_state.py             batched allowance/balance/decimals/symbol reader
│   ├── scan_multichain.py        same-code-on-other-chains approval scan
│   ├── sim_extract.py            read-only end-to-end extraction simulation
│   ├── approvals_raw.json        4,256 Approval logs (block 22,281,170..26,253,889)
│   ├── approval_pairs.json       3,284 distinct (token, owner) pairs
│   ├── state_pinned.json         live allowance/balance for all pairs @ 26,253,889
│   ├── drainable_table.{json,csv} 26 drainable pairs, nominal USD
│   ├── extractable_table.csv     fork-measured extractable amounts
│   ├── blocked_table.csv         the blocked pairs and the exact reason
│   ├── eu_table.json             consolidated E-U table + gas
│   ├── prices_llama.json         DefiLlama prices
│   ├── gecko_pools.json / gecko_pools_full.json / geckoterminal_tokens.json   pool + price data
│   ├── poolkeys_all.json / v4_poolkeys.json   v4 PoolKeys from PoolManager Initialize logs
│   ├── sim_extract.json          per-pair simulation results
│   ├── explore_all_results.txt   scope scan output (12 further candidates)
│   ├── multichain_approvals.json Base/Arbitrum/Optimism/Polygon/Unichain scan
│   └── victim_txs.json           the active approver's recent router calls
├── poc/
│   ├── foundry.toml
│   ├── lib/forge-std/            vendored
│   ├── src/README.md
│   └── test/UniswapV4Router04.t.sol   7/7 PASS
├── ci-log.txt                    CI log (written by ci/ci-run.sh)
└── ci-artifacts/                 CI artifacts
```
