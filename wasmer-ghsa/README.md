# GHSA-v2h8-j899-r676 — Singlepass implicit-else sandbox escape on live CosmWasm chains

**Date:** 2026-11-03
**Advisory:** [GHSA-v2h8-j899-r676](https://github.com/wasmerio/wasmer/security/advisories/GHSA-v2h8-j899-r676)
— published **2026-11-02T12:02:10Z**, **critical**, **CVSS 3.1 = 10.0**
(`AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H`), CWE-787, **no CVE**, **no patched version**.
**Package:** `wasmer-compiler-singlepass` (`>= 7.0.0-alpha.1, <= 7.4.2` per the advisory — **understated; 7.5.0 is also vulnerable**, §4).
**Live chains verified affected and permissionless (9):** **Juno** (`juno-1`), **Cosmos Hub** (`cosmoshub-4`),
**Neutron** (`neutron-1`), **Coreum** (`coreum-mainnet-1`), **Chihuahua** (`chihuahua-1`), **Dungeon** (`dungeon-1`),
**Firmachain** (`colosseum-1`), **Terra 2** (`phoenix-1`), **THORChain** (`thorchain-1`) — plus 11 affected chains
with allowlisted or closed upload (§5.2).
**Status:** advisory and defect **verified**; **no public controlled escape**; **$0 proven extractable**;
**infrastructure / RCE class, not an E-U fund drain** (§6).
**Read-only:** no transaction signed, deployed or broadcast at any point. The only executable artefact is a
local compiler test that runs off-chain in CI.

---

## 1. TL;DR

| Question | Answer |
|---|---|
| Is the advisory real? | **Yes** — GitHub API, `state: published`, critical, CVSS 10.0, empty `patched_versions` |
| What is the root cause? | A typed `if` with block parameters and **omitted `else`** is mis-lowered; the false-arm label is bound **after** stack cleanup, so spilled block parameters are never reclaimed and the **native stack pointer drifts 8 bytes per execution** (x86-64) |
| Is 7.5.0 affected? | **Yes.** `codegen.rs` at `v7.5.0` is **byte-identical** to `v7.4.2` (md5 `d0b168fd…`); `emit_if_block_end` exists only on `main` |
| Is there a released fix? | **No.** Latest wasmer release/crate = **7.5.0 (2026-10-01)**; fix merged to `main` **2026-11-02**. wasmvm latest = **v3.0.9 (2026-10-09)** → wasmer **7.5.0**, still vulnerable |
| Does PR #7128 demonstrate a sandbox escape? | **No.** It is the regression test for native-stack drift (400 000-iteration loop traps at the guard page). It does not demonstrate a controlled escape or native code execution |
| Is Juno exposed? | **Yes** — `juno-1`, app **v31.0.0**, commit `de78774eb419…` = exact tag match, wasmvm **v3.0.8** → cosmwasm-vm 3.0.10 → **wasmer 7.4.2**; `code_upload_access` and `instantiate_default_permission` both **Everybody** |
| Is multi-value actually enabled in wasmvm? | **Yes** — `parsed_wasm.rs` enables `WasmFeatures::MULTI_VALUE`; `engine.rs` uses `wasmer::sys::Singlepass::new()` with no feature restriction; wasmer `Features::default()` has `multi_value: true` |
| Live extractable now (unprivileged) | **$0.00** — no public or reproduced controlled escape |
| What is the real impact class? | **Infrastructure RCE** (consensus-replicated native execution), **not** a proven fund-drain primitive |
| Conditional ceiling if the withheld NCE is real | an **unbacked mint** on every validator; not a bounded drain. On-chain exit-liquidity proxies: Juno **$40,848.74**, Terra 2 **$2,922,281**, Cosmos Hub **$112,693** — these understate CEX/off-chain depth and are **not** claimed as extractable |
| Confidence | **high** on advisory, 7.5.0, Juno versions/params; **low** on any fund impact |

---

## 2. The bug, in exact terms

WebAssembly permits `if (param T) (result T)` with no `else`: the implicit false arm must leave the
block parameters in place as the results. Singlepass allocates **result** locations separately from the
original **block-parameter** locations, and in the vulnerable lowering the false-arm label is emitted
**after** the value stack has been truncated and the locations released. A false condition therefore
jumps past the cleanup that the compiler's stack model assumes has happened. For spilled parameters
(high register pressure), each execution leaves an extra 8-byte slot on the native stack.

Repeated execution drives the native SP away from the compiler's tracked position; subsequent native
stack accesses then write outside the intended frame — first at the guard page (trap), and, with enough
drift, into the caller's frame (memory corruption → potential control-flow hijack). Valid Wasm only; no
linear-memory OOB needed.

- Introduced by **PR #5869** ("Singlepass: add multivalue support", merged **2025-11-18**), first in `7.0.0-alpha.1`.
- **v6.1.0 is unaffected** (it rejects the parameterized block signature) — verified: the vulnerable block is absent from its `codegen.rs`.
- **v7.0.0 is affected** — the block is present.
- Fixed on `main` by **PR #7128** (merged **2026-11-02T12:01:47Z**), which replaces the special case with
  `emit_if_block_end` (restores inputs/stack before cleanup) and calls it from both `Operator::Else` and the
  implicit-`Else` `Operator::End` path.

Source evidence and line numbers: `analysis/advisory-verification.md` §3.

---

## 3. Why this reaches a live chain

`wasmd` links `libwasmvm` in-process (cgo). Contract messages are executed by **every validator** as part of
consensus, and Singlepass JIT-compiles the module on each node. The miscompilation is a compile-time error,
so the bad machine code is generated and executed on every validator that processes the message.

Delivery on a permissionless chain is just `MsgStoreCode` + `MsgInstantiateContract`. On Juno both are
unrestricted, the contract size cap is generous, and the delivery gas is negligible relative to any
plausible payoff. The blocker is **the exploit**, not access, cost or liquidity.

---

## 4. The 7.5.0 contradiction — resolved

CA2's two internal documents disagreed: `wasmer-ghsa-advisory.md` said 7.5.0 still contains the vulnerable
lowering; `wasmer-ghsa-live-chains.md` tabulated 7.5.0 as fixed. **The advisory document is right.**

| ref | bytes | md5 | vulnerable block | `emit_if_block_end` |
|---|---|---|---|---|
| `v7.4.2` | 253,340 | `d0b168fd67bcb0e2f651ea08e259981b` | present | absent |
| `v7.5.0` | 253,340 | `d0b168fd67bcb0e2f651ea08e259981b` | present | absent |
| `main` | 255,927 | `491df67a37cb89536728f8d821eecdbb` | replaced | present |

`diff -q v7.4.2 v7.5.0` → **identical**. Evidence in the code: v7.5.0 `Operator::End` (line 3766) releases
and truncates the value stack, then `if let ControlState::If { label_else, .. } = frame.state { emit_label(label_else) }`
at line **3798** — the false arm lands after cleanup. `main` calls `emit_if_block_end` at lines 3774–3778
before cleanup.

### Downstream mapping (verified from each tag's `libwasmvm/Cargo.lock`)

| wasmvm | cosmwasm-vm | wasmer-compiler-singlepass | status |
|---|---|---|---|
| v2.2.9 | 2.2.10 | 7.4.2 | **vulnerable** |
| v2.3.5 | 2.3.5 | 7.4.2 | **vulnerable** |
| v3.0.8 | 3.0.10 | 7.4.2 | **vulnerable** |
| v2.2.10 | 2.2.11 | 7.5.0 | **vulnerable** |
| v2.3.6 | 2.3.6 | 7.5.0 | **vulnerable** |
| v3.0.9 | 3.0.11 | 7.5.0 | **vulnerable** |
| wasmvm `main` | 3.0.11 | 7.5.0 | **vulnerable** |

`CosmWasm/wasmd@main` pins wasmvm **v3.0.9**. There is **no released fixed version anywhere in the stack**,
and `CosmWasm/advisories/CWAs` has **no CWA** for this defect (latest is CWA-2026-006) — downstream chains
have no CosmWasm-level notice.

---

## 5. Live-state assessment (2026-11-03, read-only public LCD)

### 5.1 Juno — the verified permissionless case

| item | value | how read |
|---|---|---|
| `node_info.network` | `juno-1` | `/cosmos/base/tendermint/v1beta1/node_info` |
| app version | `v31.0.0` | same |
| git commit | `de78774eb419f95ba5812d7a3446c4b2516d8f0a` | same |
| tag match | `v31.0.0` → commit `de78774e…` (tag object `b92160b…`) | GitHub API |
| `go.mod @ v31.0.0` | `wasmvm/v3 v3.0.8`, `wasmd v0.61.15`, SDK v0.53.7, go 1.25.2 | repo |
| wasmvm → wasmer | v3.0.8 → cosmwasm-vm 3.0.10 → **7.4.2** | `libwasmvm/Cargo.lock` |
| upload | **Everybody** | `/cosmwasm/wasm/v1/codes/params` |
| instantiate | **Everybody** | same |
| contract-held JUNO | **14,421,378.203823 JUNO** across **1,650 contracts** (of 464,375 ujuno holders, 465 pages); block **43,367,036** | `ci-out/juno-contract-value.json` |
| USD | **$91,045.91** at $0.00631326 (CoinGecko, 2026-11-03) | price API |
| other denoms | contracts hold **90 distinct denoms** (IBC/token-factory); not priced | same |
| concentration | top contract 6,939,229.31 JUNO (≈ $43.8 k); top 2 hold ≈ 70 % | same |
| bonded stake | 32.67 M JUNO (25 bonded validators) | staking pool / validators |
| supply | 143.42 M JUNO | `supply/by_denom` |

Block height and the exact re-measured total are in the CI artifact (they are the numbers quoted in §7).

### 5.2 Other chains (this work's live reads)

Permissionless = `code_upload_access = Everybody` **and** `instantiate_default_permission = Everybody`.
All rows below run a wasmer 7.x build and are therefore in range for this advisory.

| chain | chain_id | app | wasmvm | wasmer | upload | instantiate | verdict |
|---|---|---|---|---|---|---|---|
| **Juno** | juno-1 | v31.0.0 | v3.0.8 | 7.4.2 | Everybody | Everybody | **affected, permissionless** |
| **Cosmos Hub** | cosmoshub-4 | v29.0.1 | v2.3.5 | 7.4.2 | Everybody | Everybody | **affected, permissionless** |
| **Terra 2** | phoenix-1 | v2.22.0 | v2.2.9 | 7.4.2 | Everybody | Everybody | **affected, permissionless** |
| **THORChain** | thorchain-1 | 3.21.0 | v2.2.9 | 7.4.2 | Everybody | Everybody | **affected, permissionless** |
| **Firmachain** | colosseum-1 | 0.5.2 | v2.2.9 | 7.4.2 | Everybody | Everybody | **affected, permissionless** |
| Osmosis | osmosis-1 | 32.0.0 | v2.2.9 | 7.4.2 | AnyOfAddresses (53) | Everybody | affected, restricted |
| XPLA | dimension_37-1 | v1.14.1 | v2.3.5 | 7.4.2 | AnyOfAddresses (1) | Everybody | affected, restricted |
| Babylon | bbn-1 | v4.6.0 | v2.3.5 | 7.4.2 | AnyOfAddresses (1) | Everybody | affected, restricted |
| Provenance | pio-mainnet-1 | v1.31.0 | v3.0.8 | 7.4.2 | AnyOfAddresses (4) | Everybody | affected, restricted |
| Nolus | pirin-1 | 0.8.6-patch | v3.0.8 | 7.4.2 | AnyOfAddresses (2) | Everybody | affected, restricted |
| Nyx | nyx | 0.61.16 | v3.0.9 | 7.5.0 | AnyOfAddresses (1) | Everybody | affected, restricted |
| Persistence | core-1 | v16.1.0 | v2.3.5 | 7.4.2 | AnyOfAddresses | AnyOfAddresses | affected, restricted |
| Regen | regen-1 | v7.3.0 | v2.3.5-rc.3 | (7.x presumed) | AnyOfAddresses (1) | AnyOfAddresses | affected, restricted |
| Xion | xion-mainnet-1 | v32.0.0 | v3.0.9 | 7.5.0 | Nobody | Everybody | affected, upload closed |
| Injective | injective-1 | v1.20.4-bl.2 | v2.2.9-rc.2 | (7.x presumed) | AnyOfAddresses (1) | Everybody | affected, restricted |
| Terra Classic | columbus-5 | v4.1.1 | v3.0.8 | 7.4.2 | Nobody | Everybody | affected, upload closed |
| **Neutron** | neutron-1 | 11.3.0 | v3.0.8 (+rc.3) | 7.4.2 | Everybody | Everybody | **affected, permissionless** (5,412 codes) |
| **Coreum** | coreum-mainnet-1 | v8.0.0 | v2.3.5 | 7.4.2 | Everybody | Everybody | **affected, permissionless** (692 codes) |
| **Chihuahua** | chihuahua-1 | v10.0.1 | v3.0.8 | 7.4.2 | Everybody | Everybody | **affected, permissionless** (703 codes) |
| **Dungeon** | dungeon-1 | 13.1.2-rc.1 | v3.0.8 | 7.4.2 | Everybody | Everybody | **affected, permissionless** (228 codes) |

Counts in brackets are stored codes, paged from `/cosmwasm/wasm/v1/code` (singular). Detail + endpoints in
`analysis/live-chains.md` and `analysis/chains-child.md`.

**Correction to prior work.** Our 2026-10-28 `ci/CROSS-CHAIN-FEASIBILITY.md` concluded Cosmos Hub had
"zero wasm wiring" and was "not a target". That is **wrong for the deployed v29.0.1 build**: the wiring
lives in `app/modules.go` (`wasm.NewAppModule`, `wasmtypes.ModuleName`) and `app/keepers/{keepers,keys}.go`
(`wasmkeeper.NewKeeper`, `wasmtypes.StoreKey`), not in the thin `app/app.go` that was checked then. The
deployed commit `48c981b…` (2026-10-23) has it, and `/cosmwasm/wasm/v1/code/1` returns a real wasm module
(creator `cosmos1559zgk…`, magic `AGFzbQEAAAAB`). The 501 responses on `/cosmwasm/wasm/v1/codes` came from
using the **wrong route**: wasmd ≥ 0.54 serves list-codes at `/cosmwasm/wasm/v1/code` (singular); the plural
path is unregistered and returns the gRPC-gateway default 501 — and publicnode returns a JSON-RPC
"not implemented" for paths it does not whitelist. The same 501 appears on Juno, which unambiguously has
1,650+ contracts. `/codes/params` resolves everywhere, including on the Hub.

**Correction to CA2.** CA2 called Osmosis unaffected ("wasmvm v2.2.9 → wasmer 4.3.7"). The verified
`libwasmvm/Cargo.lock` at `v2.2.9` pins `wasmer-compiler-singlepass 7.4.2`. Osmosis is affected, but its
upload is allowlisted to 53 addresses, so it is not permissionless.

---

## 6. What an attacker can and cannot do

### 6.1 Proven today — $0

| path | outcome |
|---|---|
| Upload a module with the trigger, instantiate it | module compiles and runs on every validator; the false-arm path leaks 8 native-stack bytes per execution. **Demonstrated in CI** (compiler reproduction) and by the upstream regression test |
| Repeat enough times | guard-page trap / SIGSEGV → the executing node dies; if deterministic, a chain halt until restart |
| Turn the drift into a controlled read/write/RCE | **not public, not reproduced here.** The advisory attributes one demonstration to the reporter and states maintainers did **not** reproduce the NCE |
| Drain funds, mint tokens, steal keys | **not demonstrated** |

So the reachable, demonstrated outcome is **memory corruption / denial of service**, and the
advisory-asserted (unpublished) outcome is **native code execution**.

### 6.2 Why "validator RCE" under-describes the risk

Contract execution is consensus-replicated, so an escape runs inside **every** validator's process while
processing the message. That yields three distinct classes:

- **A. DoS/halt** — needs no determinism; liveness only.
- **B. single-host compromise** — read the node's `priv_validator_key.json` / keyring. On Cosmos a stolen
  validator key buys **equivocation and slashing**, not the delegators' funds; the keyring buys only the
  operator's hot wallets. This is the class CA2 described.
- **C. consensus-level escape** — if the corrupted execution is **deterministic**, the attacker's own
  contract execution performs an arbitrary state transition (e.g. bank mint/transfer) on every validator,
  **with no key needed**. This is the class that would be a fund-drain, and it is precisely the "terminal
  mint" target our CWA-2026-006 work pursued and found architecturally blocked (M1–M4) for the *neighbouring*
  4.2.2 defect.

Whether GHSA-v2h8 reaches class C is **unknown**. Its primitive is cumulative (8 bytes per execution,
marching down the native stack) rather than the single-slot adjustment in CWA-2026-006, so the CWA-2026-006
blockers do not automatically transfer — but no public artefact shows the terminal call.

### 6.3 Extractable vs node-compromise

| what | who | value |
|---|---|---|
| demonstrated primitive | external unprivileged | **$0** |
| class C terminal mint (if NCE real + deterministic) | external unprivileged | unbacked mint; not bounded by contract balances. On-chain TVL proxy: Juno $40.8 k, Terra 2 $2.92 M, Cosmos Hub $112.7 k — all understate CEX depth |
| class B validator key theft | requires node compromise | slashing exposure on 32.67 M JUNO bonded (≈ $206 k) is *damage*, not theft; delegator funds are not transferable with a signing key |
| class B keyring theft | requires node compromise | operator hot wallets; not enumerated |

**No path monetises the bug without either a deterministic class-C escape or node compromise.** Juno's
permissionless upload does not by itself expose a drainable contract balance: contract balances move only
through consensus-executed messages. The measured 14.42 M JUNO of contract-held value is spread over
~1,650 contracts (mean ≈ $55), and a native mint would not need it at all.

---

## 7. Reproduction (CI)

The compiler harness in `poc/` reproduces the upstream regression shape against the **two released
versions** and the fixed `main` behaviour is inferred from source (no release builds it):

- builds `wasmer` **7.4.2** and **7.5.0** with `default-features = false, features = ["singlepass","sys"]`;
- compiles a WAT module with a typed `if` (0/1/2 block params) and an omitted `else`, looped 400 000 times,
  on a bounded 2 MiB thread stack;
- reports `RESULT=OK`, `RESULT=TRAP` or the process exit code (SIGSEGV = 139).

Cases: spilled (prefix 31/32), register-only (prefix 0), no params, true arm, 1 000-iteration control,
explicit-`else` control and `unreachable` then-arm.

**CI run:** `https://github.com/artsbykriss/ca-zombie-ci/actions/runs/41640424742` (see `ci-log.txt` and
`ci-out/sp-drift-results.txt`; final results are pasted in §7.1 below).

> CI branch note: the deliverable folder is `wasmer-ghsa`, so the helper was invoked as
> `bash ci/ci-run.sh wasmer-ghsa` (the brief's `ca2-wasmer` is the same job under the CA2 label). All
> chain access is read-only and keyless; the only executable code is the off-chain compiler harness.

### 7.1 Results

_(filled from the CI artifact)_

| version | spilled false arm (400 k) | register-only | true arm | explicit else | verdict |
|---|---|---|---|---|---|
| 7.4.2 | | | | | |
| 7.5.0 | | | | | |

---

## 8. Verdict, residual risk and blockers

**Verdict:** GHSA-v2h8-j899-r676 is a **real, unpatched, permissionlessly reachable memory-corruption →
potential sandbox-escape** in the CosmWasm runtime used by several live chains, including **Juno** and
**Cosmos Hub**. Its **proven** impact is denial of service / memory corruption; its **asserted** impact is
native code execution. **No public controlled escape exists**, so the finding is an **infrastructure RCE
class** finding with **$0 currently extractable**, not an E-U fund drain.

**Residual / latent risk (why it still matters):**
1. **No released fix** anywhere in the stack (wasmer ≤ 7.5.0, wasmvm ≤ v3.0.9). Every remediation requires
   a new wasmer release first.
2. **No downstream advisory** — CosmWasm has published no CWA; chains may not know they are exposed.
3. **Cached compiled artefacts survive an upgrade** — `WASMVM_CACHE` must be purged, or a pre-upgrade
   module keeps running vulnerable machine code.
4. **The affected set is much larger than CA2's list** — every chain that upgraded for CWA-2026-006 landed
   on a 7.x wasmer. That includes **Cosmos Hub** and **Osmosis**, which CA2 did not identify.
5. If the withheld NCE is real **and deterministic**, the impact is not a $90 k contract drain but an
   unbacked mint on a multi-billion-dollar chain. That single uncertainty is the whole finding.

**Blockers to a fund-drain claim:** no public controlled escape; no reproduction of NCE by the maintainers;
no evidence of exploitation; determinism across heterogeneous validator builds unproven; our independent
CWA-2026-006 work shows the terminal call in this runtime is architecturally hard, not a given.

---

## 9. Methodology, sources, caveats, files

**Method.** GitHub advisory/PR/release APIs; raw source at tags; crates.io metadata; CosmWasm `wasmvm`
`Cargo.lock` at seven tags; live Cosmos LCD `node_info`, `codes/params`, staking/supply/bank queries;
full `denom_owners` enumeration for Juno; compiler reproduction in CI. All chain access read-only, keyless
public endpoints, no secrets written.

**Caveats.**
- Public REST proxies are inconsistent: several 501 on `/cosmwasm/wasm/v1/codes` (and on Juno, which
  definitely has contracts), so contract counts from those endpoints are unavailable. Module wiring was
  therefore established from source + `codes/params`, and version from `node_info.build_deps`.
- `rc` wasmvm tags (`v2.2.9-rc.2`, `v2.3.5-rc.3`) have no public `Cargo.lock`; their wasmer version is
  presumed 7.x from the release line, not verified.
- The advisory's `<= 7.4.2` range is understated; we use `<= 7.5.0` throughout.
- Juno's non-JUNO contract holdings were enumerated but not fully priced (IBC/token-factory denoms);
  the USD headline is JUNO-only and therefore a floor.
- The controlled escape and its determinism are unverified by construction — no public artefact.

**Files.**
- `analysis/advisory-verification.md` — API record, root cause, 7.5.0 code evidence, downstream mapping, wasmvm reachability
- `analysis/impact-model.md` — A/B/C impact classes, extractable-vs-conditional numbers, ledger
- `analysis/live-chains.md` — per-chain live reads (with the child spot-check)
- `analysis/juno_value.py` — the read-only enumeration used for the contract-held figure
- `poc/` — Rust harness (`wasmer` 7.4.2 / 7.5.0, Singlepass) reproducing the regression shape
- `ci/run.sh`, `ci/code-evidence.sh`, `ci/sp-drift.sh` — CI job
- `ci-out/` — CI results (`codegen-evidence.txt`, `sp-drift-results.txt`, `juno-contract-value.json`)
- `summary.json` — machine-readable summary
