# Phase Stake — SPMBzs program audit (unprivileged-attacker perspective)

**Target:** program `SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn` (Sanctum "SPL multi-pool deploy"), pool `phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG`.
**Question:** can a fresh, unprivileged attacker (no manager/staker/authority keys) move value out of the pool, mint tokens it did not pay for, inflate its share, or grief/brick the pool?
**Method:** source reading of the deployed branch (all 8 `program/src/*.rs` files fetched from `igneous-labs/sanctum-spl-stake-pool@sanctum-spl-multi-pool-deploy` and hash-verified), byte-diff against upstream `solana-program/stake-pool` `program@v1.0.0` / `program@v2.0.0` / `program@v2.2.0`, plus read-only mainnet verification of the Phase pool state, validator list, validator stake account and program authorities. Read-only; no transactions were sent.

Source of record (local copies used for line cites below): `/tmp/opencode/sanctum/sp2_{processor,state,instruction,big_vec,lib}.rs`, upstream refs in `/tmp/opencode/upstream/`.

---

## 0. Headline

1. **The deployed bytecode is upstream SPL stake pool v1.0.0, not a Sanctum-modified fork.** All 8 source files are byte-identical to `solana-program/stake-pool@program@v1.0.0` **except**: (a) `lib.rs` `declare_id!` (§1), (b) `state.rs` `Fee::apply` rounds fees **up** instead of down, (c) `instruction.rs` adds only off-chain instruction builders. `processor.rs` is **identical** (md5 `b965aa3feb8f66864cfb1ff4a5b8a679`).
2. **All "Sanctum" instructions (`Redelegate`, `Increase/DecreaseAdditionalValidatorStake`, `DecreaseValidatorStakeWithReserve`, `*WithSlippage`, `SetFundingAuthority`, `Create/UpdateTokenMetadata`) are stock upstream v1.0.0 features.** They are *not* the audit risk; the risk is the pre-v2.2.0 accounting that upstream later changed.
3. **One high-severity, attacker-callable accounting bug is live in the deployed code (F-1, §6A):** a permissionless crank (`UpdateValidatorListBalance`, `no_merge=false`) records **zero** lamports for a validator whose record status is `DeactivatingValidator`/`DeactivatingAll` while its stake account still holds the lamports. The pool's `total_lamports` (hence the deposit price) is then under-stated by exactly that validator's stake. A permissionless `DepositSol`/`DepositStake` in the same epoch mints tokens at that false price; when the stake is merged into the reserve (next epoch) NAV recovers and the attacker's excess tokens become backed. Upstream v2.2.0 added the missing `else { active_stake_lamports = lamports }` (evidence: `upstream/up_v22_processor.rs:2114-2116`); the deployed code lacks it (`sp2_processor.rs:2469-2496`). **Precondition: any record in a `Deactivating*` status** — i.e., after a staker `RemoveValidatorFromPool` (routine rebalancing), for the remainder of that epoch. Phase currently has **no** such record (§1.3), so F-1 is not live at snapshot time.
4. No other unprivileged path to move value, mint free tokens, inflate share, or brick the pool was found, including the `BigVec`/`start_index` class, PDA confusion, deposit↔withdraw rounding, and freshness-gate manipulation (§6 B–H). Residual unknowns in §7.

---

## 1. Deployment & provenance verification

### 1.1 Source delta vs upstream

| file | fork vs `program@v1.0.0` | fork vs `program@v2.2.0` (master) |
|---|---|---|
| `processor.rs` | **identical** (v1.0.0 → v2.0.0 upstream was itself a 1-line borsh-import change) | ≈1 010 changed lines (all are *upstream* post-v1.0.0 changes) |
| `state.rs` | 12 changed lines = `Fee::apply` ceil-vs-floor | plus upstream fee-increase-cap addition |
| `lib.rs` | 4 lines = `declare_id!` only | ✓ |
| `big_vec.rs`, `error.rs`, `entrypoint.rs`, `inline_mpl_token_metadata.rs` | identical | — |
| `instruction.rs` | +213 lines = off-chain builders (`update_validator_list_balance_chunk`, `update_stale_*`, `update_stale_stake_pool`) only; no on-chain effect | — |

The Sanctum SPL1 deploy branch (`sanctum-spl-pool-deploy`, program `SP12tW…`) has the **same** `processor.rs`/`state.rs`/`instruction.rs`/`big_vec.rs` (md5-identical); only `lib.rs` differs (`SP12tW…`). **Conclusion: every finding below applies equally to Sanctum's SPL1 program.**

