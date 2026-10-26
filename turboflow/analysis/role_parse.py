#!/usr/bin/env python3
"""Brute-force tokenise RoleData: find len-prefixed ASCII strings and candidate 32-byte pubkeys."""
import sys, json, base64
from rpc import call
from b58 import b58enc

ROLEDATA = "8BXB7nkesJEu8JwjrAkP7zMYaSzJ6pe8HLf9mbXLSG47"

def main():
    r = call("getAccountInfo", [ROLEDATA, {"encoding": "base64"}])
    raw = base64.b64decode(r["value"]["data"][0])
    n = len(raw)
    print("len", n)
    print("--- len-prefixed printable strings ---")
    for off in range(8, n - 4):
        L = int.from_bytes(raw[off:off+4], "little")
        if 0 < L <= 64 and off + 4 + L <= n:
            s = raw[off+4:off+4+L]
            if all(32 <= c < 127 for c in s):
                print(f"  off=0x{off:04x} len={L} '{s.decode()}'")
    print("--- token stream (u32 values <= 40 at 4-byte-ish offsets) ---")
    # walk greedily
    off = 8
    while off + 4 <= n:
        v = int.from_bytes(raw[off:off+4], "little")
        if 0 < v <= 64 and off + 4 + v <= n and all(32 <= c < 127 for c in raw[off+4:off+4+v]):
            print(f"  0x{off:04x} STR len={v} '{raw[off+4:off+4+v].decode()}'")
            off += 4 + v
        elif 0 <= v <= 20:
            print(f"  0x{off:04x} CNT {v}")
            off += 4
        else:
            print(f"  0x{off:04x} RAW u32={v} (0x{v:08x})")
            off += 4

if __name__ == "__main__":
    main()
