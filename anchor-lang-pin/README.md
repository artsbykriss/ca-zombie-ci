# ZH4-PASS5 · `anchor-lang` advisory pin — CVE-2026-45137 / GHSA-c6rc-8jpp-2fgc / RUSTSEC-2026-0144

**Date:** 2026-10-23 · **Chain:** Solana mainnet · **Status:** read-only; RPC `getAccountInfo`/`getProgramAccounts`/`getBlockTime` only, no transaction signed or sent; PoCs are host-side + LiteSVM/CI only.
**Finding:** P5-08 (TIER 2 HIGH) — `anchor-lang` **1.0.0 / 1.0.1** HIGH, `Program<'info, System>` not validated.

---

## 1. TL;DR

The advisory is **real** (reproduced: see §5) but its exploit precondition is **narrow** and **no live program satisfies it**.
Of the eight repos named in pass-5, **none** has a deployed program on `anchor-lang` 1.0.0/1.0.1 (two are on the patched **1.0.2**, the rest are not on the 1.0.x family at all — 0.29/0.30/0.31/0.32, Pinocchio, native Serum, or a custom entrypoint).
A broader sweep of all **655 OtterSec-verified** Solana programs found **10** verified program ids whose verified build pins `anchor-lang` **1.0.0/1.0.1** — but **none** of them forwards the caller-supplied system-program key into a CPI, which is the only way the bug yields value. **Live extractable = $0.**

| Target (pass-5 named) | Deployed program | anchor-lang family | Exact version | On 1.0.0/1.0.1? | Evidence |
|---|---|---|---|---|---|
| **marginfi** | `MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA` | 1.0.x | **1.0.2** | **No** | OtterSec-verified build @ `c5d440f6` (2026-10-12); `Anchor.toml anchor_version="1.0.2"`, `Cargo.lock anchor-lang 1.0.2` |
| **raydium-clmm** | `CAMMCzo5YL8w4VFF8KVHrK22GGUsp5VTaW7grrKgrWqK` | 1.0.x | **1.0.2** | **No** | repo `Anchor.toml`=1.0.2 & `anchor-lang = "=1.0.2"` since commit `ed1eb41519` (2026-09-29); last deploy 2026-10-22; never used 1.0.0/1.0.1 (0.32.1 → 1.0.2) |
| raydium-cp-swap (same authority) | `CPMMoo8…` | 1.0.x | **1.0.2** | **No** | `anchor-lang = "=1.0.2"` |
| raydium-launchpad (same authority) | `LanMV9s…` | 1.0.x | 1.0.x, ≥1.0.2 by date | **No** (see §6) | deploy 2026-09-11, after the 2026-05-02 fix |
| **mpl-bubblegum** | `BGUMAp9Gq7iTEuizy4pqaxsTyUCBK68MDfK752saRPUY` | ≤0.30 | n/a | **No** | ELF has the `8 byte instruction identifier` (≤0.30) markers |
| **openbook** v2 | `opnb2LAfJYbRMAHHvqjCwQxanZn7ReEHp1k81EohpZb` | ≤0.30 | n/a | **No** | ≤0.30 markers; last deploy 2024-02-27 |
| **openbook** v1 | `srmqPvymJeFKQ4zGQed1GFppgkRHL9kaELCbyksJtPX` | native Serum | n/a | **No** | not an anchor program |
| **light-protocol** system | `SySTEM1eSU2p4BGQfQpimFEWWSC1XDFeun3Nqzz3rT7` | — | n/a | **No** | Pinocchio entrypoint (not anchor) |
| light-protocol (registry / account-compression / compressed-token) | `Lighton…` / `compr6…` / `cToken…` | 0.31–0.32 | n/a | **No** | ≤0.32 family markers |
| **chainlink-solana** (OCR2 / data-feeds / access-controller) | `HEvSKofv…` / `cjg3oHmg…` / `9xi644bR…` | ≤0.30 | n/a | **No** | ≤0.30 markers; last deploys 2022 |
| **helium** (19 programs: sub-daos, data-credits, lazy-distributor, treasury, mobile-entity-manager, fanout, mini-fanout, price/rewards-oracle, hexboosting, circuit-breaker, dc-auto-top, entity-manager, voter-stake-registry, welcome-pack, lazy-transactions, no-emit, tuktuk-dca, hpl-crons, proposals) | `hdao…`, `cred…`, `1azy…`, `treaf…`, `mem…`, … | 0.31–0.32 | n/a | **No** | `Instruction discriminator not provided` (0.31+) markers, no 1.0.x markers |
| **manifest** | `MNFSTqtC93rEfYHB6hF82sKdZpUDFWkViLByLd1k1Ms` (+ `wMNFST…`, `UMnFSt…`) | — | n/a | **No** | custom entrypoint (`src/entrypoint/mod.rs`), **zero** anchor error strings in the ELF |

