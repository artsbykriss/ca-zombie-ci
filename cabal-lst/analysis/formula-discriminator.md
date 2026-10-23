# Deployed vs audited: the H-01 path, from live Move bytecode

Method: `GET /initia/move/v1/accounts/<addr>/modules/<name>` returns the module **ABI +
`raw_bytes` (the compiled Move bytecode, base64)**. We decoded `raw_bytes` and disassembled it
with `aptos move disassemble --bytecode-path cabal.mv` (aptos-cli 9.6.0). The Initia Move
binary format is compatible with the aptos disassembler. Full disassembly:
`analysis/disasm-cabal.mv.masm`.

## The audited (buggy) arithmetic — `sources/cabal.move@5b5f92a`
```
process_lp_unstake:
  lp_amount   = compound_reward + pool_router::get_real_total_stakes(stake_meta)   // gross: still includes the
                                                                                   // tokens backing already-burned shares
  cabal_lp    = supply(cabal_token)          // live share supply at process time
  unbonding   = (unstake_amount / cabal_lp) * lp_amount                            // OVER-CLAIM when pending > 0

process_lp_stake:
  lp_amount   = reward + get_real_total_stakes(stake_meta)
  cabal_lp    = supply
  mint        = (stake_amount / lp_amount) * cabal_lp                              // UNDER-MINT (no pending term)

get_estimate_unstake_amount: same over-stated formula as process_lp_unstake.
```
The over-claim is driven by the **numerator** `lp_amount` containing `unstaked_pending_amounts`
(whose shares are already burned): the unstaker is credited `(unstake_amount / supply) × pending`
that belongs to prior unstakers. The audit PoC (whose `mock_unstake` runs the process step
*before* the burn, matching `initiate_unstake`'s call order) yields A = 75 for 50 shares (fair
50). Whether the queued process observes pre- or post-burn supply, the pending term makes it
over-claim whenever `unstaked_pending_amounts > 0`; the deployed code resolves both readings.

## The deployed (fixed) arithmetic — `cabal` module `0x53c3f5d8…` (live bytecode)
`unstaked_pending_amounts[i]` = sum of burned LP **share** amounts not yet turned into a
validator undelegation. The live code adds it back into the **supply denominator** everywhere:

```
process_lp_stake (disasm L3754):
  l7 = reward + get_real_total_stakes(stake_meta)      // gross assets A
  l9 = supply(cabal_token) + unstaked_pending_amounts[type]   // <-- FIX: S_eff = supply + pending
  mint = (stake_amount / l7) * l9   (== stake_amount * S_eff / A)

process_lp_undelegate (disasm L3888):
  l6 = reward + get_real_total_stakes(stake_meta)      // A (after restaking reward)
  l8 = supply_after_burn + unstake_amount              // <-- FIX: supply BEFORE the burn == S_eff
  unbonding = (unstake_amount / l8) * l6               // = (pending / S_eff) * A   -> correct
  pool_router::unlock(stake_meta, unbonding)           // undelegate immediately

get_estimate_unstake_amount (disasm L2595) and
get_cabal_stake_token_price_rel_to_underlying (disasm L2057):
  price = get_real_total_stakes / (supply + unstaked_pending_amounts[type])   // <-- FIX
```

The over-claiming formula is **gone**: every denominator that the audit left as bare `supply`
is now `supply + unstaked_pending_amounts` (or `supply_after_burn + pending`, identical).

## Live behavioural oracle (the clincher)
Pool 1 = USDC-INIT LP (`cbl-USDC-INIT`), at height **23,352,892**:
```
supply(cabal_token[1])              = 2,726,911,250,625
unstaked_pending_amounts[1]         =        63,778,039   (63.778 LP, nonzero!)
get_real_total_stakes(LP)           = 4,737,924,767,617
```
`get_estimate_unstake_amount(1, 1_000_000)` live returned **`1,737,428`**.
```
audited  formula = 1_000_000 * real / supply             = 1,737,469   (MISMATCH)
deployed formula = 1_000_000 * real / (supply + pending) = 1,737,428   (EXACT MATCH)
```
Same for `get_cabal_stake_token_price_rel_to_underlying(1)` live = **`1.737428732502257193`**
= `4,737,924,767,617 / 2,726,975,028,664` (the +pending denominator), **not**
`4,737,924,767,617 / 2,726,911,250,625 = 1.7374693…`.

The nonzero pending (63.778 LP) means the audited and deployed formulas would differ; the live
chain returns the **deployed (fixed)** value. This is a direct, unprivileged read that could
only be produced by the patched code.

## Re-running the audit's own PoC against both formulas
`poc/audited_h01_repro.py` (audited source arithmetic) and `poc/deployed_fix_check.py`
(deployed bytecode arithmetic), using the audit PoC scenario (A=100, B=50, B unstakes, A
unstakes half):
```
audited : B gets 50, A gets 75   (fair 50)   -> 25 LP stolen from other holders
deployed: B gets 50, A gets 50   (fair 50)   -> fixed
```
