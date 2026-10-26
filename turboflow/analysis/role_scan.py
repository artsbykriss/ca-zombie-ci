#!/usr/bin/env python3
"""Scan RoleData for on-curve 32-byte windows (candidate role members)."""
import base64
from rpc import call
from b58 import b58enc
from probe import on_curve

ROLEDATA = "8BXB7nkesJEu8JwjrAkP7zMYaSzJ6pe8HLf9mbXLSG47"

def main():
    r = call("getAccountInfo", [ROLEDATA, {"encoding": "base64"}])
    raw = base64.b64decode(r["value"]["data"][0])
    seen = []
    for off in range(8, 0x220):
        b = raw[off:off+32]
        a = b58enc(b)
        if len(a) in (43, 44) and on_curve(a):
            seen.append((off, a))
    for off, a in seen:
        print(f"0x{off:04x}  {a}")

if __name__ == "__main__":
    main()
