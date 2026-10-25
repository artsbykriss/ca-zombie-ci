#!/usr/bin/env python3
"""Classify all program-owned accounts by Anchor discriminator + decode Pool."""
import json, base64, sys, os, struct
HERE = os.path.dirname(os.path.abspath(__file__))
D = json.load(open(os.path.join(HERE, "recon1c.json")))
disc = json.load(open(os.path.join(HERE, "discriminators.json")))
acc = disc["accounts"]
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

buckets = {}
for a in D["program_accounts"]:
    raw = base64.b64decode(a["data_b64"])
    d = raw[:8].hex() if len(raw) >= 8 else raw.hex()
    nm = acc.get(d, "UNKNOWN:" + d)
    buckets.setdefault((nm, a["space"]), []).append(a["pubkey"])
for (nm, sp), keys in sorted(buckets.items(), key=lambda x: (x[0][0], x[0][1])):
    print(f"{nm:22s} space={sp:6d} n={len(keys):3d}  {keys[:4]}")

# ---- decode Pool (379 bytes) ----
POOL = "FhVcYNEe58SMtxpZGnTu2kpYJrTu2vwCZDGpPLqbd2yG"
praw = base64.b64decode([a for a in D["program_accounts"] if a["pubkey"] == POOL][0]["data_b64"])
print("\nPool raw len", len(praw))
o = 8
def pub(o):
    return b58enc(praw[o:o+32]), o+32
def u64(o):
    return struct.unpack_from("<Q", praw, o)[0], o+8
def u16(o):
    return struct.unpack_from("<H", praw, o)[0], o+2
def u8(o):
    return praw[o], o+1

# guess layout: manager, susd_mint, rwa_token_mint, usdc_mint, ... try sequential pubkeys
# print the hex grouped
print("hex:", praw.hex())
