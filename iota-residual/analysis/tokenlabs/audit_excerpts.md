# MoveBit / BitLab audit of TokenLabs — excerpts

* PDF downloaded 2026-10-15 from `https://movebit.xyz/reports/20260202-Tokenlabs-Final-Audit-Report.pdf`
  (HTTP 200, 343,719 bytes, 19 pages) — copy saved in this folder as `movebit_audit_2026-01-14.pdf`.
* Report: **Wed Jan 14 2026**, auditors `jolyon`, `s3cunda`, type DeFi, language Move, platform IOTA.
* Source code listed in the report: `https://github.com/Tokenlabs-LLC/LST`
  commits `9973d19b248be3fe96f6116655214fe75d49fe14`, `a7a27c7c08f3aa179cceedb4ecef544c8904ebc4`.
  **As of 2026-10-15 that GitHub repository is NOT reachable** — `api.github.com/repos/Tokenlabs-LLC/LST` and
  `raw.githubusercontent.com/...` both return **404** (deleted or made private). No source could be downloaded from it;
  everything below is extracted from the PDF text.
* In-scope files (`liquid_staking_v2/`): `Move.toml`, `sources/native_pool.move`, `sources/math.move`,
  `sources/validator_set.move`, `sources/ownership.move`, `sources/cert.move`.
* Issue statistics: total 6 — Critical 0, Major 0, **Medium 2**, Minor 3, Informational 1; all fixed.

## Findings (titles + the parts that reveal the code's semantics)

### MAT-4 — "Minimum Share Minting with Asymmetric Rounding May Inflate Share Supply" (Medium, Fixed)
Code location `math.move#40`. The report quotes the *pre-fix* function; the shape of the arithmetic is what matters:

```move
public fun to_shares(ratio: u256, amount: u64): u64 {
    let mut shares = ((amount as u256)) * ratio / RATIO_MAX;
    assert!(shares <= (U64_MAX as u256), E_U64_OVERFLOW);
    // Ensure at least 1 share if amount > 0
    if (amount > 0 && shares == 0) { shares = 1; };
    (shares as u64)
}
```

Fix (commit `8aaca7a1b6f5a5fbf4b5e2c5786a2771cc25e755`): *"removing the forced minimum-share minting logic and instead
rejecting deposits that are too small to mint at least one share"*.

⇒ **Confirmed arithmetic**: shares = `amount * ratio / RATIO_MAX`, with `ratio` a U256 fixed-point number and
`RATIO_MAX` its scale. `math::ratio(U64, U64) -> U256` produces that fixed-point value. Rounding is **down** (integer div),
and the deployed code must mint ≥ 1 share or abort (post-fix behaviour).

### NPO-1 — "Missing Events for State Changes" (Minor, Fixed)
Affected functions named explicitly: `update_validators`, `update_rewards_revert`, `update_rewards`, `rebalance`.
Fixed in commit `f457cc87c5e8566122072ef2e6d31b952176a6f5` — *"adding event emissions for critical state changes"*.
⇒ This is why the on-chain v1/v2 modules have `RewardsUpdated`, `RebalancedEvent`(sic: `RebalanceEvent`),
`ValidatorsUpdatedEvent`, `RewardsRevertedEvent` event types.

### NPO-2 — "Missing Version Checks in Added Entry Functions" (Minor, Fixed)
`update_rewards_revert`, `add_pending`, `set_pause` could be executed without the module's version check; fixed by
*"add[ing] a version check at the beginning of all state-mutating entry and public functions"*.
⇒ The pool has a `version` field used as a migration guard (`NativePool.version` is `2` on mainnet).

### NPO-3 — "Missing Zero-Value Check in `add_pending`" (Informational, Fixed)
Quoted pre-fix code (note the **unused** cap parameter — the cap is required as an argument but never inspected):

```move
public entry fun add_pending(self: &mut NativePool, coin: Coin<IOTA>, _operator_cap: &OperatorCap) {
    let prev_value = balance::value(&self.pending);
    let coin_balance = coin::into_balance(coin);
    balance::join(&mut self.pending, coin_balance);
    event::emit(PendingValueAddedEvent { prev_value, new_value: balance::value(&self.pending) });
}
```

### NPO-7 — "Missing update function on `collectable_fee`" (Medium, Fixed)
Quoted pre-fix `collect_fee_non_entry`; shows how protocol fees are funded:

```move
fun collect_fee_non_entry(self: &mut NativePool, wrapper: &mut IotaSystemState, ctx: &mut TxContext): Coin<IOTA> {
    let available = balance::value(&self.collectable_fee);        // <= always 0
    let mut fee_coin = coin::from_balance(balance::split(&mut self.collectable_fee, available), ctx);
    // If buffer doesn't have enough, withdraw the rest from validators
    if (available < self.collected_rewards) {                     // <= always true
        let needed = self.collected_rewards - available;          // <= entire collected_rewards
        let validators = validator_set::get_validators(&self.validator_set);
        coin::join(&mut fee_coin,
            unstake_amount_from_validators(self, wrapper, needed, validators, ctx));
    };
    // Update accounting
    self.collected_rewards = self.collected_rewards - coin::value(&fee_coin);
    fee_coin
}
```

Fix: the unused `collectable_fee` variable was removed (commit `f457cc87…`).
⇒ **Fees are paid by un-staking from the pool's validator vaults** (`unstake_amount_from_validators`), scaled by the
`collected_rewards` counter, and `collected_rewards` is decremented by the amount actually paid.

### VSE-5 — "Incorrect Upper Bound Check for Validator Updates" (Minor, Fixed)
`validator_set.move#99`: `assert!(len < MAX_VLDRS_UPDATE, E_TOO_MANY_VLDRS);` rejected `len == MAX_VLDRS_UPDATE`; fixed to `<=`.

## Actors / capability model as stated by the audit (section 3, p.8)

*Admin (owns `OwnerCap`/`OperatorCap`)*: `change_min_stake`, `change_base_reward_fee`,
`change_max_validator_stake_per_epoch`, `update_validators`, `update_rewards_threshold`, `update_rewards_revert`,
`update_rewards`, `add_pending`, `collect_fee_new`, `set_pause`, `migrate`.
*User*: `stake`, `stake_to_validators`, `unstake`.
*Anyone*: `rebalance` — *"Move staked IOTA from bad validators into other validators."*

⇒ The audit itself classifies `rebalance` as a **permissionless** operation.
