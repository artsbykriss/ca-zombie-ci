# LIVE-BROADCAST PLAN — CWA-2026-006 on Archway mainnet (`archway-1`)

**Finding:** CWA-2026-006 ("WASMageddon") — Wasmer Singlepass codegen defect in the wasmvm
engine → sandbox escape → native code execution in the node process.
**Target:** Archway mainnet `archway-1` (app `archway` v10.1.0, wasmvm **v1.5.5** / Wasmer **4.2.2**).
**Scope of this document:** read-only gap analysis + plan. **No broadcast, signing, deployment, or
live-chain interaction.** The downstream cash-out / exit is out of scope (owned by the main team).

**Authoritative inputs**
- Verified local PoC: `artsbykriss/kimi-cwa006` → `docs/TECHNICAL-RECORD.md` §0 (final report card),
  `results/campaign-m4/fullchain-callback-v3/`, `results/campaign-m4/final-validation/`.
- archwayd target analysis: `archway/analysis/mint-call-candidates.md`, `archway/mint/e8/`,
  `archway/ci-artifacts/result-archway-mint/`, and this campaign's CI port run
  (`artsbykriss/ca-zombie-ci` run **40370745650**, artifacts `ci-out/port/`).
- Engine / stack model: `docs/WEAPONIZATION.md`, `docs/singlepass-batch-layout.md`,
  `docs/go-native-call-feasibility.md`.

---

## 0. Verdict (headline)

| Layer | Verdict | One line |
|---|---|---|
| Engine vulnerability (wasmvm 1.5.5 / Wasmer 4.2.2) | **LIVE-CONFIRMED** | Same engine, hash-matched on chain; permissionless upload + instantiate. |
| Delivery (store / instantiate / execute the guests) | **READY** | `code_upload_access=Everybody`, `instantiate_default=Everybody`; tiny contracts; ~28 M gas ≪ 300 M block limit. |
| Control-transfer mechanics (pivot → ROP → Go re-entry) | **READY-in-principle / PARTIAL** | Every harness gadget has an archwayd equivalent (§2); `runtime.g0` and the ABI0 entry need one CI confirmation. |
| **Mint invocation (the actual value transfer)** | **NOT-FEASIBLE with the demonstrated primitive** | The harness's `mintBridge` does not exist on archwayd; `cgocallback` can only invoke `func(unsafe.Pointer)`; and a valid `sdk.Context` + `*BaseKeeper` are unreachable **without an arbitrary-read/pointer leak (M1), which was never achieved.** See §3. |

**Overall: PARTIAL.** The vulnerability is real and the exploit primitive is proven and portable in
principle, but **the live end-to-end mint cannot be delivered today.** The single blocking
prerequisite is an **ASLR/pointer-leak primitive (M1)** plus a **multi-argument invocation mechanism**
and a **clean-commit continuation** — none of which exist in the current package.

---

## 1. The verified local chain (ground truth — do not re-derive)

Reproduced by the principal: vulnerable **6/8** `M4BANK`, patched control **3/3** clean (exit 0,
nested=4). All addresses are the **local non-PIE harness binary**
(`results/calibration/harness-vulnerable`, sha256 `5a52bf6d…`), **not** archwayd.

- Guests: `results/campaign-m4/fullchain-callback-v3/`
  - `holder.wasm` `9313c414…` — bare holder, exports `execute`; imports `env.query_chain`; its
    `execute` issues a `WasmQuery::Smart` and then XOR-folds 10 staged locals (the ROP chain).
  - `trigger.wasm` `52e38e22…` — imports `env.db_read`; `query` runs 66 283 iterations with a
    result-bearing `if` and 16 live values; calls `db_read` when `(i+234)&511==0`.
  - `benign.wasm` `87e54ca8…` — warm-up contract (harness-only; **not needed live**).
- Calibration: `--pre-call-drops 15 --frame32 2`; **R=234, K=2**; `--offset 278 --iters 66283`.
  Useful crossing at **i=65814 / db_read=132**; holder's live return slot at **holder fibre `top-0x308`**.
