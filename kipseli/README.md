# Kipseli Base "reserve" — external-unprivileged extraction assessment

**Date:** 2026-10-23 · **Chain:** Base (8453) · **Status:** read-only; PoC fork-verified only; **no mainnet transactions**; no secrets in this folder.
**Source lane:** `pass4-recon` OPEN #3 (`zombie-hunt-iv/pass4/microcap.md` row 9).

## 1. TL;DR

| Target | Live value (unprivileged) | Why closed / open | Latent risk |
|---|---|---|---|
| Kipseli reserve `0xBEE3211ab312a8D065c4FeF0247448e17A8da000` (ERC1967 proxy, unverified) | **$0** | Every value-moving selector is gated: `withdraw`/`convertETH` → operator EOA; `emergencyWithdraw`/`setAllowance`/`addOperators`/`removeOperators`/`transferOwnership` → 2-of-3 Gnosis Safe owner; proxy upgrade → admin contract whose `owner()` is the same operator EOA. The `withdraw` destination allowlist is **empty**. | P-class: operator EOA key `0x97F7d409…` (or 2 Safe signers) could drain ~$527k. Re-check if the operator EOA ever changes or a destination is approved. |

## 2. Total live extractable now

**$0 (zero) — external unprivileged attacker. Confidence: HIGH.**
Reserve holds **~$527,540** (block 52,975,121) / **~$531,739** (block 52,975,943) in USDC+WETH; all of it is **P-class** (privileged custody).

Category split: **E-U $0 · E-U-conditional $0 · H-O $0 · P ~$527.5k · S $0**.

## 3. The target and mechanism

`0xBEE3211ab312a8D065c4FeF0247448e17A8da000` was flagged by pass4 as an **unverified contract** holding pooled USDC+WETH (a "reserve wallet"); the hypothesis was a Slice-class unguarded `sweep/release`. It is in fact an **ERC1967 proxy**:

- EIP-1967 implementation slot `0x360894…2bbc` → `0x45A507EB92dDF5ab6F10e0a0d124B247e75992a8` (16,412-byte runtime, **unverified**).
- EIP-1967 admin slot `0xb53127…6103` → `0x8Bb03250fD720A6f2Dc043616532c92bd2D42f6E` (**custom ProxyAdmin**, 1,935 bytes).
- The proxy's own runtime (2,009 bytes) only exposes `upgradeToAndCall` (selector `0x4f1ef286`) to the hardcoded admin, and `delegatecall`s everything else to the implementation.

The implementation is a custom **reserve/treasury** contract (Ownable + Initializable) with an operator registry, a destination allowlist, and a WETH constant `0x4200…0006`. Recovered ABI (heimdall; selectors confirmed against the live dispatcher):

| Selector | Function | Gate |
|---|---|---|
| `0x69328dec` | `withdraw(address token, uint256 amount, address to)` | **operator** + `to` must be an approved destination |
| `0xf00baf3e` | `convertETH(uint256)` | **operator** |
| `0x95ccea67` | `emergencyWithdraw(address token, uint256 amount)` | **owner** (Safe) |
| `0x34efb1e9` | `setAllowance(address[] tokens, address spender, uint256 amount)` | **owner** |
| `0xa07aea1c` / `0xd365a377` | `addOperators` / `removeOperators(address[])` | **owner** |
| `0x0eb9142f` / `0x61bb41a7` / `0x7dadbe8c` / `0x9f273fbc` / `0xa908183d` / `0xaf38bf11` / `0x388bb62c` / `0xb9f9fc41` / `0xab06e403` | owner config helpers | **owner** |
| `0x4cf3fe9c` / `0x8594ac40` | executor/batch entrypoints | **trusted-forwarder + owner** |
| `0xf2fde38b` / `0x715018a6` | `transferOwnership` / `renounceOwnership` | **owner** |
| `0x567aa1ba` | `initialize(address)` | already initialized |
| `0x3fc8cef3`, `0x6d70f7ae`, `0xecb9e11a`, `0xd911c632`, `0x26142335`, `0xe3fa62d6`, `0x8da5cb5b`, `0x7d6a4568`, `0x61acbdcb`, `0xd49d5181`, `0x14b7c124`, `0x9e165a78`, `0x1626ba7e` | views (`weth`, `isOperator`, `numberOperators`, `getAllOperators`, `operatorAt`, …) | — |

## 4. Live-state assessment (Base)

| Field | Value |
|---|---|
| Reserve | `0xBEE3211ab312a8D065c4FeF0247448e17A8da000` (proxy) |
| Implementation | `0x45A507EB92dDF5ab6F10e0a0d124B247e75992a8` |
| Proxy admin | `0x8Bb03250fD720A6f2Dc043616532c92bd2D42f6E`; `owner()` = `0x97F7d409…` |
| `owner()` (impl) | `0xbBaE617C0b16639896156B5bD7E33cCE492F958a` = **Gnosis Safe 1.4.1, threshold 2 of 3** |
| Safe owners | `0x97F7d4093e5Bdd0776e2Ca90C90124c5e16Ca569`, `0x8999c5554a983e9b9679ccfab3709830dce75a0b`, `0x8a80ee3234ff0ba250b67398b994cd6c08da9c0e` |
| `numberOperators()` | 1 |
| `operatorAt(0)` / `getAllOperators()[0]` | `0x97F7d4093e5Bdd0776e2Ca90C90124c5e16Ca569` (EOA, code length 0) |
| `weth()` | `0x4200000000000000000000000000000000000006` |
| USDC / WETH balances | block 52,975,121: 440,787.511981 USDC + 36.186163902047726266 WETH; block 52,975,943: 432,429.024960 USDC + 41.408174638709672865 WETH |
| Native ETH | 0 |
| Prices (DefiLlama 2026-10-23) | USDC $0.9994704934726131 · WETH $2403.8388939539973 |

