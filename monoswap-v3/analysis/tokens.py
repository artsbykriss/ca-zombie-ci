#!/usr/bin/env python3
"""Token metadata + DefiLlama prices for all MonoSwap V3 pool tokens. Read-only."""
import json, urllib.request, concurrent.futures as cf

RPCS = ["https://blast-rpc.publicnode.com", "https://rpc.blast.io"]

def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for rpc_url in RPCS:
        for a in range(3):
            try:
                req = urllib.request.Request(rpc_url, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
                with urllib.request.urlopen(req, timeout=25) as r:
                    d = json.loads(r.read())
                if "result" in d:
                    return d["result"]
                last = d.get("error")
            except Exception as e:
                last = e
    raise RuntimeError(str(last))

def call(to, data):
    return rpc("eth_call", [{"to": to, "data": data}, "latest"])

def dec_str(hexstr):
    b = bytes.fromhex(hexstr[2:])
    if len(b) < 64: return None
    off = int.from_bytes(b[0:32], "big")
    ln = int.from_bytes(b[off:off+32], "big")
    return b[off+32:off+32+ln].decode("utf-8", "replace")

state = json.load(open("/home/heisenberg/CA/monoswap-v3/analysis/live_state2.json"))
pools = state["pools"]
tokens = set()
for k, v in pools.items():
    tokens.add(v["t0"].lower()); tokens.add(v["t1"].lower())

meta = {}
def get_meta(t):
    try:
        sym = dec_str(call(t, "0x95d89b41"))  # symbol()
    except Exception:
        sym = None
    try:
        dec = int(call(t, "0x313ce567"), 16)  # decimals()
    except Exception:
        dec = None
    try:
        name = dec_str(call(t, "0x06fdde03"))
    except Exception:
        name = None
    return t, {"symbol": sym, "decimals": dec, "name": name}

with cf.ThreadPoolExecutor(max_workers=6) as ex:
    for t, m in ex.map(get_meta, sorted(tokens)):
        meta[t] = m

# DefiLlama prices (blast chain)
prices = {}
try:
    addrs = ",".join(sorted(tokens))
    url = f"https://coins.llama.fi/prices/current/blast:{','.join(sorted(tokens))}"
    # llama expects chain:addr comma separated; do chunks of 10
    toks = sorted(tokens)
    for i in range(0, len(toks), 10):
        chunk = toks[i:i+10]
        u = "https://coins.llama.fi/prices/current/" + ",".join("blast:" + a for a in chunk)
        req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0"})
        d = json.loads(urllib.request.urlopen(req, timeout=30).read())
        for k, v in d.get("coins", {}).items():
            prices[k.split(":")[1]] = v
except Exception as e:
    print("price fetch err:", e)

out = {"meta": meta, "prices": prices}
json.dump(out, open("/home/heisenberg/CA/monoswap-v3/analysis/tokens.json", "w"), indent=1)
for t in sorted(tokens):
    m = meta[t]
    p = prices.get(t)
    print(f"{t} {m['symbol']} dec={m['decimals']} price={p['price'] if p else None}")
