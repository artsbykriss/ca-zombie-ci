#!/usr/bin/env python3
"""Correct PDA derivations (v1.0.0 == v2.1.1 seeds) + on-chain verification of the
Phase Delegation pool authority topology.

  withdraw authority = PDA([pool, b"withdraw"], SPoo1)
  deposit authority  = PDA([pool, b"deposit"], SPoo1)
  stake account      = PDA([vote, pool, (validator_seed_suffix_le_u32 if != 0)], SPoo1)
  transient stake    = PDA([b"transient", vote, pool, transient_seed_suffix_le_u64], SPoo1)
"""
import hashlib, json, sys
sys.path.insert(0, '.')
from rpc import rpc, b58enc

P = 2**255 - 19
D = (-121665 * pow(121666, P - 2, P)) % P

def is_on_curve(b):
    y = int.from_bytes(b, 'little') & ((1 << 255) - 1)
    if y >= P: return False
    yy = y * y % P
    u = (yy - 1) % P
    v = (D * yy + 1) % P
    w = u * pow(v, P - 2, P) % P
    if w == 0: return True
    return pow(w, (P - 1) // 2, P) == 1

def cpa(seeds, program):
    return hashlib.sha256(b''.join(seeds) + program + b'ProgramDerivedAddress').digest()

def find_pda(seeds, program):
    for bump in range(255, -1, -1):
        a = cpa(list(seeds) + [bytes([bump])], program)
        if not is_on_curve(a):
            return a, bump
    raise RuntimeError

B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58dec(s):
    n = 0
    for ch in s: n = n * 58 + B58.index(ch)
    return b"\x00" * (len(s) - len(s.lstrip("1"))) + n.to_bytes((n.bit_length() + 7) // 8, "big")

PROGRAM = b58dec("SPoo1Ku8WFXoNDMHPsrGSTSG1Y47rzgn41SLUNakuHy")
POOL = b58dec("aero2ePURjuEgLKTzcUmF6RypBncBGd7pMUYCoSsVJ6")

wd, wd_bump = find_pda([POOL, b"withdraw"], PROGRAM)
dep, dep_bump = find_pda([POOL, b"deposit"], PROGRAM)
print("withdraw authority PDA:", b58enc(wd), "bump", wd_bump, "(stored stake_withdraw_bump_seed=255)")
print("deposit  authority PDA:", b58enc(dep), "bump", dep_bump)

vlist = json.load(open('vlist_decoded.json'))
derived = []
for v in vlist:
    vote = b58dec(v['vote_account_address'])
    seeds = [vote, POOL]
    if v['validator_seed_suffix'] != 0:
        seeds.append(v['validator_seed_suffix'].to_bytes(4, 'little'))
    sa, sb = find_pda(seeds, PROGRAM)
    ts, tb = find_pda([b"transient", vote, POOL, v['transient_seed_suffix'].to_bytes(8, 'little')], PROGRAM)
    derived.append({"vote": v['vote_account_address'], "stake_account": b58enc(sa), "stake_bump": sb,
                    "transient": b58enc(ts), "listed_active": v['active_stake_lamports'],
                    "validator_seed_suffix": v['validator_seed_suffix'],
                    "transient_seed_suffix": v['transient_seed_suffix']})
json.dump(derived, open('derived_stake_accounts.json', 'w'), indent=1)
print("derived", len(derived), "PDAs; sample:", derived[0])

# fetch all stake accounts + transient in batches of 100
addrs = []
for d in derived:
    addrs.append(d["stake_account"]); addrs.append(d["transient"])
addrs += ["aeroivis36SwDvAJpzQCDX9Y7cCLXBdv9vTn1DtDnVC", "88DAgVtGsGcRhvomL8QYgz35tEuBCorzKTWFXk3yq1tw"]
accs = {}
for i in range(0, len(addrs), 100):
    batch = addrs[i:i+100]
    res = rpc("getMultipleAccounts", [batch, {"encoding": "base64"}], timeout=90)
    for a, val in zip(batch, res["value"]):
        accs[a] = val
json.dump(accs, open('stake_accounts_raw.json', 'w'))

import base64
def parse_stake(data):
    b = base64.b64decode(data)
    if len(b) < 200: return None
    tag = int.from_bytes(b[:4], 'little')
    if tag != 2:  # StakeStateV2::Stake
        return {"state_tag": tag}
    o = 4
    rent_exempt = int.from_bytes(b[o:o+8], 'little'); o += 8
    staker = b58enc(b[o:o+32]); o += 32
    withdrawer = b58enc(b[o:o+32]); o += 32
    lockup_ts = int.from_bytes(b[o:o+8], 'little', signed=True); o += 8
    lockup_epoch = int.from_bytes(b[o:o+8], 'little'); o += 8
    custodian = b58enc(b[o:o+32]); o += 32
    return {"state_tag": tag, "staker": staker, "withdrawer": withdrawer,
            "lockup": {"ts": lockup_ts, "epoch": lockup_epoch, "custodian": custodian}}

wd_str = b58enc(wd)
dep_str = b58enc(dep)
print("\nwithdrawer check: all stake accounts must have withdrawer ==", wd_str)
mismatch = 0
total_stake = 0
total_transient = 0
n_missing = 0
rows = []
for d in derived:
    a = accs.get(d["stake_account"])
    if a is None:
        n_missing += 1; rows.append({"stake_account": d["stake_account"], "missing": True}); continue
    p = parse_stake(a["data"][0])
    lam = a["lamports"]
    total_stake += lam
    ok_w = p and p.get("withdrawer") == wd_str
    ok_s = p and p.get("staker") == wd_str
    if not ok_w: mismatch += 1
    rows.append({"stake_account": d["stake_account"], "vote": d["vote"], "lamports": lam,
                 "listed": d["listed_active"], "withdrawer_ok": ok_w, "staker_ok": ok_s,
                 "lockup": p.get("lockup") if p else None})
    t = accs.get(d["transient"])
    if t is not None:
        total_transient += t["lamports"]
        rows[-1]["transient_lamports"] = t["lamports"]
print("missing:", n_missing, "| withdrawer mismatches:", mismatch)
print("sum main stake accounts:", total_stake, "=", total_stake/1e9, "SOL")
print("sum transient:", total_transient, "=", total_transient/1e9, "SOL")
res = accs.get("aeroivis36SwDvAJpzQCDX9Y7cCLXBdv9vTn1DtDnVC")
print("\nreserve account aeroivis...:", json.dumps({"lamports": res["lamports"], "owner": res["owner"],
      "parsed": parse_stake(res["data"][0])}, indent=1) if res else "MISSING")
mint_auth = accs.get("88DAgVtGsGcRhvomL8QYgz35tEuBCorzKTWFXk3yq1tw")
print("mint authority 88DAgVtGs...:", json.dumps({"lamports": mint_auth["lamports"], "owner": mint_auth["owner"]}, indent=1) if mint_auth else "MISSING")
print("mint authority == derived withdraw PDA?", b58enc(wd) == "88DAgVtGsGcRhvomL8QYgz35tEuBCorzKTWFXk3yq1tw")
json.dump(rows, open('stake_accounts_verified.json', 'w'), indent=1)
