# Rujira FIN — DEFINITIVE root-cause & live verdict (ZH4)

**Date:** 2026-10-24 (live checks ~22:09 UTC, height **28,383,399**) · **Chain:** THORChain app layer (`thorchain-1`, CosmWasm) · **Status:** read-only; no transaction signed or sent.
**Question:** *does the FIN CCL position-transfer exploit work on the LIVE chain now — THORChain 3.21.0, `HALTWASMGLOBAL=0`, FIN on the unpatched code 196?*

---

## 0. VERDICT

> ## ✅ **PATCHED** — closed at the base layer by the v3.21.0 upgrade that is live now.
>
> The exploit was **real and worked** on 2026-09-26 (proven below: the actual incident transaction, decoded). It is **no longer reproducible** because the exact base-layer dispatch it used — the `x:` / `exec` **ExecMemo → `MsgWasmExec`** path — **was removed in v3.21.0**, which executed on-chain at height **28,366,100 (2026-10-23)** and is the running version. v3.21.0 additionally added the **`TxSignedBy`** sender-authenticity guard to `MsgSend` and removed `authz`.
>
> **Exact guard / absence (cite-able):** in the v3.21.0 tree, `x/thorchain/memo/memo_exec.go`, `x/thorchain/handler_wasm_exec.go`, `x/thorchain/types/msg_wasm_exec.go`, `proto/thorchain/v1/types/msg_wasm_exec.proto` are **deleted**; the `"x"`/`"exec" → TxExec` memo mapping is gone from `x/thorchain/memo/memo.go`; `case ExecMemo:` and `m[sdk.MsgTypeURL(&MsgWasmExec{})]` are gone from `x/thorchain/handler.go`. **Binary confirmation:** the `thornode` binaries of the v3.21.0 release line (tag `909528f` and branch `mainnet-3.21.0`) contain **zero** `TxExec` / `MsgWasmExec` / `WasmExecHandler` / `ParseExecMemo` symbols and **do** contain `TxSignedBy` + the new fix strings — and they are *not stripped* (see §4).
>
> **Not** "unverifiable": the mechanism is proven from the real incident tx, and the removal of its dispatch path is proven in source **and** in the compiled v3.21.0 binary.

| | Value |
|---|---|
| **E-U now (demonstrable)** | **$0.00** |
| **E-U-conditional (only if the base layer still had `x:`)** | up to **$1,578,051.57** (whole CCL book) |
| **Verdict confidence** | **high** (mechanism high; fix high; residual private-binary caveat, §7) |
| **Why closed** | the `x:`/`exec` ExecMemo → `MsgWasmExec` dispatch is absent from the running v3.21.0 (source + binary) |
| **Incident profit (2026-09-26, historical)** | **≈ 52,116 `eth-usdc` + 221,148 `x/ruji` ≈ $86 k** (see §5) |

---

## 1. THE TRUE MECHANISM (this replaces the earlier reconstruction)

