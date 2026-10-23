#!/usr/bin/env python3
"""Classify + dump RLP and proxy accounts by discriminator/size."""
import json, sys, os, base64
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc, b58e

RLP = "JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av"
PROXY = "pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C"
ASSET_DISC = bytes([234, 180, 241, 252, 139, 224, 160, 8])
POOL_DISC = bytes([66, 38, 17, 64, 188, 80, 68, 129])

def gpa(prog, filters=None, encoding="base64"):
    cfg = {"encoding": encoding}
    if filters:
        cfg["filters"] = filters
    return rpc("getProgramAccounts", [prog, cfg])

out = {"slot": rpc("getSlot", [])["result"]}

# --- RLP assets / pools via discriminator memcmp
assets = gpa(RLP, [{"memcmp": {"offset": 0, "bytes": b58e(ASSET_DISC)}}])
pools = gpa(RLP, [{"memcmp": {"offset": 0, "bytes": b58e(POOL_DISC)}}])
print("RLP asset accounts:", len(assets.get("result", [])), "err" if "error" in assets else "")
print("RLP pool accounts:", len(pools.get("result", [])), "err" if "error" in pools else "")

def dec_asset(a):
    d = base64.b64decode(a["account"]["data"][0])
    return {"pubkey": a["pubkey"], "len": len(d), "bump": int.from_bytes(d[8:16], "little"),
            "index": d[9] if len(d) > 9 else None, "mint": b58e(d[10:42]), "hex": d.hex()}

def dec_pool(a):
    d = base64.b64decode(a["account"]["data"][0])
    o = 58
    has_opt = d[o] == 1; o += 1
    val = int.from_bytes(d[o:o+8], "little") if has_opt else None
    if has_opt: o += 8
    assetCount = d[o]; o += 1
    assetIdxs = list(d[o:o+4]); o += 4
    has_pv = d[o] == 1; o += 1
    pv = b58e(d[o:o+32]) if has_pv else None
    return {"pubkey": a["pubkey"], "len": len(d), "has_opt_u64": has_opt, "opt_u64": val,
            "assetCount": assetCount, "assetIdxs": assetIdxs, "protected_vault": pv,
            "tail_hex": d[o+32:].hex(), "hex": d.hex()}

out["assets"] = [dec_asset(a) for a in assets.get("result", [])]
out["pools"] = [dec_pool(a) for a in pools.get("result", [])]
print("\n== RLP Assets ==")
for x in sorted(out["assets"], key=lambda z: z["index"]):
    print(f"  idx={x['index']:3} mint={x['mint']} pubkey={x['pubkey']} len={x['len']}")
print("\n== RLP Pools ==")
for x in out["pools"]:
    print(f"  pv={x['protected_vault']} assetCount={x['assetCount']} idxs={x['assetIdxs']} opt={x['opt_u64']} pubkey={x['pubkey']} len={x['len']} tail={x['tail_hex']}")

# --- proxy: group by size, dump hex of one of each
pr = gpa(PROXY)
vals = pr.get("result", [])
bysize = {}
for a in vals:
    d = base64.b64decode(a["account"]["data"][0])
    bysize.setdefault(len(d), []).append((a["pubkey"], d))
print("\n== PROXY size histogram ==")
for s in sorted(bysize):
    print(f"  size {s}: {len(bysize[s])} accounts")
out["proxy_sizes"] = {str(s): [p for p, _ in v] for s, v in bysize.items()}
# dump first two of each size
out["proxy_samples"] = {}
for s, v in bysize.items():
    out["proxy_samples"][str(s)] = [{"pubkey": p, "hex": d.hex()} for p, d in v[:2]]

json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "accounts.json"), "w"), indent=2)
print("\nwrote accounts.json slot", out["slot"])
