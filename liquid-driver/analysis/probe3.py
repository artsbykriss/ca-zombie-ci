#!/usr/bin/env python3
"""Probe 3: corrected MC LP balances, strategy external masterchef, dangerous-call sims."""
import sys, json, subprocess
sys.path.insert(0, "/home/heisenberg/CA/liquid-driver/analysis")
from fetch_state import rpc_batch, call, addr_result, int_result, enc_addr, enc_uint

F = "fantom"
ATK = "0x1111111111111111111111111111111111111111"
MC = "0x742474dae70fa2ab063ab786b1fbe5704e861a0c"
MINI = "0x6e2ad6527901c9664f016466b8da1357a004db0f"
SHADOW = "0x59ab3c33e75C91B2B632d51144e57293EF64E556"
EXTMC = "0x18b4f774fdc7bf685daeef66c2990b1ddd9ea6ad"

def sig(s): return subprocess.run(["cast", "sig", s], capture_output=True, text=True).stdout.strip()
def from_call(to, data, frm=ATK):
    return rpc_batch(F, [("eth_call", [{"to": to, "data": data, "from": frm}, "latest"])])[0]
def word0_addr(r):
    return "0x" + r[2:66][24:64] if isinstance(r, str) and len(r) >= 66 else None

out = {}

# 1. MC LP balances (LP list decoded properly from poolInfo)
pl = int_result(call(F, MC, "0x081e3eda"), 0)
mc_rows = []
print("MC pools:")
for i in range(pl):
    r = call(F, MC, "0x1526fe27", enc_uint(i))
    lp = word0_addr(r)
    if not lp: 
        print("  pid", i, "decode fail", str(r)[:60]); continue
    b = int_result(call(F, lp, "0x70a08231", enc_addr(MC)))
    ts = int_result(call(F, lp, "0x18160ddd"))
    row = {"pid": i, "lpToken": lp, "chefBalance": b, "lpTotalSupply": ts}
    if b:
        row["token0"] = addr_result(call(F, lp, "0x0dfe1681"))
        row["token1"] = addr_result(call(F, lp, "0xd21220a7"))
        rr = call(F, lp, "0x0902f1ac")
        if isinstance(rr, str) and len(rr) >= 2+64*3:
            bb = bytes.fromhex(rr[2:])
            row["reserve0"] = int.from_bytes(bb[0:32], "big")
            row["reserve1"] = int.from_bytes(bb[32:64], "big")
    mc_rows.append(row)
    if b: print("  pid", i, lp, "chefBal", b, "ts", ts, flush=True)
out["mc_pools"] = mc_rows
nz = [r for r in mc_rows if r.get("chefBalance")]
print("MC pools with balance:", len(nz), "of", len(mc_rows))

# 2. external masterchef 0x18b4f774
print("\nExternal masterchef", EXTMC)
for name, s, args in [("owner()", "owner()", None), ("poolLength()", "poolLength()", None),
                      ("lqdr()", "lqdr()", None), ("boo()", "boo()", None),
                      ("totalAllocPoint()", "totalAllocPoint()", None)]:
    r = call(F, EXTMC, sig(s), args)
    out.setdefault("extmc", {})[name] = r
    print(f"  {name}: {str(r)[:80]}")

# 3. dangerous-call sims
print("\nDangerous sims (from attacker):")
sims = {}
def sim(label, to, s, args=""):
    r = from_call(to, sig(s) + args)
    sims[label] = r if isinstance(r, str) else json.dumps(r)[:140]
    print(f"  {label}: {str(sims[label])[:120]}", flush=True)

sim("mc.mint(atk,1e18)", MC, "mint(address,uint256)", enc_addr(ATK) + enc_uint(10**18))
sim("mc.add(1,atk,0,false)", MC, "add(uint256,address,uint16,bool)", enc_uint(1)+enc_addr(ATK)+enc_uint(0)+enc_uint(0))
sim("mc.updateEmissionRate(1e18)", MC, "updateEmissionRate(uint256)", enc_uint(10**18))
sim("mc.transferOwnership(atk)", MC, "transferOwnership(address)", enc_addr(ATK))
sim("mc.dev(atk)", MC, "dev(address)", enc_addr(ATK))
sim("mc.setFeeAddress(atk)", MC, "setFeeAddress(address)", enc_addr(ATK))
sim("mini.mint(atk,1e18)", MINI, "mint(address,uint256)", enc_addr(ATK) + enc_uint(10**18))
sim("mini.setLqdrPerSecond(1e18)", MINI, "setLqdrPerSecond(uint256)", enc_uint(10**18))
sim("mini.setFeeAddress(atk)", MINI, "setFeeAddress(address)", enc_addr(ATK))
sim("mini.setTreasuryAddress(atk)", MINI, "setTreasuryAddress(address)", enc_addr(ATK))
sim("mini.initialize(atk,atk,atk)", MINI, "initialize(address,address,address)", enc_addr(ATK)*3)
sim("mini.upgradeTo(atk)", MINI, "upgradeTo(address)", enc_addr(ATK))
sim("mini.upgradeToAndCall(atk,0x)", MINI, "upgradeToAndCall(address,bytes)", enc_addr(ATK) + enc_uint(0x40) + enc_uint(0))
sim("shadow.withdraw(1)", SHADOW, "withdraw(uint256)", enc_uint(1))
sim("shadow.withdraw(0)", SHADOW, "withdraw(uint256)", enc_uint(0))
sim("shadow.withdrawAll()", SHADOW, "withdrawAll()")
sim("shadow.deposit()", SHADOW, "deposit()")
sim("shadow.harvest()", SHADOW, "harvest()")
sim("shadow.emergencyWithdraw()", SHADOW, "emergencyWithdraw()")
sim("shadow.setStrategy(atk)", SHADOW, "setStrategy(address)", enc_addr(ATK))
sim("shadow.transferOwnership(atk)", SHADOW, "transferOwnership(address)", enc_addr(ATK))
sim("shadow.upgradeTo(atk)", SHADOW, "upgradeTo(address)", enc_addr(ATK))
out["sims"] = sims

# 4. proxy admin slots
SLOT_ADMIN = "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"
print("\nProxy admins:")
admins = {}
for a in [SHADOW, MINI, "0x79364E45648Db09eE9314E47b2fD31c199Eb03B9", "0x0f45B4A89AAb28f4C4dC2d08ebAD277983d4B67a"]:
    v = rpc_batch(F, [("eth_getStorageAt", [a, SLOT_ADMIN, "latest"])])[0]
    admin = "0x" + v[-40:] if isinstance(v, str) and len(v) >= 42 else None
    admins[a] = admin
    print(f"  {a} -> admin {admin}", flush=True)
out["proxy_admins"] = admins

with open("/home/heisenberg/CA/liquid-driver/analysis/probe3.json", "w") as f:
    json.dump(out, f, indent=1)
print("saved probe3.json")
