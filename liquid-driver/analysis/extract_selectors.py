#!/usr/bin/env python3
"""Extract PUSH4 selectors from deployed bytecode — READ ONLY, single eth_getCode calls."""
import json, subprocess, sys, urllib.request

def rpc(url, method, params):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode()).get("result")

def selectors(code):
    b = bytes.fromhex(code[2:])
    sels = {}
    i = 0
    while i < len(b):
        op = b[i]
        if op == 0x63 and i + 5 <= len(b):  # PUSH4
            sel = b[i+1:i+5].hex()
            sels["0x" + sel] = sels.get("0x" + sel, 0) + 1
            i += 5
        else:
            i += 1
    return sels

F = "https://fantom.drpc.org"
targets = {
    "shadow_0x59ab": "0x59ab3c33e75C91B2B632d51144e57293EF64E556",
    "minichef_ftm": "0x6e2ad6527901c9664f016466b8da1357a004db0f",
    "hundred_dai": "0x79364E45648Db09eE9314E47b2fD31c199Eb03B9",
    "xlqdr": "0x3ae658656d1c526144db371faef2fff7170654ee",
    "masterchef": "0x742474dae70fa2ab063ab786b1fbe5704e861a0c",
}
out = {}
for nm, a in targets.items():
    try:
        code = rpc(F, "eth_getCode", [a, "latest"])
        sels = selectors(code)
        out[nm] = {"addr": a, "codesize": (len(code) - 2)//2, "selectors": sorted(sels.keys())}
        print(nm, "codesize", (len(code)-2)//2, "n_selectors", len(sels), flush=True)
    except Exception as e:
        print(nm, "FAILED", e, flush=True)
        out[nm] = {"addr": a, "error": str(e)}

with open("/home/heisenberg/CA/liquid-driver/analysis/selectors.json", "w") as f:
    json.dump(out, f, indent=1)
for nm in out:
    print("\n==", nm, out[nm].get("codesize"))
    print(" ".join(out[nm].get("selectors", [])[:60]))
