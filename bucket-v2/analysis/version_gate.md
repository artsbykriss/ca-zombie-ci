# Bucket Protocol V2 — version-gate analysis (ZH4 pass-7, parent lane)

Read-only, public Sui GraphQL. No keys/signing. Checkpoint 2026-10-25.

## The gate
Bucket V2 protects against the version/import primitive with the Sui-recommended pattern: a
**version allow-list bound to a shared `Treasury` object**.

- CDP package (`vault`) `version` module:
  ```
  public package_version(): u16 { 1 }                 // in v1
  public package_version(): u16 { 2 }                 // in v4 (latest)
  public(friend) assert_valid_package(&Treasury) {
      usdb::assert_valid_module_version<BucketV2CDP>(&Treasury, package_version());
  }
  ```
- `vault::create/set_*/update_position/debtor_request/donor_request/liquidate/collect_interest`
  each call `version::assert_valid_package(&treasury)` (7 call sites in v1, 9 in v4).
- `usdb::assert_valid_module_version<T>(&Treasury, v)` (usdb pkg
  `0xe14726c336e81b32328e92afc37345d159f5b550b09fa92bd43640cfdd0a0cfd`, original id):
  looks up `Treasury.module_config_map[TypeName::get<T>()]`, then
  `vec_set::contains(valid_versions, &v)` and **aborts unless `v` is in the set**.

## The live Treasury
`Treasury` object `0x4de1c29a89d6888ebf8f7ae20364571dce4e1e42b9c9221f7df924ad6f9e617d`
(object version 1061340251), `module_config_map`:

| module (witness) | valid_versions | limited_supply (limit / supply) |
|---|---|---|
| `BucketV2CDP` (`9f835c21…::witness::BucketV2CDP`) | **[2, 1]** | 30,000,000,000,000 / 1,747,713,413,236 |
| `BucketV2PSM` (`c2ae6693…::witness::BucketV2PSM`) | [2] | 1,000,000,000,000,000 / 2,471,004,210,387 |
| `BucketV2Saving` | [1, 2] | 300,000,000,000 / 69,782,769,932 |
| `BucketV2Flash` | [1] | 5,000,000,000,000 / 0 |
| `CetusLp` / `BluefinLp` / `MomentumLp` / `FerraLp` / `SteammLp` / `CurrentLp` | [5]/[1]/… | … |

## Consequence — the allow-list still authorises CDP version 1
Because `BucketV2CDP.valid_versions = {1, 2}`, a transaction calling the **v1 CDP package**
(`0x9f835c21…`, logical `package_version()=1`) passes `assert_valid_package` and executes against
the **same live `Vault<T>` shared objects**. Cross-version struct scan (`poc/struct_diff.py`) shows
Bucket V2 vault/pool **structs are byte-identical v1→v4**, so v1 code can deserialise and mutate the
live vaults. ⇒ the version/import surface is **structurally open** (the allow-list, not the code, is
what keeps v1 alive).

## What v1 changes actually are (v1 vs v4 `vault`, bytecode diff)
- `liquidate`: v1 computes the repay amount with `double::ceil` then clamps to the debt; v4 uses
  `double::floor` plus an exact-equality special case. `liquidate` only builds a
  `request::new(...)` (`UpdateRequest`) — it does **not** transfer funds; settlement happens later in
  the witness-gated `response` flow (`destroy_response`/`update_position`).
- `destroy_response`/`debtor_request`/`donor_request`/`collect_interest`: differ only in
  field-index constants and vector lengths (e.g. `VecLen(24)`→`VecLen(26)`, `MutBorrowFieldGeneric[12]`
  →`[7]`, `type_name::get`→`type_name::with_defining_ids`) — layout bookkeeping, not gating.
- `vault::update_position` (16.7 KB→17.3 KB) is the big one; not fully diffed here.

## Verdict (parent)
- Bucket V2 has a **working version gate**, so the primitive is **mitigated by design** — but the
  **allow-list retains version 1 for CDP**, so it is not fully closed. This is a **latent** risk:
  exploitable only if a v1 CDP function has a weakness absent in v2 (candidate: the `liquidate`
  rounding change; and whatever changed in `update_position`).
- No unprivileged drain is claimed from the gate alone. Value flow is request/response + witness
  gated. See `bucket-v2/README.md` and `bucket-v2/analysis/` for the full read.
