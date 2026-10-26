# Version-gate survey across the Sui fresh cluster (ZH4 pass-7, parent lane)

Read-only, public Sui GraphQL. Checkpoint 2026-10-25.

The version/import primitive is only *closed* if a protocol adds an **explicit version check** bound to
its shared state. Here is what each target actually does (read from bytecode + live objects).

| protocol | gate mechanism | where | live value | blocks old versions? |
|---|---|---|---|---|
| **DipCoin** | `protocol::check_basic` → `check_version`: `assert!(ProtocolConfig.version == K)` (K=1 in v1, **K=6** in v9) | every entry fn calls `check_basic` | `ProtocolConfig 0xdeff2ed2…` `.version = 6` | **YES** — v1…v7 expect 1…5, live is 6 → abort `invalid_protocol_version` |
| **Bucket V2** | `version::assert_valid_package(&Treasury)` → `usdb::assert_valid_module_version<T>(&Treasury, package_version())` → `vec_set::contains(valid_versions, v)` | `vault::*` (7 sites v1, 9 v4) | `Treasury 0x4de1c29a…` `BucketV2CDP.valid_versions = [2, 1]` | **PARTIAL** — version **1 is still allowed** → v1 CDP callable |
| **Bluefin Pro** | `exchange::*` → `data_store::get_eds_version(&ExternalDataStore) == constants::get_version()` else `errors::version_mismatch()` | several `exchange::*` entry fns | `ExternalDataStore 0x740d972e…` `.version = 1`; `constants::get_version()` = **1 in BOTH v1 and v21** | **NO** — the constant was never bumped, so v1 passes |
| **AlphaFi Lend** | `alpha_lending::verify_version` asserts `LendingProtocol.version == K` (K=1 in v1–v9, 2 in v10–14, **4** in v15) | every value fn | `LendingProtocol 0x01d9cf05…` `.version = 4` | **YES** — only v15 passes (v1–v14 abort 8) |
| **Kai Finance** | `SupplyPool.version == 2`, `PositionConfig.version == 5`, `Position.version == 3` | supply/position fns | live pools v2, configs v5 | **YES** — only v19/v20/v21 (bytecode-identical) |
| **Suigar** | `sweethouse::assert_valid_version(&SweetHouse)`: `version_set.contains(package_version())` | ~50 sites | `SweetHouse 0xa1549d73…` `version_set = ["1"]` | **YES** — v1 (`package_version()=0`) blocked |

## Conclusions
- **DipCoin / AlphaFi Lend / Kai Finance / Suigar**: version gates are **effective** (equality against a
  monotonically bumped object version field). ⇒ version/import **closed**.
- **Bucket V2**: gate is **effective in mechanism but the CDP allow-list retains version 1** —
  ⇒ version/import **partially open** (latent; v1↔v4 diff is rounding/bookkeeping, and an on-chain
  `simulateTransaction` of `vault v1::donor_request` returns **SUCCESS**, confirming v1 runs — but
  semantics are equivalent; see `bucket-v2/analysis/bucket-v2.md`).
- **Bluefin Pro**: the gate is **a no-op** (`constants::get_version()` never advanced past 1 across 21
  versions). ⇒ old versions are **callable**. However, the changed entry functions
  (`authorize_account`, `authorize_liquidator`, `set_funding_rate`, `set_fee_tier`, `set_gas_fee`,
  `prune_table`, `set_account_type`, `liquidate`, `trade`, …) **still call `signature::verify` and
  compare the recovered signer to the operator/`data_store` address** in v1 too — the v1↔v21
  differences are check *ordering*, added `payload_type_*` validation and added account-creation, not
  removal of an authorization. **No unprivileged path found.**
- **Bluefin Pro — separate real authorization-bypass primitive (all versions v1…v21, incl. latest):**
  `signature::verify_signature_and_recover_signer` returns the **zero address** for signature scheme
  byte **`0x05`** with **no cryptographic verification**, and `exchange::withdraw_from_bank` treats
  `signer == 0x0` as authorized (`if signer==0x0 { ok } else { ok = signer==account }`). **Verified in
  bytecode.** Profit is **nil**: the withdrawal recipient is the *account address itself* (`loc2`, from
  the BCS payload) and `margining_engine::verify_health` + `account::get_max_withdrawable_amount` still
  run — so an attacker can trigger a withdrawal *from* any account but only *to that same account*, and
  operator-only actions (`set_funding_rate`, `authorize_liquidator`, …) require
  `signer == data_store::get_operator_address(...)`. ⇒ **mechanism high, profit $0** (residual).
- Also note: **every** old-only function in the whole cluster is `public(friend)`/`private` (internal
  helper), never `entry`/`public` — so the *removed-function* flavour of the primitive yields no
  externally callable entry point anywhere here.

## Tooling correction (important)
`simulateTransaction` **is** available on the public Sui GraphQL endpoint — it is a **Query** field (not
a Mutation), taking a gRPC-proto-JSON transaction:
`query { simulateTransaction(transaction: {"sender":"0x…","kind":{"programmableTransaction":{"inputs":[…],"commands":[{"moveCall":{…}}]}}}) { effects { status executionError{message} } } }`.
Two child reports stated it was unavailable; it works and was used (see `tools/sim_movecall.py`,
`poc/import_probes.py`, and the Bucket on-chain gate proof). Note `checksEnabled:false` is needed to
observe Move aborts (with `checksEnabled:true` the static "unused non-droppable result" check can mask
them).

## Method
`tools/sui.py` (GraphQL disassembly, exact-version `pkgat`), `tools/sim_movecall.py`
(`simulateTransaction`), live objects via `object(address:)`. Scripts: `poc/*.py`.
