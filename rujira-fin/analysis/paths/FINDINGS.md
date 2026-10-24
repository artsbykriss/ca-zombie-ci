# THORChain v3.21.0 — exhaustive base-layer → CosmWasm dispatch paths

**Date:** 2026-10-24 · **Scope:** read-only source analysis · **Status:** no transaction signed/sent.
**Question:** for every base-layer (thornode) path that causes a CosmWasm contract to execute, what is the
exact authentication/authorization check, and can a **fresh unprivileged external caller** satisfy it —
i.e. forge a caller / execute a contract as an arbitrary address / sudo a contract?

**Answer (headline):** **No.** On the public `v3.21.0` source, *no* base-layer dispatch path lets an
unprivileged external caller forge a wasm caller. Every path is gated by exactly one of:
(i) a **top-level transaction signature** (ante `SigVerificationDecorator` over the message's
`cosmos.msg.v1.signer` field), (ii) wasmd's **inner-dispatch signer constraint**
(`GetMsgV1Signers(msg) ⊆ {emitting contract}`, which the encoder makes tautological for `WasmMsg::Execute`),
(iii) **contract-admin equality** (sudo/migrate/update/clear-admin), or (iv) a **fixed module-account caller**
(the scheduler). There is **no `TxSignedBy` guard anywhere in the wasm path** — `TxSignedBy` appears only in
`x/thorchain/handler_send.go` (lines 123, 192). See §4 for the FIN owner-check consequence.

Refs compared: tag `v3.21.0` (`909528f18d62dea894cddd7461d58f1b003371e7`, 2026-10-18), branch `develop`
(tip), branch `mainnet-3.21.0`. `x/thorchain/handler_wasm_execute_contract.go`,
`x/thorchain/ante.go` and `x/thorchain/manager_wasm_current.go` are **byte-identical across all three**.

---

## 1. The plumbing: how a wasm message reaches THORChain (not wasmd)

THORChain does **not** use wasmd's msg server. It disables it and registers its own server for the *same*
wasm message types:

* `app/wasm.go:48-63` — `CustomWasmModule` embeds `*wasm.AppModule` and overrides
  `RegisterServices` to a **no-op** ("prevents Services from being registered, as these should be
  registered and handled in x/thorchain").
  wasmd's real module *would* register its msg server (`wasmd/x/wasm/module.go:152-154`
  `types.RegisterMsgServer(cfg.MsgServer(), keeper.NewMsgServerImpl(am.keeper))`) — THORChain suppresses it.
* `x/thorchain/module.go:158-162` — `RegisterServices` does
  `types.RegisterMsgServer(cfg.MsgServer(), am.msgServer)` (the **thorchain** `types.Msg` service) and
  registers the wasm *query* server.
* `proto/thorchain/v1/types/tx.proto:56-77` — the thorchain `Msg` service **clones** the wasm RPCs:
  > `// CosmWasm interface cloned in order so that we can register the x/thorchain message server as the server for x/wasm messages, and route through version control`
  with `rpc ExecuteContract(cosmwasm.wasm.v1.MsgExecuteContract) returns (…)`, `rpc SudoContract(…)`, etc.
* Routing key: cosmos-sdk `baseapp.MsgServiceRouter.registerMsgServiceHandler` keys routes by the **request
  message's own type URL**, not the service name
  (`cosmos-sdk/msg_service_router.go:138` `requestTypeName = sdk.MsgTypeURL(msg)`, stored at `:171`;
  lookup `:55` `return msr.routes[sdk.MsgTypeURL(msg)]`). So the cloned service registers the route
  `/cosmwasm.wasm.v1.MsgExecuteContract` → **thorchain's** `msgServer.ExecuteContract`
  (`x/thorchain/msg_server_wasms.go:25-28`).
* The message is the **real wasmd type** `wasmtypes.MsgExecuteContract`
  (`wasmd/proto/cosmwasm/wasm/v1/tx.proto:189-191`), which carries
  `option (cosmos.msg.v1.signer) = "sender";`. `MsgSudoContract` carries
  `option (cosmos.msg.v1.signer) = "authority";` (`:314-316`).
* Signer resolution: `app/app.go:321-325` builds `tx.NewDefaultSigningOptions()` (default annotation
  resolver) then `thorchaintypes.DefineCustomGetSigners(...)` overrides **only THORChain's own messages**
  (`x/thorchain/types/codec.go:128-153`); the wasm messages keep the default annotation resolver. The wasm
  types are registered as `sdk.Msg` via `msgservice.RegisterMsgServiceDesc(registry, &_Msg_serviceDesc)`
  (`x/thorchain/types/codec.go:125`), so both the ante and wasmd can read their signer field.
