#!/usr/bin/env python3
"""Query all ShadeSwap pair / staking / LP states via encrypted Secret queries (read-only)."""
import json
import os
import sys
import time

sys.path.insert(0, "/home/heisenberg/CA/shadeswap/analysis")
from secret_enc_query import smart_query  # noqa

OUT = "/home/heisenberg/CA/shadeswap/analysis/shadeswap-states.jsonl"

FACTORY = "secret1ja0hcwvy76grqkpgwznxukgd7t8a8anmmx05pp"
PAIRS = {
    "SHD/stkd-SCRT": "secret1qyt4l47yq3x43ezle4nwlh5q0sn6f9sesat7ap",
    "SHD/stATOM": "secret1wn9tdlvut2nz0cpv28qtv74pqx20p847j8gx3w",
    "SILK/SHD": "secret1l34fyc9g23fnlk896693nw57phevnyha7pt6gj",
    "SILK/stATOM": "secret14xsrnkfv5r5qh7m3csps72z9vg49tkgf7an0d5",
    "ATOM/sstkATOM": "secret18537ttv4l4k2ea0xp6ay3sv4c243fyjtj2uqz7",
}
STAKING = {
    "SILK/SHD staking": "secret13j4n5gj8857h2j4cnempdkfygrw9snasx4yzw2",
    "SHD/stkd-SCRT staking": "secret1vgtmfvzdn7ztn7kcrqd7p6f2z97wvauavp3udh",
    "SHD/stATOM staking": "secret17ue98qd2akjazu2w2r95cz06mh8pfl3v5hva4j",
    "ATOM/sstkATOM staking": "secret16h5sqd79x43wutne8ge3pdz3e3lngw62vy5lmr",
}
LP = {
    "SHD/stkd-SCRT LP": "secret10egcg03euavu336fzed87m4zdx8jkgzzz7zgmh",
    "SILK/SHD LP": "secret1zw9gwj6kx7vd3xax7wf45y6dmawkj3pd3dk7wt",
    "SILK/stATOM LP": "secret1u3mp0jtmszw0xn7s5dn69gl0332lx9f60kt8xk",
    "SHD/stATOM LP": "secret1ffre8nf653pem9hn5f4ep5pg70dd837tucgdyv",
    "ATOM/sstkATOM LP": "secret1l2u35dcx2a4wyx9a6lxn9va6e66z493ycqxtmx",
    "sINJ/stINJ LP": "secret17nmgfelgmmzdnzpfgr0g09kfjyk6sn5l9s0m2x",
}

done = set()
if os.path.exists(OUT):
    for line in open(OUT):
        try:
            r = json.loads(line)
            done.add((r["kind"], r["name"], r.get("query")))
        except Exception:
            pass


def q(kind, name, addr, query, key=None):
    tag = (kind, name, key or json.dumps(query))
    if tag in done:
        return None
    try:
        res, h = smart_query(addr, query)
        rec = {"kind": kind, "name": name, "address": addr, "query": key or json.dumps(query),
               "height": h, "result": res}
    except Exception as e:
        rec = {"kind": kind, "name": name, "address": addr, "query": key or json.dumps(query),
               "error": str(e)[:300]}
    with open(OUT, "a") as f:
        f.write(json.dumps(rec) + "\n")
    print(f"{kind:8s} {name:26s} -> {json.dumps(rec.get('result') or rec.get('error'))[:160]}", flush=True)
    time.sleep(0.6)
    return rec


# factory
q("factory", "factory", FACTORY, {"get_config": {}}, key="get_config")
q("factory", "factory", FACTORY, {"list_amm_pairs": {"pagination": {"start": 0, "limit": 100}}}, key="list_pairs_0")

# pairs
for name, addr in PAIRS.items():
    q("pair", name, addr, {"get_pair_info": {}}, key="get_pair_info")
    q("pair", name, addr, {"get_shade_dao_info": {}}, key="get_shade_dao_info")

# staking
for name, addr in STAKING.items():
    q("staking", name, addr, {"get_config": {}}, key="get_config")
    q("staking", name, addr, {"get_reward_tokens": {}}, key="get_reward_tokens")

# lp tokens
for name, addr in LP.items():
    q("lp", name, addr, {"token_info": {}}, key="token_info")
