# ZH4 pass-7 — Sui fresh cluster (AlphaFi, DipCoin, Bluefin Pro, Kai, Suigar)

**Date:** 2026-10-25 · **Chain:** Sui mainnet · **Status:** read-only; no transaction signed or sent;
no keys; simulation via public GraphQL `simulateTransaction` only.

**Scope (from `pass7/solana-sui.md` row 15 + `pass7/fresh-deep.md` §4):** five Sui protocols whose
packages were not yet pinned — **AlphaFi Lending** ($2.32M), **DipCoin** vault/spot/perp ($1.5M),
**Bluefin Pro** ($1.5M), **Kai Finance** ($0.88M), **Suigar** ($0.17M) — tested against the
**version/package-import** primitive (an old Sui package still callable after an upgrade) plus
**share/NAV**.

---

## TL;DR

| Target | DL TVL | live value read | version/import surface | headline E-U (unprivileged) | confidence |
|---|---|---|---|---|---|
| AlphaFi Lending | $2.32M | 36 markets, 511,873 positions; H-O ≈ $2.63M | **15 versions**; gate `LendingProtocol.version == 4` (only v15 passes) | **$0** (wind-down; 0 LTV/limits; oracle misconfig neutralised) | high |
| DipCoin (vault/perp/spot) | $1.5M | vaults $1.58M; perps bank $1.845M USDC | **9 versions**; gate `ProtocolConfig.version == 6` (v1–v7 abort) | **$0** | high |
| Bluefin Pro | $1.5M | "Aqua" USDC vault $71k | **21 versions**; gate is a **no-op** (`constants::get_version()=1` always) | **$0** (residual: `0x05`→signer `0x0` bypass, no profit) | medium |
| Kai Finance | $0.88M | leverage core; H-O ≈ $0.886M | **21 versions**; gate `SupplyPool.version==2`, `PositionConfig.version==5` (only v19–21) | **$0** | med-high |
| Suigar | $0.17M | SweetHouse houses ≈ $175,242 | 2 versions; gate `SweetHouse.version_set=["1"]` (v1 blocked) | **$0** | high |

