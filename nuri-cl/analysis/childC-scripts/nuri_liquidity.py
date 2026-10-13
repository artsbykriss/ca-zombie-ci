#!/usr/bin/env python3
"""NURI exit-liquidity probe: V2 pairs containing NURI + all CL pools' current balances."""
import json, urllib.request, subprocess

RPC = "https://rpc.scroll.io"
NURI = "0xaaae8378809bb8815c08d3c59eb0c7d1529ad769"
WETH = "0x5300000000000000000000000000000000000004"

def enc_addr(a):
    return a.lower().replace("0x", "").rjust(64, "0")

def rpc_batch(payload):
    body = json.dumps(payload).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=60))

def block_number():
    return int(rpc_batch([{"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}])[0]["result"], 16)

block = block_number()
print("block", block)

# V2 pairs containing NURI
d = json.load(open("/home/heisenberg/CA/nuri-cl/analysis/childC-v2-pairs.json"))
v2 = []
for p in d["pairs"]:
    if p.get("token0") == NURI or p.get("token1") == NURI:
        i = 0 if p.get("token0") == NURI else 1
        v2.append({"pair": p["pair"], "symbol": p.get("symbol"), "nuri_raw": p.get(f"balance_token{i}"),
                   "other_token": p.get(f"token{1-i}"), "other_raw": p.get(f"balance_token{1-i}")})
print("V2 pairs with NURI:", len(v2))
for v in sorted(v2, key=lambda x: -(x["nuri_raw"] or 0)):
    print("  ", v["pair"], v["symbol"], "NURI", (v["nuri_raw"] or 0) / 1e18, "other", v["other_raw"])

# CL pools with NURI (from parent's pool_info.json)
pi = json.load(open("/home/heisenberg/CA/nuri-cl/analysis/pool_info.json"))
cl = []
for pool in pi:
    toks = [pool["t0"], pool["t1"]]
    if NURI in [t.lower() for t in toks]:
        cl.append(pool)
print("CL pools with NURI:", len(cl))
# balances
calls = []
meta = []
for i, p in enumerate(cl):
    calls.append({"jsonrpc": "2.0", "id": 2 * i, "method": "eth_call",
                  "params": [{"to": NURI, "data": "0x70a08231" + enc_addr(p["pool"])}, hex(block)]})
    calls.append({"jsonrpc": "2.0", "id": 2 * i + 1, "method": "eth_call",
                  "params": [{"to": p["t0"] if p["t1"].lower() == NURI else p["t1"], "data": "0x70a08231" + enc_addr(p["pool"])}, hex(block)]})
res = {}
for s in range(0, len(calls), 10):
    for it in rpc_batch(calls[s:s+10]):
        res[it["id"]] = it.get("result")
out = []
for i, p in enumerate(cl):
    nr = res.get(2 * i)
    orr = res.get(2 * i + 1)
    nr = int(nr, 16) if isinstance(nr, str) and nr != "0x" else None
    orr = int(orr, 16) if isinstance(orr, str) and orr != "0x" else None
    other = p["t0"] if p["t1"].lower() == NURI else p["t1"]
    out.append({"pool": p["pool"], "other": other, "nuri_raw": nr, "other_raw": orr,
                "nuri_human": (nr / 1e18) if nr else 0.0, "liq_snapshot": p.get("liq")})
    print("  CL", p["pool"], "other", other, "NURI", (nr / 1e18) if nr else 0, "other_raw", orr)
json.dump({"block": block, "v2_nuri_pairs": v2, "cl_nuri_pools": out},
          open("/home/heisenberg/CA/nuri-cl/analysis/childC-nuri-liquidity.json", "w"), indent=1)

# quote: sell NURI on deepest V2 pair
deepest = max(v2, key=lambda x: (x["other_raw"] or 0))
if deepest["other_token"].lower() == WETH:
    data = "0x" + subprocess.run(["cast", "calldata", "getAmountOut(uint256,address)(uint256)", str(10**18), NURI],
                                 capture_output=True, text=True).stdout.strip().split("0x")[-1]
    for amount in (10**18, 10**21, 10**23, 10**24, 809757 * 10**18):
        data = "0x2b85f8dd" if False else None
    # getAmountOut(uint256,address) selector
    sel = subprocess.run(["cast", "sig", "getAmountOut(uint256,address)"], capture_output=True, text=True).stdout.strip()
    print("selector", sel)
    for amount in (10**18, 10**21, 10**22, 10**23, 10**24):
        cd = sel + hex(amount)[2:].rjust(64, "0") + enc_addr(NURI)
        r = rpc_batch([{"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                        "params": [{"to": deepest["pair"], "data": cd}, hex(block)]}])[0]
        if "result" in r and r["result"] not in (None, "0x"):
            outw = int(r["result"], 16) / 1e18
            print(f"sell {amount/1e18:.3f} NURI -> {outw:.6f} WETH (${outw*2508.44:.2f})")
        else:
            print("sell", amount / 1e18, "->", r.get("error", r))
