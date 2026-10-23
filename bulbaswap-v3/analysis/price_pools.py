#!/usr/bin/env python3
"""Price pools + measure periphery balances. Read-only, keyless RPC."""
import json, subprocess, time, urllib.request

RPC = "https://rpc.morphl2.io"
pools = json.load(open("pools_state.json"))
tokens = json.load(open("tokens.json"))
WETH = "0x5300000000000000000000000000000000000011"

def batch(calls, block_tag="latest"):
    out = []
    for i in range(0, len(calls), 40):
        chunk = calls[i:i+40]
        payload = json.dumps([{"jsonrpc": "2.0", "id": k, "method": "eth_call",
                               "params": [{"to": c[0], "data": c[1]}, block_tag]}
                              for k, c in enumerate(chunk)])
        for attempt in range(5):
            try:
                raw = subprocess.run(["curl", "-s", "-X", "POST", "-H", "Content-Type: application/json",
                                      "--data", payload, RPC], capture_output=True, text=True, timeout=90).stdout
                j = json.loads(raw)
                if isinstance(j, list):
                    j.sort(key=lambda x: x["id"])
                    out.extend([x.get("result", "0x") for x in j])
                    break
            except Exception:
                pass
            time.sleep(1.5*(attempt+1))
    return out

def dec_uint(h):
    return int(h, 16) if h and h != "0x" else 0

def enc_addr(a):
    return "0x70a08231" + "0"*24 + a[2:].lower()

def enc_sym():
    return "0x95d89b41"

def enc_dec():
    return "0x313ce567"

# --- decimals + symbol for each token ---
calls = []
for t in tokens:
    calls += [(t, enc_dec()), (t, enc_sym())]
res = batch(calls)
meta = {}
for i, t in enumerate(tokens):
    dec = dec_uint(res[2*i])
    raw = res[2*i+1]
    sym = None
    try:
        b = bytes.fromhex(raw[2:])
        if len(b) >= 64:
            off = int.from_bytes(b[:32], "big")
            ln = int.from_bytes(b[off:off+32], "big")
            sym = b[off+32:off+32+ln].decode("utf-8", "replace")
        elif len(b) >= 32:
            sym = b[:32].split(b"\x00")[0].decode("utf-8", "replace")
    except Exception:
        pass
    meta[t] = {"decimals": dec, "symbol": sym}
json.dump(meta, open("token_meta.json", "w"), indent=1)
print("token meta done", flush=True)

# --- prices from DefiLlama (morph:<addr>) ---
prices = {}
allt = tokens + [WETH]
for i in range(0, len(allt), 40):
    chunk = allt[i:i+40]
    ids = ",".join("morph:" + a for a in chunk)
    url = "https://coins.llama.fi/prices/current/" + ids
    try:
        j = json.loads(urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "curl/8"}), timeout=60).read())
        for k, v in j.get("coins", {}).items():
            prices[k.split(":", 1)[1].lower()] = {"price": v["price"], "symbol": v.get("symbol"), "decimals": v.get("decimals")}
    except Exception as e:
        print("price err", e)
    time.sleep(0.3)
json.dump(prices, open("prices.json", "w"), indent=1)
print("prices for", len(prices), "tokens")

# --- pool USD ---
rows = []
for p in pools:
    usd = 0.0
    parts = []
    for tok, bal in ((p["token0"], p["bal0"]), (p["token1"], p["bal1"])):
        dec = meta.get(tok, {}).get("decimals", 18)
        pr = prices.get(tok.lower(), {}).get("price")
        amt = int(bal) / (10 ** dec) if dec else 0
        u = amt * pr if pr else None
        if u:
            usd += u
        parts.append({"token": tok, "symbol": meta.get(tok, {}).get("symbol"), "amount": amt, "price": pr, "usd": u})
    rows.append({"pool": p["pool"], "fee": p["fee_onchain"], "token0": p["token0"], "token1": p["token1"],
                 "liquidity": p["liquidity"], "reserves_usd": round(usd, 2), "parts": parts,
                 "block": p["block"], "cardinalityNext": p["slot0"]["observationCardinalityNext"]})
rows.sort(key=lambda r: -r["reserves_usd"])
total = sum(r["reserves_usd"] for r in rows)
print(f"TOTAL reserves USD = {total:,.2f}")
json.dump({"total_usd": total, "pools": rows}, open("pool_usd.json", "w"), indent=1)
for r in rows[:20]:
    print(f"{r['pool']} fee={r['fee']} ${r['reserves_usd']:>12,.2f}  " +
          " | ".join(f"{x['symbol']}:{x['amount']:.4f}(${x['usd'] or 0:,.0f})" for x in r["parts"]))
