#!/usr/bin/env python3
"""Read-only SaucerSwap V2 pool enumeration + live balance/TVL snapshot (Hedera mainnet).
Keyless public endpoints only. No transactions are signed or sent.

Usage: python3 enumerate_pools.py
Outputs: pools.json, tokens.json, pool_balances.json, pool_tvl.json (in cwd)
"""
import json, urllib.request, time

RPC = "https://mainnet.hashio.io/api"
MIRROR = "https://mainnet-public.mirrornode.hedera.com/api/v1"
FACTORY_ID = "0.0.3946833"
POOL_TOPIC = "0x783cca1c0412dd0d695e784568c96da2e9c22ff989357a2e8b1d9b2b4e6b7118"
UA = {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"}


def get(url):
    for _ in range(5):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=40) as r:
                return json.load(r)
        except Exception:
            time.sleep(2)
    return None


def eth_call(to, data):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                       "params": [{"to": to, "data": data}, "latest"]}).encode()
    for _ in range(6):
        try:
            req = urllib.request.Request(RPC, data=body, headers=UA)
            with urllib.request.urlopen(req, timeout=30) as r:
                d = json.load(r)
            if d.get("result") and d["result"] != "0x":
                return d["result"]
        except Exception:
            pass
        time.sleep(1)
    return None


def enumerate_pools():
    url = f"{MIRROR}/contracts/{FACTORY_ID}/results/logs?limit=100"
    rows, pages = [], 0
    while url and pages < 50:
        d = get(url)
        if d is None:
            break
        for lg in d.get("logs", []):
            if lg["topics"] and lg["topics"][0] == POOL_TOPIC:
                t0 = "0x" + lg["topics"][1][-40:]
                t1 = "0x" + lg["topics"][2][-40:]
                fee = int(lg["topics"][3], 16)
                data = lg["data"][2:]
                ts = int(data[:64], 16)
                if ts >= 2 ** 23:
                    ts -= 2 ** 24
                pool = "0x" + data[64 + 24:128]
                rows.append(dict(block=lg["block_number"], ts=lg["timestamp"], token0=t0,
                                 token1=t1, fee=fee, tickSpacing=ts, pool=pool))
        nxt = d.get("links", {}).get("next")
        url = (MIRROR + nxt) if nxt else None
        pages += 1
    return rows


def main():
    pools = enumerate_pools()
    json.dump(pools, open("pools.json", "w"), indent=1)
    print("pools:", len(pools))

    tid = lambda a: "0.0." + str(int(a, 16))
    addrs = sorted({p["token0"] for p in pools} | {p["token1"] for p in pools})
    tokens = {}
    for a in addrs:
        d = get(f"{MIRROR}/tokens/{tid(a)}")
        if d:
            tokens[a] = dict(id=tid(a), symbol=d.get("symbol"), dec=d.get("decimals"),
                             type=d.get("type"))
    json.dump(tokens, open("tokens.json", "w"), indent=1)

    out = []
    for p in pools:
        b = {}
        for k in ("token0", "token1"):
            v = eth_call(p[k], "0x70a08231" + p["pool"][2:].rjust(64, "0"))
            b[k] = int(v, 16) if v else None
        out.append(dict(pool=p["pool"], fee=p["fee"], tickSpacing=p["tickSpacing"],
                        token0=p["token0"], token1=p["token1"],
                        sym0=tokens.get(p["token0"], {}).get("symbol"),
                        sym1=tokens.get(p["token1"], {}).get("symbol"),
                        dec0=tokens.get(p["token0"], {}).get("dec"),
                        dec1=tokens.get(p["token1"], {}).get("dec"),
                        bal0=b["token0"], bal1=b["token1"], ts=p["ts"], block=p["block"]))
        time.sleep(0.1)
    json.dump(out, open("pool_balances.json", "w"), indent=1)
    print("balances written")


if __name__ == "__main__":
    main()
