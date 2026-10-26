# Archer Exchange (`Archer8kg…`) — caller-supplied-account substitution in a fresh matching engine

**Date:** 2026-10-25 · **Chain:** Solana mainnet-beta · **Status:** read-only; `simulateTransaction`
only; **no transaction was signed or sent**; no keys used; all endpoints keyless/public.

**Finding:** ZH4-PASS7 TIER 3 LOW #11 — *"Archer Exchange, Solana, $0.66M, fresh (~3d), unaudited
matching engine with caller-supplied accounts."*

**Verdict: CLOSED — $0 external-unprivileged (E-U).** Every value path is gated by explicit
maker / admin / PDA / token-owner checks. 17 substitution simulations were run (with two positive
controls); every substitution is rejected with a specific, named error.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---|---|---|
| Archer Exchange `Archer8kgiavM61GyusMzaaS2ft5sALtNsD1HxkUPMhy` | **$0** | `MakerWithdrawFunds`/`MakerDepositFunds`/`CloseMakerBook`/`ClearBook`/`UpdateBookLimit`/`UpdateBookRescale` all require the book's maker (`502 UnauthorizedMaker`, `500 InvalidMakerBook`); admin ops require the global authority / market admin (`206 Unauthorized`); the swap's input token account is bound to the signer (`303 InvalidTokenAccount`); ArcherAccount ops require a real ArcherAccount (`200`/`1000`) | **P**: upgrade authority `ELGWUVJD…` (off-curve). Fresh + unaudited ⇒ keep re-reading. |
| **Stealable-if-open ceiling** (Σ maker *free* balances, all 292 books) | **$451,381.08** | this is what *would* be at risk if the maker↔book binding were missing — it is present | — |
| **Total live market vault value** (all 102 markets) | **$646,128.25** | matches DefiLlama `archer-exchange` ≈ $0.66M | — |

**Total live extractable now: $0.00** — confidence **high**.

---

## 2. The mechanism / target

Archer is a **maker-book matching engine**: market makers deposit base/quote into shared market
vaults and publish resting levels in per-`(market, maker)` `MakerBook` PDAs; takers `Swap` against
the aggregated books. Value therefore lives in two places:

1. the **market vaults** (one base + one quote ATA per market, authority = the market PDA), and
2. each maker's **claim** on those vaults, recorded in `MakerBook.{base_free, quote_free, *locked}`.

The archetypal Solana drain here is a **caller-supplied account substitution**: pass *your own*
signer but *someone else's* `makerBookAccount` (with a large `quote_free`) and withdraw their claim
from the shared vault to your own ATA. The audit question is exactly: does the program bind the
passed `makerBookAccount` to the passed `makerAccount` and to the market?

**Program facts (measured, not assumed).**
* `Archer8kgiavM61GyusMzaaS2ft5sALtNsD1HxkUPMhy`; programdata `6iDEEhGGMoj9J2h6re66g14T3fvAKRT7tm4VXGPP9HKY`;
  ELF **379 304 B**, sha256 `5c5ff975a6f24bdffa5d54a82242e937e9710680219bc4e0f6dd9a0694b0a1d5`;
  deployed slot **460 513 991** (~2026-10-22); upgrade authority `ELGWUVJD6NBNLyJ5Xv98PzoSg9Wh2Y8Bwep9JZgm9nuo` (off-curve).
* Custom (non-Anchor) framework: dispatch is a **1-byte tag** (`ArcherInstruction`, `repr(u8)`),
  e.g. `MakerWithdrawFunds = 12`, `Swap = 15`, `CollectProtocolFee = 14`, `UpdateRegistry = 38`.
  This is why the ELF contains no `global:` strings and no Anchor discriminator table.
* The program embeds a `SECURITY.TXT V1` block pointing at `github.com/ballista-tech/archer-sdk`
  (public IDL + account layouts + quoting math; source not public) and a bug bounty (up to $20k).
* Account discriminators: `ACHRMKT1` (Market), `ACHRMKR1` (MakerBook).
* PDAs: `market = ["market", market_id]`, `maker_book = ["maker", market, maker]`,
  `maker_registry = ["maker_registry", market]`, `archer_account = ["archer-account", owner, platform]`.

