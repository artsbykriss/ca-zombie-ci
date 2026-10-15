# C2-36 — Phase Delegation (ex-AeroPool) stake pool: fresh-attacker audit of the largest single Solana custody

**Date:** 2026-10-15 · **Chain:** Solana mainnet-beta · **Status:** read-only research; no transaction was
signed or sent; every claim below is re-proved from public RPCs by `analysis/verify_all.py`
(30/30 checks PASS in CI, artifact `ci-out/verification.json`).

Target: SPL Stake Pool account **`aero2ePURjuEgLKTzcUmF6RypBncBGd7pMUYCoSsVJ6`** ("Phase Delegation",
ex-**AeroPool**, token **pdSOL**), owned by the canonical SPL Stake Pool program
**`SPoo1Ku8WFXoNDMHPsrGSTSG1Y47rzgn41SLUNakuHy`**.

---

## 1. TL;DR

| Target | Live extractable (external, unprivileged) | Why closed | Latent risk |
|---|---|---|---|
| Phase Delegation pool `aero2ePUR…` — **1,101,114.88 SOL** (pool state) / **1,101,120.41 SOL** (actual accounts) ≈ **$115.3M** @ $104.73/SOL | **$0 — no unprivileged extraction path found** (high confidence) | Custody sits in 110 PDA-derived stake accounts + reserve whose staker **and** withdrawer are the program-derived authority `AKJt3m2x…`; every value-out instruction requires burning the caller's own pdSOL; deployed program is byte-identical to the official, audited `program@v2.1.0` release | Manager (now a 3-of-4 Squads multisig) can raise **withdrawal fees** (≤1.5×/epoch, ≈1.2 years to 100%) and the **epoch fee to 100% of rewards**; staker is still a single hot EOA (can re-delegate stake, capture future rewards — not principal); program upgrade authority is Squads-gated (systemic); a v2.2.0 upgrade is prepared in a hash-verified buffer |

**Total live extractable by an external unprivileged attacker now: $0.00 (E-U). Confidence: HIGH.**
**Holder-recoverable (H-O): 1,101,120.41 SOL ≈ $115.3M** (pdSOL burn-withdraw; 0.05% withdrawal fee).
**Privileged-only (P): fee-policy powers + program upgrade — no principal-theft path found.**
**Stuck (S): $0.**

Reconciliation with the corpus: ZOMBIE-HUNT-II recorded 1,099,635 SOL ≈ $133.6M (≈$121.5/SOL). Current
on-chain truth: **1,101,120.410851434 SOL** across 110 stake accounts + reserve (slot 457,279,799 in the
final CI run, epoch 1058; the pool state field lags by one crank and reads 1,101,114.884155839 SOL). USD at
the final CI run's spot $104.73/SOL = **$115,324,925**; SOL spot moved $102.9→$105.4 through 2026-10-15
($113.3M–$116.0M — the SOL amount is the invariant).

---

## 2. What this deployment actually is (the "mechanism")

This is **not** a custom/buggy contract. It is a standard **SPL Stake Pool** deployment whose custody is
held in program-derived stake accounts. The audit question — "can an outsider still take it?" — reduces to
(a) who can move the stake accounts, (b) whether the deployed program is the audited one, (c) whether any
instruction lets an unprivileged caller extract value. All three are answered on-chain below.

Notable decode detail (evidence trail): the pool account is allocated 611 bytes (the struct maximum), but
the live struct ends at byte 435 — bytes 435–466 are **stale leftovers** from an earlier state in which one
32-byte `Option` field (e.g. an old `sol_withdraw_authority`) was set; the program reads state with
`try_from_slice_unchecked` (ignores trailing bytes) and rewrites only the struct length, so stale bytes
persist. Live state: **all seven dynamic fields are None/None-like (no pending fee changes, no deposit or
withdraw authority gates, no preferred validators)** — verified twice (initial hand-parse + automated
check `all_options_none`).

---

## 3. Live-state assessment (slot 457,262,004, epoch 1058, 2026-10-15)

### 3.1 Pool account (owner = `SPoo1Ku8…`, space 611)

