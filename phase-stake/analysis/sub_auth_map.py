#!/usr/bin/env python3
"""TASK 4: Authority control mapping for Phase Stake (YIELD) and Phase pdSOL pools.
Also re-reads both pool accounts (full parse) to verify facts."""
import json, sys, time, base64, struct
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import rpc, get_data, b58encode, b58decode, on_curve

OUT = "/home/heisenberg/CA/phase-stake/analysis/auth_map.json"
POOL = "phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG"
PDSOL = "aero2ePURjuEgLKTzcUmF6RypBncBGd7pMUYCoSsVJ6"
SQUADS = "SQDS4ep65T869zMMBKyuUq6aD6EgTu8psMjkvj52pCf"

def parse_pool(data):
    o = 0
    d = {}
    def take(n):
        nonlocal o
        b = data[o:o+n]; o += n; return b
    d["account_type"] = take(1)[0]
    for f in ["manager", "staker", "stake_deposit_authority"]:
        d[f] = b58encode(take(32))
    d["stake_withdraw_bump_seed"] = take(1)[0]
    for f in ["validator_list", "reserve_stake", "pool_mint", "manager_fee_account", "token_program_id"]:
        d[f] = b58encode(take(32))
    d["total_lamports"] = struct.unpack("<Q", take(8))[0]
    d["pool_token_supply"] = struct.unpack("<Q", take(8))[0]
    d["last_update_epoch"] = struct.unpack("<Q", take(8))[0]
    d["lockup"] = dict(unix_timestamp=struct.unpack("<q", take(8))[0],
                       epoch=struct.unpack("<Q", take(8))[0],
                       custodian=b58encode(take(32)))
    def fee():
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

def acct(addr):
    time.sleep(1.3)
    r = rpc("getAccountInfo", [addr, {"encoding": "base64"}])
    v = r.get("value")
    if v is None:
        return {"exists": False, "on_curve": on_curve(b58decode(addr))}
    dl = len(base64.b64decode(v["data"][0])) if v["data"] else 0
    return {"exists": True, "owner_program": v["owner"], "executable": v["executable"],
            "lamports": v["lamports"], "datalen": dl,
            "on_curve": on_curve(b58decode(addr)),
            "is_squads_program": v["owner"] == SQUADS,
            "rent_epoch": v.get("rentEpoch")}

res = {"squads_program": SQUADS}
# Phase YIELD pool
time.sleep(1.3)
own, data = get_data(POOL)
res["yield_pool"] = {"address": POOL, "owner_program": own, "datalen": len(data), "parsed": parse_pool(data)}
# pdSOL pool
time.sleep(1.3)
own2, data2 = get_data(PDSOL)
res["pdsol_pool"] = {"address": PDSOL, "owner_program": own2, "datalen": len(data2) if data2 else None,
                     "parsed": parse_pool(data2) if data2 else None}

res["epoch_now"] = rpc("getEpochInfo", [])

# authorities of YIELD pool
auths = {
    "manager": res["yield_pool"]["parsed"]["manager"],
    "staker": res["yield_pool"]["parsed"]["staker"],
    "sol_withdraw_authority": res["yield_pool"]["parsed"]["sol_withdraw_authority"],
    "stake_deposit_authority": res["yield_pool"]["parsed"]["stake_deposit_authority"],
}
# authorities of pdSOL pool
if res["pdsol_pool"]["parsed"]:
    p2 = res["pdsol_pool"]["parsed"]
    auths["pdsol_manager"] = p2["manager"]
    auths["pdsol_staker"] = p2["staker"]
    if p2["sol_withdraw_authority"]:
        auths["pdsol_sol_withdraw_authority"] = p2["sol_withdraw_authority"]
    auths["pdsol_stake_deposit_authority"] = p2["stake_deposit_authority"]

res["authorities"] = {}
for name, addr in auths.items():
    res["authorities"][name] = {"address": addr, **acct(addr)}

# also check the mint authority & fee account (context)
res["extra"] = {}
for name, addr in {
    "yield_mint_authority": "9HYjrCF5evTobLmay372kpUWSNTrtmDU2NkQtqjdnHKa",
    "yield_fee_account": "GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U",
}.items():
    res["extra"][name] = {"address": addr, **acct(addr)}

json.dump(res, open(OUT, "w"), indent=2)
p = res["yield_pool"]["parsed"]
print("YIELD pool:", {k: p[k] for k in ("manager","staker","stake_deposit_authority","sol_withdraw_authority","sol_deposit_authority","total_lamports","pool_token_supply","last_update_epoch","reserve_stake","pool_mint","manager_fee_account","validator_list","epoch_fee_raw","stake_withdrawal_fee_raw","sol_withdrawal_fee_raw","_consumed","_remaining")})
p2 = res["pdsol_pool"]["parsed"]
if p2:
    print("pdSOL pool:", {k: p2[k] for k in ("manager","staker","stake_deposit_authority","sol_withdraw_authority","total_lamports","pool_token_supply","last_update_epoch","reserve_stake","pool_mint","manager_fee_account","validator_list","_consumed","_remaining")})
else:
    print("pdSOL pool:", res["pdsol_pool"])
print("epoch_now:", res["epoch_now"])
for n, v in res["authorities"].items():
    print(n, json.dumps(v))
for n, v in res["extra"].items():
    print(n, json.dumps(v))