**Total live extractable now: $0.00** (E-U). Confidence **high** for the named set; **medium-high** for the global claim (coverage caveat in §9).

### 1b. Why pass-5 flagged these eight repos (and why it does not matter)

Pass-5's evidence was a **`anchor-lang 1.0.0/1.0.1` Cargo hit** per repo. A repo-history audit across *all refs* of all eight repos (`analysis/child2/anchor_timeline.md`) resolves those hits:

| repo | what the "1.0.0/1.0.1 hit" actually was | deployed program |
|---|---|---|
| marginfi-v2 | `fuzz/crucible/Cargo.toml` literal `anchor-lang = "1.0.1"` (caret) → resolves **1.1.2** | 0.31.1 → **1.0.2** directly on `main` (2026-06-09) |
| raydium-clmm | nothing — never used 1.0.x | 0.32.1 → **1.0.2** (2026-09-29) |
| light-protocol | feature branch `sergey/solana3` pinned **`1.0.0-rc.5`** (pre-release, *outside* `>=1.0.0`) | `main` is 0.31.1 |
| chainlink-solana | nothing — max 0.31.1 | 0.29–0.31 (deploys 2022–2026) |
| **mpl-bubblegum** | the **Rust client crate** `clients/rust` resolves `anchor-lang 1.0.0` (real) since 2026-04-21 | **on-chain program is 0.29.0** |
| manifest | `fuzz/crucible` literal `"1.0.1"` (caret) → resolves **1.2.0** | not an anchor program at all |
| helium | nothing — max 0.31.2 | 0.26 → 0.31.2 |
| openbook-v2 | nothing — max 0.29.0 | 0.29.0 (repo inactive since 2024) |

So **none of the eight ever built its deployed program with anchor-lang 1.0.0/1.0.1**. The only true 1.0.0 pin in any of them is mpl-bubblegum's *off-chain client crate* (not a program, cannot be exploited on-chain).

---

## 2. The bug, exactly

`anchor-lang` `1.0.0` / `1.0.1` — `lang/src/accounts/program.rs`:

```rust
impl<'a, T: Id> TryFrom<&'a AccountInfo<'a>> for Program<'a, T> {
    fn try_from(info: &'a AccountInfo<'a>) -> Result<Self> {
        // Special handling for unit type () - only check executable, not program ID
        let is_unit_type = T::id() == Pubkey::default();      // <-- bug
        if !is_unit_type && info.key != &T::id() { return Err(ErrorCode::InvalidProgramId…); }
        if !info.executable { return Err(ErrorCode::InvalidProgramExecutable…); }
        Ok(Program::new(info))
    }
}
impl crate::Id for () { fn id() -> Pubkey { Pubkey::default() } }
```

`System::id()` is **also** `Pubkey::default()` (the all-zero pubkey `11111111111111111111111111111111`), so `is_unit_type` is `true` for `Program<'info, System>` and the id check is folded away: **any executable account is accepted as the system program**.

Fixed in **1.0.2** (2026-05-02, commit `3eb1fb04…`) by deleting `impl Id for ()` and adding a dedicated `TryFrom<…> for Program<'a, ()>` that only checks executability, leaving the typed `Program<'a, T>` path to compare `info.key == &T::id()`.

**Exploit precondition (from the advisory PoC).** The victim must *build a CPI instruction whose `program_id` is the caller-supplied `system_program` key*, e.g.