- Native chain (harness addresses):

  ```text
  holder top-0x308
    -> 0x4d93f8   add rsp,0x150; pop rbp; ret          (pivot)
    -> 0x437c64   pop rax; ret                          (RAX = runtime.g0 0x2fd1440)
    -> 0x861144   movups xmm15,0x10(rax); ret           (zero g0.stackguard0/1)
    -> 0x49b300   runtime.cgocallback.abi0
         [rsp+0x00] = 0x4999c8   landing (UD2)
         [rsp+0x08] = 0x1768780  fn = main.mintBridge
         [rsp+0x10] = 0            frame
         [rsp+0x18] = 0            ctxt
    -> 0x1768780  main.mintBridge(nil)  -> bank.keeper.MintCoins(bank.ctx,"mint",1000000aarch)
  ```

- `source/harness/bank.go` `mintBridge(_ unsafe.Pointer)` is the **harness-only** bridge. It owns a
  package-global `demoBank` with a **pre-constructed** `sdk.Context` and an in-memory `BaseKeeper`.
  It calls the **real Cosmos SDK v0.50.10 `BaseKeeper.MintCoins`** (not a mock), changing in-memory
  supply `0aarch → 1000000aarch`.
- Reliability: probabilistic; 6/8 uninstrumented runs, failures = SIGSEGV (exit 139) and
  `morestack on g0` (exit 2). Process exit 1 *after* `M4BANK` is the expected post-callback tail.

**What this proves:** the drift → guard-skip → cross-stack write → `RIP ← attacker value` →
Go re-entry (`cgocallback`) → SDK mint path is real through the **exact deployed engine**.
**What it does not prove:** that any of the *native* (Go-side) part ports to archwayd (§2/§3).

---

## 2. archwayd adaptation — address-by-address port table

**Target binary:** `archwayd_linux_amd64` v10.1.0, sha256
`cf9ae83316d7681cbf4f1dd3a65ef2a641678f4521c964226c5c70f9a1655901`, 105,198,520 B,
stripped, statically linked, **non-PIE `ET_EXEC`**, entry `0x44f889`, Go BuildID `a8xqi8ibt8ASDIS621Dl/…`.
Source: CI run **40370745650** (`ci-out/port/`).

| Role | harness value | **archwayd v10.1.0** | Port status |
|---|---|---|---|
| Pivot `add rsp,0x150; pop rbp; ret` | `0x4d93f8` | **`0x538dc5`** (+4 more: `0x538f2a`,`0x538f7c`,`0x53928b`,`0x539580`; 763 total) | **PORT-READY** (exact same gadget) |
| `pop rax; ret` | `0x437c64` | **`0x401001`** (334 total) | **PORT-READY** |
| Guard clear `movups %xmm15,0x10(%rax); ret` | `0x861144` | **`0x5cc615`** (also `movups %xmm0,0x10(%rax); ret` `0x5cc76a`) | **PORT-READY** (needs XMM15/XMM0 = 0 at pivot) |
| Terminal `ud2` landing | `0x4999c8` | **`0x4010ef`** (31 729 total) | **PORT-READY** |
| `runtime.cgocallback.abi0` | `0x49b300` | **`0x47e880`** (`runtime.cgocallback`; ABI0 args on stack) — *confirm ABI0 vs body on CI* | **PORT-CANDIDATE** |
| `runtime.g0` (data) | `0x2fd1440` | **CI-derivable** (see §2.1) | **RE-DERIVE** |
| `main.mintBridge` | `0x1768780` | **none** | **NO EQUIVALENT** |
| `crosscall2` / `crosscall2_trampoline` | `0x55b520` / `0x55b4e0` | `0x7f8300` / `0x7f82c0` | present |
| wasmvm `api.cSet` / `_cgoexp_…_cSet` | — | `0x7fc240` / `0x80a140` | present |
| wasmvm `api.cGet` / `api.cQueryExternal` | — | `0x7fbf60` / `0x7fd9e0` | present |
| `go:itab.Context,context.Context` | — | **not a static constant** (0 refs to the 4 method PCs) | **runtime-created** (§3) |
| `(*BaseKeeper).MintCoins` (iface wrapper) | (SDK, in-binary) | **`0x1cb3720`** — loads 6 stack args, `call *%rdx` (itab dispatch) | target |
| `BaseKeeper.MintCoins` (value body) | — | **`0x1c59cc0`** → real logic **`0x1c59aa0`** | target |
| `(*BaseKeeper).SendCoinsFromModuleToAccount` | — | **`0x1cb4500`** | target |
| `BaseSendKeeper.addCoins` / `setBalance` | — | **`0x1c5fe00`** / **`0x1c60220`** | target |
| `mintbankkeeper.(*Keeper).MintCoins` | — | **`0x2ae8a40`** (thin pass-through) | target |
| `runtime.morestack` / `cgocallbackg` | — | `0x47cc80` / `0x4811e0` | present |
| `sdk.Context.KVStore` / `CacheContext` / `Value` | — | `0x109da80` / `0x109dd80` / `0x109d9a0` | present |

