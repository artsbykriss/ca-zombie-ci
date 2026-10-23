# Annotated live disassembly — the H-01-relevant functions

Source: `analysis/disasm-cabal.mv.masm` (disassembly of the live `cabal` module
`0x53c3f5d8…`, bytecode sha256 `36379fa2…c90a5`). Line numbers refer to that file.
Notation: `lN` = local slot; comments in `#` are mine.

## `process_lp_stake` (L3754) — stake side of H-01
```
l7  = fungible_asset::amount(compound_lp_pool_rewards(...))     # reward
      + pool_router::get_real_total_stakes(stake_metadata[type]) # A (gross)
l8  = fungible_asset::supply(cabal_stake_token_metadata[type])  # Option<u128>
l9  = l8.extract() + unstaked_pending_amounts[type]             # <<< S_eff = supply + pending  (H-01 FIX)
if l9 == 0:
    mint = stake_amount                                          # (bootstrap, unchanged)
else:
    mint = bigdecimal::mul_by_u128_truncate(
               bigdecimal::from_ratio_u64(stake_amount, l7),     # stake_amount / A
               l9)                                               # * S_eff
cabal_token::mint_to(mint_cap, staker, mint)
```
Audited version used `from_ratio_u64(stake_amount, lp_amount)` × **`supply`** (no pending term).

## `process_lp_undelegate` (L3888) — replaces audited `process_lp_unstake`
```
l5  = compound_lp_pool_rewards(...)                 # reward FA
l6  = fungible_asset::amount(l5)                    # reward
      pool_router::add_stake(l5)                    # restake reward
l6  = l6 + pool_router::get_real_total_stakes(stake_metadata[type])   # A (gross)
l7  = fungible_asset::supply(cabal_stake_token_metadata[type])        # Option<u128>
l8  = l7.extract() + unstake_amount(l2)             # <<< S_eff = supply_after_burn + pending = supply BEFORE burn
l6  = bigdecimal::mul_by_u64_truncate(
          bigdecimal::from_ratio_u128(unstake_amount, l8),   # pending / S_eff
          l6)                                                # * A
pool_router::unlock(stake_metadata[type], l6)       # undelegate l6 immediately
```
Audited version: `from_ratio_u128(unstake_amount, supply)` × `(reward + real_stakes)` — no add-back.

## `get_estimate_unstake_amount` (L2595) — the permissionless oracle
```
l3  = pool_router::get_real_total_stakes(stake_metadata[type])
l5  = fungible_asset::supply(cabal_stake_token_metadata[type]).extract()
      + unstaked_pending_amounts[type]              # <<< S_eff = supply + pending
result = mul_by_u64_truncate(from_ratio_u128(unstaking_amount, l5), l3)   # amount/S_eff * real
```

## `get_cabal_stake_token_price_rel_to_underlying` (L2057)
```
pool 0  -> get_sxinit_to_init_price
pool !=0 -> bigdecimal::from_ratio_u128(
                pool_router::get_real_total_stakes(stake_metadata[type]),
                fungible_asset::supply(...).extract() + unstaked_pending_amounts[type])  # <<< FIX
```

## `batch_undelegate_pending_lps` (L681) — permissionless trigger
```
assert block_time > last_undelegate_time + 259200            # 3-day rate limit
last_undelegate_time = block_time
for each pool i with unstaked_pending_amounts[i] != 0:
    pool_router::request_claim_rewards(stake_metadata[i])
    cosmos::move_execute(assets_store_signer, "cabal", "process_lp_undelegate", [i, unstaked_pending_amounts[i]])
    unstaked_release_amount[i] += unstaked_pending_amounts[i]
    unstaked_pending_amounts[i] = 0
```
No signer argument / no role check → any account can advance the pending batch.

## `unstake_lp` (L4532) — records the SHARE amount, not underlying
```
unstaked_pending_amounts[type] += unstaking_amount
push UnbondingEntry { pool_index: type, metadata, amount: unstaking_amount, release_time: now + unbond_period[type] }
```
(Underlying conversion happens later in `process_lp_undelegate`; the claim step
`claim_unbonded_assets_internal` distributes `get_real_total_unbonding + balance` pro-rata over
`unstaked_release_amount` — share-denominated and pending-aware.)
