# anchor-lang version timeline — GHSA-c6rc-8jpp-2fgc / CVE-2026-45137 / RUSTSEC-2026-0144

Advisory: **`anchor-lang` vulnerable range `>= 1.0.0, < 1.0.2`** (first patched `1.0.2`).
Only `anchor-lang` **1.0.0** (2026-04-02) and **1.0.1** (2026-04-21) are affected; fixed in 1.0.2 (2026-05-02) and later.

Method (see `evidence.txt` for raw commands/outputs):
- Full local `git` clones of each repo; every file ever named `Anchor.toml`, `Cargo.lock`, `Cargo.toml`
  was enumerated across **all refs**, and for every commit touching such a file the anchor value was read
  at that commit and at its first parent, so **every value transition** is captured.
- Cross-checked with the authenticated GitHub API (commit history per path, commit search, raw
  `raw.githubusercontent.com` file fetches at the key SHAs).
- Dates below are **committer dates** (`%cI`), matching the GitHub API `commit.committer.date`.

A "Cargo hit" for `anchor-lang 1.0.0/1.0.1` is only a vulnerability if the **resolved** lockfile version is
`1.0.0`/`1.0.1`. A caret requirement such as `anchor-lang = "1.0.1"` means `^1.0.1` and resolves to the newest
`1.x` — so it must be checked against the lockfile. This matters below for marginfi and manifest.

Legend: ✅ = resolved 1.0.0/1.0.1 (in scope) · ⚠️ = literal `1.0.0`/`1.0.1` string but resolved elsewhere · ➖ = never 1.0.x.

---

## 1. mrgnlabs/marginfi-v2

- GitHub: `mrgnlabs/marginfi-v2` (repo id **574986155**), default branch **`main`**.
- Deployed on-chain program: `MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA` = `programs/marginfi`
  (anchor version inherited from the **root workspace** `Cargo.toml`/`Anchor.toml`).

| date | commit | file | anchor-lang | evidence |
|---|---|---|---|---|
| 2024-07-11 | `ce1bde77743e` | `Anchor.toml` / root `Cargo.lock` | 0.30.1 / 0.29.0 | `anchor_version` first introduced |
| 2025-05-27 | `4c7fa59d39ff` | `Anchor.toml` / `Cargo.toml` / `Cargo.lock` | **0.31.1** | "Consolidated 0.1.3 update (#331)" |
| 2026-04-29 | `fd1e96cc8235` | `Anchor.toml` | 0.31.1 | "Misc legacy tests (#570)" — still 0.31.1 |
| 2026-05-22 | `385d94fa8900` | root `Cargo.toml`/`Cargo.lock` | 0.31.1 → **0.32.1** | branch `debug/litesvm-hang-diagnostics` only |
| 2026-05-22 | `ba9fc536ddca` | root `Cargo.toml`/`Cargo.lock` | 0.32.1 → **1.0.2** | branch `debug/litesvm-hang-diagnostics` only |
| **2026-06-09** | **`1eaaac5eb4ee`** | `Anchor.toml` / `Cargo.toml` / `Cargo.lock` | 0.31.1 → **1.0.2** | "Upgrade to solana 3 (#597)" — **on `main`**, direct 0.31.1→1.0.2 |
| 2026-09-23 | `907ec85183c9` | `fuzz/crucible/Cargo.toml` | ⚠️ literal `anchor-lang = "1.0.1"` | "Add crucible invariant fuzz harness + FuzzCorp CI Internal (#675)" |
| 2026-09-23 | `907ec85183c9` | `fuzz/crucible/Cargo.lock` | **1.1.2** (resolved) | caret `"1.0.1"` resolves to 1.1.2, **not** 1.0.1 |
| HEAD | — | root `Cargo.lock` | 1.0.2 | current |

**Verdict — USED 1.0.0/1.0.1? NO.**
The deployed program workspace went **0.31.1 (≤2026-06-09) → 1.0.2 (2026-06-09)** directly, skipping 1.0.0/1.0.1.
The only literal `"1.0.1"` is a caret requirement in the `fuzz/crucible` invariant harness (added 2026-09-23),
whose lockfile resolves `anchor-lang 1.1.2` — not vulnerable.

