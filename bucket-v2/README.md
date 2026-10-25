# ZH4 pass-7 — Bucket Protocol V2 (Sui CDP v2)

**Date:** 2026-10-25 · **Chain:** Sui mainnet · **Status:** read-only; no transaction signed or sent;
no keys; public GraphQL + `simulateTransaction` only.

**Scope:** Bucket Protocol V2 — DefiLlama TVL **$27.84M** (+218 %/7 d), the largest fast-growing fresh
Sui target from `pass7/fresh-deep.md` §4. A Sui CDP v2 (collateralised debt positions + a PSM
stablecoin pool). Primitive focus: **version/package import** + **oracle** + **liquidation** +
**share/NAV**.

---

## TL;DR

| Question | Answer |
|---|---|
| Live custody (checkpoint 2026-10-25) | CDP collateral ≈ **$25.4M** across 21 `Vault<T>` objects; PSM pools ≈ **$2.46M**; total ≈ $27.8M (matches DL) |
| Version/import primitive | **Structurally open, but mitigated by an explicit version gate** — see below |
| Headline E-U (external unprivileged) | **$0 proven** (medium confidence) |
| Residual / latent | the CDP allow-list still authorises package version **1** |

**Total live extractable (external unprivileged) now: $0 proven.** Value movement is a witness-gated
request/response flow; the one genuinely unusual fact is the version allow-list (below).

---

## The version gate (parent lane, `analysis/version_gate.md`)

Bucket V2 uses the Sui-recommended mitigation for the version/import primitive: a **version allow-list
bound to a shared `Treasury` object**.

- CDP package `version` module: `package_version() -> u16` (1 in v1, 2 in v4) and
  `assert_valid_package(&Treasury)` → `usdb::assert_valid_module_version<BucketV2CDP>(&Treasury, package_version())`.
  `vault::{create,set_*,update_position,debtor_request,donor_request,liquidate,collect_interest}` each
  call it.
- `usdb::assert_valid_module_version<T>(&Treasury, v)` (usdb pkg
  `0xe14726c336e81b32328e92afc37345d159f5b550b09fa92bd43640cfdd0a0cfd`): looks up
  `Treasury.module_config_map[TypeName::get<T>()]` and **aborts unless `v ∈ valid_versions`**.
- Live `Treasury` `0x4de1c29a89d6888ebf8f7ae20364571dce4e1e42b9c9221f7df924ad6f9e617d`
  (obj version 1061340251):

| module | valid_versions |
|---|---|
| **BucketV2CDP** | **[2, 1]** |
| BucketV2PSM | [2] |
| BucketV2Saving | [1, 2] |
| BucketV2Flash | [1] |
| CetusLp / BluefinLp | [5] |

**⇒ the CDP allow-list still authorises version 1**, and Bucket V2 vault/pool **structs are
byte-identical v1→v4** (`ci-out`-style scan: `poc/struct_diff.py`), so the v1 CDP package
(`0x9f835c21…`, `package_version()=1`) passes the gate and executes against the **live `Vault<T>`
objects**. This is the version/import surface, structurally open.

**But the v1↔v4 bytecode diff is not obviously exploitable:** `liquidate` only builds a
`request::new(...)` (`UpdateRequest`) — it does not transfer funds; the differences are
`double::ceil`→`double::floor` rounding plus field-index/`VecLen`/`type_name::with_defining_ids`
bookkeeping. Settlement happens later in the witness-gated `response` flow. See
`analysis/version_gate.md`.

---

## Live state (checkpoint 2026-10-25)

CDP collateral by `Vault<T>` (21 objects; `total_coll_amount` priced with DefiLlama):

| collateral | coll (human) | debt (USDB) | coll USD |
|---|---|---|---|
| `0x7438e8ca…` (BTC-like, price ~$89,814) | 217.68 | 9 | **$19,551,052** |
| `0xbde4ba4c…::hasui::HASUI` | 5,005,092.30 | 1,502,788 | **$5,038,113** |
| `0x876a4b7b…` (BTC-like, ~$80,506) | 3.01 | 109,087 | $241,959 |
| `0x549e8b69…` | 230,679.12 | 3,359 | $229,135 |
| `0x0041f9f9…` (~$80,368) | 2.16 | 15,243 | $173,503 |
| `0x0000…0000` (SUI) | 63,647.11 | 28,579 | $58,943 |
| 15 more | — | — | ~$79k |
| **TOTAL** | | | **≈ $25,372,471** |

PSM pools (`Pool<T>`, 4 objects): SUI pool `balance_amount = 2,469,836.21` → **$2,463,196**;
USDC pools $1,166 + $2; total **≈ $2,464,364**. (Prices: SUI $0.9300, USDC $0.9996.)

`Treasury` `limited_supply` for CDP: limit 30,000,000,000,000, supply 1,747,713,413,236.

---

## Verdict & residual

- **Verdict:** **$0 E-U proven** for Bucket Protocol V2 (medium confidence). The version/import
  primitive is mitigated by an explicit on-chain version gate; value movement is request/response +
  witness gated; liquidation is a request builder, not a transfer.
- **Residual / latent:** the **CDP allow-list retains version 1**. If a weakness exists in a v1 CDP
  function that v2 fixed, it is reachable today. The candidate is the `liquidate` rounding change and
  whatever changed in `vault::update_position` (16.7 KB→17.3 KB) — flagged for a deeper diff, **not**
  a live drain.
- **Blockers:** no local `sui` CLI; Sui JSON-RPC deprecated on public fullnodes (GraphQL only — full
  bytecode + simulation available); DefiLlama does not price some Scallop/CLTV receipt collaterals
  (vault USD totals slightly understate).

---

## Method & files

- Sui GraphQL disassembly + `simulateTransaction`; DefiLlama prices/adapters (`bucket-protocol-v2`).
- PoC (read-only): `poc/version_matrix.py`, `poc/import_probes.py`, `poc/struct_diff.py`,
  `poc/fn_body_diff.py`, `poc/live_state.py`; helper `tools/sui.py`.
- Full per-module read: `analysis/bucket-v2.md`; gate analysis: `analysis/version_gate.md`;
  disassemblies: `analysis/disasm/`.
- CI: `bash /home/heisenberg/CA/ci/ci-run.sh bucket-v2` → `ci/run.sh` → `ci-out/`. **Run URL:** _see
  `ci-log.txt` / final report._
