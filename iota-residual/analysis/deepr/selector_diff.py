#!/usr/bin/env python3
"""Compare deployed PUSH4 selectors against verified ABI signatures (functions + errors).
Uses `cast sig` / `cast keccak` for hashing. Read-only."""
import json, subprocess, sys
from collections import Counter
import urllib.request

RPC = "https://rpc.ankr.com/iota_evm"

def rpc_code(addr):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_getCode","params":[addr,"latest"]}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json"})
    with urllib.request.urlopen(req, timeout=45) as r:
        return json.loads(r.read())["result"]

def push4s(code):
    b = bytes.fromhex(code[2:])
    out = []
    i = 0
    while i < len(b):
        op = b[i]
        if op == 0x63 and i+4 < len(b):
            out.append(b[i+1:i+5].hex()); i += 5; continue
        if 0x60 <= op <= 0x7f:
            i += 1 + (op - 0x5f); continue
        i += 1
    return out

def abi_signatures(abifile):
    d = json.load(open(abifile))
    abi = json.loads(d["result"])
    sigs = []
    for e in abi:
        t = e.get("type")
        if t == "function":
            ins = ",".join(i["type"] for i in e.get("inputs", []))
            sigs.append(f"{e['name']}({ins})")
        elif t == "error":
            ins = ",".join(i["type"] for i in e.get("inputs", []))
            sigs.append(f"{e['name']}({ins})")
        elif t == "event":
            # events are not selectors, skip
            pass
    return sigs

def sel_of(sig):
    try:
        out = subprocess.run(["cast","sig",sig], capture_output=True, text=True, timeout=20).stdout.strip()
        return out if out.startswith("0x") else None
    except Exception:
        return None

def main():
    cases = [
        ("cTokenDelegate","0x9d2cc6101bb94cc7052b39d24f45ff1472b98c7f","abi_ctoken.json"),
        ("comptrollerImpl","0x4b13e770b29b80d8aea25ab909d2cdb8b935c20d","abi_comptroller.json"),
        ("oracle","0x580bef00fa3ae215913cccc62a8d0e74160569e8","abi_oracle.json"),
    ]
    for name, addr, abifile in cases:
        code = rpc_code(addr)
        p4 = push4s(code)
        sels = set(sel_of(s) for s in abi_signatures(abifile))
        sels.discard(None)
        known = set(s[2:] for s in sels)
        print(f"=== {name}: code={len(code)//2}B abi_sigs={len(known)} push4_unique={len(set(p4))} ===")
        # count occurrences in the whole code (dispatcher entries occur many times)
        c = Counter(p4)
        unknown = sorted(set(p4) - known, key=lambda x: -c[x])
        print(f"PUSH4 not in ABI ({len(unknown)}):")
        for u in unknown:
            print(f"  {u} count={c[u]}")
        print()

if __name__ == "__main__":
    main()
