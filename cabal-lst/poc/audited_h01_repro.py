#!/usr/bin/env python3
"""
audited_h01_repro.py — reproduces C4 2025-04-cabal H-01 on the AUDITED source arithmetic.

This is a faithful, dependency-free model of `sources/cabal.move@5b5f92ab4f95e5f9f405bbfa252860472d164705`
(exactly the code the wardens tested with `initiad move test -f test_poc`). It is NOT a live
interaction — it replays the audit's own PoC scenario and the audited share/asset formulas.

Scenario (audit PoC):
  A stakes 100 LP  -> supply 100, delegated 100
  B stakes 50 LP   -> supply 150, delegated 150
  B unstakes 50    -> shares burned to 100, unstaked_pending_amounts = 50
  A unstakes 50    -> audited code pays 75 for 50 shares' worth (fair: 50)
"""
from fractions import Fraction as F

def audited_process_lp_unstake(unstake_amount, supply_after_burn, reward, real_total_stakes):
    """process_lp_unstake @5b5f92a L1043-L1085."""
    lp_amount = reward + real_total_stakes            # gross, includes burned-pending
    ratio = F(unstake_amount, supply_after_burn)      # supply read AFTER the burn
    return ratio * lp_amount                          # -> over-claim

def audited_process_lp_stake(stake_amount, supply, reward, real_total_stakes):
    """process_lp_stake @5b5f92a L938-L987."""
    lp_amount = reward + real_total_stakes
    if supply == 0:
        return stake_amount
    ratio = F(stake_amount, lp_amount)
    return ratio * supply                             # no pending term -> under-mint

def run():
    print("=== C4 H-01 audit PoC replay (audited arithmetic) ===")
    supply, delegated = 0, 0
    supply += 100; delegated += 100                   # A stakes 100
    supply += 50;  delegated += 50                    # B stakes 50
    # B unstakes 50: process runs (pre-burn supply=150), then burn 50
    b_amt = audited_process_lp_unstake(50, supply, 0, delegated)
    supply -= 50
    pending = b_amt
    # A unstakes 50: process (supply=100, delegated still 150), then burn
    a_amt = audited_process_lp_unstake(50, supply, 0, delegated)
    print(f"  B (50 shares) got {b_amt}  (fair 50)")
    print(f"  A (50 shares) got {a_amt}  (fair 50)   <-- audit PoC: '75'")
    over = a_amt - 50
    print(f"  over-claim by A = {over} LP, taken from remaining holders (pending={pending})")
    assert b_amt == 50 and a_amt == 75, (b_amt, a_amt)
    print("  -> REPRODUCED: audited code over-pays when unstaked_pending_amounts > 0")
    print()
    print("=== inverse: audited process_lp_stake under-mints while pending>0 ===")
    # state: supply=100 (B's 50 burned), pending=50 (not yet batched), real stakes A=150
    minted = audited_process_lp_stake(50, supply=100, reward=0, real_total_stakes=150)
    fair   = F(50, 150) * (100 + 50)     # new staker should own 50/200 of assets -> 50 shares
    print(f"  stake 50 with supply=100, pending=50, real=150 -> minted {float(minted):.2f} (fair {float(fair):.2f})")
    assert minted < fair
    print("  -> REPRODUCED (users receive too few shares; pending term missing)")
    return {"audited_A_payout": a_amt, "fair_A_payout": 50, "over_claim": over}

if __name__ == "__main__":
    r = run()
    print("\nRESULT:", r)
