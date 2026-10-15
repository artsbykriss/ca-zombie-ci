# IOTA L1 framework staking semantics (as deployed on IOTA mainnet)

**Provenance of the source files in this folder** (fetched 2026-10-15, keyless `raw.githubusercontent.com`):

| file | URL | notes |
|---|---|---|
| `staking_pool.move` | `iotaledger/iota` `develop` → `crates/iota-framework/packages/iota-system/sources/staking_pool.move` | 511 lines |
| `validator.move` | same tree | 949 lines |
| `validator_set.move` | same tree | 1691 lines |
| `iota_system.move` | same tree | 804 lines |
| `iota_system_state_inner.move` | same tree | 1192 lines |
| `coin.move`, `balance.move` | `crates/iota-framework/packages/iota-framework/sources/` | reference |

`develop` and `mainnet` branches were fetched for the four `iota-system` files and are **byte-identical** (`diff -q` → identical).
**Deployment check (partial, honest):** the on-chain module `0x3::staking_pool` (fetched with `iota_getNormalizedMoveModulesByPackage` at checkpoint 204,076,768, epoch 528)
exposes exactly the same set of public functions as the source file, the *only* difference being `calculate_rewards`, which is
`#[test_only]` in the source (line 485) and therefore correctly absent on chain. Struct set on chain is
`PoolTokenExchangeRate, StakedIota, StakingPoolV1` — identical to the source. **No bytecode-level comparison was done**, so if the
branch moved after the last framework upgrade the source could in principle differ from the deployed bytecode; the
function-signature match makes this unlikely but it is not proven.

---

## 1. `request_add_stake` — when a stake becomes active

`staking_pool.move:107-124` (the pool-level function) and `validator.move:270-290` (the validator wrapper):

```move
// validator.move:270-290
public(package) fun request_add_stake(
    self: &mut ValidatorV1,
    stake: Balance<IOTA>,
    staker_address: address,
    ctx: &mut TxContext,
): StakedIota {
    let stake_amount = stake.value();
    assert!(stake_amount > 0, EInvalidStakeAmount);
    let stake_epoch = ctx.epoch() + 1;                              // <-- stake_activation_epoch
    let staked_iota = self.staking_pool.request_add_stake(stake, stake_epoch, ctx);
    // Process stake right away if staking pool is preactive.
    if (self.staking_pool.is_preactive()) {
        self.staking_pool.process_pending_stake();
    };
    self.next_epoch_stake = self.next_epoch_stake + stake_amount;
    event::emit(StakingRequestEvent { ... });
    staked_iota
}
```

```move
// staking_pool.move:106-124
/// Request to stake to a staking pool. The stake starts counting at the beginning of the next epoch,
public(package) fun request_add_stake(pool, stake, stake_activation_epoch, ctx): StakedIota {
    let iota_amount = stake.value();
    assert!(!is_inactive(pool), EDelegationToInactivePool);
    assert!(iota_amount > 0, EDelegationOfZeroIota);
    let staked_iota = StakedIota { id: object::new(ctx), pool_id: object::id(pool),
                                   stake_activation_epoch, principal: stake };
    pool.pending_stake = pool.pending_stake + iota_amount;
    staked_iota
}
```

* `stake_activation_epoch = ctx.epoch() + 1` is written by the **validator** module, not the pool module.
* The new stake is added to `pool.pending_stake`; for a *preactive* (not yet activated) pool it is processed immediately
  (`process_pending_stake`, staking_pool.move:253-262) so that the depositor does not lose the first epoch.
* Returned object: a **`StakedIota`** (self-custodial, `key + store`). It is transferred to the sender by the entry wrapper;
  `request_add_stake_non_entry` (`iota_system.move:230-238`) returns it instead of transferring, for use inside PTBs:
  `let staked_iota = request_add_stake_non_entry(wrapper, stake, validator_address, ctx);`
* Minimum amount: `MIN_STAKING_THRESHOLD = 1_000_000_000` (1 IOTA) is enforced in `validator_set.move:397` for the
  staker-facing path (`assert!(iota_amount >= MIN_STAKING_THRESHOLD, EStakingBelowThreshold)`).
* **Permissionless**: the entry takes only the shared `IotaSystemState` (0x5), a `Coin<IOTA>` and a validator address.
  No validator consent, no cap. The target may be an active *or candidate* validator
  (`get_candidate_or_active_validator_mut`, validator_set.move:400).