The only behavioural delta of the fork is `Fee::apply` (state.rs:941–952, ceil) vs upstream v1.0.0 (floor). Reviewed in §5: it is fee-*hardening* (charges at least 1 unit of fee where upstream could charge 0) and is not exploitable — no user-facing amount is rounded in the user's favour anywhere.

### 1.2 On-chain corroboration (slot ~457.27k, epoch 1058)

Read-only `getAccountInfo` checks that the deployed binary behaves like the source:

* Pool account: 611 bytes = exactly the `StakePool` layout of `state.rs:45-159`; `account_type=1`; `token_program_id=Tokenkeg…`; `lockup` default; `last_update_epoch=1058` = current epoch.
* Derived PDAs match `solana-pubkey` ground truth (bit-exact): `find_withdraw_authority_program_address` → `9HYjrCF5evTobLmay372kpUWSNTrtmDU2NkQtqjdnHKa` = the stored `stake_withdraw_bump_seed=251`; `find_deposit_authority_program_address` → `DTws8vTwkJ1U1gpfgtbLsxydVgnDkLBoB9n1KYvw27BT` = the stored `stake_deposit_authority`; `find_stake_program_address(vote,pool,None)` → `8QtQ1U34DPs2UKQiwUoRPMHnjJedsmdASZdbQHa7VHKh`, an existing stake account owned by `Stake1111…`, delegated to the sole list validator with `deactivation_epoch = u64::MAX` (never deactivated).
* Accounting identity verified to the lamport: `total_lamports (30,002,233,945,691) = reserve lamports (86,131,699,596) − min_reserve (2,282,880) + Σ record.stake_lamports (29,916,104,528,975)`.
* Validator list: `account_type=2`, `max_validators=3950`, `vec_len=1`, record 0 = vote `CiTYUYPA…`, `validator_seed_suffix=0`, `transient_seed_suffix=0`, **status=0 (`Active`)**, `active_stake_lamports=29,916,104,528,975`, `last_update_epoch=1058`.
* Program is **upgradeable**: programdata `HxBTMuB7cFBPVWVJjTi9iBF8MPd7mfY1QnrrWfLAySFd` (1,080,509 B, last deploy slot 371,704,232), upgrade authority `47SND7bGKvNXrqfP1bjsLCbwTgZhFBzAgmZ42QSkRScz` (off-curve ⇒ multisig/PDA, Sanctum-controlled). Not attacker-controllable; remediation requires a Sanctum upgrade.

### 1.3 Live Phase configuration (matters for reachability)

| field | value | consequence |
|---|---|---|
| `manager` | `7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1` | privileged |
| `staker` | `DxWfcgb2kENzzFy6ATP8KconVj6FriFU2GDnK1TmK6mK` | privileged |
| `stake_deposit_authority` | `DTws8v…` = **default deposit PDA** | `DepositStake` is **permissionless** (processor.rs:2795-2814 signs with the PDA) |
| `sol_deposit_authority` | **None** | `DepositSol` is **permissionless** (state.rs:352-368 is a no-op) |
| `sol_withdraw_authority` | `phaseUTHSD78uiD8rnRQWuvbEakvY1chNSeftkpvz6d` (on-curve keypair) | `WithdrawSol` requires Sanctum's signature; **`WithdrawStake` does not** |
| `epoch_fee`, `stake/sol_deposit_fee` | 0/100, 0/1000, 0/1000 | attacker's deposit is free |
| `stake/sol_withdrawal_fee` | 1/1000 (0.1 %) | cost of the exit leg of F-1 |
| `preferred_deposit/withdraw_validator` | both = `CiTYUYPA…` (the only validator) | withdraw-source preference, see §6 J |
| validator list | 1 record, `Active`, `transient=0`, ~99.7 % of TVL | amplifies F-1 if that validator is ever removed/rebalanced |

---

## 2. Instruction → authorization gate table

`P` = processor path; all cites are `sp2_processor.rs` unless noted. "Signer" = the *externally required* signature(s); program PDAs are signed internally via `invoke_signed`.

