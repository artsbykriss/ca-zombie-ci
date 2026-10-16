# Z3-H11 · Rain white-label card fleet (Solana) — residual extractability after the Aug-28-2026 fleet drain

**Date:** 2026-10-16 · **Chain:** Solana mainnet · **Status:** read-only research; no transactions signed or
sent; all exploit replay runs in a local LiteSVM (CI). No secrets in this folder.

**Question:** the Aug 28–30 2026 incident drained ~$1.1M (Avici $500,859.22 / 1,685 users; Tria
$431,945 / 636 users) through a version-drift bug in Rain's white-label card-collateral program. Rain says
every program on the outdated build was upgraded and no further unauthorized activity occurred — but the
sibling-deployment inventory was never published. **Is any live tenant program still on a drainable
(pre-patch) build, and how much value sits in drainable state today?**

**Answer: no live extractable path was found. $0 E-U** (high confidence, with a stated coverage limit).
The historical attack path requires a *multi-admin* `Collateral` account; **zero such accounts exist in
the fleet today** — every collateral has been migrated to the `SingleSignerCollateral` account model, and
every live build either rejects that model in the vulnerable instruction or fails to deserialize it. The
remaining live value (~$60k USDC/USDT in vaults) is ordinary user balance behind the current builds, not
attacker-extractable.

---

## 1. TL;DR

| Target | Live extractable (fresh unprivileged attacker) | Why closed | Latent risk |
|---|---|---|---|
| 4 incident programs (`26DkA98…`, `CWgkFB7n…`, `3zVB27Ga…`, `8r2jms1v…`) — patched 2026-08-28 19:18–20:26 UTC | **$0** | all on post-incident builds; account model migrated | attacker's admin entry persists in account data (inert); ~$67 vault dust |
| 62 other programs under current authority `7MoSDo66…` (299,935 collateral accounts) | **$0** | post-incident builds (2026-08-28 → 10-13) + zero multi-admin collaterals | ~$60k user vault balances — protocol risk if a *new* bug appears |
| 11 programs under old authority `EfQ2zvc1…` (pre-incident builds 796,952–803,336 B ≈ the vulnerable size class) | **$0** | **zero accounts of any kind** — dormant deployments | re-arm if re-used: a funded *multi-admin* collateral on a pre-patch build would be drainable (see §6) |
| `C4y8t56f…` (V1 build, 2026-08-21, never upgraded, 1 collateral) | **$0–$2** (vault: 2.000000 USDC) | build rejects the single-signer account model at the mode gate | $2 |

**Total live extractable by a fresh unprivileged attacker (E-U): $0** (high confidence within the
enumerated fleet). Fleet-wide drainable-state surface: **0 multi-admin `Collateral` accounts** (the type
the exploit requires) vs **299,935 `SingleSignerCollateral` accounts** (the type that every live build
either rejects in `SubmitSignatures` or cannot deserialize).

---

## 2. The fleet (enumerated on-chain)

Method: every upgradeable program's ProgramData account is a 45-byte-header account owned by
`BPFLoaderUpgradeab1e…`. `getProgramAccounts` with a `memcmp` filter on the upgrade-authority field
(offset 13) enumerates **every program controlled by an authority**; `dataSize` filters enumerate
**every program chain-wide with a given code size**. Reads at slot **457,438,049** (2026-10-16 ~00:30 UTC)
unless noted.

### 2.1 Current authority `7MoSDo66QknjsyE8yX9VnsrbGj4cQTDYVjo2JHLt5RSL` — 66 programs
| build (file bytes) | code size | programs | deployed | single-signer collaterals |
|---|---|---|---|---|
| V1 | 1,005,560 | 1 (`C4y8t56f…`) | 2026-08-21 19:30 | 1 |
| V2 | 1,019,808 | 25 (incl. all 4 incident programs) | 2026-08-28 20:22 → 09-03 | 202,438 |
| V3 | 1,005,680 | 29 | 2026-09-03 23:34 → 09-04 00:28 | 91,097 |
| V4 | 1,019,688 | 9 | 2026-09-09 → 10-13 | 6,395 |
| V5 | 938,320 | 1 (`yYC31xu…`) | 2026-10-13 13:52 | 0 |
| other | 1,642,808 | 1 (`3zB9G37…`) | 2026-09-15 | 8 |