## 2. `request_withdraw_stake` — the exact epoch gate

`staking_pool.move:126-177`. This is the whole gate:

```move
public(package) fun request_withdraw_stake(
    pool: &mut StakingPoolV1,
    staked_iota: StakedIota,
    ctx: &TxContext,
): Balance<IOTA> {
    // stake is inactive
    if (staked_iota.stake_activation_epoch > ctx.epoch()) {          // <-- line 135
        let principal = unwrap_staked_iota(staked_iota);
        let withdraw_amount = principal.value();
        if (pool.is_preactive()) {
            pool.iota_balance = pool.iota_balance - withdraw_amount;
            pool.pool_token_balance = pool.pool_token_balance - withdraw_amount;
            check_balance_invariants(pool, ctx.epoch());
        } else {
            pool.pending_stake = pool.pending_stake - withdraw_amount;
        };
        return principal                                             // <-- line 152: principal only, immediately
    };

    let (pool_token_withdraw_amount, mut principal_withdraw) =
        withdraw_from_principal(pool, staked_iota);
    let principal_withdraw_amount = principal_withdraw.value();
    let rewards_withdraw = withdraw_rewards(pool, principal_withdraw_amount,
                                            pool_token_withdraw_amount, ctx.epoch());
    let total_iota_withdraw_amount = principal_withdraw_amount + rewards_withdraw.value();
    pool.pending_total_iota_withdraw =
        pool.pending_total_iota_withdraw + total_iota_withdraw_amount;
    pool.pending_pool_token_withdraw =
        pool.pending_pool_token_withdraw + pool_token_withdraw_amount;
    // TODO: implement withdraw bonding period here.                        <-- line 174
    principal_withdraw.join(rewards_withdraw);
    principal_withdraw                                                // <-- line 176
}
```

**Exact semantics**

1. **If `stake_activation_epoch > ctx.epoch()`** — i.e. the stake was created in the current epoch and has not been
   activated yet — the function **immediately returns the principal** (`return principal`, line 152), with **zero rewards**.
   The pool's bookkeeping is fixed up inline: for a preactive pool both `iota_balance` and `pool_token_balance` are
   decremented; for an active pool `pending_stake` is decremented (line 149).
2. **Otherwise** (stake already active, `stake_activation_epoch <= ctx.epoch()`) the function computes
   `pool_token_withdraw_amount` from the **exchange rate at the staking epoch** (`withdraw_from_principal`,
   lines 182-200), then the rewards from the **exchange rate at the current epoch** (`withdraw_rewards`, lines 271-286),
   joins them and **returns principal + rewards immediately** (line 175-176).
3. **It never returns 0 and never parks the request.** There is no code path that returns an empty balance: the
   `pending_total_iota_withdraw` / `pending_pool_token_withdraw` fields (lines 169-172) are *only* pool accounting —
   they are drained at the next epoch boundary by `process_pending_stake_withdraw` (lines 245-250), which is called from
   `process_pending_stakes_and_withdraws` (line 229) during `advance_epoch`. The comment `// TODO: implement withdraw
   bonding period here.` (line 174) is explicit that a delay is **not** implemented.
4. `EWithdrawalInSameEpoch` (`const EWithdrawalInSameEpoch: u64 = 13;`, line 29) is **declared but never used** anywhere in
   the module — there is no "cannot withdraw in the same epoch" abort. The only same-epoch effect is rule 1 (principal
   without rewards).
5. The **entry point** (`iota_system.move:254-271`) transfers the returned balance to the sender in the same transaction:

```move
public entry fun request_withdraw_stake(wrapper, staked_iota, ctx) {
    let withdrawn_stake = request_withdraw_stake_non_entry(wrapper, staked_iota, ctx);
    transfer::public_transfer(withdrawn_stake.into_coin(ctx), ctx.sender());
}
```

6. **Documentation/vs-code mismatch worth knowing:** `validator_set.move:404-410` still says *"the request is added to the
   validator's staking pool's pending stake withdraw entries, processed at the end of the epoch"*, and
   `validator.move:337` is titled *"Request to withdraw stake … processed at the end of the epoch"*, but the implementation
   returns the funds immediately — the pending entries only re-balance the pool at the epoch boundary.
7. **Permissionless**: any address may call it; only the `StakedIota` object (which is self-custodial) and the shared
   `IotaSystemState` are required. No validator cooperation, no cap, no queue, no fee.