| # | Instruction | Handler | Authorization actually enforced | Class |
|---|---|---|---|---|
| 1 | `Initialize` | 713 | manager `is_signer` (**735**); withdraw PDA equality (**822**); mint authority/freeze/supply/decimals (**835-861**); validator-list size (**764-773**); reserve authority = withdraw PDA (**878-894**); rent (**778**,**783**) | privileged (new pool only) |
| 2 | `AddValidatorToPool(u32)` | 957 | `check_authority_withdraw` (**988**) + `check_staker` (**994**, state.rs:420) + `check_reserve_stake` (**995**) + `check_validator_list` (**996**) + freshness (**998**) | staker |
| 3 | `RemoveValidatorFromPool` | 1106 | withdraw PDA (**1129**) + staker (**1134**) + freshness (**1136**) | staker |
| 4 | `DecreaseValidatorStake` (deprecated) | 1244 | withdraw PDA (**1288**) + staker (**1293**) + freshness (**1295**) | staker |
| 5 | `DecreaseValidatorStakeWithReserve` | 1244 (fund rent, `true`) | as #4 | staker |
| 6 | `DecreaseAdditionalValidatorStake` | 1244 (`ephemeral` Some) | as #4 + transient-seed match (**1338**) | staker |
| 7 | `IncreaseValidatorStake` | 1561 | withdraw PDA (**1605**) + staker (**1610**) + freshness (**1612**) | staker |
| 8 | `IncreaseAdditionalValidatorStake` | 1561 | as #7 + seed match (**1645**) | staker |
| 9 | `Redelegate` | 1847 | withdraw PDA (**1884**) + staker (**1889**) + freshness (**1891**) | staker |
| 10 | `SetPreferredValidator` | 2187 | `check_staker` (**2207**); validator must exist & be `Active` (**2222-2231**) | staker |
| 11 | `UpdateValidatorListBalance` | 2249 | **no signer at all**; `check_validator_list` (**2271**), withdraw PDA (**2272**), reserve (**2277**), stake program (**2278**), per-record PDA checks (**2315**, **2326** — mismatch ⇒ record skipped), `start_index+len ≤ vec_len` (**2294-2298**) | **permissionless** |
| 12 | `UpdateStakePoolBalance` | 2543 | **no signer**; `check_mint` (**2562**), withdraw PDA (**2563**), reserve (**2564**), manager fee acct (**2565**), validator list (**2569**), token program (**2572**), every record fresh this epoch (**2602**) | **permissionless** |
| 13 | `CleanupRemovedValidatorEntries` | 2667 | **no signer**; validator list pinned (**2680**); only `retain(status != ReadyForRemoval)` (**2690**) | **permissionless** |
| 14 | `DepositStake` | 2697 | withdraw PDA (**2728**) + `check_stake_deposit_authority` (**2733**, key compare only — no `is_signer`) + mint (**2734**) + validator list (**2735**) + reserve (**2736**) + fee acct (**2742**) + freshness (**2749**); if the provided authority == `find_deposit_authority_program_address` the program signs for it (**2795-2806**) else a real signature is required by the stake-program CPI (**2808-2813**) | **permissionless on Phase** (authority = default PDA) |
| 15 | `DepositStakeWithSlippage` | 2697 (`Some(min)`) | as #14 + `minimum_pool_tokens_out` (**2887**) | **permissionless on Phase** |
| 16 | `WithdrawStake` | 3110 | `check_mint` (**3139**), validator list (**3140**), withdraw PDA (**3141**), fee acct (**3147**), token program (**3150**), freshness (**3154**); burn CPI signed by the *user's* token-account authority (**3336-3342**) | any pool-token holder |
| 17 | `WithdrawStakeWithSlippage` | 3110 (`Some(min)`) | as #16 + minimum lamports out (**3190**) | any pool-token holder |
| 18 | `DepositSol` | 2962 | withdraw PDA (**2989**) + `check_sol_deposit_authority` (**2994**; no-op when `None`, state.rs:352) + mint (**2995**) + reserve (**2996**) + fee acct (**3003**) + freshness (**3012**) | **permissionless on Phase** |
| 19 | `DepositSolWithSlippage` | 2962 | as #18 + min tokens (**3046**) | **permissionless on Phase** |
| 20 | `WithdrawSol` | 3425 | withdraw PDA (**3452**) + `check_sol_withdraw_authority` (**3457**; requires Sanctum's key on Phase) + mint (**3458**) + reserve (**3459**) + fee acct (**3466**) + freshness (**3472**); user burn CPI (**3526**) | token holders **+ Sanctum key on Phase** |
| 21 | `WithdrawSolWithSlippage` | 3425 | as #20 + min lamports (**3500**) | token holders + Sanctum key |
| 22 | `SetManager` | 3727 | `check_manager` (**3741**) + new manager signer (**3742**) + fee acct valid (**3747**) | manager |
| 23 | `SetFee` | 3757 | `check_manager` (**3772**); epoch-boundary delay (**3774**); `check_too_high` (**3778**, state.rs:1024) | manager |
| 24 | `SetStaker` | 3786 | staker **or** manager (**3798-3802**) | staker/manager |
| 25 | `SetFundingAuthority` | 3810 | `check_manager` (**3828**); can set/clear `stake_deposit_authority`/`sol_deposit_authority`/`sol_withdraw_authority` (**3829-3837**) | manager |
| 26 | `CreateTokenMetadata` | 3572 | `check_manager` (**3604**) + withdraw PDA (**3605**) + mpl program (**3597**) + metadata PDA (**3611**) + payer signer (**3589**) | manager |
| 27 | `UpdateTokenMetadata` | 3654 | `check_manager` (**3678**) + withdraw PDA (**3679**) + metadata PDA (**3684**) | manager |

Verification helpers: `check_program_derived_authority` state.rs:271-293, `check_authority_withdraw` 322-335, `check_stake_deposit_authority` 338-347, `check_sol_deposit_authority` 352-368, `check_sol_withdraw_authority` 373-388, `check_mint` 392-400, `check_manager` 403-417, `check_staker` 420-434, `check_validator_list` 437-451, `check_reserve_stake` 454-470.

**Permissionless set (the attack surface): #11, #12, #13, #14/#15, #16/#17, #18/#19** (the last three conditioned on pool config, which for Phase is "deposits open, stake-withdrawals open, SOL-withdrawals Sanctum-gated").

---

## 3. Why those are really non-signer-callable

* **#11 `UpdateValidatorListBalance`** — the only key-like check is `check_authority_withdraw`, which recomputes `create_program_address([pool, b"withdraw", stored_bump])` and compares it to the *passed account key*; no `is_signer` (state.rs:322-335 has no signature test). All other accounts are pinned to state fields (`validator_list`, `reserve_stake`), to the stake program, or per record (`check_validator_stake_address` at 2315 / `check_transient_stake_address` at 2326, whose failures merely `continue`). Remaining accounts are arbitrary pairs and their *content* is decoded from the real stake accounts. An attacker derives the stake PDAs from public validator-list data and supplies them.
* **#12 `UpdateStakePoolBalance`** — no signer; `check_mint` only compares the mint key and unpacks it (the supply is read from the mint, 2656-2658); `check_authority_withdraw` is a key compare.
* **#13 `CleanupRemovedValidatorEntries`** — no signer, no authority check beyond the pool/validator-list pin; `retain` only drops records whose status is `ReadyForRemoval`.
* **#18 `DepositSol`** — `check_sol_deposit_authority` returns `Ok` immediately when `sol_deposit_authority == None` (state.rs:356) — true for Phase (§1.3).
* **#14 `DepositStake`** — `check_stake_deposit_authority` is a pure key compare (state.rs:338-347); the *only* way to satisfy the subsequent `stake_authorize` CPI without an external signature is to pass the default deposit PDA, in which case the program signs with `[pool, b"deposit", bump]` (2795-2806). For Phase the configured authority *is* that PDA, so it is open by design.
* **#16 `WithdrawStake` / #20 `WithdrawSol`** — authorized by owning pool tokens: the SPL token `Burn`/`TransferChecked` CPIs (3336, 3365, 3526) require the token account's owner/delegate to sign; the pool cannot be drained by a non-holder. `WithdrawSol` additionally needs Sanctum's `sol_withdraw_authority` key on Phase.

---

## 4. Custom-code (Sanctum) diff summary

Because the delta is tiny, the "custom paths" the brief asked about are stock upstream v1.0.0 code. Audit conclusions for them:

| Path | Where | Verdict |
|---|---|---|
| `Redelegate` impl (upstream disabled it in v2.2.0, `up_v22_processor.rs:3735`) | 1847-2186 | staker-gated (#9); bookkeeping updates the source record's active/transient/seed **before** the CPIs (2518-2525), all PDAs re-derived (2530, 2583, 2688), destination record re-checked and merged (2615-2718). No attacker path. Residual: whether the stake program's `Redelegate` instruction is enabled on mainnet today (staker-only impact if it is). |
| `DecreaseValidatorStakeWithReserve` / `*AdditionalValidatorStake` | 1244-1560, 1561-1846 | staker-gated; transient/validator/ephemeral PDA checks (1326-1362, 1659-1672); `TransientAccountInUse` + seed-match gates (1333-1343, 1640-1651). No attacker path. |
| `*WithSlippage` variants | 2887, 3190, 3046, 3500 | pure caller-side minimum-out checks; they only bind the caller's own trade. The `WithdrawStake` check sits **before** the "whole account" truncation (3190 vs 3329-3330), so a caller can receive slightly less than `minimum_lamports_out` without a revert — informational, hurts only the caller (upstream later moved the check: `up_processor.rs:3032`). |
| `SetFundingAuthority` | 3810-3840 | manager-only; can switch `stake_deposit_authority` back to the default PDA (3831) or gate SOL deposits/withdrawals. |
| `Create/UpdateTokenMetadata` | 3572-3723 | manager-only + PDA-checked metadata account + real mpl program check (165-177). |
| `big_vec.rs` (`retain`, `find*`, `push`, `deserialize_*`) | whole file | byte-identical to upstream v1.0.0 **and** upstream master. `deserialize_slice`/`deserialize_mut_slice` reject `skip+len > vec_len` (big_vec.rs:99-104, 115-120) ⇒ out-of-range `start_index` ⇒ `AccountDataTooSmall`; `find*` iterate exactly `vec_len` entries; `retain` compacts and rewrites `vec_len`, and `push` overwrites stale bytes at index `vec_len` ⇒ **no stale-entry resurrection**, and reads never touch bytes beyond `vec_len`. `retain`'s memmove indexing was hand-simulated for removals in leading/middle/trailing positions and is correct. The only writer of `vec_len` is the program (the account is owner-pinned and address-pinned by `stake_pool.validator_list`), so an attacker cannot forge a length. **No finding.** |

---

## 5. Fee & rounding math (state.rs)

Field order is `Fee { denominator, numerator }` (state.rs:928-933) — relevant for `SetFee` decoding, not for the attacker.

| function | line | formula | direction |
|---|---|---|---|
| `calc_pool_tokens_for_deposit` | 164-174 | `floor(stake_lamports · S / T)` | rounds **against** depositor |
| `calc_lamports_withdraw_amount` | 178-189 | `floor(tokens · T / S)`, `0` if `numerator < denominator` | against withdrawer |
| `calc_epoch_fee_amount` | 243-259 | `floor(S · fee_lamports / (T' − fee_lamports))` where `fee_lamports = ceil(reward · n/d)` | manager-favouring |
| `Fee::apply` (**Sanctum delta**) | 941-952 | `ceil(amt · n / d)` (upstream v1.0.0: floor) | fees ≥ 1 unit |
| `get_lamports_per_pool_token` | 263-268 | `(T + S − 1)/S` | used only for minimum-withdrawable tolerances |

Consequences checked:
* **deposit→withdraw round trip** (same epoch or not): mint is `floor`, redeem is `floor`, both fees are `ceil`, so the round trip returns ≤ deposit, typically deposit − (1–3 lamports + fee). **Not exploitable** (correctly signed, never profitable). The `calc_lamports_withdraw_amount` "Some(0)" case cannot be farmed: the handlers reject `withdraw_lamports == 0` with `WithdrawalTooSmall` (3186, 3496) *before* burning.
* Repeated tiny deposits cannot evade fees anymore (ceil ⇒ ≥ 1 unit per op); the Sanctum delta therefore *removes* the only fee-evasion nuance of upstream v1.0.0.
* `SetFee` allows `0/0` (0 % fee) and up to `n == d` (100 %) — manager-only, not attacker-reachable. The fork's `check_withdrawal` only enforces the 3/2 ratio (state.rs:957-988) where upstream master also caps the absolute increase; manager-only, informational.
* No overflow/truncation reachable by an attacker: all arithmetic is `u128` with `checked_*` and `u64::try_from`.

---

## 6. Candidate unprivileged abuse paths and verdicts

### A. F-1 — NAV under-count on deactivating validators ⇒ mint excess pool tokens — **WORKING (code path); needs a staker removal event; end-to-end NEEDS-ONCHAIN-TEST**

Code: `sp2_processor.rs:2469-2496` (deployed) vs `upstream/up_v22_processor.rs:2097-2117` (upstream fix). In the `DeactivatingValidator | DeactivatingAll` arm the deployed code sets `active_stake_lamports` only when `no_merge == true` or when the stake is fully cooled (`stake_is_inactive_without_history`, 207-211). With `no_merge = false` and a still-activating/deactivating stake it sets **nothing**, and the unconditional write at **2533-2535** then stores `active_stake_lamports = 0` for a stake account that still holds the lamports. `UpdateStakePoolBalance` (2599-2608) sums those records, so `total_lamports` excludes them. `process_update_validator_list_balance` is permissionless (§3), so the attacker chooses `no_merge`.

Attacker sequence (all permissionless; no Phase key needed):

1. Wait for / detect a record with `status ∈ {3,4}` (`DeactivatingValidator`/`DeactivatingAll`) — i.e., after the staker calls `RemoveValidatorFromPool` (1134 gate), for the remainder of that epoch (`deactivation_epoch == clock.epoch`). Detectable from the public validator list account.
2. `UpdateValidatorListBalance(start_index=that record, no_merge=false)` with the derived validator (+transient) stake accounts ⇒ record lamports zeroed while the account holds `D` lamports.
3. `UpdateStakePoolBalance` ⇒ `total_lamports = T − D` recorded, `last_update_epoch = current`, all records fresh ⇒ satisfies the freshness gate for deposits.
4. `DepositSol(X)` (Phase: open; 0 fee) ⇒ `mint = floor(X·S/(T−D))` — e.g. for Phase today (`T ≈ 30,002 SOL`, `S ≈ 25.12 M` pool tokens, single validator holding `D ≈ 29,916 SOL`, so the recorded NAV collapses to the ~86 SOL reserve): a 1,000 SOL deposit mints ≈ 292 M tokens ≈ **92 % of the post-deposit supply**, redeemable for ≈ 28,500 SOL after the merge. Generic profit after the merge: `X · D/(T − D + X)`, i.e. up to ~`D` if the attacker is well capitalised (or route through `DepositStake`, also open on Phase).
5. Next epoch: `UpdateValidatorListBalance(no_merge=false)` merges the cooled stake into the reserve (2490-2494) and `UpdateStakePoolBalance` restores NAV; attacker exits via `WithdrawStake` from the **reserve** (reserve path 3226-3238 — permitted because the record now has 0 active/transient lamports, and the reserve now holds `D` as undelegated lamports), paying the 0.1 % withdrawal fee. `WithdrawSol` is not needed, so the `sol_withdraw_authority` gate does not protect the pool.

Why nothing blocks it: the freshness gate is *satisfied by the attacker's own cranks*; the manager-fee account, mint and reserve are all pinned but public; the epoch fee on the recovered `D` is 0 on Phase so no dilution of the excess; the under-count state is produced by a permissionless instruction; and the deposit price reads only `stake_pool.total_lamports/pool_token_supply` (state.rs:164-174).

Limits/uncertainties: requires a `Deactivating*` record (staker action — not attacker-triggerable), and the exit requires the reserve to be able to pay the redeemed lamports — after the merge it holds `D` (+ the attacker's `X`), so the reserve path can cover the whole position; larger-than-pool positions would need `WithdrawStake` against validator stake accounts instead. Phase snapshot has 1 record in `Active` status, so F-1 is **not currently live**; it arms on the next validator removal/rebalance (notably, Phase today = one validator holding 99.7 % of TVL, which maximises `D/T`).

Verdict: **WORKING by code inspection** for `T ≈ 30k SOL, D ≈ 30k SOL` scenario above; end-to-end exploit requires a staker removal and should be confirmed on a local validator/clone (no writes on mainnet per engagement rules).

### B. Same under-count exploited by a *withdrawer* — **BLOCKED by direction**
Withdrawals also price off the recorded `total_lamports` (3182, 3492), so an under-counted NAV *reduces* the lamports paid out. There is no way for an attacker to *add* lamports to the record beyond real balances (§C/E below), so no "withdraw at inflated NAV" path was found. Exit-from-F-1 only works after the legitimate re-count.

### C. Epoch-reward-distribution window — **NEEDS-ONCHAIN-TEST (bounded small impact)**
Upstream v2.2.0 added `EpochRewards::get()?.active ⇒ EpochRewardDistributionInProgress` at the top of `UpdateValidatorListBalance` (`up_processor.rs:1879-1880`); the deployed code has **no** epoch-rewards guard anywhere (grep: zero hits). Cranking during the boundary window records per-validator lamports that have not yet received their epoch rewards (rewards are credited to stake accounts across the window). Permissionlessly: crank ⇒ record partial (pre-reward) balances ⇒ `DepositSol` at a discount ≈ the uncredited reward for the affected validators (~0.02 %/epoch at 7 % APY), self-consistent and self-correcting after the distribution. Impact is small and requires micro-timing inside a ~1-2 minute window; also possible that some merge/sweep CPIs behave differently mid-window. Worth a local-validator test (does the crank succeed? how large is the recorded skew?) but the extractable value is orders of magnitude below F-1.

### D. Over-statement / double-counting — **BLOCKED**
Every recorded lamport is read from a real account whose key must equal a PDA derived from the *record's own* `vote_account_address` + seed suffixes (2315-2336) — PDAs are unique per `(vote, seed)`, so the same lamports cannot be attributed to two records; passing an account under the wrong record just skips that record (`continue`), and `UpdateStakePoolBalance` then fails with `StakeListOutOfDate` (2602) because the record's `last_update_epoch` stays stale. Sweeps run *before* the record is rewritten (2445-2468 then 2533-2535), and the reserve is counted separately (2589-2598): no double count. `DepositStake` credits the measured **lamport delta** of the merge (2827-2841) and then re-syncs the record (2955). Donations to pool PDAs only ever *add* real lamports.

### E. `start_index` out of range / stale-entry resurrection (`big_vec.rs`) — **BLOCKED**
`deserialize_mut_slice` rejects `skip+len > vec_len` (99-104) so a crafted `start_index` fails with `AccountDataTooSmall` instead of wrapping (`saturating_mul` is only used after the bound check). Records beyond `vec_len`, and the stale bytes left by `retain`, are never read; `push` writes at index `vec_len` and increments, so nothing can be "resurrected". `vec_len` is only writable by the program (the account is owner- and address-pinned to `stake_pool.validator_list`, 2271/2576/2682). No attacker-controlled length or index.

### F. PDA confusion / account substitution — **BLOCKED**
* Withdraw authority: `create_program_address([pool, "withdraw", stored_bump])` compared to the passed key (state.rs:322-335); passing any other key ⇒ `InvalidProgramAddress`.
* Deposit authority: compared to the stored field (state.rs:342); the PDA-signing branch is only taken when the key *is* the pool's own deposit PDA (2797).
* SOL withdraw authority: compared to the stored field and must sign (state.rs:379-385).
* Validator/transient stakes: derived per record (2315/2326, 1326, 1668, 2780); the pool's validator stake account in `DepositStake` is additionally required to be `Active` (2788) and `usable by pool` (authority+lockup, 196-204).
* Mint, manager-fee account, reserve, validator list, token program: all compared to stored keys (2562-2573, 2734-2743, 2995-3003, 3139-3151, 3458-3466).

### G. Freshness gate manipulation — **BLOCKED except as F-1's enabler**
`last_update_epoch < clock.epoch ⇒ StakeListAndPoolOutOfDate` on all deposit/withdraw paths (2749, 3012, 3154, 3472) and on every staker rebalance path (998, 1136, 1295, 1612, 1891). `UpdateStakePoolBalance` itself requires *all* records fresh this epoch (2599-2608) and refreshes the recorded supply from the mint (2656-2658). Because the required cranks are permissionless, a stale pool cannot be used to *trap* users, and no privileged actor can be forced into anything. Exact ordering an attacker needs for F-1: (1) `RemoveValidatorFromPool` by the staker (not attacker), (2) `UpdateValidatorListBalance(start_index, no_merge=false)` for all chunks, (3) `UpdateStakePoolBalance`, (4) `DepositSol`/`DepositStake` in the same epoch, (5) next epoch re-crank to merge the cooled stake and re-count NAV, (6) `WithdrawStake` from the reserve. Steps 2-4 and 5-6 are fully permissionless; only step 1 depends on the staker.

### H. `check_stake_deposit_authority` has no `is_signer` — **BLOCKED-BY-CPI (and intentional)**
When the configured authority is a real key (not the PDA), the deposit path calls `stake_authorize` via plain `invoke` (2808-2813), and the stake program requires that key's signature; the account is pinned by key compare, so an attacker cannot substitute its own. When it is the default PDA, deposits are *meant* to be open. No bypass found; Phase is in the second case.

### I. Griefing / bricking without keys — **BLOCKED**
* Deposits/withdrawals can be starved of an in-epoch crank, but any account can crank (11/12) for tx fees, so this is self-service, not brickable.
* `CleanupRemovedValidatorEntries` can only drop `ReadyForRemoval` records, which by construction have 0 active/transient lamports (state.rs:619-644 sets `ReadyForRemoval` only after the merge/withdrawal drains the account); removing them also cannot break `find*` lookups for other validators.
* The deployed code's `preferred_withdraw_validator` handling errors (`ValidatorNotFound`, 3252) if the preference points at a validator that vanished from the list — but `RemoveValidatorFromPool` clears the preference (1231-1235) and `SetPreferredValidator` requires an existing `Active` validator (2222-2231), so no unprivileged actor can create the dangling state. (Upstream v2.2.0 added defensive resets in `UpdateValidatorListBalance`; belt-and-braces only.)
* `Initialize` cannot be re-run on the pool (account-type + owner + rent checks, 747-789).
* Program is upgradeable by Sanctum's multisig only (§1.2) — an attacker cannot patch or brick the program.

### J. Informational, not attacker-exploitable
* `WithdrawStake`'s slippage check precedes the whole-account truncation (3190 vs 3329-3330) — caller-side loss only.
* `WithdrawStake` refuses validators marked for removal (3300) — but the reserve path stays available; with the F-1 crank making `has_active_stake` false, the reserve path opens *earlier* than intended (an enabler, not a gain by itself).
* `MAX_VALIDATORS_IN_POOL` cap absent (added upstream v2.2.0): manager/staker-only surface; a large validator list makes the per-epoch full crank expensive, which would degrade the pool — no keyless attacker input.
* The `Fee::apply` ceil delta and the missing absolute fee-increase cap are manager-facing only.

---

## 7. Residual unknowns

1. **End-to-end confirmation of F-1** (and of the C window) on a local mainnet clone: crank + deposit + merge + withdraw, checking lamport-level profit and that no other instruction (e.g. `CleanupRemovedValidatorEntries` interleaving) blocks the path. Not performed here (engagement rules: no mainnet writes; local validator out of scope for this task).
2. **Deployed-binary ⇄ branch equivalence:** behavioural equivalence was verified (PDA scheme, 611-byte layout, exact accounting identity, per-record lamports equal to the real stake account). A byte-level `.so` hash comparison against a fresh build was not done.
3. **Staker opsec as the trigger:** whether Phase (or its parent flow) performs `RemoveValidatorFromPool`/rebalances that leave `Deactivating*` records — the window's existence is a staker-dependent precondition. Historical validator-list/instruction history already collected by the parent session (`mb_vlist_sigs.json`, `history_analysis.json`, `mb_pool_sigs.json`) can settle how often that state arises; at snapshot time the list held 1 `Active` record.
4. **Epoch-rewards window magnitude**: is the recorded skew limited to the not-yet-credited rewards, or can merges/sweeps mid-window create a larger or opposite-signed skew? Requires a local validator with partitioned rewards.
5. **`Redelegate` on mainnet**: whether the stake program's redelegate path is enabled (staker-only risk, not attacker-callable in this program).
6. **Sanctum SPL1 instance (`SP12tW…`)**: source is byte-identical except `declare_id!`, so F-1 applies there too; its pools' configs (deposit authorities/fees) were not enumerated here.

---

## 8. Appendix — quick cite index for the permissionless paths

```
permissionless cranks
  sp2_processor.rs:2249-2278  UpdateValidatorListBalance gates (no signer)
  sp2_processor.rs:2294-2298  start_index+len bound (BigVec)
  sp2_processor.rs:2315-2336  per-record PDA checks (mismatch => continue)
  sp2_processor.rs:2439-2536  record rewrite (the F-1 defect at 2469-2496/2533-2535)
  sp2_processor.rs:2557-2608  UpdateStakePoolBalance gates + NAV sum + freshness
  sp2_processor.rs:2667-2692  CleanupRemovedValidatorEntries
deposits
  sp2_processor.rs:2720-2751  DepositStake gates (incl. 2733 authority compare)
  sp2_processor.rs:2795-2814  PDA-signed authorize vs real-signature authorize
  sp2_processor.rs:2962-3014  DepositSol gates
withdrawals
  sp2_processor.rs:3132-3156  WithdrawStake gates
  sp2_processor.rs:3336-3342  user burn CPI (the real authorization)
  sp2_processor.rs:3446-3474  WithdrawSol gates (incl. sol_withdraw_authority)
checks
  sp2_state.rs:271-293        check_program_derived_authority (no signer)
  sp2_state.rs:338-347        check_stake_deposit_authority (key compare only)
  sp2_state.rs:352-388        SOL deposit/withdraw authority checks (None => no-op)
  sp2_state.rs:403-434        check_manager / check_staker (key + is_signer)
fees / math
  sp2_state.rs:164-189        deposit mint / withdraw lamports (floor)
  sp2_state.rs:243-259        epoch fee
  sp2_state.rs:941-952        Fee::apply (ceil; the only on-chain Sanctum delta)
```
