#!/usr/bin/env python3
"""Focused probe 2: MC LP balances, strategy balanceOf/balanceOfPool, shadow farm sims."""
import sys, json, time, subprocess
sys.path.insert(0, "/home/heisenberg/CA/liquid-driver/analysis")
from fetch_state import rpc_batch, call, call_many, addr_result, int_result, enc_addr, enc_uint

F = "fantom"
ATK = "0x1111111111111111111111111111111111111111"
MC = "0x742474dae70fa2ab063ab786b1fbe5704e861a0c"
MINI = "0x6e2ad6527901c9664f016466b8da1357a004db0f"

def sel(s):
    return subprocess.run(["cast", "sig", s], capture_output=True, text=True).stdout.strip()

S = {s: sel(s) for s in ["balanceOf()", "balanceOfPool()", "balanceOfWant()", "masterchef()",
                         "poolId()", "governance()", "harvesters(address)", "withdraw(uint256)",
                         "withdrawAll()", "deposit()", "want()", "lpToken()", "strategy()", "owner()",
                         "totalSupply()", "token0()", "token1()", "getReserves()", "balanceOf(address)"]}
print(json.dumps(S, indent=1), flush=True)

def from_call(to, data, frm):
    return rpc_batch(F, [("eth_call", [{"to": to, "data": data, "from": frm}, "latest"])])[0]

out = {}

# --- MasterChef LP balances ---
pl = int_result(call(F, MC, "0x081e3eda"), 0)
items = []
for i in range(pl):
    lp = addr_result(call(F, MC, "0x1526fe27", enc_uint(i)))
    items.append((i, lp))
out["mc_pools"] = []
print("MC pools LP balances:")
for i, lp in items:
    b = int_result(call(F, lp, S["balanceOf(address)"], enc_addr(MC)))
    ts = int_result(call(F, lp, S["totalSupply()"]))
    row = {"pid": i, "lpToken": lp, "chefBalance": b, "lpTotalSupply": ts}
    out["mc_pools"].append(row)
    print(f"  pid {i} lp {lp} chefBal {b} lpTS {ts}", flush=True)
    if b:
        row["token0"] = addr_result(call(F, lp, S["token0()"]))
        row["token1"] = addr_result(call(F, lp, S["token1()"]))
        r = call(F, lp, S["getReserves()"])
        if isinstance(r, str) and len(r) >= 2+64*3:
            bb = bytes.fromhex(r[2:])
            row["reserve0"] = int.from_bytes(bb[0:32], "big")
            row["reserve1"] = int.from_bytes(bb[32:64], "big")

# --- strategies: balanceOf, balanceOfPool, masterchef, poolId ---
strat_rows = []
print("\nMiniChef strategies:")
plm = int_result(call(F, MINI, "0x081e3eda"), 0)
for i in range(plm):
    st = addr_result(call(F, MINI, "0xd574ea3d", enc_uint(i)))
    if not st or st == "0x" + "0"*40:
        continue
    row = {"pid": i, "strategy": st}
    row["balanceOf"] = int_result(call(F, st, S["balanceOf()"]))
    row["balanceOfPool"] = int_result(call(F, st, S["balanceOfPool()"]))
    row["balanceOfWant"] = int_result(call(F, st, S["balanceOfWant()"]))
    row["masterchef"] = addr_result(call(F, st, S["masterchef()"]))
    row["poolId"] = int_result(call(F, st, S["poolId()"]))
    row["harvesters_atk"] = call(F, st, S["harvesters(address)"], enc_addr(ATK))
    row["governance"] = addr_result(call(F, st, S["governance()"]))
    # sims
    row["sim_withdraw0_atk"] = str(from_call(st, S["withdraw(uint256)"] + enc_uint(0), ATK))[:100]
    row["sim_withdrawAll_atk"] = str(from_call(st, S["withdrawAll()"], ATK))[:100]
    row["sim_harvest_atk"] = str(from_call(st, "0x4641257d", ATK))[:100]
    strat_rows.append(row)
    print(f"  pid {i} strat {st} balOf {row['balanceOf']} pool {row['balanceOfPool']} want {row['balanceOfWant']} mc {row['masterchef']} poolId {row['poolId']}", flush=True)
out["strategies"] = strat_rows

# --- shadow farm sims (the one holding 49.7 LP) ---
print("\nShadow farm sims:")
sf = "0x59ab3c33e75C91B2B632d51144e57293EF64E556"
out["shadow_sims"] = {}
for name, sig, args in [("withdraw(1)", "withdraw(uint256)", enc_uint(1)),
                        ("withdraw(0)", "withdraw(uint256)", enc_uint(0)),
                        ("withdrawAll()", "withdrawAll()", ""),
                        ("deposit()", "deposit()", ""),
                        ("harvest()", "harvest()", ""),
                        ("balanceOf(atk)", "balanceOf(address)", enc_addr(ATK))]:
    r = from_call(sf, S.get(sig, sig) + args, ATK)
    out["shadow_sims"][name] = r if isinstance(r, str) else json.dumps(r)[:120]
    print(f"  {name}: {str(out['shadow_sims'][name])[:110]}", flush=True)
# view calls (no from)
for name, sig, args in [("owner()", "owner()", ""), ("lpToken()", "lpToken()", ""), ("strategy()", "strategy()", ""),
                        ("balanceOf(farm)", "balanceOf(address)", enc_addr(sf))]:
    r = call(F, sf, S.get(sig, sig) + args)
    out.setdefault("shadow_views", {})[name] = r if isinstance(r, str) else json.dumps(r)[:120]
    print(f"  {name}: {str(out['shadow_views'][name])[:110]}", flush=True)

with open("/home/heisenberg/CA/liquid-driver/analysis/probe2.json", "w") as f:
    json.dump(out, f, indent=1)
print("saved probe2.json")
