#!/usr/bin/env python3
"""Simulate deposits on the anvil fork with prestate tracing (local only)."""
import json, urllib.request

RPC = "http://127.0.0.1:8547"
def rpc(m, p):
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),
        headers={"Content-Type":"application/json"})
    with urllib.request.urlopen(req, timeout=300) as r: d = json.load(r)
    if "error" in d: raise RuntimeError(json.dumps(d["error"])[:400])
    return d["result"]

def pad(a): return "0"*24 + a.lower().replace("0x","")
def u(x): return f"{x:064x}"

pBTC3x = "0x4472C69d299382F8847ebCE4FC6Ed8e295510E3e"
pTEST3 = "0x122408C1399E51C41B096402fea46e20E762A950"
pTEST  = "0x1193BcBfaFeB2F25C516817C46BD3143936d1d5C"
USDG   = "0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168"
team   = "0x001232c60a01d7b54cb011b0075bab75791aa03b"
trad1  = "0x0a2d8ab934d8318075850e969569ddc09e3d5101"  # allowed in factory map5
trad2  = "0x9d90417ea422c8d03e94288e70d6747df9a15e64"
dead   = "0x000000000000000000000000000000000000dEaD"

def sim(label, tok, fn, args, sender, value=None):
    data = fn + "".join(args)
    print(f"\n########## {label}")
    # plain call first
    try:
        ret = rpc("eth_call", [{"to": tok, "data": data, "from": sender}, "latest"])
        print(f"  eth_call OK ret={ret[:70]}")
    except Exception as e:
        print(f"  eth_call REVERT: {str(e)[:220]}")
        return
    try:
        tr = rpc("debug_traceCall", [{"to": tok, "data": data, "from": sender, "gas": "0x2faf080"}, "latest",
                                     {"tracer":"prestateTracer","tracerConfig":{"diffMode":True}}])
        pre, post = tr.get("pre", {}), tr.get("post", {})
        changes = []
        for addr, ps in post.items():
            pr = pre.get(addr, {})
            for slot, val in (ps.get("storage") or {}).items():
                old = (pr.get("storage") or {}).get(slot, "0x"+"00"*32)
                if old != val:
                    changes.append(f"    STORE {addr} {slot}: {old} -> {val}")
            if "balance" in ps and "balance" in pr and ps["balance"] != pr["balance"]:
                changes.append(f"    BAL {addr}: {int(pr['balance'],16)} -> {int(ps['balance'],16)}")
        for c in changes[:40]:
            print(c)
        if not changes: print("    (no state changes)")
    except Exception as e:
        print("  trace error:", str(e)[:200])

# deposit(uint256 assets, address receiver) = 0x6e553f65
print("="*80)
print("TASK 2: DEPOSIT SIMULATIONS")
sim("pBTC3x.deposit(1e6, team) from team [quota=1e8]", pBTC3x, "0x6e553f65", [u(10**6), pad(team)], team)
sim("pBTC3x.deposit(100e6, team) from team", pBTC3x, "0x6e553f65", [u(100*10**6), pad(team)], team)
sim("pTEST3.deposit(1e6, team) from team", pTEST3, "0x6e553f65", [u(10**6), pad(team)], team)
sim("pTEST3.deposit(1e6, dead) from dead", pTEST3, "0x6e553f65", [u(10**6), pad(dead)], dead)
sim("pBTC3x.deposit(1e6, trad1) from trad1 [factory-allowed, quota=0]", pBTC3x, "0x6e553f65", [u(10**6), pad(trad1)], trad1)
sim("pTEST.deposit(1e6, team) from team", pTEST, "0x6e553f65", [u(10**6), pad(team)], team)
sim("pTEST3.deposit(1e6, deployer) from deployer", pTEST3, "0x6e553f65", [u(10**6), pad("0x38d0eabaedbcd65c2c2ff8e075f58f29f83cc101")], "0x38d0eabaedbcd65c2c2ff8e075f58f29f83cc101")

print("\n" + "="*80)
print("convertToShares/convertToAssets checks")
for tok,label in [(pTEST,"pTEST"),(pBTC3x,"pBTC3x"),(pTEST3,"pTEST3")]:
    for v,fn,name in [(10**6,"0xc6e6f592","convertToShares"),(10**18,"0x07a2d13a","convertToAssets"),(1,"0xc6e6f592","convertToShares")]:
        try:
            ret=rpc("eth_call",[{"to":tok,"data":fn+u(v),"from":dead},"latest"])
            print(f"  {label} {name}({v}) = {int(ret,16)}")
        except Exception as e:
            print(f"  {label} {fn} REVERT {str(e)[:120]}")