The four incident programs' last deploys (all the remediation rollout):
`26DkA98…` slot 442,423,693 = 2026-08-28 20:22:02 · `CWgkFB7n…` 442,423,749 = 20:22:21 ·
`3zVB27Ga…` 442,424,521 · `8r2jms1v…` 442,424,530. Upgrade authority rotated to `7MoSDo66…`.

### 2.2 Old authority `EfQ2zvc1xQfscTxCPb1om4s1CetncrfVFSt5zwiUR99J` — 11 programs (still live)
This is the authority that signed the emergency patch txs on Aug 28 (verified in those txs). It still
controls 11 programs deployed 2025-12-11 → 2026-08-21, code sizes **796,952 / 801,160 / 803,336 / 637,120**,
all of the same codebase (full Rain collateral instruction set + EIP-712 strings), **all with zero
accounts of any kind** (no collaterals, no coordinator, nothing):

`5TvWLcFu…` (803,336, 2026-08-20) · `29NTjsSp…` (801,160, 2026-04-10) · `5p1sVfC3…` (801,160, 2026-07-07) ·
`8gBkN55q…` (796,952, 2026-03-12) · `4XBSKri9…` (801,160, 2026-05-04) · `7mXa6sVk…` (801,160, 2026-06-11) ·
`Upp8eD4r…` (803,336, 2026-08-21) · `DWAgJZk5…` (796,952, 2026-03-06) · `J2BjAA5m…` (801,160, 2026-05-14) ·
`F3H9wrxd…` (801,160, 2026-05-08) · `GgHpMPSb…` (637,120, 2025-12-11).

### 2.3 The pre-patch build size, from the emergency patch transactions themselves
The Aug-28 patch txs reveal the pre-patch build size via the loader's rent math
(`lamports = (128 + account_size) × 6960`):
- `CWgkFB7n…` patch 19:18:37 UTC (7 s after the last observed withdrawal): buffer `8ktBtH2W…`
  (801,205 B) → **patched code = 801,168 B**; the ProgramData account did **not** grow ⇒ pre-patch
  code **≤ 801,280 B**.
- `26DkA98…` patch 19:41:08 UTC: buffer `9sfeXCvK…` → same 801,168 B code; no growth ⇒ same bound.
- Second upgrades 20:22:02 / 20:22:21: buffers `AE5KBNmQ…` / `3UzRtR3s…` (1,019,733 B) — the current
  V2-family code.

⇒ the vulnerable build belongs to the ~801 KB class (as do the 11 dormant old-authority programs at
801,160 B) — **not** the 1.0 MB class of the current fleet. The newer 1.0 MB lineage was already in use
elsewhere in the fleet ("a small number of programs were still running an outdated version").

---

## 3. The bug and the account model (reconstructed from the exploit transactions)

Recovered from the on-chain exploit txs (attacker `FVNFzqAny8spWdPmYw6RQ9TkYa29ueFFiqCFD1gQnCEj`):

- **Instruction sequence per victim:** `SubmitSignatures` → `AddCollateralAdmin` → `SubmitSignatures` →
  `WithdrawCollateralAsset` (Anchor discriminators recovered: `submit_signatures` = `c2051298f590864d`,
  `add_collateral_admin` = `0871bd5f3c38533d`, `withdraw_collateral_asset` = `2f6c1645ee9fa7d3`).