**Reward split** (`validator.move:337-361`) emits `0x3::validator::UnstakingRequestEvent { principal_amount, reward_amount }`
where `reward_amount = withdraw_amount - staked_iota.principal`.

## 3. How rewards accrue, and when they are claimable/visible

* At each epoch boundary the protocol calls `deposit_rewards` (staking_pool.move:219-222), which moves the epoch's rewards
  into `pool.rewards_pool` (`iota_balance += rewards.value(); rewards_pool.join(rewards)`).
* Immediately after, `process_pending_stakes_and_withdraws` (lines 224-241) settles the epoch's pending stake/withdraws and
  snapshots the new exchange rate: `exchange_rates.add(new_epoch, PoolTokenExchangeRate { iota_amount: pool.iota_balance,
  pool_token_amount: pool.pool_token_balance })`.
* A `StakedIota` never changes; its value is `principal × rate(current_epoch) / rate(stake_activation_epoch)`
  (`withdraw_rewards`, lines 271-286). Rewards are therefore **claimable as soon as the epoch-boundary rate entry for the
  current epoch exists**, i.e. after the first epoch roll-over following activation. They are *visible* to a user only by
  unstaking (the framework has no "claim rewards only" function for `StakedIota`); the events
  `StakingRequestEvent`/`UnstakingRequestEvent` expose the amounts.
* Rewards are paid **out of the pool's `rewards_pool`** and are capped by its balance:
  `reward_withdraw_amount = reward_withdraw_amount.min(pool.rewards_pool.value());` (line 284). If the pool's rewards are
  smaller than the theoretical amount the staker simply gets less (the code has a `// TODO: FIGURE OUT EXACTLY WHY THIS CAN
  HAPPEN.` comment at line 283 — this is the framework's own acknowledged edge case).

## 4. Who can call staking / what it needs

| function | who | needs |
|---|---|---|
| `iota_system::request_add_stake` (iota_system.move:219) | anyone | shared `IotaSystemState` 0x5, `Coin<IOTA>` ≥ 1 IOTA, validator address |
| `iota_system::request_add_stake_non_entry` (:230) | anyone (PTB) | same, returns `StakedIota` |
| `iota_system::request_withdraw_stake` (:254) | anyone | shared 0x5 + owned `StakedIota` |
| `iota_system::request_withdraw_stake_non_entry` (:264) | anyone (PTB) | same, returns `Balance<IOTA>` |

Both are plain `public entry`/`public fun` with no capability requirement — the only authority is the shared system state
object and ownership of the `StakedIota`. Validators are not involved.

## 5. `StakedIota` object

```move
// staking_pool.move:73-82
/// A self-custodial object holding the staked IOTA tokens.
public struct StakedIota has key, store {
    id: UID,
    /// ID of the staking pool we are staking with.
    pool_id: ID,
    /// The epoch at which the stake becomes active.
    stake_activation_epoch: u64,
    /// The staked IOTA tokens.
    principal: Balance<IOTA>,
}
```

* Can be **split** (`split`, line 345; both parts ≥ 1 IOTA) — `split_staked_iota` is an entry function.
* Can be **joined** (`join`, line 371) only if `pool_id` **and** `stake_activation_epoch` match (`is_equal_staking_metadata`,
  line 388). This matters for LSTs: a pool holding many `StakedIota` receipts can only merge those from the same validator
  *and* the same activation epoch.
* `pool_id` is the staking pool's UID; the validator's staking pool can be resolved to a validator via
  `iota_system::validator_address_by_pool_id` (iota_system.move:479).

## 6. Framework version on IOTA mainnet

* Best-effort only. Framework packages are `0x1` (framework), `0x2` (std/sui-compat), `0x3` (iota-system); their object
  versions were `4`, `16`, `13` respectively at checkpoint 204,076,768, and `0x5` is the shared `IotaSystemState`
  (wrapper `version: 2` → inner `IotaSystemStateV2`, iota_system.move:571-587).
* IOTA upgrades the framework only through protocol-version upgrades; the object versions above are lamport versions of the
  publish/upgrade transactions, **not** a protocol version. I did not download `iota_getProtocolVersion`-style metadata, so
  the exact framework release string is **not** determined. What is established is that the deployed
  `0x3::staking_pool` / `0x3::validator` / `0x3::iota_system` **ABIs match the `develop`/`mainnet` branch source fetched
  here** (function set identical apart from `#[test_only]` functions).