---

## 2. raydium-io/raydium-clmm

- GitHub: `raydium-io/raydium-clmm` (repo id 493956473), default branch **`master`**.
- Deployed program `CAMMCzo5YL8w4VFF8KVHrK22GGUsp5VTaW7grrKgrWqK` = `programs/amm`.

| date | commit | file | anchor-lang | evidence |
|---|---|---|---|---|
| 2022-05-19 | `6a0d861593fe` | `Anchor.toml` | 0.24.2 | first commit |
| 2023-11-23 | `ceeedc3f15c8` | `Anchor.toml` | 0.29 | "Update anchor 0.29 (#57)" |
| 2025-05-14 | `eb7c392be9c8` | `Anchor.toml` | 0.31.0 | "Upgrade anchor to version 0.31 (#119)" |
| 2025-07-28 | `d4ec10153472` | `Anchor.toml` | 0.31.1 | "Support allowlist (#148)" |
| 2025-12-29 | `a5a46ff5cc76` | `Anchor.toml` / `programs/amm/Cargo.toml` | 0.31.1 → **0.32.1** (`=0.32.1`) | "chore: upgrade anchor to 0.32.1 (#160)" |
| **2026-09-29** | **`ed1eb41519d5`** | `Anchor.toml` / `Cargo.lock` / `programs/amm/Cargo.toml` | 0.32.1 → **1.0.2** (`=1.0.2`) | "Chore/upgrade anchor (#202)" |
| 2026-10-15 | `e414ac4b5dd2` | `tests/programs/transfer-hook-stub/*` | `=1.0.2` | new test program |

**Verdict — USED 1.0.0/1.0.1? NO.**
Direct **0.32.1 (2025-12-29) → 1.0.2 (2026-09-29)**; no `1.0.0`/`1.0.1` anywhere in history (matches the
known fact: `anchor_version = "1.0.2"` at `ed1eb41519`).

---

## 3. Lightprotocol/light-protocol

- GitHub: `Lightprotocol/light-protocol` (repo id 429237278), default branch **`main`**.
- Deployed programs (`SySTEM1...`, etc.) are built from `main`.

| date | commit | file | anchor-lang | evidence |
|---|---|---|---|---|
| 2024-02-08 | `5ecf404378ac` | root `Cargo.lock` | 0.28.0 → 0.29.0 | "chore: Update Anchor to 0.29" |
| 2025-04-22 | `cdd2f671dac2` | root `Cargo.toml` | =0.29.0 → =0.31.0 | "test: add new instruction integration test (#1703)" |
| 2025-05-05 | `5b2ba4008d9c` | root `Cargo.toml`/`Cargo.lock` | =0.31.0 → **=0.31.1** | "chore: fix token escrow idl (#1729)" |
| 2025-10-01 | `88a386ba25b5` | root `Cargo.toml` | =0.31.1 → `{ path = "./../anchor/lang" }` | branch `swen-0011-*` only |
| 2025-10-20 | `4de2eca37802` | root `Cargo.toml` | back to **=0.31.1** | "refactor: libs to nostd (#1997)" — on `main` |
| 2026-05-26 | `953063ebe8e7` | root `Cargo.toml`/`Cargo.lock` | 0.31.1 → **`1.0.0-rc.5`** | **branch `sergey/solana3` only** — "solana 3" |
| 2026-05-26 | `e41f2e41f48d` | root `Cargo.toml`/`Cargo.lock` | `1.0.0-rc.5` → **1.0.2** | **branch `sergey/solana3` only** — "Bump Anchor to 1.0.2" |
| HEAD | — | root `Cargo.toml` | **0.31.1** | `main` still 0.31.1 |

**Verdict — USED 1.0.0/1.0.1? NO.**
`main` never left 0.31.1 (still 0.31.1 at HEAD). A feature branch `sergey/solana3` briefly pinned
**`1.0.0-rc.5`** (a *pre-release*, semver `< 1.0.0`, i.e. outside the advisory range `>= 1.0.0, < 1.0.2`)
on 2026-05-26 before moving to 1.0.2 the same day. No released `1.0.0`/`1.0.1` ever appears.