**Total live extractable (external unprivileged) now: $0 proven** (confidence **medium-high** across
targets). The version/import primitive is **structurally live** on this cluster (old versions callable,
structs stable) and **three of five protocols rely on an explicit object version gate** (DipCoin,
AlphaFi, Kai, Suigar — effective; Bluefin's gate is a no-op). No unprivileged value path was found. An
honest $0 with proof is the result.

**H-O (holder-only recoverable):** AlphaFi Lend ≈ **$2.63M** (self-service withdrawals, open),
Kai ≈ **$0.886M**. Not an attacker path.

---

## The primitive, in exact terms

A Sui Move package is immutable; upgrades publish a new package object at a new address while the
*original* id remains the runtime id. Per Sui docs (*Upgrading Packages*) and the Move Book
(*Package Upgrades*): **old versions remain callable and share the same shared objects**; the only
protection is an explicit **version check** on the shared state.

**Cross-cutting results (this lane, `analysis/version-import-primitive.md`):**

1. **Old versions are genuinely callable (proven).** `simulateTransaction` with a gRPC-proto-JSON
   `MoveCall` against DipCoin **v1** `0x978fed07…::bank::set_relayer` returns
   `Function Not Found` (v1 has no `set_relayer`), while the **latest** `0xa5b1b7a4…::bank::set_relayer`
   returns `Move Bytecode Verification Error` (function found, args wrong). A non-existent package
   returns `Object … not found`. ⇒ the runtime loads the **old version's own module set**.
   Differential probes: `ci-out/import_probes.json`.
2. **The layout gate never protects old code.** Across all seven package families, **zero structs
   changed** between the first and latest version (only new structs were added) — `ci-out/struct_diff.json`.
   So any old-version function that is callable + unprivileged operates on the live objects.
3. **Version inventory & body diffs.** `ci-out/version_matrix.json` + `ci-out/body_diff.json`.
   Function-*presence* diffs are thin (a real correction: earlier Bucket "removed swap" leads were a
   pagination artefact). Function *bodies* changed widely (e.g. DipCoin `bank` 7 fns, `library`
   removed 8 incl. `verify_signature`; Bluefin `account` 18; Kai `position_core_clmm` 98).
4. **Version gates exist — and their effectiveness varies** (`analysis/version_gates.md`):
   - **DipCoin**: `protocol::check_version` asserts `ProtocolConfig.version == K` (K=1 in v1, K=6 in
     v9); live `ProtocolConfig.version = 6` ⇒ **v1–v7 blocked** — gate **effective**.
   - **Bucket V2** (sibling folder): `usdb::assert_valid_module_version<T>(&Treasury, v)`; live
     `BucketV2CDP.valid_versions = [2, 1]` ⇒ **v1 still allowed** — gate **partial**.
   - **Bluefin Pro**: `exchange::*` asserts `ExternalDataStore.version == constants::get_version()`;
     the constant is **1 in every version** ⇒ **gate is a no-op**, old versions callable.
   - Every old-only function in the whole cluster is `public(friend)`/`private` (internal helper),
     **never `entry`/`public`** ⇒ the removed-function flavour of the primitive yields no externally
     callable entry point.

---

## Live-state assessment (checkpoint 2026-10-25, `ci-out/live_state.json`)

| object | type | live value |
|---|---|---|
| DipCoin vaults (21) | `0x9645033a…::vault::VaultConfig` → vaults | **$1,581,424** (Σ `last_share_price × total_shares`) |
| DipCoin perps bank | `0x978fed07…::bank::Bank<USDC>` (`0x3cc2bfbe…`) | `coin_balance = 1,845,334,621,258` (6dp) = **$1,845,334**; `accounts.size = 789`; `is_withdrawal_allowed = true` |
| Bluefin Pro USDC vault ("Aqua") | `0xe7448169…` | `total_locked_amount = 71,147,420,000` (6dp) = **$71,147**; `deposit_paused = true`, `withdraw_paused = false` |
| Bluefin Pro data store | `0xe7448169…::data_store::ExternalDataStore` | 8 perpetuals |
| AlphaFi Lend protocol | `0x01d9cf05…` | 36 markets, 511,873 positions |
| Suigar SweetHouse | `0xcbb0929f…::sweethouse::SweetHouse` | 50 dynamic-field houses (casino bankroll) |

Prices (DefiLlama, 2026-10-25): SUI $0.9300, USDC $0.9996.

---

## DipCoin — the version/import path read in full (negative)

DipCoin perps published **9 versions** (v1 `0x978fed07…` → v9 `0xa5b1b7a4…`); the `vault` module was
added at v2 (`0x9645033a…`). Structs `Bank`, `BankAccount`, `Position`, `Perpetual`, `ProtocolConfig`
are **byte-identical v1↔v9**, so v1 code can mutate the live `Bank<USDC>`. v1–v6 expose
`entry bank::withdraw` / `withdraw_all` (kept in later versions as `withdraw`/`withdraw_v2`).

Full read of v1 `bank::withdraw`: it calls `protocol::check_basic`, rejects zero recipient, validates a
replay nonce (`sub_accounts::validate_unique_tx`), sets `acct = tx_context::sender(ctx)`, requires
`is_withdrawal_allowed` and `accounts[acct]`, then debits **the sender's own** `BankAccount` and
transfers to a caller-chosen address. **The debit is always from the sender, never a caller-supplied
victim ⇒ self-withdrawal only, not an unprivileged drain.** Full body in
`analysis/version-import-primitive.md` §5.

---

## Per-target verdicts

Detailed reads (method + quoted bytecode + live state + E-U/H-O/P/S) live in the child folders:

- `alphafi-kai/analysis/alphafi-kai.md` — AlphaFi Lending + Kai Finance.
- `dipcoin-bluefin-suigar/analysis/dipcoin-bluefin-suigar.md` — DipCoin + Bluefin Pro + Suigar.

| target | E-U | H-O | P | S | key evidence |
|---|---|---|---|---|---|
| AlphaFi Lend | $0 (high) | ≈$2.63M | — | — | `LendingProtocol.version=4`, only v15 passes; all 36 markets `borrow_limit=0`; ALPHA `deposit_limit=0`; oracle misconfig (ALPHA ~355× high) neutralised |
| DipCoin | $0 (high) | — | — | — | `ProtocolConfig.version=6`; v1–v7 abort; ungated NAV helpers need a `VaultNAV` only the gated constructor builds |
| Bluefin Pro | $0 (medium) | — | — | — | no effective gate → old versions callable, but no weaker guard; `0x05`→`0x0` signer bypass has no profit (recipient == account, health-checked) |
| Kai Finance | $0 (med-high) | ≈$0.886M | — | — | `SupplyPool.version=2`/`PositionConfig.version=5` → only v19–21 (bytecode-identical); admin fns return allow-listed `ActionRequest` |
| Suigar | $0 (high) | — | — | — | `SweetHouse.version_set=["1"]` → v1 (`package_version()=0`) blocked; v1/v2 value bodies identical |

**Summary verdict:** external unprivileged extractable **$0** on all five targets at the checkpoint
(medium-high confidence). Principal reasons: four of five rely on an effective object version gate;
AlphaFi Lend is in wind-down with 0 LTV/limits (its live oracle misconfiguration is the *cause* of the
wind-down but is neutralised); Bluefin's gate is ineffective but its v1 entry points still enforce
signatures, and its one real authorization-bypass (`0x05`→`0x0`) has no profit path. Residual/latent
risk is the version/import primitive itself, not a live drain.

---

## PoC / reproducibility

Read-only PoC scripts (`poc/`), all keyless, public GraphQL only:

| file | purpose | output |
|---|---|---|
| `poc/version_matrix.py` | per-version module/function inventory for 9 package families | `ci-out/version_matrix.json` |
| `poc/import_probes.py` | differential callability (old-version resolution) via `simulateTransaction` | `ci-out/import_probes.json` |
| `poc/struct_diff.py` | struct-layout stability first↔latest (exploitability gate) | `ci-out/struct_diff.json` |
| `poc/fn_body_diff.py` | function-body diff first↔latest (the real version signal) | `ci-out/body_diff.json` |
| `poc/live_state.py` | live value snapshot of the target objects | `ci-out/live_state.json` |
| `tools/sui.py`, `tools/sim_movecall.py` | GraphQL helpers (pkg/ver/obj/type/events/txfn/pkgat/sim) | — |

Run locally: `python3 poc/version_matrix.py` (endpoint `https://graphql.mainnet.sui.io/graphql`).
Heavy job in CI: `bash /home/heisenberg/CA/ci/ci-run.sh sui-fresh` → `ci/run.sh` writes all of the
above to `ci-out/`. **CI run URL:** _see `ci-log.txt` / final report_.

---

## Verdict, residual & blockers

- **Verdict:** **$0 E-U proven** across the five fresh Sui targets (medium confidence). No
  unprivileged value path found. AlphaFi/Kai/DipCoin/Bluefin/Suigar all resolve to gated or
  self-service or wind-down states.
- **Residual / latent (not extractable today):**
  - the **version/import primitive is live** on the whole cluster (old versions callable, structs
    stable) — any *future* discovery of a bug in an old version becomes immediately exploitable unless
    a version gate exists. Protocols here do **not** appear to use a global version gate (unlike
    Bucket V2), so this is a standing latent risk.
  - AlphaFi Lend's oracle-error wind-down is a live-incident residual (see child note).
- **Blockers:** (1) no local `sui` CLI; Sui JSON-RPC deprecated on all public fullnodes → GraphQL only
  (full disassembly + `simulateTransaction` are available, so this is **not** a code-read blocker);
  (2) Alchemy Sui RPC capacity-exceeded; (3) some value objects are priced $0 because DefiLlama does
  not price Scallop/CLMM receipt tokens (TVL figures therefore understate a few vaults).

---

## Methodology & sources

- Sui GraphQL `package`/`object`/`objects`/`events`/`transactions`/`simulateTransaction`
  (`https://graphql.mainnet.sui.io/graphql`), full Move bytecode disassembly.
- DefiLlama `api.llama.fi/protocols` + `coins.llama.fi/prices/current`; DefiLlama-Adapters for
  object discovery; Sui docs *Upgrading Packages*; Move Book *Package Upgrades*; HackenProof Kai scope.
- All reads are point-in-time 2026-10-25; re-read live state before acting. Web content treated as
  untrusted data. Nothing here is an instruction to transact.