### 2.1 What ports and what must be re-derived

**Ports essentially for free (engine-determined, binary-independent):**
- The **guest contracts**. They use the real wasmvm imports `db_read` and `query_chain`, both present
  in archwayd's wasmvm 1.5.5. The drift shape, the 16·spacing write stream, the guard-skip, and the
  holder return slot at **`top-0x308`** are all determined by **wasmvm/corosensei/Wasmer 4.2.2**, which
  is the **same library** on both binaries → the `[X]` offset and (in principle) the **R=234, K=2**
  calibration port. (Caveat: the live STACK_POOL state is not controllable — §5.)
- The **gadget *shapes***: the exact pivot, `pop rax; ret`, guard-clear, and UD2 all exist in
  archwayd (§2 table). Non-PIE ⇒ they are **compile-time constants**.
- **cgo re-entry**: `crosscall2`, `runtime.cgocallback`, `runtime.needm`, `api.cSet` all present.

**Must be re-derived on archwayd (one CI run, scripted):**
1. **`runtime.g0` absolute address.** The harness staged the constant `0x2fd1440`; archwayd's differs.
   Derivation: `objdump -d` the ELF entry stub (`_rt0_amd64_linux @0x44f889`) → its `lea …; jmp`
   target is `runtime.rt0_go`; inside `rt0_go` the `LEAQ runtime·g0(SB), …` gives the absolute.
   (The pclntab entry for asm `TEXT` funcs is mis-delimited by a few bytes; do **not** trust the
   pclntab address for `rt0_go`/`cgocallback`.) **Method implemented in
   `archway/live/ci/port_analysis.sh` step 6c; the value is recorded in `ci-out/port/port_g0.txt`.**
2. **Confirm the ABI0 entry of `runtime.cgocallback`** (`0x47e880` candidate). The pclntab does not
   emit a `.abi0` suffix on this binary; verify with the unstripped-symbol route or by disassembling
   the stub (args `fn/frame/ctxt` on the stack).
3. **Guard-register precondition.** The guard-clear gadget writes 16 zero bytes from `XMM15`/`XMM0`.
   The harness relied on XMM15 already being zero at the pivot. On archwayd, XMM15/XMM0 at the pivot
   is **unverified** — either pick a gadget that zeroes the register first, or prove the register is
   zero on the holder-fibre path (E9 pre-flight).

**Quantification:** ~4 of the 6 native stages (pivot, `pop`, guard-clear, UD2) port verbatim; the
ABI0 entry ports as a candidate; **`runtime.g0` is a one-value re-derivation; and the *mint target*
has no archwayd equivalent at all** (§3).

---

## 3. The context problem (the crux)

The harness's mint works only because `mintBridge` **owns** a `sdk.Context` and a `BaseKeeper` that
were constructed in-process (`newBankTarget()`: `sdk.NewContext(commitMultiStore, Header{}, false, …)`
+ `bankkeeper.NewBaseKeeper(...)` over a `dbm.NewMemDB()`). On archwayd there is no such owner.

### 3.1 Can a valid `sdk.Context` be **constructed** from the pivot? — **No.**

`MintCoins(ctx, name, amt)` requires (source-verified, `mint-call-candidates.md` §2–§3):
- a **correct `ctx.itab`** = `go:itab.Context,context.Context`. The CI itab hunt found **0 static
  references** to `Context.{Deadline,Done,Err,Value}` → the itab is **runtime-created** (heap); its
  address is **not a compile-time constant**. `[HIGH]`
- a **`ctx.data`** pointer to an 872-byte `sdk.Context` whose **`ms`** (MultiStore iface),
  **`gasMeter`** (iface), **`kvGasConfig`** and **`eventManager`** (iface) are live and valid.