Full raw evidence: `analysis/live_probe.md`, `analysis/kipseli_base_bytecode.txt`, `analysis/kipseli_impl_bytecode.txt`, `analysis/heim_out/decompiled.sol`, `analysis/kipseli_asm.txt`.

## 5. What an attacker can / cannot do

**Cannot (all fork-proven at block 52,975,121):**
- `withdraw(USDC|WETH, amount, anyDest)` from a fresh EOA → `revert "caller is not operator"`.
- `convertETH(amount)` → `revert "caller is not operator"`.
- `emergencyWithdraw`, `setAllowance`, `addOperators`, `removeOperators`, `transferOwnership`, `renounceOwnership` → `revert "Ownable: caller is not the owner"`.
- `initialize(attacker)` → `revert "Initializable: contract is already initialized"`.
- Proxy `upgradeAndCall` via the admin → `revert OwnableUnauthorizedAccount(0x…beef)`.
- Even pranking as the **real operator**, `withdraw` reverts `"destination is not approved"` — the destination allowlist is empty today.
- All 20 state-changing selectors revert from an unprivileged caller; the other 13 are views.

**Can (privileged only):** the operator EOA can `withdraw` to an approved destination and `convertETH`; the 2-of-3 Safe can `emergencyWithdraw`/`setAllowance`/change operators/owner; the operator EOA (as admin owner) can replace the implementation entirely. None of these is reachable by an external unprivileged actor.

No capital/flash-loan path exists: the value never leaves custody without an operator/Safe/admin signature.

## 6. PoC / fork verification

- Project: `poc/` (Foundry 1.8.5, solc 0.8.24, cancun), vendored `lib/forge-std`.
- Test: `poc/test/KipseliReserve.t.sol` — forks Base at block **52,975,121** (`BASE_RPC_URL` env with public fallback).
- **12/12 PASS**: live-state assertions; per-path revert checks with exact require strings; a 33-selector sweep (20 gated / 13 views); operator destination-gate; proxy-admin upgrade gate; net-extractable-zero (balances unchanged after attacker attempts).
- CI: `bash ci/ci-run.sh kipseli` → GitHub Actions `artsbykriss/ca-zombie-ci`. Run URL(s): _see `ci-log.txt` / below_.
- `ci/run.sh` re-reads live owner/operator/admin-owner/balances and writes `ci-out/validation.json` (headline E-U = 0).

## 7. Verdict, residual / latent risk, blockers

**Verdict:** E-U **$0**, high confidence. The pass4 "unverified reserve with an unguarded sweep" hypothesis is **disproven** — the reserve is a gated, operator/Safe-owned treasury.

**Residual / latent risk (P-class, monitor):**
- Single-EOA operator `0x97F7d409…` is also a Safe signer and the proxy-admin owner: compromise of that one key gives `withdraw` + **implementation replacement** (full drain). This is a key-management risk, not an unprivileged one.
- If the operator ever approves a malicious destination (`setAllowance`/destination registry) or the impl is upgraded, the ~$527k moves. Monitor `Upgraded`/`OwnershipTransferred`/`OperatorsAdded` events on the proxy.

**Blockers to a live E-U:** the operator check, the Safe-owner check, the admin-owner check, and the empty destination allowlist.

## 8. Methodology & sources

- `eth_getCode`, `eth_getStorageAt` (EIP-1967 slots), `eth_call` from a fresh EOA at explicit Base blocks via public RPCs; no tx signed/sent.
- Decompilation: `heimdall` (`heim_out/decompiled.sol`, `heim_out/abi.json`) + `cast disassemble`; selectors confirmed against the live dispatcher (33 selectors) and `cast sig`.
- Prices: DefiLlama `coins.llama.fi`.
- Corpus: `pass4-recon/README.md` OPEN #3, `zombie-hunt-iv/pass4/microcap.md`, `pass4-recon/analysis/childA-live.md`.

## 9. Caveats & limitations

- Both proxy and implementation are **unverified**; gates were established dynamically (eth_call revert strings) and via decompilation, not from audited source.
- Balances are point-in-time and move (the reserve is active). Re-read before acting.
- Source-of-funds (protocol fees vs user deposits) was not traced; the contract exposes no user-recovery function, so H-O = 0 either way.
- `setAllowance`'s array encoding was validated (owner call returns success; outsider reverts `Ownable: caller is not the owner`).

## Files index

```
kipseli/
├── README.md
├── summary.json
├── analysis/
│   ├── live_probe.md                 # consolidated live evidence + selector sweep
│   ├── kipseli_base_bytecode.txt     # proxy runtime
│   ├── kipseli_impl_bytecode.txt     # implementation runtime
│   ├── kipseli_impl_abi.txt          # recovered ABI
│   ├── kipseli_asm.txt               # proxy disassembly
│   ├── heim_out/{decompiled.sol,abi.json}
│   ├── impl_src.json, proxy_src.json # "not verified" responses
│   ├── rpclib.py
│   └── selectors_4byte.json
├── poc/{foundry.toml,src/,test/KipseliReserve.t.sol,lib/forge-std}
├── ci/run.sh
├── ci-out/validation.json
├── ci-log.txt
└── ci-artifacts/
```