* `GetMsgV1Signers` = `interfaceRegistry.SigningContext().GetSigners(msgV2)`
  (`cosmos-sdk/proto_codec.go`, `ProtoCodec.GetMsgV1Signers`), i.e. the annotation resolver.

**Two entry classes only:**
1. **Top-level tx message** → ante verifies the tx signature against the message's signer field, then the
   msg server handler runs.
2. **Contract submessage** → wasmd `SDKMessageHandler.handleSdkMessage` enforces
   `GetMsgV1Signers(msg) ⊆ {emitting contract}` *before* routing
   (`wasmd/x/wasm/keeper/handler_plugin.go:103-111`):
   ```go
   signers, _, err := h.cdc.GetMsgV1Signers(msg)
   ...
   for _, acct := range signers {
       if !contractAddr.Equals(sdk.AccAddress(acct)) {
           return nil, errorsmod.Wrap(sdkerrors.ErrUnauthorized, "contract doesn't have permission")
       }
   }
   ```

---

## 2. Exhaustive dispatch-path table

Every place that can make a contract's code run, with its exact gate.

| # | Path | Who can trigger | Exact auth check (file:line) | Forge caller / execute-as-arbitrary / sudo arbitrary? | Fresh unprivileged reachable? |
|---|------|-----------------|------------------------------|------------------------------------------------------|-------------------------------|
| 1 | **Top-level `MsgExecuteContract`** → `msgServer.ExecuteContract` → `WasmExecuteContractHandler.handle` → `WasmMgr.ExecuteContract` → `PermissionedKeeper.Execute` | Any tx signer | Ante `SigVerificationDecorator` verifies sig over `tx.GetSigners()`; for this msg signers = `[msg.Sender]` (signer annotation `sender`). Handler's own `validate` is a **no-op** (`handler_wasm_execute_contract.go:51-53`); `handle` reads `senderAddr := msg.Sender` (`:61`) and calls `ExecuteContract(contractAddr, senderAddr, …)` (`:70`). No `TxSignedBy`. | **No** — caller = `msg.Sender`, who must have signed the tx. | Yes, but only executes **as the signer**. Cannot execute as a victim. |
| 2 | **Contract submessage `WasmMsg::Execute`** → `SDKMessageHandler` → encoders → router → path 1 | Any contract | `EncodeWasmMsg` **forces** `Sender = emitting contract` (`handler_plugin_encoders.go:232-245`: `Sender: sender.String(), Contract: msg.Execute.ContractAddr`); then `handleSdkMessage` signer check `signers ⊆ {contractAddr}` (`handler_plugin.go:103-111`) passes tautologically. | **No** — target is arbitrary but caller is always the emitting contract. | Contract-owner only (a contract executes as itself). |
| 3 | **Contract submessage `CosmosMsg::Any`/Stargate of `MsgExecuteContract` with foreign sender** | Any contract | `EncodeAnyMsg` unpacks the raw `Any` (`handler_plugin_encoders.go:211-229`) → `handleSdkMessage` calls `GetMsgV1Signers` = `[sender]` and rejects unless `sender == emitting contract` (`handler_plugin.go:103-111`). | **No** — blocked. This is the classic wasmd vector; it is closed. | No. |
| 4 | **Top-level `MsgSudoContract`** → `WasmSudoContractHandler.handle` → `WasmMgr.SudoContract` → `PermissionedKeeper.Sudo` | Any tx signer | Signer annotation `authority` (tx must be signed by `msg.Authority`) **plus** `checkIsContractAdmin(contractInfo, caller)` requiring `caller == contractInfo.AdminAddr()` (`manager_wasm_current.go:260`, `:410-419`). | **No** — you may sudo a contract only if you are **its admin**. | Yes iff the caller *is* the target's admin. Not arbitrary contracts. |
| 5 | **Top-level `MsgInstantiateContract` / `InstantiateContract2`** (runs `init`) | Any tx signer | Signer annotation `sender`; handler reads `msg.Sender` (`handler_wasm_instantiate_contract.go:53`); `checkInstantiateAuthorization` (`manager_wasm_current.go:89,125,399-408`) — any existing contract bypasses the permission check. | **No** — creator = signer. | Yes, as self. Not a caller-forgery. |
| 6 | **Top-level `MsgMigrateContract`** | Any tx signer | Signer annotation `sender` + `checkIsContractAdmin` (`manager_wasm_current.go:207`). | **No** — must be the contract admin. | Only for own contracts. |
| 7 | **Top-level `MsgUpdateAdmin` / `MsgClearAdmin`** | Any tx signer | Signer annotation `sender` + `checkIsContractAdmin` (`manager_wasm_current.go:281,302`). | **No** — must be the contract admin. | Only for own contracts. |
| 8 | **Top-level `MsgStoreCode`** | Any tx signer | Signer annotation `sender` + `checkCanStore` (mimir `WasmPermissionless` or permission list) (`manager_wasm_current.go:55,353-368`). | **No** — creator = signer. | Yes (permissioned/pinned list). Not a caller-forgery. |
| 9 | **Scheduler EndBlock `ExecuteSchedule`** → `wasmKeeper.Execute` | Nobody directly; runs every block over scheduled msgs | Scheduling: `MsgScheduleExecuteContract{sender}` is signer-annotated `sender` (`x/scheduler/types/tx.proto`) and, as an inner dispatch, must satisfy `sender == emitting contract` (path 2 rule). At exec (`x/scheduler/keeper/keeper.go:77-83`): `Execute(execCtx, contractAddress=msg.Sender, caller=authtypes.NewModuleAddress(types.ModuleName), …)`. | **No** — the **caller is the fixed `scheduler` module account**; the target is the scheduling contract. Neither is attacker-arbitrary. | Reachable to schedule, but the executing contract sees `info.sender == scheduler module`, never an arbitrary address. |
| 10 | **Reply / error callbacks** (`DispatchSubmessages`) | Contract itself | `keeper.reply(ctx, contractAddr, reply)` (`wasmd/x/wasm/keeper/msg_dispatcher.go:197`) — invoked as the contract, no sender field. | **No.** | n/a |
| 11 | **IBC / BeginBlock / EndBlock module hooks** | — | No base-layer module hook dispatches wasm execution (grep: only the msg server and the scheduler call the wasm keeper). | **No.** | n/a |
| 12 | **`x/denom` messages** (`CreateDenom`/`MintTokens`/…) | Contracts only | `assertContractSender` requires `HasContractInfo(sender)` (`x/denom/keeper/msg_server.go:33-45`); top-level denom msgs are rejected by ante (`x/thorchain/ante.go:264-266` default branch). | Not a wasm-execute path. | n/a |

