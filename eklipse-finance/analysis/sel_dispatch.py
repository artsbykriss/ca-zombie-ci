#!/usr/bin/env python3
"""Extract *dispatcher* selectors from EVM bytecode (Solidity pattern) + openchain lookup."""
import json, sys, subprocess

def extract_dispatch(hexcode):
    b = bytes.fromhex(hexcode[2:] if hexcode.startswith("0x") else hexcode)
    sels = []
    for i in range(len(b) - 8):
        # PUSH4 <4 bytes> PUSH1 0xe0 SHL ... (0x63 xx xx xx xx 60 e0 1c)
        if b[i] == 0x63 and b[i+5:i+8] == b"\x60\xe0\x1c":
            sels.append(b[i+1:i+5].hex())
    return sels

def openchain(sels):
    out = {}
    try:
        r = subprocess.run(["curl","-s","-m","40","-X","POST","-H","Content-Type: application/json",
                            "--data-binary", json.dumps({"function": ["0x"+s for s in sels]}),
                            "https://api.openchain.xyz/signature-database/v1/lookup?filter=true"],
                           capture_output=True, text=True, timeout=70)
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
    sels = sorted(set(extract_dispatch(hexcode)))
    print(f"{len(sels)} dispatcher selectors")
    oc = openchain(sels)
    for s in sels:
        print(f"  0x{s} {oc.get(s, '(not in openchain)')}")