---

## 4. smartcontractkit/chainlink-solana

- GitHub: `smartcontractkit/chainlink-solana` (repo id 399216773), default branch **`develop`**.
- Contracts live under `contracts/`.

| date | commit | file | anchor-lang | evidence |
|---|---|---|---|---|
| 2024-07-31 | `a008941dcfa6` | `contracts/Anchor.toml` / `contracts/Cargo.lock` | 0.29.0 | "Update: Anchor Contract Dependencies (#769)" |
| 2026-02-12 | `40ee7c89340a` | `contracts/Anchor.toml` | 0.29.0 → 0.30.0 | "wip" |
| 2026-02-20 | `8fd61df7e0d0` | `contracts/Anchor.toml` / `contracts/Cargo.lock` | 0.30.0 → **0.31.0 / 0.31.1** | "success build" |
| 2026-04-20 | `ea62f88cbdb4` | `contracts/Anchor.toml` | 0.29.0 → **0.31.0** | "bump anchor to 0.31 (#1530)" — on `develop` |
| 2026-10-19/22 | `b523bd63749c` / `108b3addec1c` | new program `Cargo.toml`s | 0.31.0 | new Data Feeds programs, still 0.31.x |

**Verdict — USED 1.0.0/1.0.1? NO.**
Highest anchor-lang anywhere is **0.31.1** (`contracts/Cargo.lock`); `Anchor.toml` tops out at 0.31.0.
No 1.0.x at all.

---

## 5. metaplex-foundation/mpl-bubblegum

- GitHub: `metaplex-foundation/mpl-bubblegum` (repo id 651611079), default branch **`main`**.
- Deployed program `BGUMAp9Gq7iTEuizy4pqaxsTyUCBK68MDfK752saRPUY` = `programs/bubblegum`.

Two independent dependency graphs exist:

**A. On-chain program (`programs/bubblegum`) — never 1.0.x**

| date | commit | file | anchor-lang | evidence |
|---|---|---|---|---|
| 2023-08-02 | `0cb181b5b31d` | `programs/bubblegum/program/Cargo.toml` | 0.26.0 → 0.28.0 | "Bump anchor version (#20)" |
| 2024-05-16 | `b25553af62d8` | `programs/bubblegum/program/Cargo.toml` | 0.28.0 → **0.29.0** | "feat: add create tree with root instruction" |
| HEAD | — | `programs/bubblegum/program/Cargo.toml` | **0.29.0** | `programs/bubblegum/Anchor.toml` has **no** `anchor_version` field (ever) |

**B. Rust client crate (`clients/rust`, package `mpl-bubblegum` v4.0.0, its own workspace) — ⚠️ real 1.0.0**

| date | commit | file | anchor-lang | evidence |
|---|---|---|---|---|
| 2025-05-30 | `1eb7edd100cc` | `clients/rust/Cargo.lock` | 0.29.0 → 0.31.1 | "Allow Solana 2.0 and test some V2 instructions…" |
| **2026-04-21** | **`6d95fd0b17be`** | `clients/rust/Cargo.toml` + `Cargo.lock` | 0.31.1 → **1.0.0** (resolved) | "Update mpl-bubblegum Rust client to Solana 3.0 (#157)" |
| 2026-09-22 | `da5fcbfef208` | `clients/rust/Cargo.toml` + `Cargo.lock` | **1.0.0** (still) | "chore: Release mpl-bubblegum version 4.0.0 (#180)" — on `main` |

Declared as `anchor-lang = { version = "1.0.0", optional = true }` (feature `anchor`); lockfile resolves
exactly `1.0.0` (checksum `8de9dce227fa0c08be20fef008c5b04681e1e0a15cb396e9619a9a1f800ff6cd`), on `main` since
2026-04-21 through HEAD.