| Field | Value |
|---|---|
| manager | `7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1` — **Squads v4 vault (index 0)** |
| staker | `QocTiqKmq654c5hxBitSUD7UKZH7JMzjkcNHeh917wk` — single EOA (hot; Jupiter/vote activity) |
| stake_deposit_authority | `4Y6XeEZ2Dg2zXU9NJgdmAG9xpwAsNusLReSTLzJxtZJ8` = default deposit PDA (bump 254) |
| stake_withdraw_bump_seed | 255 → withdraw authority = **`AKJt3m2xJ6ANda9adBGqb5BMrheKJSwxyCfYkLuZNmjn`** (PDA verified by derivation) |
| reserve_stake | `aeroivis36SwDvAJpzQCDX9Y7cCLXBdv9vTn1DtDnVC` — 18.169026093 SOL, state=Initialized |
| pool_mint (pdSOL) | `aeroXvCT6tjGVNyTvZy86tFDwE4sYsKCh7FbNDcrcxF`, 9 decimals, supply **952,415.109886148** = pool_token_supply, **mint authority = the withdraw PDA**, freeze authority **None** |
| manager_fee_account | `HC77HUgE6XpEVnS6RtNwe1yf7a1BoBdQzdxyWrAsxVac` (pdSOL account owned by `Gutj91DY4…`; holds 21.33 pdSOL ≈ 24.7 SOL) |
| total_lamports / last_update_epoch | 1,101,114.884155839 SOL / **1058 = current epoch** (cranked every epoch) |
| fees | epoch_fee **5%** (100/5), stake_deposit **0.05%** (10000/5), stake_withdrawal **0.05%**, sol_deposit **0.05%**, sol_withdrawal **0.05%**, referrals 0 |
| dynamic fields | all None (no pending fee changes; no `sol_deposit_authority`; no `sol_withdraw_authority`; no preferred validators) |
| lockup | none (custodian = system program) |
| exchange rate | 1 pdSOL = 1.156155… SOL |

### 3.2 Custody: 110 stake accounts + reserve — all PDA-controlled, zero orphans

- Validator list `aero4efZ7zHhWpqXQj4Uqw59koxj8KXqMCPUuvmhgUQ` (space 36,509 = 500 max): **110 validators,
  all status=Active, all updated in epoch 1058**, Σ active = 1,101,096.716795986 SOL (list value at last crank).
- For each validator, stake account = PDA(`[vote, pool, (validator_seed_suffix)]`, SPoo1). All **110
  derived accounts exist**, and for every one: **staker == withdrawer == `AKJt3m2x…`** (the pool withdraw
  PDA), no lockups. Σ on-chain = **1,101,102.241825341 SOL**; + reserve 18.169026093 = **1,101,120.410851434 SOL**.
- `getProgramAccounts` sweeps of the Stake program filtered by `withdrawer == AKJt3m2x…` **and** by
  `staker == AKJt3m2x…` each return **exactly 111 accounts** = the 110 stake accounts + the reserve.
  **No orphaned, foreign-controlled, or unaccounted stake accounts exist.** (Both sweeps are part of CI.)
- Transient stake: 0. No deactivated stake exists today.
- Independent re-verification of all 110 accounts (child-A artifacts, `analysis/child-a/`): every account
  is owned by the Stake program, in `Stake` state, **withdrawer == AKJt3m2x…, and delegated to exactly the
  listed vote account**; the only deltas vs the validator list are tiny positive lamport differences from
  rewards accrued since the last crank (≤ ~5.5 SOL aggregate). One entry (#43) is a dust validator holding
  only the 1,000,000-lamport minimum active stake (+rent) — included in the sweeps, immaterial to totals.
- Recent activity (sampled 500 pool-account signatures ≈ 8.6 h): the pool account is referenced ~1×/min by
  **Kamino Scope oracle** update transactions (`HFn8GnPADiny6XqUoWE8uRPPxb29ikn4yTuPa9MF2fWJ`, Scope TWAP
  price source for pdSOL) — read-only reads; no holder withdrawals or admin instructions appeared in the
  sampled window. The pool is cranked by the staker's ops at least once per epoch (`last_update_epoch`
  1058 = current).

### 3.3 Program: deployed binary == official audited release

