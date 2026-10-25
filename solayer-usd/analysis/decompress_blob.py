#!/usr/bin/env python3
"""Decompress the zlib blobs in the unknown-disc accounts."""
import json, base64, sys, os, zlib
HERE = os.path.dirname(os.path.abspath(__file__))
D = json.load(open(os.path.join(HERE, "recon1c.json")))
by = {a["pubkey"]: a for a in D["program_accounts"]}
for pk in ["3wgB6vYowPy9PeqmZeFBM3o5R5zHGSmNamViuLrGxGeo",
           "BSWq7LBrbBprv2oc539h257bB6PRmtP7XVn7UtRuyfpT"]:
    raw = base64.b64decode(by[pk]["data_b64"])
    print("====", pk, "len", len(raw), "disc", raw[:8].hex())
    pk2 = raw[8:40].hex()
    ln = int.from_bytes(raw[40:44], "little")
    print("  inner pubkey(hex):", pk2, "declared len:", ln, "actual:", len(raw)-44)
    blob = raw[44:]
    try:
        d = zlib.decompress(blob)
        print("  decompressed len:", len(d))
        open(os.path.join(HERE, "blob_%s.bin" % pk[:6]), "wb").write(d)
        print("  head:", d[:300].decode("utf8", "replace"))
    except Exception as e:
        print("  err", e)