**Complete caller list for wasm execution** (full-repo grep of non-test Go): the 8 wasm msg-server handlers
(`x/thorchain/msg_server_wasms.go`) → `WasmManager` (`manager_wasm_current.go`), and **exactly one** non-message
caller: `x/scheduler/keeper/keeper.go:77`. Nothing in `x/thorchain/handler_*.go` other than the
`handler_wasm_*` files calls `WasmManager().ExecuteContract/SudoContract/...` (the only other reference is
`handler_send.go:191` `HasContract`, a read).

---

## 3. Answers to the four explicit questions

### (a) wasmd `cosmwasm.wasm.v1.MsgExecuteContract` or a THORChain-custom message?
**The standard wasmd message type**, carrying `option (cosmos.msg.v1.signer) = "sender"`
(`wasmd/proto/cosmwasm/wasm/v1/tx.proto:189-191`). THORChain does **not** define its own message; it defines a
**cloned proto service** `types.Msg` (`proto/thorchain/v1/types/tx.proto`) whose RPCs take the wasmd message
types, so that (i) THORChain's msg server becomes the registered handler for the wasm type URLs (wasmd's own
msg server is disabled via `CustomWasmModule.RegisterServices` no-op, `app/wasm.go:62-63`) and (ii) the
routing still keys on `/cosmwasm.wasm.v1.MsgExecuteContract`. So the signer annotation is the wasmd one and it
is honoured by both the ante and wasmd's inner-dispatch check.

### (b) Where is `MsgSudoContract` defined; what authority does it require; can an external tx sudo an arbitrary contract?
Defined in wasmd: `wasmd/proto/cosmwasm/wasm/v1/tx.proto:314-316`
(`option (cosmos.msg.v1.signer) = "authority";`, field `authority`). THORChain's handler
(`x/thorchain/handler_wasm_sudo_contract.go:47-66`) passes `msg.Authority` as the caller to
`WasmMgr.SudoContract` (`manager_wasm_current.go:246-266`), which requires
`checkIsContractAdmin` → `caller.Equals(contractInfo.AdminAddr())` (`:260`, `:410-419`). So on THORChain the
sudo authority is **the contract's own admin**, *not* a chain-gov authority (the wasmd gov-authority check is
bypassed because THORChain replaced wasmd's msg server). An external tx **can** invoke sudo **only if it is
signed by (or, for an inner dispatch, emitted by) the target contract's admin**. There is **no** path for an
external tx to sudo an arbitrary contract.

