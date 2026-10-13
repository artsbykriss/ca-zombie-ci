#!/usr/bin/env python3
"""Price PairFees token balances + native balances of key contracts; totals."""
import json, urllib.request, urllib.parse

RPC = "https://rpc.scroll.io"
d = json.load(open("/home/heisenberg/CA/nuri-cl/analysis/childC-v2-pairs.json"))
det = json.load(open("/home/heisenberg/CA/nuri-cl/analysis/childC-v2-pair-details.json"))
priced = json.load(open("/home/heisenberg/CA/nuri-cl/analysis/childC-v2-pairs-priced.json"))

tokmap = {}  # feeAddr -> {0: token0, 1: token1}
for p in d["pairs"]:
    tokmap[p["fees"]] = {0: p.get("token0"), 1: p.get("token1")}

# collect nonzero pairfees balances
need = []
for k, v in det["pairfees_balances"].items():
    if v:
        addr, idx = k.split(":")
        t = tokmap.get(addr, {}).get(int(idx))
        need.append((addr, int(idx), t, v))
tokens = sorted({t for _, _, t, _ in need if t})
prices = {}
for s in range(0, len(tokens), 40):
    ids = ",".join("scroll:" + t for t in tokens[s:s+40])
    url = "https://coins.llama.fi/prices/current/" + urllib.parse.quote(ids, safe=",:")
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    r = json.load(urllib.request.urlopen(req, timeout=60))
    for k, v in (r.get("coins") or {}).items():
        prices[k.split(":", 1)[1].lower()] = v

def usd(t, raw):
    p = prices.get((t or "").lower())
    if not p or raw is None: return 0.0
    dec = p.get("decimals")
    if dec is None: return 0.0
    return raw / 10**dec * float(p["price"])

total = 0.0
rows = []
for addr, idx, t, v in need:
    u = usd(t, v)
    total += u
    if u > 0.01:
        rows.append({"fees": addr, "token": t, "sym": d["tokens"].get(t, {}).get("symbol"), "raw": v, "usd": round(u, 2)})
rows.sort(key=lambda x: -x["usd"])
print("priced PairFees balances total USD:", round(total, 2))
for r in rows[:12]: print("  ", json.dumps(r))

# native balances
def rpc(payload):
    body = json.dumps(payload).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=60))

addrs = {
    "voter": "0xAAAf3D9CDD3602d117c67D80eEC37a160C8d9869",
    "minter": "0xAAA823aa799BDa3193D46476539bcb1da5B71330",
    "safe_owner_treasury": "0xC9d28676b7d470210a3C490B60729660eE5a7257",
    "v2_factory": "0xAAA16c016BF556fcD620328f0759252E29b1AB57",
    "nuri_token": "0xaaae8378809bb8815c08d3c59eb0c7d1529ad769",
    "pair_impl": "0xf5d139c3f51967505c532c42898ba47b15da4b9f",
}
native = {}
for i, (name, a) in enumerate(addrs.items()):
    r = rpc({"jsonrpc": "2.0", "id": i, "method": "eth_getBalance", "params": [a, "latest"]})
    native[name] = int(r["result"], 16) / 1e18
print("native ETH balances:", json.dumps(native, indent=1))

# NURI held by V2 pairs (sum raw)
nuri = "0xaaae8378809bb8815c08d3c59eb0c7d1529ad769"
nuri_raw = 0
for p in d["pairs"]:
    for i in (0, 1):
        if p.get(f"token{i}") == nuri:
            nuri_raw += p.get(f"balance_token{i}") or 0
implied = 0.0008082042893822046
print("NURI in V2 pairs:", nuri_raw / 1e18, "=> at DEX-implied $%.7f = $%.2f" % (implied, nuri_raw / 1e18 * implied))
print("Total V2 (DefiLlama only): $%.2f" % priced.get("total_usd_incl_nuri_implied", 0.0))
print("Total V2 + NURI at DEX-implied price: $%.2f" % (priced.get("total_usd_incl_nuri_implied", 0.0) + nuri_raw / 1e18 * implied))

out = {"pairfees_priced_total_usd": round(total, 2), "pairfees_top": rows,
       "native_eth": native, "nuri_in_v2_pairs": nuri_raw / 1e18,
       "nuri_implied_price_usd": implied,
       "total_v2_usd_defillama": priced.get("total_usd_incl_nuri_implied", 0.0),
       "total_v2_usd_incl_nuri_implied": round(priced.get("total_usd_incl_nuri_implied", 0.0) + nuri_raw / 1e18 * implied, 2)}
json.dump(out, open("/home/heisenberg/CA/nuri-cl/analysis/childC-v2-other-value.json", "w"), indent=1)
print("saved childC-v2-other-value.json")