```rust
let ix = Instruction { program_id: ctx.accounts.system_program.key(), accounts, data /* system Transfer */ };
invoke(&ix, &[sender, recipient, system_program])?;
```

**Why that precondition is rare.** Every Anchor `system_program::*` helper (`transfer`, `create_account`, `allocate`, `assign`, `…`) and every `#[account(init)]` expansion calls `solana_program::system_instruction::*`, which **hard-codes `system_program::ID`**; `CpiContext.program_id` is only read by `Debug` in anchor-lang 1.0.x (verified against the crate sources, §5). So the (very common) `transfer(CpiContext::new(ctx.accounts.system_program.key(), …))` pattern — which *looks* like it forwards the key — is **immune**. Only a hand-rolled `Instruction { program_id: …system_program… }` is exploitable.

---

## 3. Live-state assessment (all reads at Solana finalized slot **460,352,xxx**, 2026-10-23)

| # | Program (id) | last deploy (UTC) | upgrade authority | ELF | anchor family | 1.0.x markers |
|---|---|---|---|---|---|---|
| 1 | marginfi `MFv2hWf31…` | 2026-10-12 15:18 | `J3oBkTkDXU3TcAggJEa3YeBZE5om5yNAdTtLVNXFD47` | 3.86 MB | 1.0.x | dup-mutable, already-migrated |
| 2 | raydium-clmm `CAMMCzo5…` | 2026-10-22 06:24 | `FytDrVzDybM1TwFQPGb8qaxZR7dBCzNeqT3vtQsceZQK` | 1.50 MB | 1.0.x | dup-mutable, already-migrated |
| 3 | raydium-cp-swap `CPMMoo8…` | 2026-10-01 | `FytDrVz…` | — | 1.0.x | — |
| 4 | raydium-launchpad `LanMV9s…` | 2026-09-11 | `FytDrVz…` | — | 1.0.x | — |
| 5 | mpl-bubblegum `BGUMAp9…` | 2026-09-22 | `bfQVv6niKVgEURYqQ1beJmiEQQN7MrvLRvk3mZGFubb` | 1.34 MB | ≤0.30 | none (`8 byte instruction identifier`) |
| 6 | openbook-v2 `opnb2LAf…` | 2024-02-27 | — | 1.04 MB | ≤0.30 | none |
| 7 | helium-sub-daos `hdao…` | 2026-09-25 | `pULUgsYtKvT7qhsL8QJ2oJXYQUeCCdjtfawPnBqEr3U` | 1.13 MB | 0.31–0.32 | none |
| 8 | light-system `SySTEM1e…` | 2026-03-12 | `7PeqkcCXeqgsp5Mi15gjJh8qvSLk7n3dgNuyfPhJJgqY` | 0.70 MB | Pinocchio | none (not anchor) |
| 9 | manifest `MNFSTqtC…` | 2026-10-20 | — | 0.36 MB | custom entrypoint | none (not anchor) |
| 10 | chainlink OCR2 `HEvSKofv…` | 2022-11-02 | `BMKk78WEmZCQPptNYET8jdwf4EnsXY4WS74TBWjiSAbb` | 0.33 MB | ≤0.30 | none |

The **only** two named programs that are even on the 1.0.x family (marginfi, raydium-clmm/cp-swap/launchpad) are **1.0.2** — the fixed release. marginfi is a *reproducible verified build* (OtterSec `is_verified=true`, `on_chain_hash == executable_hash == eb761836…`, commit `c5d440f6`, `Anchor.toml anchor_version="1.0.2"`), which is a byte-level provenance proof. raydium pinned `anchor-lang = "=1.0.2"` before its last deploy and never used 1.0.0/1.0.1.

## 4. Broader sweep — every OtterSec-verified program

`analysis/verified_scan.py` enumerated **655** verified programs (`verify.osec.io/verified-programs/<n>`), resolved each verified git commit, and read its `Cargo.lock`. **329** use `anchor-lang`. Ten program ids pin **1.0.0 / 1.0.1**:

