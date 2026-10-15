#!/usr/bin/env python3
"""Focused probe: MiniChef pools + strategies, and simulate strategy calls from a random EOA.
READ ONLY: eth_call only, no transactions."""
import sys, json, time
sys.path.insert(0, "/home/heisenberg/CA/liquid-driver/analysis")
from fetch_state import rpc_batch, call, call_many, addr_result, int_result, enc_addr, enc_uint

F = "fantom"
MINI = "0x6e2ad6527901c9664f016466b8da1357a004db0f"
ATTACKER = "0x1111111111111111111111111111111111111111"
out = {}

def eth_call_from(chain, to, data, frm, blk="latest"):
    p = {"to": to, "data": data}
    if frm: p["from"] = frm
    return rpc_batch(chain, [("eth_call", [p, blk])])[0]

# MiniChef poolLength
pl = int_result(call(F, MINI, "0x081e3eda"), 0)
print("MiniChef poolLength:", pl, flush=True)
out["poolLength"] = pl
rows = []
for i in range(pl):
    lp = addr_result(call(F, MINI, "0x78ed5d1f", enc_uint(i)))
    st = addr_result(call(F, MINI, "0xd574ea3d", enc_uint(i)))
    rows.append({"pid": i, "lpToken": lp, "strategy": st})
    print(f"pid {i}: lp={lp} strategy={st}", flush=True)
out["pools"] = rows

# for each strategy: want(), balanceOf(), owner(), and simulate withdraw(balance) from attacker
for r in rows:
    st = r.get("strategy")
    if not st or st == "0x" + "0"*40:
        continue
    d = {}
    d["want"] = addr_result(call(F, st, "0x1f1fcd51"))       # want()
    d["balanceOf"] = int_result(call(F, st, "0x70a08231", enc_addr(st)))
    d["owner"] = addr_result(call(F, st, "0x8da5cb5b"))
    bal = d["balanceOf"] or 0
    # simulate withdraw(balance) from attacker
    sim = eth_call_from(F, st, "0x2e1a7d4d" + enc_uint(bal), ATTACKER)
    d["sim_withdraw_from_attacker"] = sim if isinstance(sim, str) else str(sim)
    # simulate harvest() from attacker
    sim2 = eth_call_from(F, st, "0x4641257d", ATTACKER)
    d["sim_harvest_from_attacker"] = sim2 if isinstance(sim2, str) else str(sim2)
    r.update(d)
    print(f"strategy {st}: want={d['want']} bal={d['balanceOf']} owner={d['owner']}", flush=True)
    print(f"   sim withdraw: {str(d['sim_withdraw_from_attacker'])[:80]}", flush=True)
    print(f"   sim harvest:  {str(d['sim_harvest_from_attacker'])[:80]}", flush=True)

with open("/home/heisenberg/CA/liquid-driver/analysis/minichef-strategies.json", "w") as f:
    json.dump(out, f, indent=1)
print("saved")