- **Signature proof:** each sensitive action is authorized by Solana **ed25519 precompile instructions**
  whose payload the program re-reads from the instructions sysvar. In every exploit tx **two ed25519
  instructions are present and the second one's payload offsets point back into the first instruction**
  (`sig_ix=0, pk_ix=0, msg_ix=0` ⇒ all three fields read from instruction #0), so **one attacker-controlled
  signature verified twice** and stood in for the two independent authorizations the program expected
  (matches Blockaid's root-cause description; the raw txs confirm it byte-for-byte).
- **Authorization messages are EIP-712 typed data** (recovered type strings: `AddAdmin(address
  admin,uint256 nonce)`, `Withdraw(address user,address asset,uint256 amount,address recipient,uint256
  nonce)`, `EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32
  salt)`, …). The attacker supplied their own ed25519 keypair; no victim signature was used.
- **Account model (decisive):** the exploit operated on a **multi-admin `Collateral`** account
  (Anchor discriminator `7b82ea3ffff0ff5c`) — the account type that carries the admin list the
  `AddCollateralAdmin` flow needs. The 177-byte accounts visible today (disc `132d631dc432e475`) are
  **`SingleSignerCollateral`** accounts (disc verified by Anchor name hash). Both types are present in the
  program's dispatch/state code.

---

## 4. Live-state assessment

- **Zero multi-admin `Collateral` accounts** (`7b82ea3ffff0ff5c`) exist across all 66 + 11 programs
  (verified with per-program `getProgramAccounts` + discriminator filters, slot 457,438,049+). Every
  collateral has been migrated to the `SingleSignerCollateral` model
  (`MigrateToSingleSignerCollateral` is in the instruction set).
- **299,935 `SingleSignerCollateral` accounts** across 38 programs (28 programs have none). The
  post-incident accounts retain migration residue — e.g. the attacker's pubkey remains stored at offset
  139 of `Ao7nbAbk2aHwbEj2zfrQ7tpMBPdJjZjSzyiWVbaA1Bx8` (26DkA98) — harmless while the vulnerable
  instruction is unreachable.
- **Vaults:** vault authority = PDA `[b"CollateralAuthority", collateral]` (verified against the exploit's
  `2JZogpfp…`); vault token account = ATA(vault_authority, mint) (verified: `Fn8nf3c7…` =
  ATA(`2JZogpfp…`, USDT)). Residual dust in incident-program vaults: `Fn8nf3c7…` = 6.783 USDT,
  `H7ANUpwV…` = 60.225 USDT (both with now-closed authority PDAs; recoverable only through the program's
  own withdrawal path, not by an attacker).
- `C4y8t56f…` (V1, never upgraded): 1 single-signer collateral (`E3chFpqh…`), vault 2.000000 USDC.

---

## 5. Live funds (vault balances)

Fleet-wide scan of every single-signer collateral's USDC/USDT vault ATAs
(`analysis/fleet_fund_scan.json`, in progress at report time — values below are the settled subset):

| | amount |
|---|---|
| USDC in vaults | **$11,167.74** |
| USDT in vaults | **$45,228.67** |
| **total (partial, 51/66 programs)** | **≈$56,396** |

These are **user card balances** behind the current builds — withdrawable by their owners through the
program (`H-O`), not extractable by an attacker. The four incident programs' own vaults hold dust only.

---

## 6. What an attacker can / cannot do today (fresh unprivileged standard)

**Cannot:** reach the historical drain path. Replaying the exact on-chain exploit transactions in LiteSVM
against every live build (see §7) shows the path dies at the first instruction:

| build | `SubmitSignatures` result on the migrated collateral |
|---|---|
| V1 (Aug 21) | `MultiAdminOnly` (6023) — "Instruction only available for multi-admin collateral" |
| V2 (Aug 28, the incident patch) | `MultiAdminOnly` (6023) |
| V3 (Sep 3) / V4 (Sep 9) / V5 (Oct 13) | `MultiAdminOnly` (6023) |
| pre-incident 801,160 B build | `AccountDiscriminatorMismatch` (3002) — it requires the *multi-admin* account type and cannot deserialize the migrated accounts |

Every subsequent step (`add`, `submit2`, `withdraw`) fails as a consequence. **The vulnerable
instruction path requires a multi-admin `Collateral` account; none exists.**

**Could:** create a *new* multi-admin collateral via `CreateCollateral` — but an attacker-created
collateral holds only the attacker's own funds (no victim funds can be attributed to it). The 11 dormant
old-authority programs are pre-incident builds with zero accounts: **if any of them is ever re-used for a
live card program without a rebuild, the first funded multi-admin collateral would be drainable with the
same public recipe** — that is the residual Z3-H11 scenario, and it is empty today.

---

## 7. PoC / verification (LiteSVM differential replay)

`poc/` (Rust + LiteSVM 0.18 with the ed25519 precompile) replays the **exact historical exploit
transactions** (fetched as on-chain data) against each build, loaded at the incident program's address with
the compiled-in `declare_id!` bytes patched (both the rodata const and the inline immediates), and the real
account states:

1. `submit1` (2 ed25519 ixs with the reused-signature pattern + `SubmitSignatures`),
2. `add` (`AddCollateralAdmin`),
3. `submit2` (second `SubmitSignatures`),
4. `withdraw` (`WithdrawCollateralAsset`).

Result matrix (full logs in `ci-out/litesvm_results.json`): all six builds stop at step 1; the five live
builds with `MultiAdminOnly` (the single-signer gate) and the pre-incident build with
`AccountDiscriminatorMismatch` (it expects the multi-admin type). No build accepted the reused-signature
proof, because none reached the signature logic — the account model closes the path before it.

Files: `poc/src/main.rs`, `poc/Cargo.toml`, `poc/data/` (6 ELFs + account/tx JSON), `ci/run.sh`.

---

## 8. Verdict, residual risk, blockers, coverage limit

- **Verdict:** MEDIUM → **$0 live E-U**. The vendor-attested remediation is corroborated on-chain from
  three independent directions: (a) all four incident programs and the whole current-authority fleet carry
  post-incident builds (last-deploy slots); (b) the vulnerable build class survives only on **dormant,
  empty** programs under the old authority; (c) **the account type the exploit requires (multi-admin
  `Collateral`) has been fully migrated away — 0 instances remain** — and every live build either rejects
  the replacement type at the mode gate or at deserialization.
- **Residual/latent:** (a) 11 dormant pre-incident programs — re-arm risk on re-use (see §6); (b) the
  attacker's admin entry persists in migrated account data (inert); (c) ~$60k of user vault balances
  behind current builds — a future bug in those builds would be fleet-wide (structural risk).
- **Blockers to a stronger claim:** the exact pre-patch build binary is not recoverable from chain state
  (overwritten by the patches); the replay therefore uses the closest surviving pre-incident build
  (801,160 B) plus the mode-gate evidence. The migrated accounts also cannot be restored to their
  multi-admin form, so the signature-check fix itself could not be exercised end-to-end — but that is
  immaterial because the path is unreachable by account type.
- **Coverage limit:** Rain's partner list (>100 brands) is not published; only deployments findable
  on-chain are enumerated (by upgrade authority + chain-wide code-size filters). Tenants self-hosting
  forks under different authorities/code sizes cannot be exhaustively discovered and are not covered.

---

## 9. Files index

- `analysis/` — fleet enumeration (`fleet_map_main.jsonl`, `fleet_map_main.json`, `collateral_counts.json`,
  `old_auth_programs.json`, `multi_admin_counts.json`), exploit decoding (`decode_full.py`, `ci_test_data.json`),
  PDA derivation (`sol_rpc.py`), fund scan (`fleet_fund_scan_fast.py`, `fleet_fund_scan.json`),
  build fingerprints (`build_fingerprints.json`, `elf/`, `elf_old/`, `strs/`).
- `poc/` — LiteSVM replay harness + vendored ELFs and account/tx data.
- `ci/` — `run.sh` (CI job).
- `ci-out/` — LiteSVM result matrix + logs.
- `summary.json` — machine-readable summary.

## 10. Methodology & sources

- On-chain: Solana JSON-RPC (`getProgramAccounts`, `getAccountInfo`, `getMultipleAccounts`,
  `getSignaturesForAddress`, `getTransaction`, `getBlockTime`, `simulateTransaction`), read-only, at
  explicit slots recorded per call. Public endpoints + a keyed endpoint (key never written to files).
- Incident sources: Blockaid (2026-09-02), MASTRlabs on-chain reconstruction (2026-08-28), CoinDesk,
  cryptocard.guide, The Daily Crypto Briefs; corpus leads in `zombie-hunt-iii/work/S1-xalerts.md`,
  `S4-solana-move.md` (re-verified on-chain; note S4's "program IDs not published" was resolved here).
- Caveats: vendor statements are attributed, not trusted; balances are point-in-time; USD ≈ $1 for
  USDC/USDT; "dormant" = no accounts, which is the correct test (an attack needs an existing, funded
  collateral account to escalate).