**Verdict — USED 1.0.0/1.0.1? YES in the Rust *client* crate only — window 2026-04-21 → present (still at HEAD).
On-chain program: NO** (program is 0.29.0; the client crate is not the deployed program).

---

## 6. Bonasa-Tech/manifest  (CKS-Systems/manifest resolves to the same repo)

- GitHub: `Bonasa-Tech/manifest` — repo id **845595897**; `CKS-Systems/manifest` **redirects to the same id**
  (rename, not a separate fork). Default branch **`main`**.
- Deployed program `MNFSTqtC93rEfYHB6hF82sKdZpUDFWkViLByLd1k1Ms` is **not an Anchor program** (no `Anchor.toml`
  ever existed in the repo; own account/instruction framework).

| date | commit | file | anchor-lang | evidence |
|---|---|---|---|---|
| 2024-11-25 | `0689daebbec7` | root `Cargo.lock` | 0.29.0 | "Sync audit formal verification (#294)" |
| 2025-07-01 | `263d828f3c97` | root `Cargo.lock` | 0.29.0 → **0.31.1** | "Update dependencies (#421)" |
| 2026-09-08 | `64340cb368f1` | `certora/solana-cvt/*` | 0.31.1 | "Run the programs on pinocchio (#702)" |
| 2026-10-05 | `f1875a0f8e6d` | `fuzz/crucible/Cargo.toml` | ⚠️ literal `anchor-lang = "1.0.1"` | "Init crucible fuzzing (#745)" |
| 2026-10-05 | `f1875a0f8e6d` | `fuzz/crucible/Cargo.lock` | **1.2.0** (resolved) | caret `"1.0.1"` resolves to 1.2.0, **not** 1.0.1 |

**Verdict — USED 1.0.0/1.0.1? NO.**
The program does not use anchor at all. The only literal `"1.0.1"` is a caret requirement in the
`fuzz/crucible` harness (added 2026-10-05), whose lockfile resolves `anchor-lang 1.2.0` — not vulnerable.

---

## 7. helium/helium-program-library

- GitHub: `helium/helium-program-library` (repo id 528358675), default branch **`master`**.
- Deployed programs (`hdaoVTC…`, `credMBJh…`, `1azyuav…`, `memMa1H…`, `treaf4w…`) use the root workspace.

| date | commit | file | anchor-lang | evidence |
|---|---|---|---|---|
| 2023-06-17 | `f30ec6d83315` | root `Cargo.toml` | 0.26.0 | "Remove submodule programs and use workspace inheritance deps" |
| 2023-09-21 | `9bba8516e90c` | root `Cargo.toml` | 0.26.0 → 0.28.0 | "Upgrade to anchor 28, solana 1.16… (#411)" |
| 2024-02-02 | `e10d8a4340c9` | root `Cargo.toml` | 0.28.0 → 0.29.0 | "WIP" |
| 2025-03-20 | `f913854bd729` | root `Cargo.toml` | 0.28.0 → **0.31.0** | "Feat/anchor 30 upgrade (#881)" |
| 2025-04-21 | `ccd0ab1fd5b9` | root `Cargo.toml`/`Cargo.lock` | 0.31.0 → **0.31.1** | "Fix exit ordering on closing delegation (#925)" |
| 2026-09-17 | `6ad71ee0bda5` | root `Cargo.toml`/`Cargo.lock` | 0.31.1 → **0.31.2** | "chore: bump anchor to 0.31.2" |
| HEAD | — | root `Cargo.toml` / `Cargo.lock` | **0.31.2** | `Anchor.toml` has no `anchor_version` field |

**Verdict — USED 1.0.0/1.0.1? NO.**
Highest anchor-lang is **0.31.2**. No 1.0.x at all.

---

## 8. openbook-dex/openbook-v2

- GitHub: `openbook-dex/openbook-v2` (repo id 632311168), default branch **`master`**.
- Deployed program `opnb2LAfJYbRMAHHvqjCwQxanZn7ReEHp1k81EohpZb` = `programs/openbook-v2`.
- Repo inactive since 2024-07-15.