---

## 3. Live-state assessment (read-only, 2026-10-25)

| Item | Value |
|---|---|
| Live markets (`ACHRMKT1`) | **102** (74 Active, 27 Paused, 1 Closed) |
| Live maker books (`ACHRMKR1`) | **292** (all `status = Active`; 125 MM-kind, 167 LO-kind) |
| **ArcherAccount-owned books** (`maker_is_archer_account = 1`) | **0** — no ArcherAccounts in use |
| Total market-vault value (base+quote ATAs, DefiLlama prices) | **$646,128.25** |
| Σ maker **free** balances (withdrawable) | **$451,381.08** |
| Largest single book free balance | `939Pgm7J…` (maker `GLKCuotK…`, market `BZDUzrgR…`) ≈ **$80,163.80** |
| Archer treasury (hard-coded `Hfj4HDxLqdj4k9FB3eZeURf4sZtu3w9aJMRfctmXR66P`) | checked as a literal in the ELF |
| Global authority (`AuthYRbdcyksthcB1AM8ZKB3CidzChURkLzsGN8pYUmw`) | holds all registry/market-status power |

The vaults hold ≈$648k, of which ≈$455k is maker free collateral. **$0** of that is
unprivileged-extractable via account substitution (see §4).

---

## 4. What an attacker can / cannot do — substitution battery

All rows are `simulateTransaction` (`sigVerify:false`, `replaceRecentBlockhash:true`).
Full JSON: `ci-out/archer_results.json` and `analysis/arch_battery*_results.json`.

| # | Substitution | Result | Meaning |
|---|---|---|---|
| **A3** | **CONTROL** `MakerWithdrawFunds`: victim signs victim's own book | **SUCCESS** | positive control — the instruction works |
| A1 | `MakerWithdrawFunds`: attacker signs, **victim's maker book** | **`502 UnauthorizedMaker`** | maker↔book binding enforced |
| A2 | `MakerWithdrawFunds`: victim as maker, attacker as authority + attacker ATAs | **`303 InvalidTokenAccount`** | authority + destination binding enforced |
| G1 | `MakerDepositFunds`: attacker maker + victim's book | **`502 UnauthorizedMaker`** | deposit path also bound |
| H1 | `CloseMakerBook`: attacker maker + victim's book | **`502 UnauthorizedMaker`** | cannot close/refund someone else's book |
| B2 | `ClearBook`: attacker signer + victim's book | **`502 UnauthorizedMaker`** | cannot zero someone else's levels |
| B3 | `UpdateBookRescale`: attacker signer | **`502 UnauthorizedMaker`** | vault-only path gated (doc says `529 InvalidMakerVault`) |
| F1 | `UpdateBookLimit`: attacker maker + victim's **LO** book | **`502 UnauthorizedMaker`** | LO write path bound |
| I1 | `MakerWithdrawFunds` with a book from a **different market** | **`500 InvalidMakerBook`** | book↔market binding enforced |
| **E3** | **CONTROL** `Swap` with the victim as taker | `507 NoMatchingLiquidity` | control reaches the matching engine (past all auth) |
| E2 | `Swap` with attacker as taker but the **victim's quote ATA** as input | **`303 InvalidTokenAccount`** | input token account bound to the signer |
| C1 | `CollectProtocolFee` with attacker as market admin | **`206 Unauthorized`** | admin gate |
| C2 | `ChangeMarketStatus` with attacker as global authority | **`206 Unauthorized`** | global-authority gate |
| C3 | `UpdateRegistry` with attacker as global authority | **`206 Unauthorized`** | global-authority gate |
| C4 | `ToggleBookSuspension` with attacker as market admin | **`206 Unauthorized`** | market-admin gate |
| D1 | `ArcherAccountWithdraw` with source = a victim ATA | **`200 InvalidAccount`** | ArcherAccount PDA/owner bound |
| D2 | `SwapFromArcherAccount` with a substituted ArcherAccount | **`1000 InvalidArcherAccount`** | ArcherAccount bound |