### (c) Any internal dispatch to `ExecuteContract` carrying an attacker-controlled sender without a signature/ante check?
**No.** The only non-message internal dispatch is the scheduler (`x/scheduler/keeper/keeper.go:77`); it passes
the **fixed scheduler module address** as the caller and the scheduled contract as the target — neither is
attacker-arbitrary. All other inner dispatches go through wasmd's `SDKMessageHandler`, which enforces
`signers ⊆ {emitting contract}` (`handler_plugin.go:103-111`); for `WasmMsg::Execute` the encoder already
forces `Sender = emitting contract` (`handler_plugin_encoders.go:240-245`), and for the `Any`/Stargate variant
the signer check rejects a foreign sender. Top-level messages require the signer's signature via the ante.

### (d) What would a base-layer fix look like, and where?
Mirroring the guards added by commit `1c7c9dab` in `x/thorchain/handler_send.go:123` and `:192`:
```go
// handler_wasm_execute_contract.go, in handle() after parsing senderAddr (~line 61-64)
if !h.mgr.WasmManager().HasContract(ctx, senderAddr) && !TxSignedBy(ctx, senderAddr) {
    return nil, errorsmod.Wrapf(sdkerrors.ErrUnauthorized,
        "execute from %s was not signed by its sender", msg.Sender)
}
```
(`TxSignedBy` is defined at `x/thorchain/ante.go:120-127`, recording the tx signer set in the ante at
`ante.go:56-63`.) This is the "inner message dispatched on behalf of its signer" guard: require the caller to be
either a **tx signer** (`TxSignedBy`) or a **contract** (whose inner dispatch was already constrained by wasmd
to be the emitter). Note the `HasContract` disjunct is **mandatory** — a pure `TxSignedBy` guard would break
FIN's own `Range → self-call Arb{then} → self-call DoRange` chain (FIN is a contract and never signs).
Consequently such a guard is **defence-in-depth**: it does not close the contract-owner / execute-as-self
vector (a contract caller is explicitly allowed).

---

## 4. Consequence for the FIN `RangeMsg::Transfer` owner check

FIN authorises `Transfer` on `sender == range.owner`, where `sender` is FIN's `info.sender` of the original
`Range(msg)` call (`contract.rs:87`). To bypass, an attacker must make FIN receive a `Range(msg)` call whose
`info.sender` is the victim — i.e. **forge a caller**. Per §2, on the public v3.21.0 source there is **no path**
that sets a contract's `info.sender` to an arbitrary unprivileged address:

* top-level: `info.sender == msg.Sender`, who signed;
* submessage: `info.sender ==` the emitting contract (encoder-forced + signer check);
* scheduler: `info.sender ==` the fixed `scheduler` module account.

So the owner check **cannot be bypassed by caller forgery** under the public source. The only shape in which a
contract's `info.sender` can equal an `owner` is when the **owner is itself a contract** that emits the call
(execute-as-self, `EXPLOIT-PATH.md` §3.5) — that is the owner contract acting as itself, not a forgery.

**Therefore** the private v3.21 fix cannot be reconstructed from public source. If it is a `TxSignedBy` guard in
`handler_wasm_execute_contract.go`, it addresses a vector **not visible in the public tree**; if the incident was
the contract-owner shape, a `TxSignedBy` guard would *not* close it. This is consistent with the
`UNVERIFIABLE` status in `LIVE-RECHECK-2.md`.

---

## 5. Negative results (documented so they are not re-investigated)

* **No `TxSignedBy` in any wasm handler** — grep of the full v3.21.0 tree: `TxSignedBy` occurs only in
  `x/thorchain/ante.go` (definition) and `x/thorchain/handler_send.go:123,192`. `x/denom` uses its own
  `assertContractSender`, not `TxSignedBy`.
* **No base-layer handler constructs a wasm execute** — grep for `MsgExecuteContract{` / `WasmMsg{` in
  non-test Go: only the wasmd encoder (`handler_plugin_encoders.go`) and the test harness.
