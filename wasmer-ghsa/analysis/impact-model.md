# Impact model — what is actually extractable, and by whom

This note separates four things that were conflated in the CA2 write-up:

1. the **compiler defect** (proven),
2. the **publicly demonstrated primitive** (native stack drift → trap / memory corruption),
3. the **advisory-asserted but unpublished primitive** (controlled native code execution in wasmvm),
4. the **financial consequence** (fund extraction vs node compromise vs denial of service).

## 1. Execution model — why "validator RCE" is an incomplete description

`wasmd` links `libwasmvm` (Rust/wasmer) **in-process** through cgo. A contract message is executed by
every validator as part of consensus. Singlepass JIT-compiles the module at instantiation / first use;
the miscompilation is a **compile-time** error, so the bad machine code is generated on every node that
compiles the module, and it executes inside each validator's node process during `vm.Execute`.

That gives three distinct consequence classes, which have very different economics:

| class | what happens | determinism needed? | who is compromised | money |
|---|---|---|---|---|
| **A. DoS / halt** | drift hits the guard page → trap or SIGSEGV; if all validators fault on the same tx, the chain stalls until restart/replay | no (any node crashing is enough to lose a block; all nodes = halt) | liveness only | none directly; temporary outage |
| **B. single-host RCE** | controlled escape on the machine(s) that execute the tx; read `priv_validator_key.json`, keyring, DB | no | every host that executes it, but *independently* | validator key ⇒ equivocation/slashing, not theft of delegators' funds; keyring ⇒ operator hot wallets only |
| **C. consensus-level RCE** | the corrupted native execution is *deterministic* and can call host functions (bank keeper) inside the tx → arbitrary state transition committed by all validators, **no keys needed** | **yes** | the chain's state machine | direct mint/transfer ⇒ bounded only by exit liquidity |

CA2 asserted class **B** and stopped there ("validator/sentry RCE, not a direct fund-theft primitive").
That is the wrong frame for a consensus-replicated runtime: if the escape is deterministic, the
attacker does not need to steal any validator key — their own contract execution performs the state
change on every validator. Class **C** is the real terminal impact, and it is exactly the "unprivileged
native mint" target that our CWA-2026-006 work pursued (M1–M4).

Conversely, CA2's headline number (14.42 M JUNO of *contract-held* balances) is not the ceiling of
either B or C: class C can mint or move any balance, and class B is about keys, not contract balances.
Contract-held value is a defensible proxy for "value sitting in code that runs in wasmvm"; it is not
an extractable amount.

## 2. What is proven today

- **Defect**: yes. Source-verified in v7.4.2 *and* v7.5.0; PR #7128 fixes it on `main`; not released.
- **Public primitive**: native-stack drift of 8 bytes per affected execution, cumulative, leading to a
  guard-page trap. Demonstrated by the upstream regression test (400 000 iterations) and re-run
  independently in CI for this report.
- **Permissionless delivery**: yes on Juno (`code_upload_access = Everybody`,
  `instantiate_default_permission = Everybody`). Cost of `MsgStoreCode` + `MsgInstantiateContract` is
  cents — the blocker is the exploit, not the delivery.
- **Controlled escape**: **no public artefact.** The advisory attributes NCE to the reporter in a
  wasmvm deployment and states the maintainers did **not** reproduce it.
- **Observed exploitation**: none reported by wasmer, CosmWasm or Juno; no on-chain signature of a
  halt or an anomalous mint was found in this work.

## 3. What an external unprivileged attacker can extract *today*

**$0.** There is no published or reproducible controlled escape, so there is no path from "funded
account on Juno" to value. The reachable, demonstrated outcome is a trap / node crash.

That is not a claim that the bug is harmless — it is a claim that the **extraction** is unproven, and
that the burden is on the unpublished NCE claim, not on the chain state.

## 4. Conditional ceiling if the withheld NCE is real

Two sub-cases, with measured numbers (Juno, block-height snapshot from `ci-out/juno-contract-value.json`):