- a **`*BaseKeeper`** receiver — the real app instance. Fabricating one from qwords is **not realistic**
  (it embeds three itab/data pairs plus `collections` maps/indexes and function-value closures).

→ A context cannot be synthesised; its interface words and the keeper pointer must be **borrowed**
from live heap objects.

### 3.2 Can a valid `sdk.Context` be **borrowed** at the pivot? — **Only with an arbitrary read.**

Live objects that exist during the exploit window (`x/wasm/keeper`, archway fork `v0.50.2-archway`):
- `QueryHandler struct { Ctx sdk.Context; Plugins …; Caller … }` — created by
  `newQueryHandler(sdkCtx, contractAddr)` and passed **by pointer** into `wasmVM.Execute/Query`.
  `QueryHandler.GetCtx() *sdk.Context` returns `&q.Ctx`. For the **holder's `execute`** this `Ctx` is
  the **writable, committing** tx cache context. `[HIGH]`
- The app's real `BaseKeeper` — reachable from `ArchwayApp.Keepers.BankKeeper`, from
  `WASMKeeper.bankKeeper`, and (via the decorator) from `MintKeeper.bankKeeper` =
  `mintbankkeeper.Keeper{bankKeeper iface}`. `[HIGH]` (wiring) / the box address is heap.

Both are **heap addresses**. To use them you must first **read a pointer out** — i.e. an
**arbitrary-read / pointer-leak primitive (M1)**. **M1 was not achieved** (`TECHNICAL-RECORD.md` §6.1):
the only consumption of attacker values through real wasmvm is the libgcc unwinder's *read* of a
corrupted candidate-RIP (`mov 0x98(%r12),%rax; cmpb $0x48,(%rax)`), which is consumed by CFI logic
and **never surfaced to the guest**. So:

> **Context verdict: a valid `sdk.Context` can neither be constructed nor borrowed with the current
> primitive set. Borrowing is gated on an M1-class pointer leak, which does not exist. The boundary
> is exact: the exploit needs ≥1 leaked host pointer (to a live `QueryHandler`/`sdk.Context` and to a
> live `*BaseKeeper`) plus the runtime-created itab; none is obtainable today.**

### 3.3 The invocation-shape problem (independent of the context)

Even *given* a valid context, the harness's entry cannot be reused:
- `runtime.cgocallback` invokes `fn(frame)` as an **ABIInternal `func(unsafe.Pointer)`** — **one**
  pointer argument. `MintCoins` needs 8 register words (receiver + ctx itab/data + name ptr/len +
  amt ptr/len/cap). `[HIGH]`
- **There is no archwayd `func(unsafe.Pointer)` that mints.** The harness's `fn=0x1768780` is
  `main.mintBridge`, which exists only in the harness. So the staged `[UD2][mintBridge][0][0]` tuple
  has **no live-chain `fn`.**
- To call `MintCoins` directly you need either **Option E** (`manual exitsyscall/reentersyscall`
  sandwich, `go-native-call-feasibility.md` §6E) for full signature freedom, or a **JOP gadget that
  loads the 8 argument registers from `[frame]` and jumps** — neither is catalogued on archwayd.

### 3.4 The commit problem

