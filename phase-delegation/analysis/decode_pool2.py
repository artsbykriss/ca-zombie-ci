#!/usr/bin/env python3
"""Decode the Phase Delegation StakePool account.

Field sequence is identical across program v1.0.0 / v2.1.1 / master:
  account_type u8, manager/..(8 pubkeys), total_lamports u64, pool_token_supply u64,
  last_update_epoch u64, lockup 48, epoch_fee Fee(den,num), next_epoch_fee FutureEpoch<Fee>,
  pref_dep Option, pref_wd Option, stake_deposit_fee, stake_withdrawal_fee,
  next_stake_wd FutureEpoch, stake_referral_fee u8, sol_dep_auth Option, sol_dep_fee Fee,
  sol_referral_fee u8, sol_wd_auth Option, sol_wd_fee Fee, next_sol_wd FutureEpoch,
  last_epoch_pool_token_supply u64, last_epoch_total_lamports u64

FutureEpoch = u8 tag + payload (tag 0=None; 1=One(T); 2=Two(T)) -> 1 or 17 bytes.
Option<Pubkey> = u8 tag + 32 -> 1 or 33 bytes.
Fee = {denominator u64, numerator u64} -> 16 bytes.
"""
import base64, itertools, json, sys

raw = base64.b64decode(open('raw_pool.b64').read())
assert len(raw) == 611
u64 = lambda o: int.from_bytes(raw[o:o+8], 'little')
B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58(b):
    n = int.from_bytes(b, 'big'); s = ""
    while n: n, r = divmod(n, 58); s = B58[r] + s
    return "1" * (len(b) - len(b.lstrip(b"\0"))) + s
pk = lambda o: b58(raw[o:o+32])

def fee(o): return {"den": u64(o), "num": u64(o+8)}

TAIL_START = None
# find first offset of a run of >=40 zero bytes extending to the end
run = 0
for o in range(len(raw)-1, -1, -1):
    if raw[o] == 0:
        run += 1
        if run >= 100:
            TAIL_START = o
            break
    else:
        run = 0
print("first offset of the trailing 100+ zero run:", TAIL_START)
# find ALL offsets from which the rest of the account is zero
zero_tail_from = [o for o in range(len(raw)) if all(b == 0 for b in raw[o:])]
print("struct must end at one of:", zero_tail_from[:6], "...", zero_tail_from[-3:] if zero_tail_from else None)

def parse(dyn):
    """dyn: dict name->('none'|'one'|'two'|'some') for the dynamic fields"""
    o = 0
    d = {}
    d["account_type"] = raw[o]; o += 1
    for f in ["manager","staker","stake_deposit_authority"]: d[f] = pk(o); o += 32
    d["stake_withdraw_bump_seed"] = raw[o]; o += 1
    for f in ["validator_list","reserve_stake","pool_mint","manager_fee_account","token_program_id"]: d[f] = pk(o); o += 32
    d["total_lamports"] = u64(o); o += 8
    d["pool_token_supply"] = u64(o); o += 8
    d["last_update_epoch"] = u64(o); o += 8
    d["lockup"] = {"ts": int.from_bytes(raw[o:o+8],"little",signed=True), "epoch": u64(o+8), "custodian": pk(o+16)}; o += 48
    d["epoch_fee"] = fee(o); o += 16
    tag = raw[o]
    if dyn["next_epoch_fee"] == "none": o += 1
    else: o += 1; d["next_epoch_fee"] = fee(o); o += 16
    for f in ["pref_dep","pref_wd"]:
        if dyn[f] == "some": d[f] = pk(o+1); o += 33
        else: o += 1
    d["stake_deposit_fee"] = fee(o); o += 16
    d["stake_withdrawal_fee"] = fee(o); o += 16
    if dyn["next_stake_wd"] == "none": o += 1
    else: o += 1; d["next_stake_wd"] = fee(o); o += 16
    d["stake_referral_fee"] = raw[o]; o += 1
    if dyn["sol_dep_auth"] == "some": d["sol_dep_auth"] = pk(o+1); o += 33
    else: o += 1
    d["sol_deposit_fee"] = fee(o); o += 16
    d["sol_referral_fee"] = raw[o]; o += 1
    if dyn["sol_wd_auth"] == "some": d["sol_wd_auth"] = pk(o+1); o += 33
    else: o += 1
    d["sol_withdrawal_fee"] = fee(o); o += 16
    if dyn["next_sol_wd"] == "none": o += 1
    else: o += 1; d["next_sol_wd"] = fee(o); o += 16
    d["last_epoch_pool_token_supply"] = u64(o); o += 8
    d["last_epoch_total_lamports"] = u64(o); o += 8
    return d, o

names = ["next_epoch_fee","pref_dep","pref_wd","next_stake_wd","sol_dep_auth","sol_wd_auth","next_sol_wd"]
results = []
for combo in itertools.product(["none","set"], repeat=7):
    dyn = dict(zip(names, combo))
    try:
        d, end = parse(dyn)
    except Exception as e:
        continue
    if end not in zero_tail_from:
        continue
    # sanity
    ok = True
    for f in ["epoch_fee","stake_deposit_fee","stake_withdrawal_fee","sol_deposit_fee","sol_withdrawal_fee"]:
        fv = d[f]
        if fv["den"] != 0 and not (0 <= fv["num"] <= fv["den"] <= 10**7): ok = False
    for f in ["stake_referral_fee","sol_referral_fee"]:
        if d[f] > 100: ok = False
    if abs(d["last_epoch_pool_token_supply"] - d["pool_token_supply"]) > 0.2*d["pool_token_supply"]: ok = False
    if abs(d["last_epoch_total_lamports"] - d["total_lamports"]) > 0.2*d["total_lamports"]: ok = False
    results.append((ok, end, dyn, d))

results.sort(key=lambda x: (not x[0], x[1]))
for ok, end, dyn, d in results[:4]:
    print("\n=== parse ending at", end, "sane:", ok, "dyn:", dyn)
    print(json.dumps(d, indent=1))
