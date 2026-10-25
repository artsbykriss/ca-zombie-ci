#!/usr/bin/env python3
"""Inspect the unknown-disc program accounts (2397 / 4340) + OpenedenInfo + SusdSupplyOffset + SunsetInfo."""
import json, base64, sys, os, struct
HERE = os.path.dirname(os.path.abspath(__file__))
D = json.load(open(os.path.join(HERE, "recon1c.json")))
A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58enc(b):
    n = int.from_bytes(b, "big"); out = ""
    while n > 0:
        n, r = divmod(n, 58); out = A[r] + out
    pad = 0
    for c in b:
        if c == 0: pad += 1
        else: break
    return "1" * pad + (out or "")

by = {a["pubkey"]: a for a in D["program_accounts"]}

def show(pk):
    raw = base64.b64decode(by[pk]["data_b64"])
    print("====", pk, "space", len(raw))
    print("hex:", raw.hex())
    # find 32-byte windows that are valid-looking pubkeys (base58 of printable)
    print("ascii runs:", "".join(chr(c) if 32 <= c < 127 else "." for c in raw))
    return raw

for pk in ["3wgB6vYowPy9PeqmZeFBM3o5R5zHGSmNamViuLrGxGeo",
           "4MTMsBW6vM8qhWmYy1eFjLbwHBsEd8ysyiZf3kGCPXQQ",
           "BSWq7LBrbBprv2oc539h257bB6PRmtP7XVn7UtRuyfpT",
           "9HhZLsdF8pGQ9fuSJH5UnqJyXBeuMJ729eYVesXCC6mc",
           "5P5xvu52ocJegFgdynRB2MtCJNbnw2jt6vbiAtFB8zQz",
           "EtKFLi9f8HnUpDbc9y8KeaA1dbYeYgUq34ruAJ9P2cZh"]:
    show(pk)
    print()