The nested query — which is what creates the second (trigger) fibre and the crossing — runs inside
`QueryHandler.Query`, which does `subCtx, _ := q.Ctx.CacheContext()` and **discards the cache**
(`query_plugins.go`: *"discard all changes/ events in subCtx by not committing the cached context"*).
→ **A mint performed through the nested-query context is thrown away.** For a *committing* mint the
ROP chain must write through the **outer `execute` context** (the holder's `QueryHandler.Ctx`) **and**
the process must return cleanly so baseapp commits the tx. The harness sidesteps both (its bank store
is separate; it terminates in `UD2`). Live, a `UD2`/abort means **the tx never commits** — so the
deliberate terminal landing is **wrong for the live chain**; a clean continuation is required.

### 3.5 Context verdict summary

| Question | Answer |
|---|---|
| Construct a `sdk.Context` at the pivot? | **No** — runtime-created itab; needs 3 live ifaces + closures; not synthesizable from qwords. |
| Borrow a live `sdk.Context`? | **Not with the current primitive** — requires an M1 pointer leak (unachieved). The *writable* target is the outer `QueryHandler.Ctx`. |
| Reuse `mintBridge`? | **No** — harness-only; `cgocallback` can only call `func(unsafe.Pointer)`. |
| Call `MintCoins` directly? | Needs **Option E** or a **JOP arg-load gadget** — not built. |
| Commit a mint done during the nested query? | **No** — nested `subCtx` is discarded; must use the outer ctx + clean return. |

**This is the boundary.** The engine exploit is proven; the *money call* is blocked on a missing
read primitive and a missing argument-passing mechanism.

---

## 4. Delivery plan (guests + on-chain path)

Live params confirmed **today** at height **17,965,315** (2026-10-26T17:32Z), via public LCD:
- `application_version`: app `archway` **v10.1.0**, `wasmd v0.51.0`, **`wasmvm v1.5.5`**, `cosmos-sdk v0.50.10`.
- `/cosmwasm/wasm/v1/codes/params`: `code_upload_access = {"permission":"Everybody"}`,
  `instantiate_default_permission = "Everybody"` → **upload and instantiate are permissionless.**
- Chain is live and producing blocks (17,965,315).

**4.1 Guests.** Ship **two** contracts (the harness `benign.wasm` is a warm-up artefact and is not
used live):
- **trigger** — `trigger.wasm` (66 283-iter drift loop, imports `db_read`). Deploy first.
- **holder** — `holder.wasm`, but **regenerated** so its embedded `WasmQuery::Smart.contract_addr`
  is the **real trigger contract address** (the harness WAT hard-codes the burner
  `archway1khgqgnnpw984e70chqjc5yu5r3ed8255qy6mhw` as a placeholder; on-chain the smart query must
  route to the deployed trigger or the nested query returns an error and the holder unwinds via the
  **DWARF path** instead of the `ret` lane — the exact blocker the narrow trigger avoids).
  Regeneration: `python3 source/harness/contracts/nested/gen_nested_contracts.py …` with the trigger
  address substituted (the generator already parameterises the request bytes).

**4.2 On-chain messages** (Archway is a standard Cosmos SDK chain):
1. `MsgStoreCode { sender, wasm_byte_code (base64), instantiate_permission }` ×2 — allowed
   (`Everybody`). The guests are **812 B (holder) / 819 B (trigger)**; StoreCode gas is compile +
   store, negligible.
2. `MsgInstantiateContract { sender, admin, code_id, label, msg="{}", funds=[] }` ×2 — allowed
   (`Everybody`). Instantiate both; read the trigger address from the response.
3. `MsgInstantiateContract2` (predictable address via `salt`) — **available but unnecessary**; we do
   not need to grind to a chosen address (the holder is regenerated to point at the real trigger).
4. `MsgExecuteContract { sender, contract=holder, msg="{}" }` — the attack tx.
   Path: `holder.execute` → `env.query_chain(Smart{trigger,"{}"})` →
   wasmd `QueryHandler.Query` (cached `subCtx`) → `QuerySmart(trigger)` →
   `wasmVM.Query(trigger)` → trigger's 66 283-iter loop → drift → cross into holder → pivot → ROP.

**4.3 Query-depth / gas.**
- Nested depth = **1**; wasmd's `DefaultMaxQueryStackSize = 10`
  (`x/wasm/types/wasmer_engine.go`, archway fork `v0.50.2-archway`) → fine.
- Harness gas for the whole execute ≈ **28.2 M** (vulnerable-1.json `executes[0].gas`), total
  **45.3 M** incl. instantiate. Archway `max_gas` per block = **300 M** → ample headroom.
- Fee at min gas price **140 000 000 000 aarch/gas**: ≈ 28 M × 1.4e11 ≈ **3.9 ARCH**.
  The known gas burner `archway1khgqgnnpw984e70chqjc5yu5r3ed8255qy6mhw` holds **551.7 ARCH**
  (re-verified live: `551666881944886604409 aarch` = 551.667 ARCH) — ample.

**4.4 Propagation / observability.** Archway is CometBFT (`cometbft v0.38.17`): public mempool, no
Flashbots-style private relay; ~5–6 s blocks; priority = fees. **The tx is visible in the mempool
before it executes.** There is no atomicity/MEV protection; the single-tx choreography is fully
observable.

**4.5 Permissionless-upload caveat from the advisory:** *"A contract already stored on chain by an
attacker remains a path even where those parameters are restricted."* Not relevant here (upload is
open), but it means a config-only mitigation would not neutralise a pre-stored contract.

