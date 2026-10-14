#!/usr/bin/env python3
"""Extract Vyper-dispatcher selectors: PUSH4 <sel> (EQ|GT|LT) PUSH3 <dest> JUMPI."""
import json, sys, subprocess

def extract_vyper(hexcode):
    b = bytes.fromhex(hexcode[2:] if hexcode.startswith("0x") else hexcode)
    sels = []
    for i in range(len(b) - 10):
        if b[i] == 0x63 and b[i+5] in (0x14, 0x11, 0x10) and b[i+6] == 0x62 and b[i+10] == 0x57:
            sels.append(b[i+1:i+5].hex())
    return sels

def openchain(sels):
    out = {}
    try:
        q = "&".join("function=0x" + s for s in sels)
        url = "https://api.openchain.xyz/signature-database/v1/lookup?filter=true&" + q
        r = subprocess.run(["curl","-s","-m","60", url], capture_output=True, text=True, timeout=90)
        d = json.loads(r.stdout)
        for s, v in d.get("result", {}).get("function", {}).items():
            if v: out[s.replace("0x","")] = v[0]["name"]
    except Exception as e:
        print("openchain failed:", e, file=sys.stderr)
    return out

if __name__ == "__main__":
    raw = open(sys.argv[1]).read().strip()
    try:
        hexcode = json.loads(raw).get("result") or raw
    except Exception:
        hexcode = raw
    sels = sorted(set(extract_vyper(hexcode)))
    print(f"{len(sels)} Vyper dispatcher selectors", flush=True)
    oc = openchain(sels)
    for s in sels:
        print(f"  0x{s} {oc.get(s, '(not in openchain)')}", flush=True)
