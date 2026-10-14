#!/usr/bin/env python3
"""Check union of app-JS IOTEX addresses for MinMax pool clones (read-only)."""
import json, re, sys, time, urllib.request
from concurrent.futures import ThreadPoolExecutor

RPC = "https://babel-api.mainnet.iotex.io"

def rpc(method, params, retries=1):
    for _ in range(retries + 1):
        try:
            req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                                         headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=15) as r:
                return json.loads(r.read())
        except Exception:
            time.sleep(0.2)
    return {}

def call_ok(to, data):
    d = rpc("eth_call", [{"to": to, "data": data}, "latest"])
    return d.get("result") if "result" in d else None

def words(h):
    if not h or h == "0x": return []
    h = h[2:]
    return [int(h[i:i+64], 16) for i in range(0, len(h), 64)]

def addr(w): return "0x" + f"{w:040x}"[-40:]

SEL = {"swapStorage()": "0x5fd65f0f", "getToken(uint8)": "0x82b86600", "getTokenBalance(uint8)": "0x91ceb3eb",
       "paused()": "0x5c975abb", "owner()": "0x8da5cb5b", "totalSupply()": "0x18160ddd"}

IMPL = "0e62d07a666691ca2276adb729ca33b03779b2b15"
MMOWNER = "0x226f272a2635523b9d50a8d2b481ced204b4d9c2"

def code(a):
    d = rpc("eth_getCode", [a, "latest"])
    return a, d.get("result", "0x")

def probe(a):
    ss = words(call_ok(a, SEL["swapStorage()"]))
    if len(ss) < 7:
        return None
    lp = addr(ss[6])
    o = words(call_ok(a, SEL["owner()"]))
    out = {"addr": a, "lp": lp, "lpSupply": (words(call_ok(lp, SEL["totalSupply()"])) or [None])[0],
           "paused": (words(call_ok(a, SEL["paused()"])) or [None])[0],
           "owner": addr(o[0]) if o else None, "tokens": [], "bals": []}
    for i in range(4):
        v = call_ok(a, SEL["getToken(uint8)"] + f"{i:064x}")
        out["tokens"].append(addr(words(v)[0]) if v else None)
        v2 = call_ok(a, SEL["getTokenBalance(uint8)"] + f"{i:064x}")
        out["bals"].append(words(v2)[0] if v2 else None)
    return out

if __name__ == "__main__":
    addrs = set()
    for f in sys.argv[1:]:
        js = open(f).read()
        addrs.update(re.findall(r'IOTEX,"(0x[a-fA-F0-9]{40})"', js))
    addrs = sorted(addrs)
    print("union addresses:", len(addrs))
    with ThreadPoolExecutor(max_workers=16) as ex:
        codes = dict(ex.map(code, addrs))
    clones = [a for a, c in codes.items() if IMPL in c.lower()]
    others = [a for a, c in codes.items() if a not in clones]
    print("\n=== MinMax pool clones:", len(clones))
    for a in clones:
        print("  ", a)
    print("\n=== probing non-clone contracts for swapStorage (other pool types):")
    nonEOA = [a for a in others if len(codes[a]) > 3]
    with ThreadPoolExecutor(max_workers=12) as ex:
        res = [r for r in ex.map(probe, nonEOA) if r]
    for r in res:
        print("  POOL?", r["addr"], "owner=", r["owner"], "paused=", r["paused"], "lp=", r["lp"], "lpSupply=", r["lpSupply"])
        print("      tokens:", r["tokens"], "bals:", r["bals"])
    json.dump({"clones": clones, "probed": res, "all": addrs}, open("union_probe.json", "w"), indent=1)
    print("\ndone")
