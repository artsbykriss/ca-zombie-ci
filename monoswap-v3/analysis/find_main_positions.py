#!/usr/bin/env python3
"""Find LP positions in the main USDB/WETH pool (corrected filter: t0=USDB, t1=WETH, fee=3000)."""
import json, urllib.request, concurrent.futures as cf
RPC = "https://blast-rpc.publicnode.com"
NPM = "0x0f0c3de3cd5185454ede5ef184bc9c7f4133fb90"
USDB = "0x4300000000000000000000000000000000000003"
WETH = "0x4300000000000000000000000000000000000004"

def call(to, data, t=8):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                       "params": [{"to": to, "data": data}, "latest"]}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=t) as r:
        return json.loads(r.read()).get("result")

def pos(i):
    try:
        h = call(NPM, "0x99fbab88" + hex(i)[2:].rjust(64, "0"))
    except Exception:
        return None
    if not h or len(h) < 2 + 64 * 12:
        return None
    w = [h[2:][k * 64:(k + 1) * 64] for k in range(12)]
    u = lambda x: int(x, 16)
    return {"id": i, "t0": "0x" + w[2][-40:], "t1": "0x" + w[3][-40:], "fee": u(w[4]),
            "tl": u(w[5]), "tu": u(w[6]), "liq": u(w[7]), "owed0": u(w[10]), "owed1": u(w[11])}

ids = list(range(1, 11407))
found = []
with cf.ThreadPoolExecutor(max_workers=16) as ex:
    for r in ex.map(pos, ids):
        if r and r["t0"].lower() == USDB and r["t1"].lower() == WETH and r["liq"] > 0:
            found.append(r)
            print("FOUND", r, flush=True)
found.sort(key=lambda r: -r["liq"])
json.dump(found, open("/home/heisenberg/CA/monoswap-v3/analysis/main_pool_positions.json", "w"), indent=1)
print("open main-pool positions:", len(found))
for f in found[:10]:
    print(f)