| Program id | repo @ verified commit | anchor-lang | notes |
|---|---|---|---|
| `2qEmhLEnTDu2RiabWT7XaQj5ksmbzDDs6Z7Mr2nBcU9C` | koshak01/tidex6 @ `f71575d8` | **1.0.0** | **frozen (immutable)** — cannot be patched; ~$0.15 in pool vaults (§6) |
| `Gt1duB4bPj2CmW9y7eiGzekeCfiR1UckjiyPGSbyWRVU` | koshak01/tidex6 @ `2965920f` | **1.0.0** | frozen |
| `gaszjG8797GGm8oACCzH2KLLifGp2nugKkLwaecwBjT` | axelarnetwork/axelar-amplifier-solana @ `3a1f2e7f` | **1.0.0** | gas-service |
| `gtwqvLL93XK7pC2eMvfGamqokvs19AytzaVhrL2iKiz` | ″ | **1.0.0** | gateway |
| `itsAUdHnV2K99ppbM6d6WUDac8MD54RAE7dUKHnw1Eg` | ″ | **1.0.0** | interchain-token-service |
| `memtaCuA26EANM26matPAhiQGPnvsrYdJYrYcK8wcon` | ″ | **1.0.0** | memo |
| `opre2VP8uvjq3YS15NRhRagsWvsY5DybitvCeLPAwbK` | ″ | **1.0.0** | operators |
| `wocur7QRRMdzPZN52688gBa5iJD4mLkNWSxN5xGGRjY` | Woody4618/workflow-tutorial @ `88f139fb` | **1.0.1** | tutorial |

(tidex6 `CSDD31Zm…` and `D1dCoBui…` carry a stale `Anchor.toml` saying 1.0.0 but their `Cargo.lock` is **1.1.2** → not vulnerable.)

**Exploitability of the 10:** `analysis/pattern_scan.py` downloads each repo@commit and searches **on-chain program code** for `Instruction { program_id: <…system_program…> }` (the only exploitable shape) → **0 hits**. The tidex6 programs use `invoke(&system_instruction::transfer(…))` (hard-coded id); the Axelar programs use Anchor's `transfer` helper and self-CPI `Instruction { program_id: crate::id() }`. All safe.

## 5. PoC / verification

| PoC | File | Result | Run |
|---|---|---|---|
| **Host validation PoC** (decisive for the mechanism) | `poc/host/` | `anchor-lang 1.0.0`: fake executable program **accepted** as `Program<System>` → VULNERABLE. `1.0.1`: accepted. `1.0.2` / `1.0.3`: **rejected** with `AnchorError InvalidProgramId (3008) "Program ID was not as expected"` | `ci-out/host-poc.txt` |
| **SBF + LiteSVM end-to-end PoC** ✅ | `poc/sbf/victim` (built at 1.0.1 and 1.0.2), `poc/sbf/noop` (hostile program that accepts any ix), `poc/litesvm/` | **1.0.1** → tx `OK`; inner CPI redirected to the attacker program (`Program J8tFbKk8… invoke [2]`, `victim: invoked 'system program' = J8tFbKk8…`); recipient **moved 0 lamports** → payment bypass. **1.0.2** → tx `ERR InstructionError(0, Custom(3008))` `InvalidProgramId … Left: J8tFbKk8… Right: 11111111111111111111111111111111` | `ci-out/litesvm-poc.txt` |
| **Deployed-version pinning** | `analysis/fetch_elf.py`, `classify_anchor.py`, `pin_programs.py`, `build_table.py` | anchor family from verified version-discriminating `.rodata` markers (validated against all crate versions 0.29→2.0.0-rc) | `analysis/version_table.json`, `analysis/elf-manifest.txt` |
| **Global verified-program sweep** | `analysis/verified_scan.py` | 655 scanned → 329 anchor → **10 on 1.0.0/1.0.1** | `ci-out/verified-programs-anchor.json` |
| **Exploit-pattern scan** | `analysis/pattern_scan.py` | **0** programs forward the passed system-program key | `ci-out/pattern-scan.json` |

**CI:** <https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39921938138> — conclusion **success**; artifacts `result-anchor-lang-pin` (host-poc, litesvm-poc, verified-programs-anchor.json, pattern-scan.json, victim-1.0.1.so, victim-1.0.2.so). SBF artifacts: `victim-1.0.1.so` sha256 `b3628d30…`, `victim-1.0.2.so` sha256 `e37a9f7d…`.

