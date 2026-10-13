#!/usr/bin/env python3
"""Check self-LP balances (burn() extraction surface) + active-gauge pair details."""
import json, urllib.request

RPC = "https://rpc.scroll.io"
def enc_addr(a):
    return a.lower().replace("0x", "").rjust(64, "0")
def rpc_batch(payload):
    body = json.dumps(payload).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=60))

d = json.load(open("/home/heisenberg/CA/nuri-cl/analysis/childC-v2-pairs.json"))
details = json.load(open("/home/heisenberg/CA/nuri-cl/analysis/childC-v2-pair-details.json"))
block = d["block"]
pairs = [p["pair"] for p in d["pairs"]]

# balanceOf(pair) on each pair (self-LP) + balanceOf(0x0)
calls = []
for i, p in enumerate(pairs):
    calls.append({"jsonrpc": "2.0", "id": 2*i,   "method": "eth_call", "params": [{"to": p, "data": "0x70a08231" + enc_addr(p)}, hex(block)]})
    calls.append({"jsonrpc": "2.0", "id": 2*i+1, "method": "eth_call", "params": [{"to": p, "data": "0x70a08231" + "0"*64}, hex(block)]})
res = {}
for s in range(0, len(calls), 10):
    for it in rpc_batch(calls[s:s+10]):
        res[it["id"]] = it.get("result")
self_lp = {}
for i, p in enumerate(pairs):
    a = res.get(2*i); b = res.get(2*i+1)
    self_lp[p] = {
        "self": int(a, 16) if isinstance(a, str) and a != "0x" else None,
        "zero": int(b, 16) if isinstance(b, str) and b != "0x" else None,
    }
nonzero = {p: v for p, v in self_lp.items() if v["self"]}
print("pairs with self-LP balance > 0:", len(nonzero))
for p, v in nonzero.items():
    row = next(x for x in d["pairs"] if x["pair"] == p)
    print("  ", p, row.get("symbol"), "selfLP", v["self"], "totalSupply", row.get("totalSupply"))
# total self-LP across all pairs normalized by each pair's totalSupply -> value at risk if priced
tot = 0.0
priced = json.load(open("/home/heisenberg/CA/nuri-cl/analysis/childC-v2-pairs-priced.json"))
pr = {r["pair"]: r for r in priced["pairs"]}
for p, v in nonzero.items():
    row = next(x for x in d["pairs"] if x["pair"] == p)
    ts = row.get("totalSupply")
    if ts:
        share = v["self"] / ts
        usd = pr.get(p, {}).get("usd", 0.0) * share
        tot += usd
        print("   burn-share value (priced tokens only):", p, round(share,6), "usd", round(usd,2))
print("total self-LP extractable via burn() at priced tokens: $%.2f" % tot)

# active-gauge pairs
act = [p for p, s in details["pair_slot3"].items() if s.get("hasActiveGauge") == 1]
print("pairs with active gauge:", act)
for p in act:
    row = next(x for x in d["pairs"] if x["pair"] == p)
    f = row.get("fees")
    fd = details["pairfees_feeDistributor"].get(f)
    print("  ", p, row.get("symbol"), "fees", f, "feeDistributor", fd)
# feeSplit=80 and 19 pairs
for p, s in details["pair_slot3"].items():
    if s.get("feeSplit") != 42:
        row = next(x for x in d["pairs"] if x["pair"] == p)
        print("weird feeSplit", s, p, row.get("symbol"))
json.dump({"block": block, "self_lp": self_lp, "active_gauge_pairs": act}, open("/home/heisenberg/CA/nuri-cl/analysis/childC-v2-selflp.json", "w"), indent=1)