The earlier `EXPLOIT-PATH.md` model ("`RangeMsg::Transfer` trusts `info.sender`") was **right about the contract but wrong about the delivery**: the real incident did **not** use a top-level `Range(Transfer)` (hence the 2026-09-26 scan's "0 `range.transfer`"). It used the **module-account deposit + `x:` memo** route, which makes FIN **call itself**.

### 1.1 The real incident transaction — found and decoded

* **tx** `8CDB3A24DDD74A034AD81AAB2FA22329B1DC2CB3303331D48CE4EC6D1B3C063B`
* **height 27,988,325** · **2026-09-26T12:02:33Z** · code 0 (success) · gas_used 7,367,771
* (The earlier "0 range.transfer on 2026-09-26" scan window ended at 27,988,051 — **274 blocks before this tx**; it missed the incident. `analysis/incident/scan_prehalt.json` finds it.)

**Message body** (2 × `MsgExecuteContract`, sender `thor10k8yl…5fnx` = attacker, contract `thor17cawwg…l5d0a` = FIN pair `x/ruji`/`eth-usdc`):

```
memo = x:thor17cawwg…l5d0a:<base64>
        └─ decodes to  {"do_range":["thor1zspr6va4ev78lpsh48s57nv6szxj4cdyey34wa",   ← VICTIM (range owner)
                                     {"transfer":{"idx":"64","to":"thor10k8yl…5fnx"}}]}  ← ATTACKER
msg0 = {"swap":{"price":"0","to":"thor1v8ppstuf6e3x0r4glqc68d5jqcs2tf38cg2q6y","callback":null}}   funds 1 eth-usdc
msg1 = {"range":{"close":{"idx":"64"}}}
```

**`thor1v8ppstuf6e3x0r4glqc68d5jqcs2tf38cg2q6y` is the `thorchain` module account** (verified live: `/cosmos/auth/v1beta1/accounts/…` → `ModuleAccount name="thorchain"`). The attacker set the swap's **`to` = the module**.

**Event trace** (exactly matches the mechanism):

```
msg_index 0  (the swap)
  execute FIN ×4  ← ①Swap ②Arb ③DoSwap ④DoRange        (a plain swap is only 3)
  wasm-rujira-fin/range.transfer  from=thor1zspr6…  idx=64  to=thor10k8yl…   ← the theft
msg_index 1  (the close)
  execute FIN ×3
  wasm-rujira-fin/range.close     idx=64  owner=thor10k8yl…  base=22114808678216  quote=5211634359708
  transfer → thor10k8yl…  (52,116.34 eth-usdc + 221,148.09 x/ruji)          ← payout to the attacker
```

### 1.2 The chain of calls (base layer → FIN), exact

1. **FIN swap → the module.** `MsgExecuteContract{FIN, swap{to: thor1v8ppstuf…}}`. FIN's `execute_swap` (`contract.rs:323-383`) sends the swap output with `BankMsg::Send{to_address: recipient}` where `recipient = req.to()` = the **`thorchain` module account**.
2. **MsgSend-to-module → MsgDeposit (memo from the TX body).** THORChain routes bank sends through its own `MsgSendHandle`. For `to == GetModuleAccAddress(ModuleName)` it builds a deposit from the **transaction memo** (`handler_send.go` `getDeposit`, reading `ctx.Value(ContextKeyTxMemo)`, set in `x/thorchain/ante.go:52-53`): `NewMsgDeposit(coins, memo = "x:FIN:<…>", fromAddress = FIN)`.
3. **Memo parse → ExecMemo.** `handler_deposit.go` → `processOneTxIn` (`handler.go:211`) parses the memo with `ParseMemoWithTHORNames`; `"x"` maps to **`TxExec`** (`memo.go:96`) and `ParseExecMemo` (`memo_exec.go`) yields `ExecMemo{Contract: FIN, Msg: do_range(victim,transfer)}`.
4. **ExecMemo → MsgWasmExec with `sender = tx.Tx.FromAddress.MappedAccAddress()`** (`handler.go:291-298`). Since `fromAddress` is **FIN**, the new message is `MsgWasmExec{Contract: FIN, Sender: FIN, Msg: do_range(victim,transfer)}`.
5. **MsgWasmExec → `ExecuteContract(FIN, sender = FIN, …)`** (`handler_wasm_exec.go:77`). FIN therefore sees **`info.sender == FIN`**.
6. **FIN's `DoRange` guard passes; the embedded `sender` is trusted.**
   * `contract.rs:181-186` `ExecuteMsg::DoRange((sender,msg))` requires `info.sender == env.contract.address` → **FIN == FIN ✓**
   * then `execute_range(deps, env, info, sender, msg, price)` (`contract.rs:190`) with **`sender` taken from the message payload = the victim**
   * `ranges/execute.rs:180-189` `RangeMsg::Transfer` checks `sender == range.owner` → **victim == owner ✓** → `range.owner = attacker` + `event_transfer_range(from=victim,to=attacker)`.
7. **`msg1 = Range(Close{64})`** from the attacker (now owner) → payout of the position.

**One-line root cause:** the base layer let a **contract (FIN) convert its own bank send into a deposit whose *transaction memo* was chosen by the attacker**; that memo (`x:` ExecMemo) then executed a contract call **as FIN**, and FIN's `DoRange`/`Transfer` logic trusts a caller-supplied `sender`. The contract was *never* the bug; the base layer's memo dispatch was.

### 1.3 Why the earlier model failed, and what it got right
`RangeMsg::Transfer` does authorise on `sender == range.owner` (`ranges/execute.rs:184`), and `sender` is fed from `DoRange((info.sender, msg))` (`contract.rs:87`). The earlier model assumed an attacker could set `info.sender` to the victim directly — there is **no such path** (§3). The real path makes `info.sender == FIN` (satisfying `DoRange`) while the *payload* carries the victim.

---

## 2. Live state (2026-10-24, height 28,383,399)

| Item | Value | Source |
|---|---|---|
| `current` / `next` | **3.21.0** / 3.21.0 | `/thorchain/version` |
| upgrade 3.21.0 @ 28,366,100 | **executed** (2026-10-23; app layer resumed 28,366,103) | `/thorchain/version`, prior re-check |
| `HALTWASMGLOBAL` | **0** (App Layer executing) | `/thorchain/mimir` |
| `HALTWASMCONTRACT-YEVLEC` (rujira-fin) | 0 | `/thorchain/mimir` |
| `HALTWASMCONTRACT-27DUYT` (ghost-credit) | **0** (now lifted too) | `/thorchain/mimir` |
| FIN pair `thor17cawwg…` code_id | **196** (unchanged, unpatched) | `/cosmwasm/wasm/v1/contract/…` |
| CCL book | **$1,578,051.57** / 1,199 ranges (2026-10-24 CI) | `ci-out/rujira-state.json` |
| post-unhalt `range.transfer` | **0** (12,064+ blocks, 16k+ wasm execs) | `ci-out/postunhalt-scan.json` |

**FIN is still on the vulnerable contract** — the fix is **entirely base-layer**. That is exactly why "code 196 unchanged" does **not** imply "still exploitable".

---

## 3. Every FIN/base-layer path that could move a CCL position on code 196

Exhaustive enumeration (full detail in [`analysis/paths/FINDINGS.md`](analysis/paths/FINDINGS.md)); the only path that the incident used is marked ⚠.

| # | Path | Auth check | Attacker-reachable now? |
|---|---|---|---|
| 1 | Top-level `MsgExecuteContract` → `WasmExecuteContractHandler` → `ExecuteContract(contract, msg.Sender, …)` | caller = `msg.Sender`, signed (ante `SigVerificationDecorator`) | executes only as the signer → **cannot be the victim** |
| 2 | Contract submsg `WasmMsg::Execute` | `EncodeWasmMsg` forces `Sender = emitting contract`; wasmd signer check `GetMsgV1Signers ⊆ {contract}` | executes as the contract, not arbitrary |
| 3 | Contract `CosmosMsg::Any`/Stargate of a foreign `MsgExecuteContract` | wasmd `handleSdkMessage` signer check | **closed** |
| 4 | `MsgSudoContract` | signer `authority` **and** `caller == contractInfo.AdminAddr()` | only a contract's own admin |
| 5–8 | instantiate / migrate / update-admin / store-code | signer + admin / permission list | own contracts only |
| 9 | scheduler `ExecuteSchedule` | caller = fixed `scheduler` module account; target = scheduling contract | no arbitrary caller |
| 10 | reply/error callbacks | invoked as the contract | n/a |
| 11 | IBC/BeginBlock/EndBlock | no wasm dispatch | n/a |
| 12 | `x/denom` msgs | `assertContractSender` | not a wasm-execute |
| **⚠ A** | **`x:`/`exec` memo (TxExec/ExecMemo) → `MsgWasmExec`** — reachable via native `MsgDeposit`, `MsgSend`-to-module, or observed L1 tx; sender = `tx.FromAddress.MappedAccAddress()` | **none beyond the memo** | **THE INCIDENT PATH — REMOVED in v3.21.0** |
| **B** | `MsgSend`→`MsgDeposit` memo injection (the *enabling* bug: a send from `from` executes the **tx memo** with `from`'s authority) | v3.20.x: none; v3.21.0: `TxSignedBy(from) || HasContract(from)` | for a **contract** sender (FIN) the guard still passes ⇒ the `x:` removal (§A) is what actually closes FIN |
| C | credit-account liquidation (ghost-credit `AccountMsg::Execute`) | contract sudo path; **was individually halted** | was blocked; `27DUYT` now =0 — but it only reaches *contract-owned* ranges, and this route needs the account contract's own admin/flow |

Only **⚠A** yields `info.sender == FIN` while carrying a victim `sender`. It is gone.

---

## 4. Deployed-code verdict (binary evidence)

MR !5226 states v3.21.0 ships a **private binary** ("additional security patches — DO NOT build from source"), so the *deployed* image itself is not public. I exhausted the binary route and obtained the **two public images on the same v3.21.0 tree**:

* `registry.gitlab.com/thorchain/thornode:909528f` (tag **v3.21.0**, commit `909528f1`)
* `registry.gitlab.com/thorchain/thornode:mainnet-3.21.0` (branch **mainnet-3.21.0** = 3.20.3 + tag v3.21.0; a **different build** — distinct config digest `3abe81e9…` vs `77ed331d…`)

Both contain `usr/bin/thornode` (ELF, **not stripped**, with debug_info, go1.26.9). `grep -a` results (identical for both):

| needle | count | meaning |
|---|---:|---|
| `TxExec` | **0** | `x:`/`exec` memo type — **removed** |
| `MsgWasmExec` | **0** | the message ExecMemo produced — **removed** |
| `WasmExecHandler` | **0** | its handler — **removed** |
| `ParseExecMemo` | **0** | its parser — **removed** |
| `TxSignedBy` | 2 | new sender-auth guard — **present** |
| `cannot convert send to deposit: %s did not sign the transaction` | 1 | v3.21.0 fix string (`handler_send.go:123`) — **present** |
| `send from %s was not signed by its sender` | 1 | v3.21.0 fix string (`handler_send.go:192`) — **present** |
| `BondYieldMemo` / `ExecuteContract` / `TxType not supported: %s` | 3 / 46 / 1 | controls — present |

Because the binaries are **not stripped** (control symbols and Go runtime are all present), the **absence** of the ExecMemo machinery is real: the incident's dispatch path is **compiled out** of the v3.21.0 release line. The private build is this tree **plus** patches — it cannot re-introduce a removed feature. Full log: [`analysis/binary-evidence.txt`](analysis/binary-evidence.txt).

**Source cross-check** (`gitlab.com/thorchain/thornode` compare `v3.20.3..v3.21.0`): the deletions/edits in §0 are exactly as listed.

---

## 5. Capital & profit (the real path)

* **Capital required: ≈ $0.** The trigger is a swap whose output goes to the module account; the incident used **1 base unit** of `eth-usdc` (dust) + gas `2,000,000 rune` ≈ **0.02 RUNE**. No flash loan, no large balance. The whole attack is one tx.
* **Profit (real incident, tx `8CDB3A24…`):** the victim's range #64 was transferred and closed for **`22114808678216 x/ruji` + `5211634359708 eth-usdc`** = **221,148.09 x/ruji + 52,116.34 eth-usdc** (1e8 convention, consistent with the confirmed `x/ruji` 8-decimals) ≈ **$86 k** (USDC $52.1 k + RUJI $34.5 k at $0.1557, DefiLlama). One position only; press: *"one Rujira-team position, no user funds lost."*
* **Ceiling if it were live today:** the full CCL book **$1,578,051.57** (1,199 ranges) — iterable per range at dust cost.
* **Preconditions:** (a) FIN code 196 unchanged — **satisfied**; (b) base layer still dispatching `x:`/ExecMemo — **NOT satisfied** (v3.21.0).

*(Decimal caveat: THORChain stores the range amounts in 1e8 units; if `eth-usdc` were 6-decimals the USDC leg would be ~100× larger. The `x/ruji` leg is unambiguously 1e8 and the current CCL book ($1.58 M / 1,199 ranges, 1e8) is the consistent scale, so ≈$86 k is the defensible figure.)*

---

## 6. PoC (local, cw-multi-test) — extended to the exact mechanism

`poc/rujira/contracts/rujira-fin/src/exploit_poc.rs` (against **rujira-fin v2.2.2**, code_id 196, hash `5CC7E136…E071`):

1. `fin_owner_check_blocks_direct_transfer` — the check works as written.
2. `owner_transfer_works` — control.
3. `forged_caller_drains_position` — caller-forgery model (`info.sender == victim`).
4. `contract_owned_position_transferred_via_execute_as_self` — contract-owned range.
5. **`incident_exact_self_exec_do_range`** *(new)* — models the **real** incident: `ExecuteMsg::DoRange((victim, Transfer{idx,to}))` delivered **FIN → FIN** (`info.sender == FIN`), i.e. exactly what the `x:` ExecMemo path produced; the range moves to the attacker and pays out.
6. **`do_range_guard_blocks_external_caller`** *(new)* — negative control: the same `DoRange` from a **non-FIN** caller reverts. Proves the position is reachable **only** when the VM reports FIN as caller — i.e. only via the base layer.

`cw-multi-test` cannot model the base-layer `MsgSend`→`MsgDeposit` conversion, so tests 5/6 model its **result** (a FIN self-call) against the deployed contract — the part that is on-chain today and unchanged. The base-layer half is proven by the decoded incident tx (§1) and the v3.21.0 removal (§4).

CI: `bash /home/heisenberg/CA/ci/ci-run.sh rujira-fin` → run URL in `ci-log.txt` / `ci-out/`.

---

## 7. Confidence, blockers, what would change the verdict

**Confidence.** Mechanism: **high** (the real tx is decoded and every event/step lines up, including the 4th `execute` and the module `to`). Fix: **high** — the removal is in source *and* in the compiled v3.21.0 binary, and the chain runs 3.21.0.

**Blocker (residual, small):** the *deployed* image is the **private** `thornode-private` build; the public Docker Hub repo is private/absent and the GitLab registry holds only the two public builds above, so I could not read the exact deployed bytes. This is bounded: the private build is the v3.21.0 tree + security patches (MR !5226), and a security build does not re-add a removed dispatch path. **What would change the verdict:** a deployed-binary symbol table containing `TxExec`/`MsgWasmExec`, or any on-chain `range.transfer` from a non-owner, or a fork replay that forges a caller.

**Negative results (do not re-investigate):** no top-level `Range(Transfer)` (that is why the old scan saw 0); no `TxSignedBy`/`assertContractSender` guard in `handler_wasm_execute_contract.go` (the fix is *not* there — it is the memo-path removal + the `MsgSend` guard); the GitLab-registry images are public builds, not the deploy.

---

## 8. Files

`analysis/incident/raw_tx_8CDB3A24.json`, `raw_txresponse_8CDB3A24.json` (decoded incident tx + events), `analysis/incident/scan_prehalt.json` (finds it), `analysis/binary-evidence.txt` (binary + source diff), `analysis/paths/FINDINGS.md` (full path enumeration), `poc/…/exploit_poc.rs` (6 tests), `ci-out/*`, `ci-log.txt`, `summary.json`.

*Read-only research; no mainnet transactions; no secrets. Prepared 2026-10-24.*
