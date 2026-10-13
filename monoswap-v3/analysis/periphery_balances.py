#!/usr/bin/env python3
"""Check stray token balances of MonoSwap periphery contracts (NPM/routers/factory). Read-only."""
import json, urllib.request, concurrent.futures as cf

RPCS = ["https://blast-rpc.publicnode.com", "https://rpc.blast.io", "https://blast.drpc.org"]

def call(rpc_url, to, data, timeout=12):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                       "params": [{"to": to, "data": data}, "latest"]}).encode()
    req = urllib.request.Request(rpc_url, data=body,
        headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        d = json.loads(r.read())
    return d.get("result")

def bal(owner, token, idx):
    data = "0x70a08231" + "000000000000000000000000" + owner[2:].lower()
    for a in range(3):
        try:
            res = call(RPCS[(idx + a) % len(RPCS)], token, data)
            return int(res, 16) if res else 0
        except Exception:
            continue
    return None

OWNERS = {
    "npm": "0x0f0c3de3cd5185454ede5ef184bc9c7f4133fb90",
    "swapRouter": "0x334641e7de5e0de838d050b9fc05093fc7063b4c",
    "router02?": "0x1fdf0dba0c1cda76ee7cf57a69ca08cb1ae7b4bc",
    "v2router": "0x816381bb69a22c5fdddb09af8eeedf7b340318f2",
    "factory": "0x48d0f09710794313f33619c95147f34458bf7c3b",
    "v2factory": "0xe27cb06a15230a7480d02956a3521e78c5bfd2d0",
}
toks = json.load(open("/home/heisenberg/CA/monoswap-v3/analysis/tokens.json"))
meta = toks["meta"]; prices = {k.lower(): v["price"] for k, v in toks["prices"].items()}
TOKENS = sorted(meta.keys()) + ["0x4300000000000000000000000000000000000003",
                                "0x4300000000000000000000000000000000000004"]

tasks = []
for oname, oaddr in OWNERS.items():
    for i, t in enumerate(TOKENS):
        tasks.append((oname, oaddr, t, i))

res = {}
def run(task):
    oname, oaddr, t, i = task
    v = bal(oaddr, t, i)
    return (oname, t), v

with cf.ThreadPoolExecutor(max_workers=12) as ex:
    for key, v in ex.map(run, tasks):
        res[key] = v

out = {}
for (oname, t), v in sorted(res.items()):
    if v:
        sym = meta.get(t, {}).get("symbol", "?")
        pr = prices.get(t.lower())
        usd = (v / 10 ** (meta.get(t, {}).get("decimals") or 18)) * pr if pr else 0
        out.setdefault(oname, []).append({"token": t, "symbol": sym, "raw": str(v), "usd": round(usd, 2)})
json.dump(out, open("/home/heisenberg/CA/monoswap-v3/analysis/periphery_balances.json", "w"), indent=1)
print(json.dumps(out, indent=1))
