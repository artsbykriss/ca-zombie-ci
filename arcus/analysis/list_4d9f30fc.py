#!/usr/bin/env python3
"""Identify the 0x4d9f30fc(uint256) list."""
import json, urllib.request
from eth_utils import keccak

RPC = "http://127.0.0.1:8547"
def rpc(m, p):
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),
        headers={"Content-Type":"application/json"})
    with urllib.request.urlopen(req, timeout=300) as r: d = json.load(r)
    if "error" in d: raise RuntimeError(json.dumps(d["error"])[:200])
    return d["result"]
def u(x): return f"{x:064x}"
F = "0x9c3663FA9ab976E67B42939486EC4966Cb41a0BB"

lst = []
for i in range(0, 40):
    try:
        r = rpc("eth_call", [{"to": F, "data": "0x4d9f30fc" + u(i)}, "latest"])
        a = "0x" + r[-40:]
        lst.append(a)
    except Exception:
        break
print("0x4d9f30fc list length:", len(lst))
for i, a in enumerate(lst):
    code = rpc("eth_getCode", [a, "latest"])
    sz = (len(code) - 2) // 2
    print(f"  [{i:2d}] {a} codesize={sz}")

d = json.load(open('/home/heisenberg/CA/arcus/analysis/factory_beacon_logs.json'))
addrs = set(a.lower() for a in lst if a != "0x" + "0" * 40)
print("\n-- appear in factory logs? --")
for a in sorted(addrs):
    hits = []
    for l in d['factory']:
        blob = (l['topics'] or []) 
        for t in blob:
            if a[2:] in t.lower():
                hits.append((int(l['blockNumber'],16), l['topics'][0][:12]))
                break
        else:
            if a[2:] in (l['data'] or '').lower():
                hits.append((int(l['blockNumber'],16), l['topics'][0][:12]))
    print(f"  {a}: {hits[:6]}{'...' if len(hits)>6 else ''}")

# same addresses in pTokenAt list? in isPToken map?
print("\n-- isPToken check via factory --")
for a in lst[:8]:
    r = rpc("eth_call", [{"to": F, "data": "0x22555cda" + "0"*24 + a[2:]}, "latest"])
    print(f"  {a}: isPToken={int(r,16)}")
