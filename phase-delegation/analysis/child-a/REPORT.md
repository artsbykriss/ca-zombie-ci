# Child-A — Adversarial source review of the DEPLOYED code
## SPL Stake Pool `SPoo1Ku8WFXoNDMHPsrGSTSG1Y47rzgn41SLUNakuHy`, pool `aero2ePURjuEgLKTzcUmF6RypBncBGd7pMUYCoSsVJ6` (Phase Delegation / ex-AeroPool, pdSOL)

Author: child-a (Phase Delegation audit, delegated task) · Date: 2026-10-15 · Scope: **source review of the exact deployed program binary + on-chain reconciliation (read-only)**.

---

## 0. Verdict (headline)

**No. An unprivileged attacker (no keys, own capital only) cannot extract value from this pool today, and I found no code path that would let one.** All 27 instruction variants (26 landable; `Redelegate` is a hard error) are accounted for; every value-moving path is gated by a PDA-address check, a signer check, or the SPL Token owner check, and every accounting write is derived from real on-chain balances through permissionless, re-derivable updates. Rounding is consistently in the pool's favour on both deposit and withdrawal. The only privilege-free "edge" I found (harvesting third-party lamports that sit un-swept in pool stake accounts) is **~200× too small to beat the 0.1% round-trip fee**, and needs a >1,101 SOL un-swept donation plus a race against an updater that anyone (including the attacker) can run.

The residual risks are all *privileged* (upgrade authority, staker EOA, manager multisig) plus one liveness/DoS class. Details in §5.

---

## 1. What exactly was reviewed, and why it is the deployed code

| Item | Value | How verified |
|---|---|---|
| Tag → commit | `refs/tags/program@v2.1.0` → `54cdceda5d77b06ea7cea6e18c99560212755ab1` | `git ls-remote` (git protocol, not the rate-limited API) |
| Source files | `program/src/{processor,state,instruction,lib,big_vec,error}.rs` (+ `entrypoint.rs`) | sha256 of each local copy == sha256 of `raw.githubusercontent.com/.../54cdceda…` (all 6 matched) |
| Local hashes | `processor.rs 6807ce6e…b14`, `state.rs 62a95efc…f16`, `instruction.rs 11023fa1…8f1`, `lib.rs 53deec9d…9b5`, `big_vec.rs 47dfc5e0…075`, `error.rs a0fc653d…4f4` | `sha256sum` vs remote |
| Deployed binary | `spoo1_program.so` sha256 `ec2dfefaa70d560754a0000f39bd2cabc192b895d36205b3c428f601b6e1d7e1` == official release asset `spl-stake-pool.so` of tag `program@v2.1.0` (given) | reproduced locally on the downloaded asset |
| Dependency pinning | `solana-stake-interface 4.2.0`, `borsh 1.6.1`, `spl-token-2022-interface 3.0.1` | `program/Cargo.toml` + `Cargo.lock` @54cdceda |

**Honest caveat:** I did *not* reproduce the build bit-for-bit. The claim "the deployed BPF implements exactly this Rust" rests on the (independently established) equality of the deployed program with the official release asset of that tag. I also cross-checked upstream CPI helper semantics against `solana-stake-interface 4.2.0` from crates.io rather than assuming them (§3.6).

Two deploy-level facts I decoded myself from the raw account bytes rather than trusting prior notes (`raw_pool.b64`, `raw_vlist.b64` from the parent tree, plus a **live re-read at slot ~457,274,445** which returned byte-identical `total_lamports` / `pool_token_supply` / `last_update_epoch`):

* `epoch_fee = 5/100`, `stake_deposit_fee = 5/10000`, `stake_withdrawal_fee = 5/10000`, `sol_deposit_fee = 5/10000`, `sol_withdrawal_fee = 5/10000`, all `next_*` = `None`, both preferred validators `None`, `stake_referral_fee = 0`, `sol_referral_fee = 0`, `lockup = default`.
* **`stake_deposit_authority = 4Y6XeEZ2Dg2zXU9NJgdmAG9xpwAsNusLReSTLzJxtZJ8` which IS the pool's deposit PDA** (`find_program_address([pool,"deposit"])`, bump 254; off-curve). ⇒ `DepositStake` is permissionless.
* **`sol_deposit_authority = None` and `sol_withdraw_authority = None`** ⇒ `DepositSol` / `WithdrawSol` are permissionless (by design: `state.rs:350-366`, `371-386`).
* The pool is **not stale**: `last_update_epoch = 1058` == current epoch ⇒ deposits and withdrawals are live *right now*.
* pdSOL mint: legacy `Tokenkeg…`, 9 decimals, mint authority = withdraw PDA, **freeze authority = None**, supply `952415109886148`.
* Account space 611 B, but the v2.1.0 `StakePool` struct serialises to **435 B** — the trailing 176 B are stale bytes from a legacy layout. Inert: `try_from_slice_unchecked` reads only the struct, writes only 435 B (see the note at the end of §5).

