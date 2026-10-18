#!/usr/bin/env python3
"""CI re-validation for zkSwap V2 (public zkSync Era RPC only)."""
import json, os, urllib.request

RPC = "https://mainnet.era.zksync.io"
FACTORY = "0xeeE1Af1CE68D280e9cAfD861B7d4af776798F18d"
PAIR0 = "0xa55e595aaeda7f8f8e74b0f765b1c9f7eaa0540d"
DEAD = "0x000000000000000000000000000000000000dEaD"

def rpc(method, params):
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
                                 headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        j = json.load(r)
    if "error" in j:
        raise RuntimeError(j["error"])
    return j["result"]

def call(to, data):
    return rpc("eth_call", [{"to":to,"data":data}, "latest"])

def w(h):
    return int(h, 16) if h and h != "0x" else 0

def enc_swap(a0, a1):
    return "0x022c0d9f" + "%064x"%a0 + "%064x"%a1 + "%064x"%int(DEAD,16) + "%064x"%128 + "%064x"%0

block = int(rpc("eth_blockNumber", []), 16)
ALEN = "0x574f2ba3"      # allPairsLength()
n = w(call(FACTORY, ALEN))
feeTo = "0x" + call(FACTORY, "0x017e7e58")[-40:]          # feeTo()
FTS = "0x094b7415"       # feeToSetter()
feeToSetter = "0x" + call(FACTORY, FTS)[-40:]
res = call(PAIR0, "0x0902f1ac")
r0, r1, ts = w(res[2:66]), w(res[2+64:2+128]), w(res[2+128:2+192])
sup = w(call(PAIR0, "0x18160ddd"))
b0 = w(call("0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4", "0x70a08231" + "%064x"%int(PAIR0,16)))
b1 = w(call("0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91", "0x70a08231" + "%064x"%int(PAIR0,16)))

def probe(a0, a1):
    try:
        call(PAIR0, enc_swap(a0, a1))
        return {"ok": True}
    except Exception as e:
        return {"ok": False, "error": str(e)[:180]}

p0 = probe(max(0, r0-1), 0)
p1 = probe(0, max(0, r1-1))
out = {
  "chain": "zksync-era", "block": block,
  "factory": FACTORY, "allPairsLength": n, "feeTo": feeTo, "feeToSetter": feeToSetter,
  "pair0": {"token0": "0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4",
             "token1": "0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91",
             "reserve0": r0, "reserve1": r1, "blockTimestampLast": ts,
             "lpTotalSupply": sup, "balance0": b0, "balance1": b1,
             "surplus0": b0-r0, "surplus1": b1-r1},
  "drain_probe_token0": p0, "drain_probe_token1": p1,
  "checks": {
    "pairs_48": n == 48,
    "no_surplus": b0 == r0 and b1 == r1,
    "drain0_blocked": not p0["ok"],
    "drain1_blocked": not p1["ok"],
    "feeTo_zero": feeTo == "0x"+"0"*40,
    "lp_supply_live": sup > 0
  }
}
out["all_passed"] = all(out["checks"].values())
os.makedirs("ci-out", exist_ok=True)
json.dump(out, open("ci-out/validation.json","w"), indent=1)
print(json.dumps(out, indent=1))
if not out["all_passed"]:
    raise SystemExit(1)
