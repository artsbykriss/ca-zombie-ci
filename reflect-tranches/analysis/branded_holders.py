#!/usr/bin/env python3
"""Enumerate the senior-tranche branded mints and their largest holders (read-only)."""
import sys, os, json, base64
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc, b58e

st = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "live_state.json")))
proxy_states = st["proxy_states"]
out = {}
for pk, v in proxy_states.items():
    bm = v["branded_mint"]
    r = rpc("getTokenLargestAccounts", [bm])
    vals = r.get("result", {}).get("value", [])
    out[pk] = {"branded_mint": bm, "stablecoin_mint": v["stablecoin_mint"], "fee": v["fee"],
               "authority": v["authority"], "principal": v["principal"], "commission": v["commission"],
               "holders": [{"address": a["address"], "amount": a["uiAmountString"]} for a in vals]}
print("live ProxyStates:", len(proxy_states))
for pk, v in out.items():
    if v["holders"]:
        print(f"\n{pk}\n  branded={v['branded_mint']} stable={v['stablecoin_mint']} fee={v['fee']} auth={v['authority']}")
        for h in v["holders"][:6]:
            print("   holder", h["address"], h["amount"])
json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "branded_holders.json"), "w"), indent=2)