- Programdata `EmiU8AQkB2sswTxVB6aCmsAJftoowZGGDXuytm6X65R3`: ELF (1,080,464 B) sha256
  **`ec2dfefaa70d560754a0000f39bd2cabc192b895d36205b3c428f601b6e1d7e1`** — **byte-identical** to the
  official release asset `spl-stake-pool.so` of tag **`program@v2.1.0`** (solana-program/stake-pool),
  verified by download + hash compare in CI.
- Last upgrade: **slot 429,882,117 (2026-06-30)**, executed through the Squads program-upgrade flow
  (`SMPLecH534…` `ExecuteTransaction` + `SMPLKTQh…` `SetAsExecuted`, tx
  `3pSWuPCuow7qc67HtTKGFMYzyxdGDYbHfZ4iehcpVeqauLvVnVM85RUM1PGug9nzdQE9kxs2bvY4khxtXhRx3hp6`;
  log "Upgraded program SPoo1Ku8…").
- Upgrade authority: `dPpFfahSWhm5M2RB3nVaHsXfnh9ooz5bWtR3WeUguDH` (assigned 2026-06-30 in the same tx;
  Squads-controlled — its 17 txs are SetAuthority/upgrade operations, never a plain EOA-signed upgrade).
- Source-level deltas v2.1.0 → v2.2.0 (released 2026-10-06, **not yet deployed**) are non-custodial: allow
  mints with freeze authority for *new* pools, 1-SOL minimum-delegation handling in withdraw-stake,
  slippage-check ordering, docs. **No security fix applicable to this pool's custody.** `Redelegate` is
  explicitly disabled in the deployed binary ("Instruction: Redelegate will not be enabled",
  processor.rs:3736).
- **Pending upgrade (monitor):** on 2026-10-06 the SPL ops key prepared a program buffer
  `EmR4UhwTPoEwKe9JNnVaHqSgmup3ebeBMyogY5fR9bgf` (loader tag=Buffer) and set its authority to the same
  Squads vault `dPpFfahS…`. Its content (328,264 B) is **byte-identical** (sha256
  `40ff077967f1616ea2e14088dbb13c918a93f185ea1a60f87b8025f198f844c7`) to the official **`program@v2.2.0`**
  release asset — i.e. a v2.2.0 upgrade is prepared and awaits multisig execution. Executing it is a
  governance action (visible on-chain) and v2.2.0's deltas are non-custodial for this pool; a malicious
  *substituted* buffer would be detectable by hash.
- Relevant history (child-b research, `analysis/child-b/REPORT.md`): the canonical program has **no
  published security advisories** and no documented unprivileged theft on mainnet. The permissionless
  classes that did exist — Certora H-03 (`WithdrawStake` reserve drain/hijack), cluster-restart stake
  hijacks, transient-lamport accounting — were **fixed in v2.0.4 (2025-12-04)**, and the withdrawal-fee
  cap-bypass (`Option::map` vs `and_then`) in **v2.1.0**; both fixes are inside the hash-verified deployed
  build. Older classes (2021 reserve front-run; HAL-01 fee avoidance 2024) are long fixed.

### 3.4 Who holds the keys (fresh-attacker relevance)

| Role | Holder | What it can do | Can it take principal? |
|---|---|---|---|
| manager | **Squads v4 vault `7LqSTwcw…`** = PDA index 0 of multisig `GRe1iCBEeAMdEeFmEMavgXJE8Uk8tU82pyxZ4iXXAD1v` — **3-of-4, 1-day timelock**, members `CQeJSnKk…`, `E8S39Hwm…`, `GQJUoajR…`, `Gutj91DY4…` (all Initiate+Vote+Execute); config authority = system program (config frozen) | SetFee (epoch fee ≤100% of *rewards*; withdrawal fees +≤0.5pp and ≤1.5×/epoch, 2-epoch delay), SetStaker, SetManager, SetFundingAuthority, metadata | **No** |
| staker | `QocTiq…` single hot EOA (active since 2025-07; recent Jupiter swaps/vote txs) | add/remove validators, increase/decrease stake between validators, set preferred validators, update validator list | **No** (can only re-delegate pool stake; a malicious staker could add a validator it controls and capture future *rewards* — visible, reversible by holders exiting) |
| withdraw authority | PDA `AKJt3m2x…` — **only the program can sign** (bump 255 = stored) | moves stake accounts only through burn-gated instructions | No (program-enforced) |
| deposit authority | default PDA `4Y6XeEZ2…` (signature not required → stake deposits open) | — | n/a (deposits add value) |
| program upgrade authority | `dPpFfahS…` (Squads-gated) | replace SPoo1 code for **all** pools on the program | Systemic trust in SPL/anza release process + Squads governance; not Phase-specific |

