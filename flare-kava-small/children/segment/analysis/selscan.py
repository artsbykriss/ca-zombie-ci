#!/usr/bin/env python3
"""Extract PUSH4 selectors guarded by EQ from EVM bytecode (dispatcher scan)."""
import re, sys, json, os, urllib.request

def selectors(code_hex):
    code = code_hex[2:] if code_hex.startswith("0x") else code_hex
    b = bytes.fromhex(code)
    sels = {}
    for i in range(len(b) - 5):
        if b[i] == 0x63:  # PUSH4
            sel = b[i+1:i+5]
            nxt = b[i+5]
            if nxt in (0x14, 0x15):  # EQ / ISZERO after push4 (common dispatch patterns)
                sels[sel.hex()] = sels.get(sel.hex(), 0) + 1
    return sels

if __name__ == "__main__":
    for a in sys.argv[1:]:
        import subprocess
        code = subprocess.run(["cast","code",a,"--rpc-url","https://opbnb-mainnet-rpc.bnbchain.org"],capture_output=True,text=True).stdout.strip()
        s = selectors(code)
        print(f"== {a} bytes={len(code)//2-1} selectors={len(s)}")
        print(" ".join(sorted(s.keys())))
