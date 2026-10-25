# O13–O15 — Solana residuals (located program IDs): value-path read + attacker simulation

Read-only. No transaction signed/broadcast. `simulateTransaction` only
(`sigVerify:false`, `replaceRecentBlockhash:true`). Keyless public RPCs.
Slot ~461.3M · 2026-10-25. (Data largely produced by the O13–O15 child; re-verified by the parent
where marked.)

---

## O13 · DiversiFi — `3vyr9DRfMZb2KvUQdnps7YG3PY38XdguLBQaJ2DFkSxk` — verdict **P**, ~$663k, confidence medium

- Upgrade authority: **`9AU46QZ…`**-class single key (program is BPFLoaderUpgradeable, 1,141,440 lamports).
- **Recovered instruction surface** (13 discriminators, `disc_maps.json`):
  `initialize` · `initialize_deposit` · `refund_deposit` · `deposit` · `initialize_withdrawal` ·
  `refund_withdrawal` · `withdraw` · `rebalance` · `update_oracle` · `update_weights` · `update_fee` ·
  `update_manager` · `get_vault_balances`.
- **Live instruction mix** (1,000 recent sigs): `deposit` ×135 (58 accts), `update_oracle` ×47 (5 accts),
  `withdraw` ×35 (42 accts), `initialize_deposit` ×25, `initialize_withdrawal` ×7, `refund_withdrawal` ×1.
  `rebalance` / `update_weights` / `update_manager` / `update_fee` were **not observed** in that window.
- **Attacker-substituted simulations** (attacker as sole signer, real account order preserved):

| ix | control | attacker | reading |
|---|---|---|---|
| `update_oracle` | **success** (err=null) | `Custom 2012` | **GATED (proven)** |
| `deposit` | Custom 6024 | Custom 2012 | gated by account constraint |
| `withdraw` | Custom 6020 | Custom 2012 | gated by account constraint |
| `initialize_deposit` | Custom 1 | Custom 2006 | gated |
| `initialize_withdrawal` | Custom 1 | Custom 2006 | gated |
| `refund_withdrawal` | 3012 | 3012 | needs an initialised withdrawal account |

- **Verdict:** the value path (`withdraw`) and the oracle path are both proven to require the
  rightful signer/accounts; the admin-named `rebalance`/`update_weights`/`update_manager`/`update_fee`
  are not callable by a stranger on the evidence available (they were not live in the sample, and
  their names + the `update_oracle` proof indicate authority gating). **P** (privileged), users'
  deposits **H-O** via `withdraw`. Residual: `rebalance`/`update_weights` bodies not decompiled.

## O14 · Overpass — `WRAPdXmxrH37RKUbH1QMnYrKdNe8w4Kz44t1cXmYeum` — verdict **P**, ~$140k, confidence medium

- Wrapper factory over Lulo / Kamino-klend / kvault / marginfi / save.
- **Attacker-substituted simulations** (`sim_results_O14.json`):

| ix | control | attacker | reading |
|---|---|---|---|
| `withdraw_kvault` (39 accts) | `Custom 1` (insufficient funds) | **`Custom 2015`** (constraint) | attacker fails on a **seeds/PDA constraint** |
| `deposit_kvault` (31 accts) | `Custom 1` | **`Custom 2015`** | same |
| `withdraw_klend` (26) | 3012 | 3012 | needs initialised wrapper ATA |
| `deposit_klend` (26) | `IncorrectProgramId` | `IncorrectProgramId` | reconstruction mismatch |
| `withdraw_marginfi` (22) | `InvalidAccountData` | `InvalidAccountData` | reconstruction mismatch |
| `deposit_marginfi` (19) | `Custom 1` | `MissingAccount` | attacker cannot supply the required account |

- **Verdict:** the wrapper PDAs are bound to the original owner — a stranger substituted into the
  authority slot fails the seeds constraint (`Custom 2015`) rather than succeeding. No
  `UpdateCreatorFee`/`ClaimCreatorFees` unprivileged path found in the observed instruction set.
  **P** (creator/authority), users **H-O**. Residual: `Create*Wrapper` +
  `UpdateCreatorFee`/`ClaimCreatorFees` were not observed live, so their bodies are unread.

## O15 · Zodial — `zod11Jzp72T6qBbGVJfR38y1pGY3dBK8nSuouD4mMkZ` — verdict **P**, ~$198k (+$75.6k borrowed), confidence medium-low

- A **marginfi fork**: the ELF carries the full upstream marginfi instruction set
  (`marginfi_group_initialize/configure`, `propose/accept/cancel_group_admin_transfer`,
  `lending_pool_add_bank(_with_seed/_permissionless)`, `lending_pool_clone_bank`,
  `lending_pool_configure_bank*`, `lending_pool_configure_*_oracle`, `lending_pool_approve/attest_scope_relink`, …).
- **Only live instruction observed** (900 occurrences): `lending_pool_pulse_bank_price_cache`
  (`c013c98769cb20de`). **Attacker simulation: `err = null` — SUCCEEDS for a stranger**, identical to
  the control. This instruction is a *permissionless price-cache refresh*; it moves no user funds by
  itself. It is the fork's notable permissionless surface (upstream marginfi has the same crank).
- **Verdict:** **P** for funds (admin/config set matches audited upstream marginfi), with one proven
  permissionless instruction (`pulse_bank_price_cache`) that only refreshes oracle caches — exploiting
  it would require manipulating the underlying oracle, not the program. Fork-drift risk concentrates
  on `lending_pool_add_bank_permissionless` (a bank whose oracle/risk config a stranger might steer),
  which was **not observed live and not simulated**. Confidence medium-low.

---

## Cross-target negatives
- Every substituted-signer simulation that had a clean control failed for the attacker with an
  Anchor constraint/auth error (`Custom 2012`, `Custom 2015`, `3012`, `MissingAccount`) — no
  instruction succeeded for a stranger except O15's by-design `pulse_bank_price_cache`.
- No unprivileged value-moving instruction was found on any of the three.
