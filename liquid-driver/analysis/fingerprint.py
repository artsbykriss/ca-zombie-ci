#!/usr/bin/env python3
"""Fingerprint unverified contracts: selectors + ASCII strings from bytecode."""
import json, urllib.request, sys, re

def post(url, payload, timeout=30):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def get_code(url, addr):
    return post(url, {"jsonrpc": "2.0", "id": 1, "method": "eth_getCode", "params": [addr, "latest"]})["result"]

def selectors(code):
    b = bytes.fromhex(code[2:])
    sels, i = [], 0
    while i < len(b):
        if b[i] == 0x63 and i + 5 <= len(b):
            s = "0x" + b[i+1:i+5].hex()
            if s not in sels: sels.append(s)
            i += 5
        else:
            i += 1
    return sels

def strings(code, minlen=5):
    b = bytes.fromhex(code[2:])
    out = []
    cur = b""
    for byte in b:
        if 32 <= byte < 127:
            cur += bytes([byte])
        else:
            if len(cur) >= minlen: out.append(cur.decode())
            cur = b""
    if len(cur) >= minlen: out.append(cur.decode())
    return out

F = "https://fantom.drpc.org"
targets = sys.argv[1:] or ["0x59ab3c33e75C91B2B632d51144e57293EF64E556"]
res = {}
for a in targets:
    code = get_code(F, a)
    res[a] = {"codesize": (len(code)-2)//2, "selectors": selectors(code), "strings": strings(code)}
    print("==", a, "codesize", res[a]["codesize"])
    print("selectors:", res[a]["selectors"])
    print("strings:")
    for s in res[a]["strings"]:
        print("   ", s)
with open("/home/heisenberg/CA/liquid-driver/analysis/fingerprints.json", "a") as f:
    f.write(json.dumps(res, indent=1) + "\n")