* **No authz / group / feegrant / circuit / gov module** in THORChain's `ModuleManager`
  (`app/app.go:486-498`: genutil, auth, bank, upgrade, params, consensus, thorchain, customWasm, denom,
  scheduler). The only custom route is `cosmos.bank.v1beta1.Msg` (`app/app.go:446`). So there is no `MsgExec`
  style "message that executes other messages" path to abuse (the concern noted in
  `handler_wasm_execute_contract.go:104-114`).
* **wasmd msg server is disabled** — `CustomWasmModule.RegisterServices` no-op (`app/wasm.go:62-63`);
  therefore wasmd's own gov-authority `SudoContract`/`MsgServer` policy is not in play.
* **Scheduler is not a forgery vector** — caller is `authtypes.NewModuleAddress("scheduler")`
  (`x/scheduler/keeper/keeper.go:80`), target is the scheduling contract (signer-constrained to the emitter).

---

## 6. Tag / ref comparison

| File | v3.21.0 | develop | mainnet-3.21.0 |
|---|---|---|---|
| `x/thorchain/handler_wasm_execute_contract.go` | — | **identical** | **identical** |
| `x/thorchain/ante.go` | — | **identical** | **identical** |
| `x/thorchain/manager_wasm_current.go` | — | **identical** | **identical** |
| `x/thorchain/handler_wasm_sudo_contract.go` | — | identical | (not fetched) |
| `x/thorchain/handler_send.go` | — | identical | (not fetched) |
| `x/denom/keeper/msg_server.go` | — | identical | (not fetched) |
| `x/scheduler/keeper/keeper.go` | — | identical | (not fetched) |
| `app/wasm.go`, `app/ante.go` | — | identical | (not fetched) |
| `app/app.go` | — | differs (unrelated: `runtime.NewKVStoreService` → store key, in-process CometBFT local client, import) | (not fetched) |

No public ref (tag `v3.21.0`, `develop`, `mainnet-3.21.0`) contains a wasm sender-auth guard. The latest tag is
`v3.21.0` (2026-10-18); there is no `v3.21.x` public tag.

---

## 7. Caveats

* **Signer resolution is inferred, not executed.** That `GetMsgV1Signers(MsgExecuteContract) == [sender]` is
  deduced from SDK semantics (`tx.NewDefaultSigningOptions()` default annotation resolver; wasm types registered
  via `msgservice.RegisterMsgServiceDesc`; `wasmd/proto/.../tx.proto` carries the annotation). If this were
  ever to resolve to an *empty* set, both the ante and wasmd's check would be vacuous — but that would break
  every signed message app-wide, so it is not a plausible FIN-specific gap. Confidence: **medium-high**.
* **Private binary.** The v3.21 deployable image is private ("DO NOT build from source", MR !5226). Anything the
  private build adds on top of the public tag is invisible here. This analysis bounds only the **public** source.
* `x/wasm` is **not** vendored in thornode — THORChain uses upstream `github.com/CosmWasm/wasmd v0.54.10`
  (`go.mod:53`) and `github.com/cosmos/cosmos-sdk v0.53.0` (`go.mod:65`); the wasmd/SDK files analysed are from
  those exact tags.
* Read-only; no live replay, no transaction.

---

## 8. Source file index (`analysis/paths/src/`)

```
v3.21.0/  (tag v3.21.0, commit 909528f1)
  app/{app.go,ante.go,wasm.go,msg_service_router.go,encoding.go}
  proto/thorchain/v1/types/tx.proto
  x/thorchain/{ante.go,handler.go,handler_send.go,handler_deposit.go,module.go,
               manager_wasm_current.go,manager_wasm_dummy.go,msg_server.go,msg_server_wasms.go,
               handler_wasm_{execute,instantiate,instantiate_2,migrate,store_code,sudo,update_admin,clear_admin}_contract*.go,
               types/{codec.go,tx.pb.go}}
  x/scheduler/{keeper/{keeper.go,msg_server.go,store.go},types/{tx.proto,expected_keepers.go,keys.go}}
  x/denom/keeper/msg_server.go
  go.mod
develop/            (branch develop — diffs only where noted in §6)
mainnet-3.21.0/     (branch mainnet-3.21.0 — 3 key files)
wasmd/              (github.com/CosmWasm/wasmd v0.54.10)
  x/wasm/module.go
  x/wasm/keeper/{msg_dispatcher.go,handler_plugin.go,handler_plugin_encoders.go,contract_keeper.go,msg_server.go,keeper.go}
  proto/cosmwasm/wasm/v1/tx.proto
cosmos-sdk/         (github.com/cosmos/cosmos-sdk v0.53.0)
  msg_service_router.go
  proto_codec.go
```