Marker methodology: the ELF `.rodata` strings `"A duplicate mutable account constraint was violated"`, `"Account is already migrated"`, `"Account must be migrated before exiting"` occur in **1.0.0–1.0.3 only**; the ≤0.32 markers `"IDL account must be empty in order to resize…"`, `"The program was compiled without idl instructions"`, `"interface-instructions"` occur in **0.30–0.32 only**. The 1.0.x markers are *identical across 1.0.0–1.0.3*, so the ELF alone cannot separate 1.0.0/1.0.1 from 1.0.2 — the exact version is resolved by **verified-build attestation / repo pin / deploy date** (this is why the host PoC exists as the mechanism oracle).

## 6. What an attacker can / cannot do

- **Cannot** exploit marginfi, raydium-clmm/cp-swap, or any named program: they are on 1.0.2+ (or not anchor).
- **Cannot** exploit the ten 1.0.0/1.0.1 verified programs: none forwards the system-program key (verified by source scan). Their system transfers use `system_instruction::*`, which hard-codes the real system-program id, so a substituted program account is simply ignored.
- **Could** exploit *any* future program that (a) is built with anchor-lang 1.0.0/1.0.1 **and** (b) hand-builds a CPI `Instruction` whose `program_id` is the caller-supplied `Program<'info, System>` key. Such a program would suffer payment bypass (the victim believes a system transfer/account-creation happened) and, with `invoke_signed`, PDA-signer abuse.
- **Cost:** zero capital (one transaction). **Blocker:** the vulnerable pattern does not exist in the live set.

## 7. Verdict & residual / latent risk

**E-U = $0.00** (high confidence for the named set). No live program on `anchor-lang` 1.0.0/1.0.1 is exploitable, and no named program is on an affected version at all.
**H-O = $0 · P = $0 · S ≈ $0** — the only "stuck" value found is tidex6's pool vaults: 4 pools, one with 18 historical leaves (all withdrawn), total vault balance **890,880 lamports ≈ $0.15** (rent dust). Nothing is bricked.
**Latent risk:** the advisory class remains live for *newly built* programs. The 1.0.0/1.0.1 window is 2026-04-02 → 2026-05-02; a program built in that window and never rebuilt is exposed **iff** it forwards the key.

## 8. Monitor / tripwires

| Trigger | Why |
|---|---|
| Any program whose ELF carries the **1.0.x markers** *and* whose last deploy is **before 2026-05-02** | candidate 1.0.0/1.0.1 build |
| The 10 verified program ids in §4 (esp. immutable `2qEmhLEn…`) if they are ever re-verified/upgraded | only the frozen tidex6 program cannot be patched |
| New GitHub/OSV hits for `anchor-lang 1.0.0/1.0.1` in a program's `Cargo.lock` | new builds on the vulnerable release |
| Any program using a raw `Instruction { program_id: <passed system_program>.key() }` | the sole exploitable shape |

## 9. Methodology & sources; caveats

**Sources:** GitHub advisory API (`GHSA-c6rc-8jpp-2fgc`), OSV (`RUSTSEC-2026-0144`), crates.io version metadata, the `anchor-lang` crate sources 0.29.0→2.0.0-rc.2 (`anchor-syn`, `anchor-attribute-program`, `anchor-derive-accounts`), OtterSec `verify.osec.io` (verified-build attestations + the 655-program list), Solana mainnet RPC, and the repos' `Anchor.toml`/`Cargo.lock` history.
**Caveats:** (1) the ELF string markers cannot separate 1.0.0/1.0.1 from 1.0.2 — exact-version claims rest on verified-build attestations or repo pins + deploy dates; (2) the global sweep covers only *OtterSec-verified* programs (655) — a non-verified program on 1.0.0/1.0.1 would not be caught (there is no global on-chain program registry); (3) point-in-time 2026-10-23.

*Files: `summary.json`, `analysis/` (scripts + `version_table.json` + `pinned_raw.json` + `elf-manifest.txt` + `child1/` + `child2/`), `poc/` (host + sbf + litesvm), `ci/run.sh`, `ci-out/`.*