| sub-case | ceiling | value |
|---|---|---|
| **C, deterministic mint/transfer** | realizable exit liquidity | **≈ $40.8 k** (DefiLlama "Juno" chain TVL, 2026-11-03) |
| C, nominal book value reachable | liquid (unstaked) JUNO 89.37 M + staked 54.04 M | ≈ $563 k liquid / ≈ $904 k total supply |
| C, if limited to contract-held balances (CA2's metric) | 14.42 M JUNO | ≈ **$91,045.91** (measured 14,421,378.203823 JUNO at $0.00631326, block 43,367,036) |
| **B, validator-key theft** | operator hot keys / slashing exposure | not a transfer of delegator funds; slashing of 32.67 M JUNO bonded (≈ $206 k) is the upper bound of *damage*, not of *theft* |
| **A, halt** | outage cost | not quantified; 25 bonded validators |

Why $40.8 k and not $904 k: a mint primitive is only worth what you can sell into. Juno's entire DeFi
TVL is $40,848.74, and the JUNO/USDC and JUNO/ATOM pools are a fraction of that. Nominal supply is not
realizable.

## 5. Can the RCE be monetised *without* validator-key theft?

Only through class **C**. Class B needs key material (and on Cosmos, a stolen validator key does not
transfer delegators' funds — it enables equivocation and slashing). There is no shortcut in which an
attacker drains a contract balance with the compiler bug alone: contract balances move only through
consensus-executed messages, so either the escape is deterministic inside the tx (class C) or it is a
node compromise (class B).

The specific question "permissionless upload **plus** a directly drainable contract balance" therefore
resolves as: Juno has permissionless upload; the contract balances are **not** directly drainable by any
*separate* public path found here; and the only route from the bug to those balances is the unproven
class-C escape. The 14.42 M JUNO is spread over **1,650 contracts** (mean ≈ $55) and is heavily
concentrated: the largest contract holds **6,939,229.31 JUNO ≈ $43.8 k** (48 % of the total) and the top
two hold ≈ 70 %. So even a per-contract drain primitive would be a two-target problem, while a native
mint would not need either contract at all.

## 6. Ledger classification

| category | USD | note |
|---|---|---|
| **E-U** (proven) | **$0.00** | no public controlled escape; no deterministic consensus-level primitive demonstrated |
| **E-U-conditional** | **≤ $40,848.74** | only if the withheld NCE is real *and* deterministic; then bounded by Juno exit liquidity; explicitly not claimed as extractable |
| **H-O** | $0.00 | no user-serviceable recovery path in this finding |
| **P** | $0.00 | no privileged path to value |
| **S** | $0.00 | nothing is bricked |

**Primary classification: infrastructure RCE (CWE-787, CVSS 10.0, S:C), not an E-U fund-drain.**
It should be tracked on the infrastructure/RCE ledger, with a conditional E-U tail that is gated on an
unpublished exploit.

## 7. Confidence

| claim | confidence |
|---|---|
| advisory contents, CVSS, published_at, empty patched range | **high** (direct API read) |
| 7.4.2 == 7.5.0 codegen; 7.5.0 vulnerable; no released fix | **high** (byte-identical file + crates.io/release metadata) |
| Juno runs v31.0.0 / wasmvm v3.0.8 / wasmer 7.4.2 | **high** (live `node_info` + `go.mod` + `Cargo.lock` + tag-commit match) |
| Juno upload+instantiate permissionless | **high** (live params) |
| contract-held JUNO = 14,421,378.20 JUNO ≈ $91,045.91 | **high** (re-measured, CI artifact) |
| realizable ceiling ≈ $40.8 k | **medium** (DefiLlama chain TVL is a proxy; pool-level depth not measured) |
| a deterministic class-C escape exists | **low** (single unreproduced reporter claim; our independent CWA-006 work found the analogous terminal call architecturally blocked) |
| no live exploitation | **medium-high** (no advisory/report; not exhaustively monitored) |

What would change the verdict: a public or independently reproduced controlled escape that is
deterministic across validators. That single artefact moves this from $0/infrastructure to
E-U ≈ $41 k realizable on Juno (and larger on bigger chains if any run 7.x).

## 8. Operational note that is easy to miss

The advisory warns that **already-compiled or serialized native artifacts stay vulnerable after the
compiler is upgraded** and must be invalidated and recompiled. wasmvm caches compiled modules on disk
(`WASMVM_CACHE`). A contract uploaded before a Juno upgrade but executed after it would still run the
vulnerable machine code. Any remediation on Juno must purge the wasm cache, not just bump wasmvm.
