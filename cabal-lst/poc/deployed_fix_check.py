#!/usr/bin/env python3
"""
deployed_fix_check.py — verifies the DEPLOYED (live) Cabal Move code no longer has H-01.

Two independent checks:
  (1) FORMULA MODEL of the deployed bytecode (cabal module 0x53c3f5d8…, disassembled to
      analysis/disasm-cabal.mv.masm). Shows the audit PoC now pays the correct amounts.
  (2) LIVE ORACLE: reads the live chain and checks that the deployed (fixed) formula matches
      the returned values while the audited (buggy) formula does not.

Run:  python3 deployed_fix_check.py            # uses https://rest.initia.xyz (public, keyless)
Exit code 0 = deployed code is patched for H-01.
"""
import json, sys, urllib.request, urllib.error
from fractions import Fraction as F

ADDR = "0x53c3f5d8e11844ba3747ebaec1b2d25051574ffbeedc69d72068395991e3ea28"
REST = "https://rest.initia.xyz"
LP   = "0x543b35a39cfadad3da3c23249c474455d15efd2f94f849473226dee8a3c7a9e1"
POOL = 1  # USDC-INIT LP pool

# ---- (1) deployed formula model (from disasm L3754 / L3888 / L2595 / L2057) ----
def deployed_process_lp_undelegate(pending_shares, supply_after_burn, reward, real_total_stakes):
    A = reward + real_total_stakes
    s_eff = supply_after_burn + pending_shares        # supply BEFORE the burn
    return F(pending_shares, s_eff) * A

def deployed_process_lp_stake(stake_amount, supply, pending, reward, real_total_stakes):
    A = reward + real_total_stakes
    s_eff = supply + pending
    return stake_amount if s_eff == 0 else F(stake_amount, A) * s_eff

def deployed_get_estimate(unstake_amount, supply, pending, real_total_stakes):
    return F(unstake_amount, supply + pending) * real_total_stakes

def audited_get_estimate(unstake_amount, supply, real_total_stakes):
    return F(unstake_amount, supply) * real_total_stakes

def model():
    print("=== (1) deployed-formula model on the audit PoC scenario ===")
    supply, delegated = 150, 150
    # B unstakes 50 -> pending=50, burn -> supply 100
    b = deployed_process_lp_undelegate(50, 100, 0, 150)   # pending batch of 50
    supply, delegated = 100, 100                          # unlock 50
    # A unstakes 50 -> pending=50, burn -> supply 50
    a = deployed_process_lp_undelegate(50, 50, 0, 100)
    print(f"  B (50 shares) got {b} (fair 50);  A (50 shares) got {a} (fair 50)")
    assert b == 50 and a == 50, (b, a)
    print("  -> deployed code pays 50/50: H-01 over-claim GONE")
    # stake side: supply=100, pending=50, real=150 -> new staker should own 50/200 of assets = 50 shares
    dep_mint = deployed_process_lp_stake(50, 100, 50, 0, 150)
    aud_mint = F(50, 150) * 100                       # audited formula (no pending term)
    print(f"  stake-side: deployed mint {float(dep_mint):.2f} (correct), audited mint {float(aud_mint):.2f} (under-mint)")
    assert dep_mint == 50 and aud_mint < 50

# ---- (2) live oracle ----
def view(mod, fn, args):
    body = json.dumps({"address": ADDR, "module_name": mod, "function_name": fn,
                       "args": args, "typeArgs": []}).encode()
    req = urllib.request.Request(REST + "/initia/move/v1/view/json", data=body,
                                 headers={"Content-Type": "application/json",
                                          "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=40) as r:
        return json.loads(r.read().decode())["data"]

def oracle():
    print("\n=== (2) live oracle (Initia mainnet, public REST) ===")
    supply  = int(json.loads(view("cabal", "get_cabal_token_total_supply", ['"%d"' % POOL])))
    pending = int(json.loads(view("cabal", "get_lp_pool_unstaked_pending_amount", ['"%d"' % POOL])))
    real    = int(json.loads(view("pool_router", "get_real_total_stakes", ['"%s"' % LP])))
    live_est = int(json.loads(view("cabal", "get_estimate_unstake_amount", ['"%d"' % POOL, '"1000000"'])))
    live_price = float(json.loads(view("cabal", "get_cabal_stake_token_price_rel_to_underlying", ['"%d"' % POOL])))
    print(f"  supply={supply}  pending={pending}  real_total_stakes={real}")
    dep = int(deployed_get_estimate(1000000, supply, pending, real))
    aud = int(audited_get_estimate(1000000, supply, real))
    print(f"  live get_estimate_unstake_amount(1,1e6) = {live_est}")
    print(f"    deployed formula (supply+pending)     = {dep}   {'MATCH' if dep==live_est else 'no'}")
    print(f"    audited  formula (supply)             = {aud}   {'match' if aud==live_est else 'NO MATCH'}")
    dep_p = float(F(real, supply + pending))
    aud_p = float(F(real, supply))
    print(f"  live price_rel_to_underlying = {live_price}")
    print(f"    deployed = {dep_p:.18f}  audited = {aud_p:.18f}")
    ok = (dep == live_est and aud != live_est and abs(live_price - dep_p) < 1e-12)
    print("  -> live chain returns the DEPLOYED (fixed) formula" if ok else "  -> UNEXPECTED")
    return ok

if __name__ == "__main__":
    model()
    ok = oracle()
    print("\nVERDICT:", "H-01 FIXED in deployed code" if ok else "INCONCLUSIVE/FAIL")
    sys.exit(0 if ok else 1)