**Positive controls exist** (A3 ⇒ SUCCESS; E3 ⇒ past-auth) so the rejections are not an
"everything reverts" artefact. The `MakerBook`'s own error surface (500/502/515/516/517/529/530)
and the token-account errors (300/303/1002) are all exercised, i.e. the program's validation is
real and reaches these paths.

### 4.1 Independent verification

A second, separately-written verifier (own enumeration + own simulation code) reproduced the key pair
of results: **ATTACK** (fresh signer + victim's `MakerBook`) ⇒ `Custom 502 UnauthorizedMaker`, and
**CONTROL** (victim signs their own book) ⇒ `err: null` (SUCCESS). See `analysis/verify/VERIFY.md`.

**No path found** by which an unprivileged signer can move another maker's collateral, mint without
deposit, or withdraw from a vault they do not own.

---

## 5. PoC

* `poc/archer_poc.py` — self-contained (only `solders` + stdlib). Enumerates markets/books, prices
  the vaults, ranks the free-balance ceiling, then runs the 17-case battery.
* `poc/solcore.py` — keyless RPC + PDA + `simulateTransaction` toolkit.
* Run: `python3 poc/archer_poc.py` → `ci-out/archer_results.json`.
* CI: `ci/run.sh` (GitHub Actions via `ci/ci-run.sh archer-exchange`); run URLs in `ci-log.txt` /
  `ci-artifacts/`.

Expected (last local run, slot 461454122): 1 control SUCCESS + 16 rejections, as tabulated.

---

## 6. Verdict, residual and latent risk

* **E-U: $0.00** (high confidence). All caller-supplied-account substitutions tested are rejected.
* **H-O:** $0 additional — makers can already withdraw their own free balances (A3 control proves it);
  that is normal self-service, not an extraction.
* **P:** upgrade authority `ELGWUVJD6NBNLyJ5Xv98PzoSg9Wh2Y8Bwep9JZgm9nuo`; global authority
  `AuthYRbdcyk…`. Both privileged.
* **S:** none observed.
* **Latent risk / monitor:** the program is **fresh (~3 days) and unaudited** — a substitution path
  in a code path not reachable from the current live state (e.g. once an **ArcherAccount** maker
  exists: `maker_is_archer_account = 1`, currently **0/292**) could differ, because the
  maker-signer rule becomes "PDA + owner/delegate". Tripwires: programdata hash change
  (`5c5ff975a6f24bdffa…`), first `maker_is_archer_account = 1` book, a new market/vault, or any
  `MakerRegistry` seating change.

---

## 7. Methodology, sources, caveats, files

**Method.** (1) Dump the ELF from the upgradeable loader and hash it; (2) recover the instruction
surface from the project's own public SDK (`github.com/ballista-tech/archer-sdk` → `idl/archer_v1.json`,
`src/onchain/instruction.rs`, `src/onchain/params.rs`) cross-checked against ELF source-map strings
(`program/src/processor/…`) and custom error strings; (3) enumerate all live markets/books by
account discriminator; (4) price the vaults; (5) build and simulate each instruction with substituted
accounts, with positive controls; (6) map error codes.

**Caveats / limitations.**
* The **program source is not public**; account *constraints* are inferred from the SDK's
  documentation + the observed error codes. The security conclusion rests on the simulations, not on
  the docs.
* `sigVerify:false` lets any pubkey be marked a signer for simulation. The A2/E2/D1 results (303/200)
  and the A3 success show the program genuinely enforces owner/signer bindings, so the controls are
  not artefacts.
* The `Swap` matching engine itself (fill math, pro-rata, invariants 900–906) was **not** exhaustively
  fuzzed — only its account-authorisation surface was tested. E3 stopped at `507 NoMatchingLiquidity`
  (no resting ask matched the synthetic order), so a *successful* swap control was not obtained; the
  input-account binding (E2) is nevertheless proven by 303.
* Point-in-time 2026-10-25; re-read all state before acting. Nothing here is an instruction to transact.

**Files.** `README.md` · `summary.json` · `analysis/` (ELF + sha256, source paths, error strings,
live markets/books, free-balance ranking, battery results) · `poc/` · `ci/` · `ci-out/`.

*Prepared 2026-10-25 · read-only · no tx signed or sent.*