Manager rotation evidence (fresh governance change): on **2026-10-12 05:33:39 UTC** (slot 455,932,770,
tx `4as7vmMhAvD8ekPnKtEqsbyuS6UaJRhAFyBNi8wyFbNuMvysPxXZuZpM4eKy`) the multisig vault executed
`SPoo1 SetManager` on this pool: old manager **`Gutj91DY4…` (single EOA)** → new manager **`7LqSTwcw…`
(Squads vault)**, new fee account `HC77HUgE…`. The same batch migrated the manager role on 7 pools
(Phase's own pool program `phasejkG1akKgq…`, Hylo ×2, Portal `prt1stdb…`, Sanctum `sntn1Y9g…`,
Meso `Meso1TUD…`) from the same EOA to the same vault.

---

## 4. What an attacker can and cannot do (exact gates)

Every instruction of the deployed program (v2.1.0) was reviewed against the live state. Value-out paths:

| Instruction | Gate in deployed code | Live value | Attacker can extract? |
|---|---|---|---|
| `WithdrawSol` (16) | burns caller's pdSOL (`token_burn`, processor.rs:3246); withdraws **only from the reserve**; fails when `reserve - amount < rent` ("maximum possible SOL withdrawal is X") | reserve = **18.169 SOL** → ≤ ~18.167 SOL per call, first-come-first-served | No — you get only what your burned tokens are worth (0.05% fee) |
| `WithdrawStake` (10) | burns caller's pdSOL (processor.rs:3060); source stake account must equal PDA(`[vote, pool, seed]`) — `check_validator_stake_address` (processor.rs:58); amount ≤ listed active stake minus minimum-delegation/rent margins | full pool (110 accounts) | No — burn-gated, share-proportional |
| `WithdrawSolWithSlippage` / `WithdrawStakeWithSlippage` (25/23) | same as above + slippage floor | same | No |
| `DepositSol` (15) | permissionless (`sol_deposit_authority` = None); mints pdSOL at `calc_pool_tokens_for_deposit` | — | No (deposits add value; mint math is checked arithmetic with ceiling fee logic) |
| `DepositStake` (9) | deposit authority is the default PDA → no signature required; stake account must be initialized+delegated per program rules | — | No (front-run risk only for the depositor's own in-flight stake) |
| `UpdateValidatorListBalance` (7) / `UpdateStakePoolBalance` (8) / `CleanupRemovedValidatorEntries` (9) | permissionless by design; every stake account passed is verified to be the PDA for a listed validator; balances are read from real accounts | — | No — cannot credit fake lamports (PDAs checked), cannot redirect value; only updates accounting |
| `SetManager`/`SetFee`/`SetStaker`/`SetFundingAuthority` | current manager signature (`check_manager`) + (for SetManager) new-manager signature; fees validated (`check_too_high`, `can_only_change_next_epoch`) | — | No (manager = 3-of-4 multisig) |
| `Increase/DecreaseValidatorStake(+Additional)(+WithReserve)` | staker signature; PDA-verified stake/transient/ephemeral accounts; transient seeds must match the list | — | No (staker only; moves stake between the pool's own validator accounts) |
| `Redelegate` | **disabled** in deployed binary (processor.rs:3736) | — | No |
| `Initialize` | one-shot per pool | — | No |
| `CreateTokenMetadata`/`UpdateTokenMetadata` | manager | — | No |

**Costs:** any extraction attempt today costs transaction fees and yields at most the attacker's own
burned-token value — i.e. no positive expected value. No flash-loan/round-trip surface exists: pdSOL
mint/burn is 1:1 against a monotonically-updated `total_lamports`, with rounding ceilings fixed in the
2023 HAL-01 remediation and re-checked in v2.2.0 (not deployed) only for minimum-delegation handling.
Child-A's independent instruction-by-instruction review (`analysis/child-a/REPORT.md`) reached the same
verdict and quantified the only privilege-free edge case found — harvesting un-swept third-party lamports
in pool stake accounts (5.525 SOL; round-trip fee ~199× the gain) — as economically closed.

---

## 5. Verification (this folder's PoC equivalent)

Solana has no Foundry fork harness; the equivalent here is a **from-scratch re-verification against
public RPCs** (no keys, no transactions):

- `analysis/verify_all.py` — 30 independent checks: pool decode, PDA derivations (pure-python ed25519),
  110 stake-account authority checks, two `getProgramAccounts` orphan sweeps, mint/fee/lockup checks,
  totals reconciliation, deployed-ELF vs official v2.1.0 release hash, pending-upgrade buffer vs official
  v2.2.0 release hash, SOL price/valuation.
- **Local run: 30/30 PASS; CI run: 30/30 PASS** (`ci-out/verification.json`). CI run URLs: `ci-links.md`.
- Independent adversarial source review of the deployed v2.1.0 instruction set (child-A,
  `analysis/child-a/REPORT.md`, 191 lines): independently re-derived the tag→commit binding
  (`program@v2.1.0` → `54cdceda…`, sha256 of all 6 source files), reviewed **all 27 instruction variants
  (26 landable)**, and reconciled the pool against the chain with its own decoders. **Verdict: no
  unprivileged extraction path.** Every stake account consumed by any instruction is either a derived
  pool PDA (seeds from the validator-list record, never instruction data) or a caller-owned account;
  no missing PDA/authority checks; no type confusion; no fake-lamport injection; rounding pool-favouring;
  `Redelegate` a hard error. Ledger reconciles to the lamport (reserve contribution 18,167,359,853 +
  Σrecords 1,101,096,716,795,986 = T_stored).
- **Only candidate E-U found (quantified and rejected):** third-party lamports sitting un-swept in pool
  stake accounts (currently **5.525 SOL**; ε≈5.02e-6) could be harvested by deposit → self-triggered
  permissionless update → withdraw, but the 0.1% round-trip fee is **~199× the gain**; break-even needs
  >1,101 SOL un-swept. Provenance: an external Jito/Router tx (slot 457,091,792) donated 0.490827886 SOL
  into a pool stake account; the pool program was never invoked. Child-A also flags one liveness/DoS class
  (delinquent-deactivation update path; escape `no_merge`) — not value-extracting.
- History/incident research (SPL stake pool exploit history, Phase/AeroPool, pdSOL market): `analysis/child-b/REPORT.md`.

Key numbers reproduced by the checks: pool 1,101,114.884155839 SOL; supply 952,415.109886148 pdSOL;
110/110 stake accounts with staker==withdrawer==`AKJt3m2x…`; 111 accounts in each sweep (0 orphans);
program sha256 `ec2dfef…`; reserve 18.169026093 SOL; no pending fee changes.

---

## 6. Verdict, residual/latent risk, blockers

**Verdict (fresh-attacker standard):** no external unprivileged path to extract or redirect any part of
the 1,101,120.41 SOL custody exists today. The prior "H-O unstake only" classification is confirmed and
strengthened: the custody is on the canonical, hash-verified, audited program; every authority that can
move it is either a program PDA or a multisig-gated role; the entire stake-account set is accounted for.

**Residual / latent risks (none E-U):**

1. **Manager fee powers (P, multisig-gated).** Epoch fee can be raised to 100% of *rewards* (not
   principal). Withdrawal fees can rise by ≤0.5pp and ≤1.5× per epoch — from today's 0.05% that is a
   ~1.2-year, fully visible ramp to 100%, during which any holder can exit. Realistic conditional impact
   only if holders fail to exit: up to the full pool value in the limit; expected: near-zero.
2. **Staker key (P, single hot EOA).** Can re-delegate stake to a validator it controls (rewards capture
   at 100% commission). Cannot touch principal. Detection: any `AddValidatorToPool` /
   `IncreaseValidatorStake` / `SetPreferredValidator` by this key is public and immediate.
3. **Program upgrade authority (systemic P).** Squads-gated; a malicious upgrade of SPoo1 would affect
   every pool on the program (237 initialized pools; 220 with stake — enumerated by `getProgramAccounts`),
   not just this one. Out of Phase's control.
4. **Withdrawal-liquidity mechanics (H-O nuance).** `WithdrawSol` is capped by the 18.169 SOL reserve
   (zero deactivated stake today); exits beyond ~18 SOL require `WithdrawStake` → user-owned stake
   account → self-deactivate (~2–3 days) → SOL. This is a latency/complexity cost, not a lock.
   Secondary-market depth is thin (child-b): Jupiter/Sanctum quotes exit near NAV only up to ~35k pdSOL
   (~$4M), then fall off a cliff (40k pdSOL → 96.8% price impact) — the native stake-pool withdraw path
   (not the market) is the real exit for large holders.
5. **No blockers found**: no lockup, no freeze authority on pdSOL, no deposit/withdraw authority gates,
   no pending fee changes, pool cranked every epoch.

**What would change the verdict:** (a) execution of the prepared v2.2.0 upgrade (or any other upgrade) of
SPoo1 — watch `last_deployed_slot` / the buffer `EmR4UhwTPoEwKe9JNnVaHqSgmup3ebeBMyogY5fR9bgf`; (b)
`SetManager`/`SetStaker`/`SetFee` txs on the pool (watch manager `7LqSTwcw…`); (c) the staker key moving
stake to new validators; (d) a published vulnerability in stake-pool ≤ v2.1.0.

---

## 7. Methodology, sources, caveats

- Everything is read from public RPCs (`solana-rpc.publicnode.com`, `api.mainnet-beta.solana.com`) at
  finalized commitment; slot recorded in `ci-out/verification.json`. No transaction was ever signed/sent.
- Decoders are written from the exact borsh layouts of the program sources at tag `program@v2.1.0`
  (state.rs, processor.rs, lib.rs, instruction.rs) and validated against live data and cross-checks
  (mint supply == pool supply; 110/110 PDA matches; two independent sweeps).
- The deployed binary was verified by sha256 against the official release asset — this is stronger than
  a source read, but it still trusts the SPL/anza release process for v2.1.0 (audited by third parties;
  public audit references in the repo).
- Caveats: no local execution of the program (Solana programs cannot be forked locally without an
  SBF toolchain and a validator); USD figures use DefiLlama spot at the stated timestamp; Squads
  multisig decode is from the official IDL (@sqds/multisig 2.1.4) and live account bytes.
- Sources: on-chain data as cited; solana-program/stake-pool v2.1.0/v2.2.0 tags; solanacompass pool
  listing (stale for manager/fee account — on-chain values used); phase.cc; Colosseum stake-pool research
  (AeroPool→Phase rebrand).

## 8. Files index

```
README.md                     this report
summary.json                  machine-readable summary
ci-links.md                   CI run URLs
ci-log.txt, ci-artifacts/     CI outputs (after runs)
ci/run.sh                     CI job (runs analysis/verify_all.py)
analysis/verify_all.py        the 30-check re-verification (runs locally and in CI)
analysis/pool_state.json      decoded pool/vlist/mint state
analysis/vlist_decoded.json   110 validators (vote, stake, suffixes)
analysis/derived_stake_accounts.json  derived PDAs per validator
analysis/stake_accounts_verified.json per-account authority/balance checks
analysis/role_accounts.json   all role accounts (manager/staker/mint/fee/reserve/program)
analysis/squads_multisig.json 3-of-4 multisig details + vault derivation
analysis/withdrawer_scan.json 111-account orphan sweep (withdrawer filter)
analysis/raw_*.b64            raw account dumps (pool, vlist, mint)
analysis/spoo1_program.so     on-chain ELF (hash-verified against v2.1.0 release)
analysis/spoo1_upgrade_buffer.so  pending-upgrade buffer ELF (hash-verified against v2.2.0 release)
analysis/child-a/REPORT.md    independent adversarial instruction review
analysis/child-b/REPORT.md    history/incident research
```
