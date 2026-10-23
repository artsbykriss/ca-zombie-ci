# Cardboard Trade (Solana perp DEX) — program ELF reverse-engineering & margin/withdraw auth test (ZH4-PASS5 Tier-3 #2)

**Date:** 2026-10-23 · **Chain:** Solana mainnet-beta · **Status:** read-only; simulations only; no transactions signed/sent
**Programs:** exchange `J7vt5nGQd7YggFTV6GPwmWycfxzLjnHoGX6GRUKo9M7A`, oracle `5g3PW7gtfnM3QYsGPaPGLiCxtous4arSugCct9KPHHWo`
**Reference slot:** 460,345,410 (keeper tx) · ELF deploy slots: exchange 459,756,763 / oracle 459,759,659

---

## 1. TL;DR

| Target | Live custodied | Unprivileged extractable | Why closed | Confidence |
|---|---|---|---|---|
| **Cardboard Trade** exchange + oracle (Solana) | **1,037,944.75 USDC** (vault `DSnqZ6ctTToaCMoCwULqdfkXGTTXfQ9oiv3qH98NR4hv`) | **$0** | The exchange's price-settle instruction (tag `0x1f`) is **caller-gated to the oracle program** (direct call → `ORCLSKIP`, no settle); the oracle push (tag `0x07`) is permissionless but **validates every price-source account** against a hardcoded program-id allowlist **and specific account keys** (bad source → `ORCLSKIP`), and its instruction data is only 2 bytes (no price can be supplied by the caller). No unprivileged path to an attacker-chosen settlement price. | **high** |

**Headline: external-unprivileged extractable = $0 (high confidence).** The pass-5 hypothesis ("does the `071f` push
enforce `oracle-authority.is_signer()`?") resolves as: the push is **deliberately permissionless** (a cranking
function) — but that is *not* exploitable, because the price is assembled from **owner-allowlisted** source accounts,
not from caller input.

**Residual (bounded, not E-U):** a permissionless push with *all* sources invalid still refreshes the feed from the
registry's **last-known prices** (stale, not attacker-chosen). Un-reversed: the `oracle_learning.rs` aggregation and the
exact sysvar caller-read in the exchange. No top-level user instruction (deposit `0x05` / withdraw / margin) was observed
in 200 recent exchange txs, so those entry points were not exercised.

---

## 2. What was delivered

1. **Program ELF dump** (upgradeable-loader `ProgramData`) for both programs:
   - `analysis/cardboard_exchange.so` — 199,056 B, `e_machine=0x107` (SBF), stripped, entrypoint `0x1fb40`.
   - `analysis/cardboard_oracle.so` — 101,992 B, SBF, stripped.
   - Upgrade authority (both): `9XuzmXiPydjjvBNcSabfF8HC8hgzjTW3wdMNSfXPSTdf`.
2. **Disassembly** with the `sbpf` SBF disassembler: `analysis/exchange.asm` (27,000 lines), `analysis/oracle.asm` (13,569 lines).
3. **Instruction-surface map** from live transactions + disassembly (tags, account layouts, PDA seeds).
4. **Auth tests** via `simulateTransaction` (fork-sim against live state, `sigVerify=false`) and disassembly of the
   caller/signer checks.

---

## 3. Build fingerprint (from ELF `.rodata` strings)

- `pinocchio-0.11.2` entrypoint (`…/pinocchio-0.11.2/src/entrypoint/mod.rs`), `solana-account-view-2.1.0`,
  `solana-address-2.9.0`, `five8_const-1.0.0`.
- Build path `/builds/joebuild/cardboardtrade/…` — **stripped**, custom **1-byte-tag** dispatch.
- Protocol source files visible in strings: `crates/protocol/src/{state,math,payout,referral,oracle,oracle_learning}.rs`,
  `programs/exchange/src/{events,metadata}.rs`, `programs/oracle/src/lib.rs`, `crates/oracle-sources/src/lib.rs`.
- Syscalls: exchange `{sol_try_find_program_address, sol_get_sysvar, sol_invoke_signed_c, sol_log_64_, sol_panic_, sol_memcpy_, sol_memset_}`;
  oracle adds `sol_memcmp_`.
- PDA seed ASCII constants (8-byte, from `lddw` immediates): exchange `CTCFG003/005`, `CTCPOL003/004`, `CTMKT005`;
  oracle `prices`, `config`, `weights`, `oracle-authority`, `oracle`, `market`.

---

## 4. Live state (read-only)

- **Config PDA** `HrW16vpyqURMvR4CeRf1QYMucEGKusHuzPVz1V3h7R7B` (owner = exchange, 347 B, discriminator `CTCFG005`).
  Decoded pubkey fields include admin `5CRhPBLG…`, a second authority `AsVbkLq1…`, USDC mint
  `EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v`, **USDC vault `DSnqZ6ctTToaCMoCwULqdfkXGTTXfQ9oiv3qH98NR4hv`**,
  reward mint `9Dmbnc5E…`, reward vault `BGffX12Z…` (full decode in `analysis/recon.json`).
- **USDC vault** `DSnqZ6ct…` holds **1,037,944.751058 USDC ≈ $1.0374M** (DefiLlama TVL $1,081,481.93 includes the reward token).
- The config owns **1,355** token accounts (per-trader margin/deposit PDAs); only **3** are non-zero.
- Keeper `Ef1YAVrvuUfjULKGEN2eqUSHwYTSUx2aE3VjoBefxVVb` is the *fee payer* of every observed push; **no account in the
  oracle instruction list is a signer**.

