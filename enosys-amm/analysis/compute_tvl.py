#!/usr/bin/env python3
"""Compute per-pool and total USD TVL from pools_live.json. Read-only."""
import json, urllib.request, time

d = json.load(open("pools_live.json"))

def fetch_prices(addrs, chain="flare"):
    out = {}
    for i in range(0, len(addrs), 40):
        part = addrs[i:i+40]
        u = "https://coins.llama.fi/prices/current/" + ",".join(f"{chain}:{a}" for a in part)
        r = json.loads(urllib.request.urlopen(u, timeout=40).read().decode())["coins"]
        for k, v in r.items():
            out[k.split(":")[1].lower()] = v["price"]
    return out

def compute_flare():
    ch = d["chains"]["14"]; toks = ch["tokens"]
    addrs = sorted({v["token0"] for v in ch["pools"].values()} | {v["token1"] for v in ch["pools"].values()})
    prices = fetch_prices(addrs, "flare")
    # derive missing from the deepest WFLR pool
    wflr = prices["0x1d80c49bbbcd1c0911346656b529df9e5c2f783d"]
    def derive(pool, side):
        v = ch["pools"][pool]; t = v["token0"]; q = v["token1"]
        if side == 1:
            b0 = v["bal0"] / 10**toks[t]["decimals"]; b1 = v["bal1"] / 10**toks[q]["decimals"]
            other = prices.get(t.lower())
            return (b0 * (other if other else wflr)) / b1 if b1 else 0
    derived = {
        "eETH": derive("0x507ba799d81c8e7848fa4e0c966bf96a7e28b5cd", 1),
        "eQNT": derive("0xe6fbab907141a578c51326c25300950a1c38b27c", 1),
        "FACT": derive("0xa49b020de0216dbd059bb580fdc48bed758815ae", 1),
    }
    for a, v in toks.items():
        if v["symbol"] in derived and a.lower() not in prices:
            prices[a.lower()] = derived[v["symbol"]]
    rows = []
    for p, v in ch["pools"].items():
        t0, t1 = v["token0"], v["token1"]
        d0, d1 = toks[t0]["decimals"], toks[t1]["decimals"]
        usd = (v.get("bal0") or 0) / 10**d0 * prices.get(t0.lower(), 0) + \
              (v.get("bal1") or 0) / 10**d1 * prices.get(t1.lower(), 0)
        rows.append({"pool": p, "pair": f'{toks[t0]["symbol"]}/{toks[t1]["symbol"]}',
                     "fee": v["fee"], "usd": usd, "token0": t0, "token1": t1,
                     "bal0": v.get("bal0"), "bal1": v.get("bal1"),
                     "liquidity": v["liquidity"], "slot0_raw": v["slot0_raw"]})
    rows.sort(key=lambda x: -x["usd"])
    return {"block": ch["block"], "total_usd": sum(r["usd"] for r in rows), "pools": rows,
            "prices": prices, "derived": derived}

def compute_songbird():
    ch = d["chains"]["19"]; toks = ch["tokens"]
    px = {"WSGB": 0.00080549, "exUSDT": 1.0, "FXRP": 1.30, "exXDC": 0.03331155,
          "exETH": 2411.41, "USDX": 1.0, "FDOGE": 0.0}
    # derive EXFI/SFIN from WSGB pools
    v = ch["pools"]["0x296d52ac39562458e4c0b42437eca2db9f750d0e"]
    px["EXFI"] = (v["bal0"] / 10**toks[v["token0"]]["decimals"]) / \
                 (v["bal1"] / 10**toks[v["token1"]]["decimals"]) * px["WSGB"]
    v = ch["pools"]["0xbb3979bf08821b9975a52a8214bc6f6abff18a2e"]
    px["SFIN"] = (v["bal0"] / 10**toks[v["token0"]]["decimals"]) / \
                 (v["bal1"] / 10**toks[v["token1"]]["decimals"]) * px["WSGB"]
    rows = []
    for p, v in ch["pools"].items():
        t0, t1 = v["token0"], v["token1"]
        d0, d1 = toks[t0]["decimals"], toks[t1]["decimals"]
        usd = (v.get("bal0") or 0) / 10**d0 * px.get(toks[t0]["symbol"], 0) + \
              (v.get("bal1") or 0) / 10**d1 * px.get(toks[t1]["symbol"], 0)
        rows.append({"pool": p, "pair": f'{toks[t0]["symbol"]}/{toks[t1]["symbol"]}',
                     "fee": v["fee"], "usd": usd, "token0": t0, "token1": t1,
                     "bal0": v.get("bal0"), "bal1": v.get("bal1"),
                     "liquidity": v["liquidity"], "slot0_raw": v["slot0_raw"]})
    rows.sort(key=lambda x: -x["usd"])
    return {"block": ch["block"], "total_usd": sum(r["usd"] for r in rows), "pools": rows, "prices": px}

out = {"read_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
       "flare": compute_flare(), "songbird": compute_songbird()}
out["total_local_usd"] = out["flare"]["total_usd"] + out["songbird"]["total_usd"]
json.dump(out, open("tvl_final.json", "w"), indent=1)
print("flare", round(out["flare"]["total_usd"], 2), "at", out["flare"]["block"])
print("songbird", round(out["songbird"]["total_usd"], 2), "at", out["songbird"]["block"])
print("total local", round(out["total_local_usd"], 2))
print("top flare")
for r in out["flare"]["pools"][:10]: print(f'  {r["usd"]:14,.2f} {r["pool"]} {r["pair"]} fee={r["fee"]}')
print("top songbird")
for r in out["songbird"]["pools"][:6]: print(f'  {r["usd"]:12,.2f} {r["pool"]} {r["pair"]} fee={r["fee"]}')