---

## 5. Reliability

**Local observed: 6/8.** Failure modes: **SIGSEGV** (exit 139, attempt 4) and **`morestack on g0`**
(exit 2, attempt 5). The 6 successes minted before the expected `call stack exhausted` tail.

**What drives the 6/8 (three coupled conditions):**
1. **STACK_POOL parity / adjacency.** The drift only crosses into the *holder* when the holder sits
   on a stack **directly below** the trigger's stack (`[holder][4 KiB guard][trigger]`). The harness
   forces this with **3 warm-up executions** (odd count flips the FIFO `[B,A]` ordering). Even/zero
   warm-ups put the stream descending *away* from the holder.
2. **The 3-event alignment (the race).** For success, in order: (a) the crossing batch must land on
   `[X]` (`top-0x308`); (b) the trigger must **return `Ok`** (not trap first) so the holder resumes
   through the trampoline `ret`; (c) the holder must take the `ret` lane (not the libgcc unwind).
   The narrow trigger (`--pre-call-drops 15 --frame32 2`) aligns these; the old wide batch did not.
3. **Process layout variance.** Each run is a fresh process (fresh mmap/ASLR) → the 6/8 is
   layout variance across processes, not within one.

**How to raise local reliability:** repeat attempts; sweep more `(R,K)` phases; ensure the crossing
batch is the **last** scheduled call; avoid GC/allocation near the pivot (`morestack on g0` is a
g0-guard/runtime-tail failure); keep XMM15/XMM0 zero for the guard clear.

**What the live environment adds / removes:**
- **Adds:** the node's `STACK_POOL` state is **arbitrary** (no warm-ups) and shared with every other
  wasm execution in the process → the adjacency condition is **not attacker-controllable** without
  priming; multiple goroutines/txs run concurrently; the real wasmd query path (gas session, depth
  checks); the min-gas/query-gas regime.
- **Removes:** the harness's controlled 3-warm-up parity trick; the single-threaded, deterministic
  environment; the generous `-gas` limit.
- **Consequence:** live reliability is **strictly worse** and, critically, **non-deterministic across
  validators** (§6).

---

## 6. Risk register

