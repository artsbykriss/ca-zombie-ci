#!/usr/bin/env python3
"""Query all 30 factory pairs + involved tokens (encrypted Secret queries, read-only)."""
import json
import os
import sys
import time

sys.path.insert(0, "/home/heisenberg/CA/shadeswap/analysis")
from secret_enc_query import smart_query  # noqa

OUT = "/home/heisenberg/CA/shadeswap/analysis/all-pairs-states.jsonl"
res = json.load(open("/home/heisenberg/CA/shadeswap/analysis/factory-pairs.json"))
pairs = res["list_a_m_m_pairs"]["amm_pairs"]

done = set()
if os.path.exists(OUT):
    for line in open(OUT):
        try:
            r = json.loads(line)
            done.add(r["address"])
        except Exception:
            pass


def q(addr, query, kind, name=""):
    if addr in done:
        return None
    try:
        r, h = smart_query(addr, query)
        rec = {"kind": kind, "name": name, "address": addr, "result": r}
    except Exception as e:
        rec = {"kind": kind, "name": name, "address": addr, "error": str(e)[:200]}
    with open(OUT, "a") as f:
        f.write(json.dumps(rec) + "\n")
    print(f"{kind:6s} {addr} {name[:30]:30s} -> {json.dumps(rec.get('result') or rec.get('error'))[:110]}", flush=True)
    time.sleep(0.55)
    return rec


tokens = set()
for p in pairs:
    q(p["address"], {"get_pair_info": {}}, "pair", "")
    for side in p["pair"][:2]:
        tokens.add(side["custom_token"]["contract_addr"])

# add known tokens + reward tokens
tokens |= {
    "secret153wu605vvp934xhd4k9dtd640zsep5jkesstdm",
    "secret1fl449muk5yq8dlad7a22nje4p5d2pnsgymhjfd",
    "secret1umeg3u5y949vz6jkgq0n4rhefsr84ws3duxmnz",
}
for t in sorted(tokens):
    q(t, {"token_info": {}}, "token", "")