---

## 2. Every instruction: signer, value movement, unprivileged verdict

Line numbers are from the verified v2.1.0 `program/src/processor.rs` unless prefixed `state.rs:` / `big_vec.rs:`.
"PDA-addr" = address check only (no signature required) — i.e. the account is the canonical pool PDA.

| # | Instruction | Required signers / checks | Value that can move | Unprivileged-abuse verdict |
|---|---|---|---|---|
| 1 | `Initialize` (646-890) | **manager must sign** (668); `is_uninitialized` (682, 692); owner checks (680, 689); exact `max_validators` fits account (697-709); fees ≤ 1 (727-734); mint supply 0 / 9 dec / mint-auth = withdraw PDA / no freeze auth / supported extensions (767-798); reserve `Initialized`, correct auths, no lockup (801-839); manager fee account validated (799) | seeds the pool account/mint, mints `total_lamports` to the *manager fee account* | **No.** Cannot re-initialise an owned, initialised pool; manager+staker are chosen by the initialiser, not attacker-controlled. |
| 2 | `AddValidatorToPool(seed)` (894-1037) | **staker** (931) + PDA-addr (925) + reserve/vlist checks (932-933); duplicate vote rejected (952-957); `len < max_validators` (946); `<= MAX_VALIDATORS_IN_POOL` (949) | splits `rent + min_delegation` from the **reserve** into a new stake account delegated to `vote` | **No** (staker-only). Staker can pick the validator → directs pool stake (validator commission accrues to that validator); cannot withdraw. |
| 3 | `RemoveValidatorFromPool` (1041-1175) | **staker** (1069) + PDA-addr (1064) + fresh epoch (1071) + vlist (1080) + PDA check on stake (1103) + transient PDA (1117) | deactivates validator (and transient) stake; sets status `Deactivating*` | **No** (staker-only). Enables orderly exit of stake; cannot move lamports to anyone. |
| 4 | `DecreaseValidatorStake` / `…WithReserve` / `AdditionalValidatorStake` (1179-1499) | **staker** (1228) + PDA-addr (1223) + fresh epoch (1230) + vlist + validator-stake PDA w/ record seed (1262-1268) + transient seed must match record (1274-1280) + `lamports >= min_delegation` (1296-1305) + remainder ≥ rent+min_delegation (1311-1320) | validator stake → **transient** account (PDA) or **ephemeral** (PDA); may pull `stake_rent` from the reserve | **No** (staker-only). All destinations are pool PDAs; bookkeeping is T-neutral (`active -= lamports`, `transient = account.lamports()`). |
| 5 | `IncreaseValidatorStake` / `Additional` (1503-1785) | **staker** (1552) + PDA-addr (1547) + fresh epoch (1554) + reserve PDA (1559) + `check_validator_stake_account` (owner + PDA + authenticated to withdraw PDA + lockup + voter) (1601-1609) + reserve-solvency (1636-1650) | **reserve → transient/ephemeral** (`lamports + stake_rent`) | **No** (staker-only). Reserve can only be drained into pool-owned PDAs; `transient += total_lamports`. |
| 6 | `SetPreferredValidator` (1789-1847) | **staker** (1809); target must exist and be `Active` (1819-1835) | none (steers deposits/withdrawals) | **No** (staker-only). |
| 7 | `UpdateValidatorListBalance(start_index, no_merge)` (1851-2171) | **NO SIGNER.** Only PDA-addr on withdraw authority (1876), vlist (1875), reserve (1881), stake program (1882); `EpochRewards.active` guard (1884-1888); per-pair PDA checks, *skipped* pairs `continue` (1925-1946) | writes `active_stake_lamports` / `transient_stake_lamports` / `last_update_epoch` **from real `AccountInfo::lamports()`** (2101/2105/2121/2150-2167); sweeps excess → reserve (2081-2098); merges transient↔validator/reserve (1979-2054/2026) | **Permissionless, but not abusable.** Every account it trusts is a pool-program PDA that an attacker cannot create (see §3.4); every number it writes is a real balance. |
| 8 | `UpdateStakePoolBalance` (2175-2291) | **NO SIGNER.** PDA-addr (2196), mint (2195), reserve (2197), manager-fee key equality (2198), vlist key equality (2202), token program (2205) | recomputes `total_lamports = reserve−rent + Σrecords` (2219-2236), mints epoch fee (2249-2260), rolls `next_*` fees (2262-2281), stores supply from the mint (2284-2286) | **Permissionless, not abusable.** Requires *every* record `last_update_epoch >= clock.epoch` (2230-2232) ⇒ numbers are always one-epoch-fresh and re-derived from the chain. |
| 9 | `CleanupRemovedValidatorEntries` (2295-2383) | **NO SIGNER.** vlist PDA (2308); only removes `ReadyForRemoval & lamports==0` records (2318, `state.rs:755-758`); may reset stale preferred validators (2327-2376) | shrinks the vlist; clears dangling preferred validators | **No.** Bounded by `is_removed`; no value movement. |
| 10 | `DepositStake` / `…WithSlippage` (2387-2648) | **deposit authority** (2423; = deposit **PDA** here, signed via `invoke_signed` 2488-2496) + fresh epoch (2439-2441) + mint/vlist/reserve/manager-fee (2424-2434) + validator-stake **PDA** check (2470-2476) + status `Active` (2478) + slippage (2577-2581) | user's stake account → validator stake account (authorize+merge) then `total_lamports += real delta` (2521-2531, 2639-2642); SOL-excess swept to reserve (2619-2631); tokens minted (2583-2616) | **No.** The authorize CPI (2498-2504) can only succeed if the *source's current staker is the deposit authority*; with the deposit-authority set to a PDA, the attacker must first authorise **their own** stake account to that PDA. Merge requires the same voter (enforced by the stake program). Destination must be a pool PDA. |
| 11 | `WithdrawStake` / `…WithSlippage` (2800-3145) | **`user_transfer_authority` must be a transaction signer** for a *non-signed* `invoke` burn (3060-3066); mint/epoch/vlist/manager-fee checks (2831-2848) | burns the user's own pool tokens; splits stake to a user-chosen *uninitialised* stake account and authorises it to the user (3068-3086); `total_lamports -= withdraw_lamports`, record decremented (3100-3142) | **No.** SPL Token enforces owner/delegate for burn; the split source must be the reserve or a validator/transient **PDA carrying the record's seed** (2918, 2975-3010). ValidatorRemoval path is tightly boxed (3027-3055). |
| 12 | `WithdrawSol` / `…WithSlippage` (3149-3289) | **`user_transfer_authority` signer** (3246-3252); fresh epoch (3198-3200); `sol_withdraw_authority` **None ⇒ no extra signer** (3183); reserve-rent floor (3232-3244) | burn own tokens → `stake_withdraw` from the **reserve** to a user account; `total_lamports -= withdraw_lamports` (3282-3285) | **No.** Only the caller's own tokens; amount is the pool-price floor; the reserve keeps its rent floor. |
| 13 | `DepositSol` / `…WithSlippage` (2652-2796) | **`sol_deposit_authority` None ⇒ no extra signer** (2684); fresh epoch (2702-2704) | `system transfer` of the caller's lamports → reserve (2742-2746); mints at the stored ratio (2706-2757) | **No.** Self-funded; mint is capped by `calc_pool_tokens_for_deposit`. |
| 14 | `SetFee` (3477-3502) | **manager** (3492); `check_too_high` ≤ 100% (`state.rs:1047-1062`); withdrawal/epoch fees only take effect next epoch (`3494-3496`, `state.rs:1067-1072`) and are rate-limited (`state.rs:954-1013`) | none directly (fee schedule) | **No** (manager-only). See §5.3 (epoch-fee confiscation of *rewards*). |
| 15 | `SetManager` (3447-3473) | **manager** (3461) + **new manager signs** (3462-3465) + new fee account owned by token program & matching mint (3456, 3467) | none (roles) | **No.** |
| 16 | `SetStaker` (3506-3526) | **staker OR manager** (3518-3522) | none (role) | **No.** |
| 17 | `SetFundingAuthority` (3530-3560) | **manager** (3548) | sets `stake_deposit_authority` / `sol_deposit_authority` / `sol_withdraw_authority` (to any key, or to the deposit PDA / `None`) | **No** (manager-only). Note: it can only *tighten* (attach a signer) or loosen (detach) these; it cannot touch mint/token-program/vaults. |
| 18 | `CreateTokenMetadata` (3292-3371) | **manager** (3324) + **payer signs** (3309) + PDA-addr (3325) + metadata PDA matches mint (3331) | creates the Metaplex metadata (payer's lamports) | **No.** |
| 19 | `UpdateTokenMetadata` (3374-3443) | **manager** (3398) + PDA-addr (3399) + metadata PDA (3404) | metadata only | **No.** |
| 20 | **`Redelegate`** (3736-3739) | — | **hard error, unconditionally**: `Err(ProgramError::InvalidInstructionData)` | **Disabled** — confirmed no-op. Only a stub exists; `instruction.rs:608-627` marks it deprecated. |
| 21-24 | `DepositStakeWithSlippage` / `WithdrawStakeWithSlippage` / `DepositSolWithSlippage` / `WithdrawSolWithSlippage` (3740-3781) | same as #10-13 | same as #10-13, plus min-out checks | **No.** I explicitly checked the argument order — `(pool_tokens_in, minimum_lamports_out)` / `(lamports_in, minimum_pool_tokens_out)` are passed in the correct positions (3746-3780); no swap bug. |

**Total instruction space = 27 enum variants; 26 are landable** (27 − `Redelegate`). All 26 are covered in the table above.

### 2.1 Decimal-level check of the money functions

| Function | File:line | Semantics | Exploitable? |
|---|---|---|---|
| `calc_pool_tokens_for_deposit` | `state.rs:162-172` | `floor(Δ·S/T)`; `Δ` if T==0 or S==0 | floor ⇒ favours the pool; the `S==0` branch is only reachable for an unseeded pool |
| `calc_lamports_withdraw_amount` | `state.rs:176-187` | `floor(x·T/S)`; 0 when `x·T < S` | floor ⇒ under-pays the withdrawer; **no round-trip arbitrage** |
| `Fee::apply` | `state.rs:939-950` | **ceil**(`amt·n/d`) | fees round *up* ⇒ favours pool/manager. Consequence: tiny withdrawals with fee `5/10000` set the fee to ≥1 token, so `pool_tokens_burnt = pool_tokens − fee` can be 0 ⇒ `WithdrawalTooSmall` (DoS-of-self only, 2878/3222) |
| `calc_epoch_fee_amount` | `state.rs:241-257` | `S_capacity = floor(S·fee/(T_after−fee))` | standard; degenerate `T_after == fee` branch (`state.rs:247-248`) mints the whole reward as tokens but is unreachable for a live pool (needs `T ≈ 5%` of one epoch's rewards) |
| `get_lamports_per_pool_token` | `state.rs:261-266` | `ceil(T/S)` used only as a tolerance in withdrawal gating | conservative |
| `check_withdrawal` / `check_too_high` | `state.rs:954-1013`, `1047-1062` | withdrawal fee ≤ ×1.5 +0.005/epoch, absolute cap 100% | prevents instant fee rug |

---

## 3. Targeted hunt: the specific bug classes asked for

### 3.1 Missing PDA checks — **none found**
Every stake account the program CPIs on is either (a) derived and compared, or (b) a caller-owned account it merely authorises. Derivation helpers: `lib.rs:91-163`; enforcement:
`check_validator_stake_address` processor.rs:58-79, `check_transient_stake_address` 82-101, `check_ephemeral_stake_address` 104-118, `check_stake_state` (owner + authority + lockup + voter) 254-277 via `check_validator_stake_account` 282-306, `check_reserve_stake` state.rs:452-466, `check_validator_list` state.rs:435-449, `check_mint` state.rs:390-398, `check_authority_withdraw` state.rs:320-333 (uses `stake_pool.stake_withdraw_bump_seed`, i.e. `create_program_address`, not a re-derivation race — the pool state's bump is what `Initialize` wrote at 756-765).

### 3.2 Missing authority checks — **none found**
* Manager-only: `SetFee`, `SetManager`, `SetStaker`, `SetFundingAuthority`, both metadata ops.
* Staker-only: `AddValidatorToPool`, `RemoveValidatorFromPool`, `SetPreferredValidator`, `Increase*`, `Decrease*`.
* Deposit authority: `DepositStake` (PDA here ⇒ permissionless by design); `DepositSol`/`WithdrawSol` when the corresponding Option is `Some`.
* **The three permissionless instructions (7, 8, 9) move no value to any caller.** §3.4 explains why that is safe.
* Withdrawal burn authority is enforced by the *token program* through a plain `invoke` (`token_burn` 565-582; call sites 3060, 3246) — a real signer is required, so nobody can burn another holder's pdSOL.

### 3.3 Type confusion between stake-account kinds — **none found**
Validator stake = `[vote, pool(, seed_le)]`; transient = `[b"transient", vote, pool, seed_le]`; ephemeral = `[b"ephemeral", pool, seed_le]`; reserve = the stored key; deposit target/vaults are all PDA-checked. Seeds come from the **validator-list record** (`validator_seed_suffix` / `transient_seed_suffix`), not from attacker-supplied instruction data — so an attacker cannot swap a transient for a validator account, cannot pass the same account twice in one pair (the pair is positional over records), and cannot use the reserve as a split source unless the pool is globally inactive (2918-2938). `MINIMUM_ACTIVE_STAKE`/`minimum_delegation` are enforced on all decrease paths.

One deploy-specific check worth stating: **all 110 records use `validator_seed_suffix = 0` and `transient_seed_suffix ∈ {0..4}` with `transient_stake_lamports = 0`** (my own decode), so today every validator stake PDA is the no-seed derivation and there is no dangling transient to confuse.

### 3.4 Fake lamports into the validator list / pool totals — **not possible**
* `UpdateValidatorListBalance` (permissionless) only writes `AccountInfo::lamports()` of accounts that must equal pool-program PDAs (2150-2167, 2101, 2105, 2121, 1976, 2057). **Only the pool program can sign for a PDA**, so only it can create accounts there (all creation goes through `create_stake_account` → `allocate`+`assign` under `invoke_signed`, 309-324). There is no path that lets a third party put an attacker-owned account at a pool PDA (off-curve addresses cannot be keypair-signed; the system program demands a signature).
* Consequently no attacker can inflate `Σrecords` in `UpdateStakePoolBalance` (2227-2236), and `reward_lamports` (2238) is always real.
* Duplicate vote entries (which would double-count one account) are rejected on insert (952-957) and I verified the live list has no duplicates.
* The one direction that *is* possible — lamports *appearing* in a pool stake account from outside — only ever makes `T_real > T_stored` (§4), i.e. it *helps* holders; the pool cannot be pushed into `T_stored > T_real`.

### 3.5 Burning fewer tokens than the value withdrawn — **not possible**
Both withdrawal paths compute `pool_tokens_burnt = pool_tokens − ceil(pool_tokens·fee)` **once** (2870-2872, 3214-3216) and use that identical value for (a) `calc_lamports_withdraw_amount` (2874-2876, 3218-3220) and (b) the burn (3065, 3251). The fee leg is a separate `transfer_checked` of exactly `pool_tokens_fee` to the manager fee account (3088-3098, 3254-3264). The fee can be zeroed only when `burn_from_pool == manager_fee_account` (2861-2864, 3205-3208) — i.e. only for the manager burning its own tokens, and that account's owner must sign the burn. There is no path where `withdraw_lamports > floor(pool_tokens_burnt·T/S)`.

### 3.6 Deposit-flow abuse — **not possible**
* *Stale validator list*: impossible — deposits require `last_update_epoch == epoch` (2439-2441, 2702-2704), and `total_lamports` at that point was re-derived from chain balances with every record fresh (2230-2236).
* *Wrong stake state*: `DepositStake` re-reads the destination and derives the delta from **real lamports** and **real delegation** deltas (2451-2531); `stake_deposit_lamports` and `sol_deposit_lamports` must both be non-negative (`checked_sub`), and the SOL part is physically swept to the reserve (2619-2631) after the tokens are computed, so nothing can be double-counted.
* *Double deposit of one stake account*: the stake program's `Merge` drains the source and leaves it non-`Stake`; a second merge fails. `stake_merge` uses `merge_instruction[0]` = the `Merge` instruction (verified against `solana-stake-interface 4.2.0`, whose `merge()` returns a one-element vec).
* *CPI helper correctness* (I checked upstream rather than assuming): `split()` returns `[allocate, assign, split]` and the pool correctly invokes `.last()` (processor.rs:398-404) with metas `[stake(w), split_stake(w), authority(signer)]`; `delegate_stake`/`authorize`/`withdraw` metas match the pool's account lists (2451-2600 region, 331-561).
* *Authority-theft check*: the deposit `authorize` (2498-2504) is a **non-signed** `invoke`, so it can only succeed when the source stake account's current staker really is the deposit authority. With the deposit authority = the deposit PDA, an attacker can only donate their own stake — they must first sign an `Authorize` on their own account. They cannot make the pool ingest a pool-managed account, because those are owned by the *withdraw* authority, not the deposit authority. (Note: if a manager ever set `stake_deposit_authority == withdraw_authority`, stake-deposit theft becomes possible — that is a *privileged* footgun worth flagging; not the case here, verified: deposit auth = `4Y6X…`, withdraw auth = `AKJt…`.)

### 3.7 Arithmetic / rounding — **pool-favouring on every leg**
Raw `±` on value paths: none. Only `checked_*` (29 sites) and `saturating_*` (25 sites) touch lamports/amounts; I also confirmed the deployed `.so` has **no** `attempt to add/subtract with overflow` panic strings, i.e. it was built with `overflow-checks = false` (`raw ±` in `big_vec.rs`, which is `#![allow(clippy::arithmetic_side_effects)]`, is index arithmetic whose worst case is a panic → whole-instruction rollback). `BigVec` bounds are checked against the length prefix (`big_vec.rs:95-101, 110-116`), and `ValidatorStakeInfo`'s `PodU64` = `[u8;8]` gives it alignment 1, so `bytemuck::try_cast_slice_mut` never spuriously fails.

---

## 4. Candidate E-U path: the "un-swept inbound lamports" sandwich (and why it is NOT profitable)

This is the only place I found where a *fresh, permissionless* state asymmetry can be harvested by an unprivileged actor. I am reporting it with full quantification because it is the honest best-case for an attacker.

**Mechanism.** `T_stored = total_lamports` is only refreshed by `UpdateStakePoolBalance` (2282), and each record is only refreshed by `UpdateValidatorListBalance` (2165-2167) / `DepositStake` (2645). Lamports transferred *directly* into a pool validator stake account (a plain system transfer — no pool program involved) are therefore invisible to the pool until the next `UpdateValidatorListBalance`, which sweeps them to the reserve (2081-2098). Both instructions are **permissionless**. While such lamports are un-swept, `T_stored < T_real`, so a depositor mints tokens at a discount and — after re-running the update — can withdraw at the trued-up price.

**Step-by-step (all with the attacker's own funds):**
1. Precondition: `last_update_epoch == current epoch` (else go to step 2 anyway) and δ lamports of *third-party* inbound lamports sitting un-swept in pool stake accounts.
2. Attacker calls `DepositSol Δ` (permissionless; `sol_deposit_authority = None`) → receives `floor(Δ·S/T_stored)` tokens − deposit fee. (`DepositStake` works equally.)
3. Attacker calls `UpdateValidatorListBalance` for every validator record (≤4/pair per instruction → ~28 instructions) and then `UpdateStakePoolBalance`. **Both are permissionless and need no signatures** — this is the crux: the attacker can self-trigger the true-up.
4. Attacker calls `WithdrawStake` (or `WithdrawSol` up to the ~18.17 SOL reserve) and receives ≈ `tokens·T_real/S`.
5. Net ≈ `Δ·ε − Δ·0.001` where `ε = δ/T_real`.

**Preconditions / bounds.**
* δ must be supplied by someone else; an attacker donating their own δ recovers only their pro-rata share (net loss `(1−f)·δ`).
* Exit size: `WithdrawSol` is capped by the reserve (`reserve − rent ≈ 18.17 SOL`), so a large harvest needs `WithdrawStake`, which leaves ≥ `rent + 1 SOL` behind in each source stake account (3022-3025) and needs one pre-allocated destination stake account per split — throughput-limited but not blocking.
* The window is raced by the pool's own keeper: the observed tx history shows `UpdateValidatorListBalance` bundles running routinely, and the pool was updated in the current epoch.

**Measured magnitudes (my own reads, slot ≈ 457.27 M, epoch 1058):**

| Quantity | Value |
|---|---|
| `T_stored` | `1,101,114,884,155,839` lamports |
| `reserve_contrib = reserve.lamports() − rent(200B)` | `18,167,359,853` |
| `Σ records` | `1,101,096,716,795,986` (exactly `T_stored − reserve_contrib`) |
| `T_real = reserve_contrib + Σ live stake accounts` | `1,101,120,409,185,194` |
| δ (un-swept inbound lamports) | **`5,525,029,355` lamports = 5.525 SOL ⇒ ε = 5.02 × 10⁻⁶** |
| round-trip fee (deposit 5/10⁴ + withdraw 5/10⁴) | **1.0 × 10⁻³** |
| break-even δ needed to beat the fee | **> 0.1% × T = 1,101 SOL** |

⇒ **The attacker's edge is ~199× smaller than the fee. Expected value of the full sequence is negative (−0.000995 per unit deposited).** Even a 1,000 SOL un-swept donation would not pay for the round trip. Verdict: **not a viable E-U.**

**Provenance of δ (so this is not a pool bug):** I decoded the exact transaction that created the drift on record #14 (`52qokGjZ…`, δ = 490,827,886 lamports). Slot `457,091,792`, sig `3SxADdpTCZWjzqt6h7Di8RhKqC7fjzL2d3bAnFCzrpFip1MA7zFF9M4ujG9evmZpiPpcLfnq58Hj4w7oNec4Y1LC`: top-level instructions are `ComputeBudget`, `ComputeBudget`, and a **`RouterBmuRBkPUbgEDMtdvTZ75GBdSREZR5uGUxxxpb`** call whose inner CPI into `4R3gSG8BpU4t19KYj8CfnbtRpnT8gtk4dvTHxVRwc2r7` moves lamports from `CEtZmN63…` (**−490,827,886**) into the pool's stake account (**+490,827,886**), plus a Jito tip to `GJGRMLX…` (+1,178,560) from `6jWg4ost…`. The **pool program is not invoked at all** in that transaction — this is an inbound lamport transfer by a third party (an MEV/Jito-bundle style flow), not a pool accounting error. Just before it (slot 457,063,453) a genuine `UpdateValidatorListBalance` had swept `−79,601,149` out of the same account and set the record, and `getInflationReward(epoch 1057)` for that account returns `amount = 1,604,321,339`, `postBalance = 11,792,268,929,899` — which reconciles the whole history to the lamport:
`post-reward 11,792,268,929,899 − sweep 79,601,149 = 11,792,189,328,750 = record` ✓ and `record + 490,827,886 = 11,792,680,156,636 = live balance` ✓ (stable across a 3-minute poll; no mid-epoch crediting is happening).

---

## 5. Top 5 residual risks (all privileged unless stated)

**R1 — Upgradeable program with a live upgrade authority (HIGHEST).**
`getAccountInfo(SPoo1…)` → owner `BPFLoaderUpgradeab1e…`, tag 2, programdata `EmiU8AQkB2sswTxVB6aCmsAJftoowZGGDXuytm6X65R3`, `has_upgrade_authority = 1`, **upgrade authority `dPpFfahSWhm5M2RB3nVaHsXfnh9ooz5bWtR3WeUguDH`** (off-curve ⇒ likely a multisig vault), last deploy slot 429,882,117. Whoever controls that key can replace the code and drain the entire 1.1 M SOL. The byte-identity with the official `program@v2.1.0` asset is a *point-in-time* guarantee only, and I note an upgrade **buffer** artifact (`spoo1_upgrade_buffer.so`, 328 KB) exists in the parent tree — if a staged upgrade is pending, its contents should be reviewed before it lands.

**R2 — Staker is a single on-curve EOA (`QocTiqKmq654c5hxBitSUD7UKZH7JMzjkcNHeh917wk`), not a multisig.**
Staker powers (all reachable without the manager): `AddValidatorToPool` (point pool stake at a validator it runs and collect its commission), `SetPreferredValidator` (steer all deposits/withdrawals), `Increase/DecreaseValidatorStake` (shuffle stake between validators; each decrease burns ~0.002283 SOL of pool reserve into transient rent until it is merged back; mismatched transient seeds can wedge a validator until the right seed is used), `RemoveValidatorFromPool` (deactivate any validator — with a live transient, the default `no_merge=false` path calls `stake_merge` and **propagates** a `MergeMismatch` error, breaking the whole update). **No principal theft, but a single leaked key is a costly nuisance/DoS + a commission-diversion channel on ~1.1 M SOL.**

**R3 — Manager can confiscate the entire reward stream (Squads vault `7LqST…`).**
`SetFee(Epoch(100/100))` (allowed: `check_too_high` only caps at 100%) makes `calc_epoch_fee_amount` mint the manager's fee account ≈ the whole epoch reward, i.e. all future staking yield is diverted to the manager. Withdrawal fees can also be walked up (≤ ×1.5 +0.005 per epoch, hard cap 100%), which for a 100% fee would give the manager the entire burnt-token value. Two epochs' delay applies (`FutureEpoch`). Principal itself is not directly withdrawable by the manager: every exit path burns tokens the caller must own. Also in scope: `SetFundingAuthority` can attach/remove deposit+withdraw authorities, and `SetManager` can hand the role to a fresh key.

**R4 — Permissionless-update liveness/DoS (partially unprivileged).**
`UpdateValidatorListBalance` propagates CPI failures instead of skipping the offending pair (1979-2054, 2026-2035, 2087, 2109, 2140). A pool stake account that a third party can touch **without the pool's authority** — anyone may invoke the stake program's `DeactivateDelinquent` on a delinquent validator's delegated account — can be pushed into states that make the default update revert (e.g. active transient + deactivating validator stake → `MergeMismatch`). The escape hatch is `no_merge = true` (skips all merges), but if the keeper doesn't use it, `UpdateStakePoolBalance` never advances `last_update_epoch`, and **deposits *and* withdrawals freeze** (2439, 2846, 3198 all require `last_update_epoch == epoch`). Compounding factor: a record whose stake account can never be addressed/updated can never be flagged fresh, which would make the freeze permanent; today all 110 records are verified consistent (accounts exist, owner = stake program, staker = withdrawer = `AKJt…`, voter = the recorded vote, `deactivation_epoch = MAX`, one epoch fresh), but this is a standing fragility of the design.

**R5 — Fee-schedule dependence of the donation-drift free-ride (economic, conditional).**
The sandwich in §4 is only unprofitable because today's round-trip fee (0.1%) exceeds the realistically harvestable drift (5 × 10⁻⁶). Both terms are manager-controlled/observable: if the manager ever *lowers* the fees toward 0 (`SetFee` has no floor — `check_too_high` only caps the top, and the increase-limiter only restricts *increases*), or a third party parks >1,101 SOL of lamports in pool stake accounts between updates, the arbitrage becomes positive-EV for anyone with capital. Secondary: the `Some(reward_lamports)` branch at `state.rs:247-248` would mint an unbounded token amount if `total_lamports == epoch_fee_amount` (unreachable at today's T) — worth a defensive bound upstream.

*(Also noted, not scored: the pool account carries 176 bytes of stale legacy tail (space 611 vs the 435-byte v2.1.0 struct). Harmless today — only the first 435 bytes are deserialised and written — but any future version that appends fields would start by reading stale bytes from the ex-AeroPool layout.)*

---

## 6. Reproduction (all artifacts in `analysis/child-a/`)

| File | Purpose |
|---|---|
| `processor.rs`, `state.rs`, `instruction.rs`, `lib.rs`, `big_vec.rs`, `error.rs` | verified copies of the v2.1.0 tag sources |
| `decode_pool_v210.py` | strict borsh decoder for `StakePool` (note `Fee { denominator, numerator }` order) |
| `decode_vlist_v210.py` | strict decoder for `ValidatorList` + PDA derivation of every validator stake account (`vlist_decoded_child_a.txt`, `derived_validator_stakes.json`) |
| `pda.py` | pure-python ed25519 `find/create_program_address` (used to prove deposit auth == deposit PDA, and the withdraw-authority bump 255) |
| `verify_records_vs_chain.py`, `check_consistency_now.py` | record↔chain reconciliation and the `T_stored` / `T_real` delta (`consistency_now.json`) |
| `drift_analysis.py`, `poll_lamports.py`, `dump_tx.py`, `decode_one_tx.py` | provenance of the drift (donation transaction decoding, stability polling) |

Nothing in this review signed, sent, or simulated a transaction; all network access was read-only JSON-RPC against public keyless endpoints, and no keys are stored anywhere in the tree.
