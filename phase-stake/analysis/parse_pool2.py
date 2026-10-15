#!/usr/bin/env python3
"""Careful parse of the Phase Stake pool account with offset tracing.
FutureEpoch tags: 0=None, 1=One(T), 2=Two(T). Option tags: 0=None, 1=Some(T)."""
import struct, sys, json
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import get_data, b58encode

POOL = "phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG"

def parse(data):
    o = 0
    d = {}
    def take(n):
        nonlocal o
        b = data[o:o+n]; o += n; return b
    d["account_type"] = take(1)[0]
    for f in ["manager","staker","stake_deposit_authority"]:
        d[f] = b58encode(take(32))
    d["stake_withdraw_bump_seed"] = take(1)[0]
    for f in ["validator_list","reserve_stake","pool_mint","manager_fee_account","token_program_id"]:
        d[f] = b58encode(take(32))
    d["total_lamports"] = struct.unpack("<Q", take(8))[0]
    d["pool_token_supply"] = struct.unpack("<Q", take(8))[0]
    d["last_update_epoch"] = struct.unpack("<Q", take(8))[0]
    d["lockup"] = dict(unix_timestamp=struct.unpack("<q", take(8))[0],
                       epoch=struct.unpack("<Q", take(8))[0],
                       custodian=b58encode(take(32)))
    def fee():
        # denominator first per current master; keep both interpretations visible
        a = struct.unpack("<Q", take(8))[0]; b = struct.unpack("<Q", take(8))[0]
        return [a, b]
    def future_fee():
        t = take(1)[0]
        if t == 0: return {"tag": 0}
        return {"tag": t, "fee": fee()}
    def opt_pk():
        t = take(1)[0]
        if t == 0: return None
        return b58encode(take(32))
    d["epoch_fee_raw"] = fee()
    d["next_epoch_fee"] = future_fee()
    d["preferred_deposit_validator_vote_address"] = opt_pk()
    d["preferred_withdraw_validator_vote_address"] = opt_pk()
    d["stake_deposit_fee_raw"] = fee()
    d["stake_withdrawal_fee_raw"] = fee()
    d["next_stake_withdrawal_fee"] = future_fee()
    d["stake_referral_fee"] = take(1)[0]
    d["sol_deposit_authority"] = opt_pk()
    d["sol_deposit_fee_raw"] = fee()
    d["sol_referral_fee"] = take(1)[0]
    d["sol_withdraw_authority"] = opt_pk()
    d["sol_withdrawal_fee_raw"] = fee()
    d["next_sol_withdrawal_fee"] = future_fee()
    d["last_epoch_pool_token_supply"] = struct.unpack("<Q", take(8))[0]
    d["last_epoch_total_lamports"] = struct.unpack("<Q", take(8))[0]
    d["_consumed"] = o
    d["_remaining"] = len(data) - o
    return d

if __name__ == "__main__":
    owner, data = get_data(POOL)
    print("owner:", owner, "len:", len(data))
    d = parse(data)
    print(json.dumps(d, indent=2))
    # sanity: borsh size check
    print("consumed:", d["_consumed"], "remaining:", d["_remaining"])