| # | Risk | Assessment |
|---|---|---|
| R1 | **Consensus divergence / chain halt (highest).** | The exploit's success depends on the node's fibre-stack layout (6/8 across processes). Validators execute the same tx with **different ASLR/layout** → different results (clean Ok vs crash vs mint) → **app-hash divergence → the block cannot finalize → chain halt.** A non-deterministic sandbox escape is, on a live chain, primarily a **halt vector**, not a clean mint. |
| R2 | **Node/process crash.** | SIGSEGV and `morestack on g0` are live failure modes; `UD2`/`SIGILL` (the harness's terminal landing) aborts the process. A proposer crash → missed blocks; a crash on all validators → halt. Overlaps with the five separate permissionless DoS vectors (CWA-2025-001/002/007, CWA-2026-003/005) already live on this chain. |
| R3 | **On-chain observability (very high).** | The mint is not stealthy: a supply change appears in `/cosmos/bank/v1beta1/supply` and the `mint` module balance; `coin_minted`/`coin_received`/`transfer` events fire; the attack tx is **public in the mempool** (~5–6 s before execution); a crashed tx and any missed blocks are visible. |
| R4 | **Detection heuristics.** | Two tiny (812 B / 819 B) contracts whose only imports are `db_read`/`query_chain`, with a 66 k-iteration loop and no business logic, are trivially flagged. Supply monitors / anomaly alerts catch any successful mint immediately. |
| R5 | **Legal / operational exposure.** | Unauthorized minting on a live validator/node is an attack on financial infrastructure (computer-misuse / fraud exposure; validator ToS breach). The **legitimate alternative is the existing responsible-disclosure path** (wasmvm/CosmWasm maintainers + the Archway team; CWA-2026-006 is already public with a bounty timeline). Per the handoff, **no mainnet action without an explicit principal decision.** |
| R6 | **Patch clock.** | The chain is unpatched (wasmvm 1.5.5; the 1.5 line "will not be patched"; only a consensus-breaking upgrade to wasmvm ≥2.2.9/3.0.8 fixes it). Any window closes only with a coordinated validator upgrade. |

---

## 7. Feasibility verdict and exactly what remains

**Headline: PARTIAL.** Engine exploit **live-confirmed**; delivery **READY**; control-transfer
mechanics **port in principle**; **live mint NOT-FEASIBLE with the demonstrated primitive.**

**Remaining work, in dependency order (all gated on #1):**
1. **M1 — arbitrary-read / pointer-leak primitive through real wasmvm 1.5.5.** *Does not exist.*
   The last unexplored thread is the `a10` read's value flow (`mov 0x98(%r12),%rax; cmpb $0x48,(%rax)`).
   **Without this, nothing downstream is possible.**
2. **Context/keeper staging** (§3): use the leak to borrow (a) the **outer** `QueryHandler.Ctx`
   (`*sdk.Context`, writable) and (b) a live **`*BaseKeeper`** (or `mintbankkeeper` box); account for
   the **runtime-created itab**.
3. **Invocation mechanism:** **Option E** (manual `exitsyscall`/`reentersyscall`) or a JOP
   arg-load gadget to call `MintCoins`/`SendCoinsFromModuleToAccount` with real arguments —
   `cgocallback` alone is insufficient.
4. **Clean-commit continuation:** replace the terminal `UD2` with a return into the holder's
   resumption so baseapp commits the tx (and write through the **outer**, not the discarded nested, ctx).
5. **archwayd address finalisation (CI):** `runtime.g0` absolute; ABI0 `cgocallback` confirmation;
   XMM-zero precondition. (Everything else is already resolved — §2.)
6. **Live layout determinism:** a way to satisfy the STACK_POOL adjacency deterministically, or an
   explicit acceptance that the outcome is a halt (§6 R1) rather than a mint.

**Boundary statement.** With the current package the exploit is a **proven local, in-memory
demonstration through the real engine** and a **proven control-transfer primitive that ports
address-for-address**; it is **not** a live mint. The two hard missing pieces are **(i) a read
primitive (M1)** and **(ii) a multi-argument Go call path + clean commit**. Neither is a "known-hard"
dead end, but neither exists today, and (i) is a strict prerequisite for the rest.

**Recommendation.** Treat this package as (a) a **strong CWA-2026-006 disclosure artefact** and (b) a
**local PoC of the impact class**, **not** as a live-broadcast-ready exploit. No mainnet action.

---

## 8. Evidence / reproduction index

- Local PoC: `artsbykriss/kimi-cwa006` — `docs/TECHNICAL-RECORD.md` §0; `results/campaign-m4/`
  (`fullchain-callback-v3/`, `final-validation/`, `fullchain-callback-v3-ptrace/`, `…-single-run-sigcont/`).
- archwayd port CI: `artsbykriss/ca-zombie-ci` run **40370745650** (success) → `ci-out/port/`:
  `port_archwayd.sha256`, `port_functions.txt`, `port_target_disasm.txt`, `port_gadgets.txt`,
  `port_gadget_greps.txt`, `port_mint_itab.txt`, `port_g0_candidates.txt`, `port_itab.txt`.
- Port script: `archway/live/ci/port_analysis.sh` (run via `bash ci/ci-run.sh archway`).
- Live state reads (read-only): `node_info` (app v10.1.0 / wasmvm v1.5.5 / wasmd v0.51.0),
  `/cosmwasm/wasm/v1/codes/params` (Everybody/Everybody), `consensus_params` (`max_gas=300000000`),
  block **17,965,315** @ 2026-10-26T17:32Z.
- Source: `archway-network/archway-wasmd@v0.50.2-archway` `x/wasm/keeper/query_plugins.go`
  (`QueryHandler.Query` → discarded `CacheContext`), `x/wasm/keeper/keeper.go`
  (`QuerySmart`/`checkAndIncreaseQueryStackSize`); `archway@v10.1.0` `app/app.go`
  (`maccPerms`, `mintbankkeeper.NewKeeper`).

*Prepared as a read-only gap analysis. No transaction was signed, deployed, or broadcast; no
live-chain state was modified.*
