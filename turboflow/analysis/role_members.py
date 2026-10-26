#!/usr/bin/env python3
"""Extract candidate member pubkeys from RoleData by trying 32-byte windows."""
import sys, base64
from rpc import call
from b58 import b58enc
from probe import on_curve

ROLEDATA = "8BXB7nkesJEu8JwjrAkP7zMYaSzJ6pe8HLf9mbXLSG47"

def main():
    r = call("getAccountInfo", [ROLEDATA, {"encoding": "base64"}])
    raw = base64.b64decode(r["value"]["data"][0])
    # candidate member slots (from token walk)
    cands = [0x26, 0x46, 0x92, 0xb2, 0xfe, 0x11e, 0x170, 0x190, 0x1b0, 0x1d0, 0x1f0]
    for off in cands:
        if off + 32 > len(raw):
            continue
        b = raw[off:off+32]
        a = b58enc(b)
        print(f"0x{off:04x}  {a}  len_b58={len(a)} on_curve={on_curve(a)}")

if __name__ == "__main__":
    main()
