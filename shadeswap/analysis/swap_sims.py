#!/usr/bin/env python3
"""Simulate swaps on mispriced ShadeSwap pools (read-only query simulations)."""
import json
import sys
import time

sys.path.insert(0, "/home/heisenberg/CA/shadeswap/analysis")
from secret_enc_query import smart_query  # noqa

TOK = {
    "SHD": ("secret153wu605vvp934xhd4k9dtd640zsep5jkesstdm", "638a3e1d50175fbcb8373cf801565283e3eb23d88a9b7b7f99fcc5eb1e6b561e"),
    "SILK": ("secret1fl449muk5yq8dlad7a22nje4p5d2pnsgymhjfd", "638a3e1d50175fbcb8373cf801565283e3eb23d88a9b7b7f99fcc5eb1e6b561e"),
    "stkd-SCRT": ("secret1k6u0cy4feepm6pehnz804zmwakuwdapm69tuc4", "f6be719b3c6feb498d3554ca0398eb6b7e7db262acb33f84a8f12106da6bbb09"),
    "SSCRT": ("secret1k0jntykt7e4g3y88ltc60czgjuqdy4c9e8fzek", "5f8a7c1f6b0d0f6f2a9c1f0f1e... placeholder"),
}

PAIRS = {
    "SILK/stkd-SCRT": "secret1a6efnz9y702pctmnzejzkjdyq0m62jypwsfk92",
    "SHD/stkd-SCRT": "secret1qyt4l47yq3x43ezle4nwlh5q0sn6f9sesat7ap",
    "SSCRT/stkd-SCRT": "secret1y6w45fwg9ln9pxd6qys8ltjlntu9xa4f2de7sp",
    "SILK/SHD": "secret1l34fyc9g23fnlk896693nw57phevnyha7pt6gj",
    "SILK/saUSDC": "secret1qz57pea4k3ndmjpy6tdjcuq4tzrvjn0aphca0k",
    "SILK/saUSDT": "secret10szrjlyza5u7yqcqvqenf28nmhwph4pad9csyw",
    "SILK/sCMST": "secret1cqk6t9jjzqelwm0f72n5u2utvljdfgsq047cqu",
}

# get token code hashes from pair infos
pairinfo = {}
for line in open("/home/heisenberg/CA/shadeswap/analysis/all-pairs-states.jsonl"):
    r = json.loads(line)
    if r.get("kind") == "pair" and "result" in r:
        pi = r["result"].get("get_pair_info") or r["result"]
        pairinfo[r["address"]] = pi


def tok(sym_or_addr):
    if sym_or_addr in TOK:
        return TOK[sym_or_addr]
    # find in pair info
    for pi in pairinfo.values():
        for side in pi["pair"][:2]:
            ct = side["custom_token"]
            if ct["contract_addr"] == sym_or_addr:
                return (ct["contract_addr"], ct["token_code_hash"])
    raise KeyError(sym_or_addr)


def sim(pair_name, offer_sym, amount_raw):
    addr = PAIRS[pair_name]
    ca, ch = tok(offer_sym)
    q = {"swap_simulation": {"offer": {"token": {"custom_token": {"contract_addr": ca, "token_code_hash": ch}}, "amount": str(amount_raw)}, "exclude_fee": False}}
    r, h = smart_query(addr, q)
    print(f"SIM {pair_name:18s} offer {amount_raw} {offer_sym} -> {json.dumps(r)[:300]}", flush=True)
    return r


out = {}
for pair_name, sym, amt in [
    ("SILK/stkd-SCRT", "stkd-SCRT", 1000_000000),        # 1000 stkd-SCRT
    ("SHD/stkd-SCRT", "stkd-SCRT", 1000_000000),         # 1000 stkd-SCRT
    ("SSCRT/stkd-SCRT", "SSCRT", 1000_000000),           # 1000 SSCRT
    ("SILK/SHD", "SHD", 1000_00000000),                  # 1000 SHD
    ("SILK/saUSDC", "SILK", 1000_000000),                # 1000 SILK
    ("SILK/saUSDT", "SILK", 1000_000000),                # 1000 SILK
    ("SILK/sCMST", "SILK", 100_000000),                  # 100 SILK
]:
    try:
        out[f"{pair_name}|{sym}"] = sim(pair_name, sym, amt)
    except Exception as e:
        print(f"SIM {pair_name} {sym} ERR: {str(e)[:200]}", flush=True)
        out[f"{pair_name}|{sym}"] = {"error": str(e)[:200]}
    time.sleep(0.6)

json.dump(out, open("/home/heisenberg/CA/shadeswap/analysis/swap-sims.json", "w"), indent=1)
