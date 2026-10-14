#!/usr/bin/env python3
"""Enumerate all Mimo V2 pairs on IoTeX and dump tokens/reserves (read-only, public RPC)."""
import json, sys, time
sys.path.insert(0, "/tmp/opencode")
from concurrent.futures import ThreadPoolExecutor
import urllib.request

RPC = "https://babel-api.mainnet.iotex.io"
FAC = "0xda257cbe968202dea212bbb65ab49f174da58b9d"

def rpc(method, params, retries=2):
    for i in range(retries + 1):
        try:
            req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                                         headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.loads(r.read())
        except Exception:
            time.sleep(0.5)
    return {}

def call_ok(to, data):
    d = rpc("eth_call", [{"to": to, "data": data}, "latest"])
    return d.get("result") if "result" in d else None

def words(h):
    if not h or h == "0x": return []
    h = h[2:]
    return [int(h[i:i+64], 16) for i in range(0, len(h), 64)]

def addr(w): return "0x" + f"{w:040x}"[-40:]

def ap(i):
    r = call_ok(FAC, "0x1e3dd18b" + f"{i:064x}")
    return addr(words(r)[0]) if r else None

def info(p):
    t0 = call_ok(p, "0x0dfe1681"); t1 = call_ok(p, "0xd21220a7"); rr = call_ok(p, "0x0902f1ac")
    w = words(rr) if rr else []
    return {"pair": p, "t0": addr(words(t0)[0]) if t0 else None, "t1": addr(words(t1)[0]) if t1 else None,
            "r0": w[0] if w else None, "r1": w[1] if len(w) > 1 else None}

if __name__ == "__main__":
    n = words(call_ok(FAC, "0x574f2ba3"))[0]
    print("pairs:", n, flush=True)
    with ThreadPoolExecutor(max_workers=20) as ex:
        pairs = [p for p in ex.map(ap, range(n)) if p]
    print("got pairs:", len(pairs), flush=True)
    with ThreadPoolExecutor(max_workers=20) as ex:
        infos = list(ex.map(info, pairs))
    json.dump(infos, open(sys.argv[1] if len(sys.argv) > 1 else "mimo_pair_infos.json", "w"), indent=0)
    print("done", flush=True)
