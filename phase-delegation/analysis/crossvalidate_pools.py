#!/usr/bin/env python3
"""Fetch all 240 StakePool accounts on SPoo1 and cross-validate struct layout.

Question: does the StakePool borsh struct (per solana-program/stake-pool v1.0.0..v2.2.0)
end at 435 bytes when all Option/FutureEpoch are None, or is it longer?
Method: decode each pool; for each, find first offset where the rest of the account is
all zeros; compare with the parse end. Stale non-zero tails => older program version
wrote a longer struct (leftover bytes), or current struct is longer than the repo says.
"""
import base64, itertools, json, sys
sys.path.insert(0, '.')
from rpc import rpc

pools = json.load(open('all_pools.json'))
print("pools:", len(pools))

accounts = {}
for i in range(0, len(pools), 100):
    batch = pools[i:i+100]
    res = rpc("getMultipleAccounts", [batch, {"encoding": "base64"}], timeout=90)
    for a, v in zip(batch, res["value"]):
        if v is not None:
            accounts[a] = base64.b64decode(v["data"][0])
print("fetched:", len(accounts))
json.dump({k: base64.b64encode(v).decode() for k, v in accounts.items()}, open('all_pools_raw.json', 'w'))

u64 = lambda b, o: int.from_bytes(b[o:o+8], 'little')
def pk(b, o):
    B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    n = int.from_bytes(b[o:o+32], 'big'); s = ""
    while n: n, r = divmod(n, 58); s = B58[r] + s
    return "1" * (len(b[o:o+32]) - len(b[o:o+32].lstrip(b"\0"))) + s

def parse(b, dyn):
    o = 0
    d = {"account_type": b[0]}; o = 1
    for f in ["manager","staker","stake_deposit_authority"]: d[f] = pk(b,o); o += 32
    o += 1
    for f in ["validator_list","reserve_stake","pool_mint","manager_fee_account","token_program_id"]: d[f] = pk(b,o); o += 32
    d["total_lamports"] = u64(b,o); o += 8
    d["pool_token_supply"] = u64(b,o); o += 8
    d["last_update_epoch"] = u64(b,o); o += 8
    o += 48
    d["epoch_fee"] = (u64(b,o), u64(b,o+8)); o += 16
    if dyn[0]: o += 1; d["next_epoch_fee"] = (u64(b,o), u64(b,o+8)); o += 16
    else: o += 1
    for j,f in [(1,"pref_dep"),(2,"pref_wd")]:
        if dyn[j]: d[f] = pk(b,o+1); o += 33
        else: o += 1
    d["stake_deposit_fee"] = (u64(b,o), u64(b,o+8)); o += 16
    d["stake_withdrawal_fee"] = (u64(b,o), u64(b,o+8)); o += 16
    if dyn[3]: o += 1; d["next_stake_wd"] = (u64(b,o), u64(b,o+8)); o += 16
    else: o += 1
    d["stake_referral_fee"] = b[o]; o += 1
    if dyn[4]: d["sol_dep_auth"] = pk(b,o+1); o += 33
    else: o += 1
    d["sol_deposit_fee"] = (u64(b,o), u64(b,o+8)); o += 16
    d["sol_referral_fee"] = b[o]; o += 1
    if dyn[5]: d["sol_wd_auth"] = pk(b,o+1); o += 33
    else: o += 1
    d["sol_withdrawal_fee"] = (u64(b,o), u64(b,o+8)); o += 16
    if dyn[6]: o += 1; d["next_sol_wd"] = (u64(b,o), u64(b,o+8)); o += 16
    else: o += 1
    d["last_epoch_pool_token_supply"] = u64(b,o); o += 8
    d["last_epoch_total_lamports"] = u64(b,o); o += 8
    return d, o

def first_zero_tail(b):
    for o in range(len(b)):
        if all(x == 0 for x in b[o:]): return o
    return None

def sane(d):
    for f in ["epoch_fee","stake_deposit_fee","stake_withdrawal_fee","sol_deposit_fee","sol_withdrawal_fee"]:
        den, num = d[f]
        if den != 0 and not (0 <= num <= den <= 10**7): return False
    if d["stake_referral_fee"] > 100 or d["sol_referral_fee"] > 100: return False
    if d["pool_token_supply"] and abs(d["last_epoch_pool_token_supply"] - d["pool_token_supply"]) > 0.25*d["pool_token_supply"]: return False
    return True

report = []
for addr, b in accounts.items():
    zt = first_zero_tail(b)
    best = None
    for combo in itertools.product([False,True], repeat=7):
        try: d, end = parse(b, combo)
        except Exception: continue
        if end != zt: continue
        if best is None or (sane(d) and not best[0]): best = (sane(d), combo, d, end)
    if best is None:
        report.append((addr, zt, None, None, None)); continue
    s, combo, d, end = best
    report.append((addr, zt, end, s, d))

nok = sum(1 for r in report if r[3] is None)
print(f"pools where NO parse ends at the zero-tail boundary: {nok}/{len(report)}")
for r in report[:15]:
    addr, zt, end, s, d = r
    if d is None: print(addr, "zero_tail:", zt, "NO PARSE"); continue
    print(f"{addr} zero_tail@{zt} parse_end@{end} sane={s} total={d['total_lamports']/1e9:.2f} SOL epoch_fee={d['epoch_fee']}")
json.dump([{"addr": r[0], "zero_tail": r[1], "parse_end": r[2], "sane": r[3],
            "total_lamports": r[4]["total_lamports"] if r[4] else None,
            "epoch_fee": r[4]["epoch_fee"] if r[4] else None,
            "mgr": r[4]["manager"] if r[4] else None} for r in report], open('all_pools_decoded.json','w'), indent=1)
