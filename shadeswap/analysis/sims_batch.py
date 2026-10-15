#!/usr/bin/env python3
"""Batch swap simulations across all pools with error capture (read-only)."""
import json
import sys
import time

sys.path.insert(0, "/home/heisenberg/CA/shadeswap/analysis")
from secret_enc_query import smart_query  # noqa

pi = {}
for line in open("/home/heisenberg/CA/shadeswap/analysis/all-pairs-states.jsonl"):
    r = json.loads(line)
    if r.get("kind") == "pair" and "result" in r:
        pi[r["address"]] = r["result"]["get_pair_info"]

# pairs to test: (pair_addr, offer_token_addr, amount_raw, label)
TESTS = [
    ("secret1a65a9xgqrlsgdszqjtxhz069pgsh8h4a83hwt0", "secret19e75l25r6sa6nhdf4lggjmgpw0vmpfvsw5cnpe", 100_000000, "sATOM/sstATOM sell 100 sATOM"),
    ("secret1a65a9xgqrlsgdszqjtxhz069pgsh8h4a83hwt0", "secret155w9uxruypsltvqfygh5urghd5v0zc6f9g69sq", 100_000000, "sATOM/sstATOM sell 100 sstATOM"),
    ("secret1gxqsuht45uh2tpqdpru6z6tsw3uyll6md7mzka", "secret150jec8mc2hzyyqak4umv6cfevelr0x9p0mjxgg", 1000_000000, "sOSMO/sstOSMO sell 1000 sOSMO"),
    ("secret1gxqsuht45uh2tpqdpru6z6tsw3uyll6md7mzka", "secret1jrp6z8v679yaq65rndsr970mhaxzgfkymvc58g", 1000_000000, "sOSMO/sstOSMO sell 1000 sstOSMO"),
    ("secret1c26v64jmesejsauxx5uamaycfe4zt3rth3yg4e", "secret14706vxakdzkz9a36872cs62vpl5qd84kpwvpew", 1000_000000000000000000, "sINJ/sstINJ sell 1000 sINJ"),
    ("secret1c26v64jmesejsauxx5uamaycfe4zt3rth3yg4e", "secret1eurddal3m0tphtapad9awgzcuxwz8ptrdx7h4n", 1000_000000000000000000, "sINJ/sstINJ sell 1000 sstINJ"),
    ("secret12wxpcquw2jx6an6da5nxyz6l7qd955u23ljcjn", "secret1z6e4skg5g9w65u5sqznrmagu05xq8u6zjcdg4a", 500_000000, "sJUNO/sstJUNO sell 500 sJUNO"),
    ("secret1u0yg9w8mhj5tlkh8cjr4vhzxwu02hrn4nxan8j", "secret1fl449muk5yq8dlad7a22nje4p5d2pnsgymhjfd", 1000_000000, "SILK/sstkATOM sell 1000 SILK"),
    ("secret18537ttv4l4k2ea0xp6ay3sv4c243fyjtj2uqz7", "secret19e75l25r6sa6nhdf4lggjmgpw0vmpfvsw5cnpe", 100_000000, "sATOM/sstkATOM sell 100 sATOM"),
    ("secret14xsrnkfv5r5qh7m3csps72z9vg49tkgf7an0d5", "secret1fl449muk5yq8dlad7a22nje4p5d2pnsgymhjfd", 1000_000000, "SILK/sstATOM sell 1000 SILK"),
    ("secret152alvf6ha9wk3gddkslkrpdlh97w5k32nusf3l", "secret1fl449muk5yq8dlad7a22nje4p5d2pnsgymhjfd", 500_000000, "SILK/sqATOM sell 500 SILK"),
    ("secret19nldywqd78rwf0vd7srg7nr76u2sxzekt64pg0", "secret1fl449muk5yq8dlad7a22nje4p5d2pnsgymhjfd", 500_000000, "SILK/sUSK sell 500 SILK"),
    ("secret1lrlfevkpmwc0kfxl9e59x0er5d8pzh48t68m0e", "secret1fl449muk5yq8dlad7a22nje4p5d2pnsgymhjfd", 500_000000, "SILK/sIST sell 500 SILK"),
    ("secret1hnev28m6s2hkzkkdfn7m79kdxg57haacqzwu7g", "secret153wu605vvp934xhd4k9dtd640zsep5jkesstdm", 500_00000000, "SHD/saWBTC sell 500 SHD"),
    ("secret1fe22vmduz3xt53r5vxcmd567z08g3yryzck8az", "secret153wu605vvp934xhd4k9dtd640zsep5jkesstdm", 500_00000000, "SHD/SIENNA sell 500 SHD"),
    ("secret1uekg0c2qenz4mxwpg5j4s439rqu25p4a6wlhk6", "secret153wu605vvp934xhd4k9dtd640zsep5jkesstdm", 500_00000000, "SHD/sJKL sell 500 SHD"),
    ("secret19964kxsa07lvz7pmujehpe6mrjfqxf73m86d3j", "secret153wu605vvp934xhd4k9dtd640zsep5jkesstdm", 200_00000000, "SHD/sBLD sell 200 SHD"),
    ("secret1y5ay9sw43rqydyyds6tuam0ugt4rxxu3cmpc79", "secret155w9uxruypsltvqfygh5urghd5v0zc6f9g69sq", 50_000000, "sstATOM/sstOSMO sell 50 sstATOM"),
]
out = {}
for pair, tok, amt, label in TESTS:
    p = pi[pair]
    ct = None
    for s in p["pair"][:2]:
        if s["custom_token"]["contract_addr"] == tok:
            ct = s["custom_token"]
    if ct is None:
        out[label] = {"error": "token not in pair"}
        continue
    q = {"swap_simulation": {"offer": {"token": {"custom_token": ct}, "amount": str(amt)}, "exclude_fee": False}}
    try:
        r, h = smart_query(pair, q)
        out[label] = r
        print(f"OK   {label}: {json.dumps(r)[:220]}", flush=True)
    except Exception as e:
        out[label] = {"error": str(e)[:260]}
        print(f"FAIL {label}: {str(e)[:220]}", flush=True)
    time.sleep(0.5)

json.dump(out, open("/home/heisenberg/CA/shadeswap/analysis/sims-batch.json", "w"), indent=1)