---

## 5. Instruction surface & auth (evidence)

**Instruction surface (from live txs + disassembly):**

| Program | Where | Tag | Meaning |
|---|---|---|---|
| oracle | top-level | `0x07` (`071f`, base58 `YS`) | push/update prices — **permissionless**; 3× per keeper tx |
| exchange | inner CPI (from oracle) | `0x1f` | settle/apply price — data `[0x1f][u16 market][u64 price][u64 price][u64 ts][u64 seq]` |
| exchange | inner CPI (self) | `0x43` (`CTEVNT`) | event emit, 140 B |

The exchange also has a full 1-byte tag dispatch over `0x00..0x2d` (incl. `0x05` deposit) at `exchange.asm:20572–20605`,
but **no top-level user invocation was observed in 200 recent exchange signatures** — every live exchange call is an
inner `0x1f`/`CTEVNT` from the oracle. Independent tag census: `analysis/tag_census.json`.

**Gate (A) — exchange `0x1f` caller check.** A direct top-level call with the *exact* oracle-CPI account list and the
*exact* 35-byte payload returns `err: None` but logs `ORCLSKIP` (`0x50494b534c43524f`, `0x1, 0x1f, 0x0, 0x3`) and
consumes only **1,361 CU** — a no-op. The gate is `fn_05d0` (`exchange.asm:230`) comparing the caller's 32-byte program
id to the hardcoded oracle id (returns `0x1a`); the settle handler (`exchange.asm:19662`, `jmp_22dc8`) requires it.
Bypass probes (append/prepend the oracle program or PDAs, prepend a real `071f` push, sysvar-first) all bail
(`analysis/oracle-re/sim_gate_probe.py`).

**Gate (B) — oracle source validation.** `fn_8480` (`oracle.asm:4733`, loop `:5579`) validates each source group's
**owner program id** against a hardcoded allowlist (`BiSoNHVp…`, `TessVdML…`, `goonuddt…`, `ojh19oja…`, `AQU1FRd7…`,
`ALPHAQmeA…`, `dijkbkCA…`, `fastC7gqs…`) **and specific account keys** (`DmocjvFX…`, `8mZVRgrr…`); a non-matching
source is **skipped** with `ORCLSKIP` rather than trusted. The oracle instruction data is only 2 bytes, so no price can
be injected by the caller. Source price accounts are written by **authorised updater signers** of the source programs
(`dijk←FTp1…`, `fast←AK9U…`, `BiSo←7Rrq…`), not permissionlessly.

**Decisive simulations (`poc/cardboard_auth_test.py`, `simulateTransaction sigVerify=false`):**

| Test | Result |
|---|---|
| Direct exchange settle `0x1f` (attacker caller) | `err None`, `ORCLSKIP`, **1,361 CU** — **no settle** ✅ |
| Oracle push `071f`, fresh real accounts (control) | `err None`, **no** `ORCLSKIP`, 18,595 CU |
| Oracle push `071f`, DEX source → SystemProgram | `err None`, **`ORCLSKIP`** (code `0xa`) — source rejected ✅ |

**Verdict: no unprivileged path to an attacker-chosen settlement price.** The ~$1.04M USDC vault is not reachable this
way.

---

## 6. Verdict & residual risk

**E-U = $0 (high confidence).** Both gates hold: the exchange settle is caller-gated to the oracle, and the oracle's
price inputs are owner-allowlisted and signer-updated. Independent verification: the harness reproduces both
`ORCLSKIP` outcomes and the clean control on a fresh reference tx.

**Residual / latent (not E-U):**
- A push with **all** sources invalid still writes the feed and settles from the registry's **last-known** prices
  (`analysis/oracle-re/all_sources_invalid.txt`) — a *stale-refresh* primitive, bounded by the last valid price, not an
  arbitrary-price primitive. Worth monitoring if source availability can be suppressed.
- The exchange's `oracle_learning.rs` deviation/TWAP aggregation and the exact sysvar caller-read were not fully
  reversed (the gate is empirically robust).
- No top-level user instruction (deposit/withdraw/margin) was observed live ⇒ those auth paths were **not exercised**
  (a real gap if the protocol later exposes them to the public).

**Blockers:** Solana BPF is stripped with no published IDL/source (upstream repo empty); analysis is disassembly-only.
Public RPC `https://api.mainnet-beta.solana.com`.

---

## 7. Methodology & limitations

- ELF via `getAccountInfo` on the `ProgramData` account (45-byte header stripped); disassembly via `sbpf disassemble`.
- Simulations via `python3` + `solders` `simulateTransaction` (`sigVerify=false`, `replaceRecentBlockhash=true`) against
  live mainnet state — a fork-sim, no transaction sent.
- No source or IDL is published (upstream repo empty); everything below is from disassembly + on-chain state.
- Public RPC `https://api.mainnet-beta.solana.com`.

**Files:** `analysis/cardboard_exchange.so`, `analysis/cardboard_oracle.so`, `analysis/exchange.asm`,
`analysis/oracle.asm`, `analysis/tx1.json`, `analysis/owners.py`, `analysis/vault.py`, `analysis/recon.json`,
`analysis/tag_census.py`/`tag_census.json`, `analysis/oracle_source_test.py`/`source_validation.json`,
`analysis/oracle-re/` (full disassembly excerpts + swap matrix + gate probes), `analysis/oracle-re.json`,
`poc/cardboard_auth_test.py`, `ci/run.sh`, `ci-out/cardboard-auth.json`, `ci-out/oracle-re.json`, `summary.json`.