| date | commit | file | anchor-lang | evidence |
|---|---|---|---|---|
| 2023-04-25 | `f3a23d31a11b` | `Cargo.toml` / `Cargo.lock` | 0.27.0 | "initial commit" |
| 2023-09-11 | `1abd8fb378bd` | `Cargo.lock` | 0.27.0 → 0.28.0 | "Moving to compile everything in anchor v0.28.0 instead" |
| 2024-04-16 | `6ba26edd2734` | `Cargo.toml` / `Cargo.lock` | 0.28.0 → **0.29.0** | "program: update to anchor 0.29 and solana 1.17 (#249)" |
| HEAD | — | `Cargo.toml` | **0.29.0** | root `Anchor.toml` has no `anchor_version` field |

**Verdict — USED 1.0.0/1.0.1? NO.**
Highest anchor-lang is **0.29.0**. No 1.0.x at all.

---

## Consolidated verdicts

| # | repo | versions used (first-seen dates) | ever 1.0.0/1.0.1? | window / notes |
|---|---|---|---|---|
| 1 | mrgnlabs/marginfi-v2 | 0.30.1 (2024-07-11) → 0.31.1 (2025-05-27) → **1.0.2 (2026-06-09)** | **NO** | direct 0.31.1→1.0.2 on `main`; `fuzz/crucible` literal `"1.0.1"` (2026-09-23) resolves to 1.1.2 |
| 2 | raydium-io/raydium-clmm | 0.24.2 → 0.29 → 0.31.0 → 0.31.1 → 0.32.1 (2025-12-29) → **1.0.2 (2026-09-29)** | **NO** | direct 0.32.1→1.0.2 |
| 3 | Lightprotocol/light-protocol | 0.28.0 → 0.29.0 → 0.31.0 (2025-04-22) → 0.31.1 (2025-05-05); `main` **still 0.31.1** | **NO** | feature branch `sergey/solana3` briefly pinned `1.0.0-rc.5` (pre-release, out of range) → 1.0.2 on 2026-05-26 |
| 4 | smartcontractkit/chainlink-solana | 0.29.0 (2024-07-31) → 0.30.0 (2026-02-12) → 0.31.0 (2026-02-20) | **NO** | max 0.31.1 in lockfile; no 1.0.x |
| 5 | metaplex-foundation/mpl-bubblegum | program 0.26.0 → 0.28.0 → **0.29.0**; client crate 0.31.1 → **1.0.0 (2026-04-21)** | **YES — client crate only** | resolved `anchor-lang 1.0.0` in `clients/rust` since 2026-04-21, still at HEAD; on-chain program 0.29.0 |
| 6 | Bonasa-Tech/manifest (CKS-Systems/manifest → same repo) | 0.29.0 (2024-11-25) → **0.31.1 (2025-07-01)**; not an anchor program | **NO** | `fuzz/crucible` literal `"1.0.1"` (2026-10-05) resolves to 1.2.0 |
| 7 | helium/helium-program-library | 0.26.0 → 0.28.0 → 0.29.0 → 0.31.0 (2025-03-20) → 0.31.1 (2025-04-21) → **0.31.2 (2026-09-17)** | **NO** | max 0.31.2; no 1.0.x |
| 8 | openbook-dex/openbook-v2 | 0.27.0 (2023-04-25) → 0.28.0 → **0.29.0 (2024-04-16)** | **NO** | repo inactive since 2024-07-15 |

### Caveats / limitations
- The clones contain all **branches and tags** present on GitHub, but **not deleted branches or PR refs**.
  A 1.0.0/1.0.1 pin that existed only on a now-deleted branch cannot be observed via git; no such pin is
  claimed by any commit search either.
- `git log --all` history scanning is exhaustive for the three file names that carry the anchor version
  (`Anchor.toml`, `Cargo.lock`, `Cargo.toml`); no alternate table syntax (`[dependencies.anchor-lang]`) was
  ever used in any of the eight repos.
- The marginfi GitHub commit-search endpoint (`/search/commits?q=repo:mrgnlabs/marginfi-v2+...`) returns
  `Validation Failed` for this token; the local clone was used instead (equivalent, and more complete).
