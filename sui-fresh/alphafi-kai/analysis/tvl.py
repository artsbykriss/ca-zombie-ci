#!/usr/bin/env python3
"""Compute AlphaLend market TVL in USD using market state + DefiLlama prices."""
import json, urllib.request, time

EP = "https://graphql.mainnet.sui.io/graphql"

def gql(q, v):
    b = json.dumps({"query": q, "variables": v}).encode()
    r = urllib.request.Request(EP, data=b, headers={"Content-Type": "application/json"})
    return json.loads(urllib.request.urlopen(r, timeout=90).read().decode())

def llama(coin_types):
    # batch query
    keys = ",".join("sui:0x" + c if not c.startswith("0x") else "sui:" + c for c in coin_types)
    url = "https://coins.llama.fi/prices/current/" + keys
    try:
        with urllib.request.urlopen(url, timeout=60) as r:
            return json.loads(r.read().decode()).get("coins", {})
    except Exception as e:
        return {}

def main():
    markets = json.load(open("markets.json"))
    rows = []
    cts = []
    for mid, m in markets.items():
        if not m: continue
        ct = m["coin_type"]
        cts.append(ct)
    # decimals via coinMetadata
    dec = {}
    for ct in cts:
        j = gql("query($t:String!){ coinMetadata(coinType:$t){ decimals symbol } }", {"t": ct})
        md = (j.get("data") or {}).get("coinMetadata")
        dec[ct] = md["decimals"] if md else None
    prices = {}
    for i in range(0, len(cts), 8):
        prices.update(llama(cts[i:i+8]))
        time.sleep(0.3)
    total = 0.0
    for mid, m in sorted(markets.items(), key=lambda x: int(x[0])):
        if not m: continue
        ct = m["coin_type"]
        d = dec.get(ct)
        pi = prices.get("sui:0x" + ct, {})
        p = pi.get("price")
        if d is None:
            d = pi.get("decimals")
        bal = int(m["balance_holding"]); bor = int(m["borrowed_amount"])
        if d is None or p is None:
            rows.append((mid, ct.split("::")[-1], d, p, bal, bor, None)); continue
        usd = (bal + bor) / (10 ** d) * p
        total += usd
        rows.append((mid, ct.split("::")[-1], d, p, bal, bor, usd))
    print(f"{'mkt':>3} {'coin':<16} {'dec':>3} {'price':>10} {'bal':>20} {'borrow':>16} {'usd':>12}")
    for r in rows:
        print(f"{r[0]:>3} {r[1]:<16} {str(r[2]):>3} {('%.6g'%r[3]) if r[3] else '-':>10} {r[4]:>20} {r[5]:>16} {('%.2f'%r[6]) if r[6] is not None else 'n/a':>12}")
    print(f"\nAlphaLend markets total (avail+borrowed) ~= ${total:,.2f}")

if __name__ == "__main__":
    main()
