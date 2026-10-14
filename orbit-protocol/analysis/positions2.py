"""Batched position analysis for Orbit Protocol (Blast) — fast version.

For every candidate borrower: getAssetsIn + getAccountSnapshot (JSON-RPC batches),
then compute Compound account liquidity with true current prices (DefiLlama),
nominal and cash-realizable collateral values.

Writes ci-out/positions2.json. Read-only.
"""
import json
import os
import sys
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
OUTDIR = os.environ.get("CI_OUT", HERE)
CAND = os.environ.get("CANDIDATES", os.path.join(OUTDIR, "candidates.txt"))

RPCS = ([os.environ["BLAST_RPC_URL"]] if os.environ.get("BLAST_RPC_URL") else []) + [
    "https://blast-rpc.publicnode.com", "https://81457.rpc.thirdweb.com", "https://blast.drpc.org"]

MARKET_INFO = {
    "0xf92996ddc677a8dcb032ac5fe62bbf00f92ae2ec": ("c1 oETH#1", None, 18, 0.0),
    "0x9aecedcd6a82d26f2f86d331b17a1c1676442a87": ("c1 USDB", "0x4300000000000000000000000000000000000003", 18, 0.8),
    "0xf9b3b455f5d900f62bc1792a6ca6e1d47b989389": ("c1 oETH#2", None, 18, 0.8),
    "0x0872b71efc37cb8dde22b2118de3d800427fdba0": ("c1 oETHV2", None, 18, 0.8),
    "0x8c415331761063e5d6b1c8e700f996b13603fc2e": ("c1 BTC?", "0xf7bc58b8d8f97adc129cfc4c9f45ce3c0e1d2692", 8, 0.0),
    "0x795dcd51eac6eb3123b7a4a1f906992eaa54cb0e": ("c2 oETHV2", None, 18, 0.8),
    "0x4991b902f397dc16b0bbd21b0057a20b4b357ae2": ("c2 ezETH", "0x2416092f143378750bb29b79ed961ab195cceea5", 18, 0.8),
    "0xb51b76c73fb24f472e0dd63bb8195bd2170bc65d": ("c2 small", "0x66714db8f3397c767d0a602458b5b4e3c0fe7dd1", 18, 0.0),
    "0xafabd582e82042f4a8574f75c36409abea916ac5": ("c3 oETHV2", None, 18, 0.8),
    "0x9bbba6322fe5f3968c1f27c8b860727d683194c8": ("c3 wrsETH", "0xe7903b1f75c534dd8159b313d92cdcfbc62cb3cd", 18, 0.8),
    "0xd55634a79e571dc4c7cdd2f2c0a5857bf7a8a782": ("c3 small", "0x66714db8f3397c767d0a602458b5b4e3c0fe7dd1", 18, 0.0),
    "0xfb661cdcfcb62b4ed7bbef6f70068863e213cb6b": ("c3 weETH", "0x04c0599ae5a44757c0af6f9ec3b93da8976c150a", 18, 0.0),
    "0xa3135b76c28b3971b703a5e6cd451531b187eb5a": ("c3 DETH", "0x1da40c742f32bbee81694051c0ee07485fc630f6", 18, 0.6),
    "0x4adf85e2e760c9211894482df74ba535bcae50a4": ("c3 DUSD", "0x1a3d9b2fa5c6522c8c071dc07125ce55df90b253", 18, 0.6),
    "0x3a61f4bf054cdfac3a3436a21c4463c6d85c2408": ("c3 USDB", "0x4300000000000000000000000000000000000003", 18, 0.8),
    "0x7732e29e35e8a8b26e7f026c0865c7c2d88cf853": ("c3 USDe", "0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34", 18, 0.8),
    "0x586abb06179535de9eb6c6d968a355128dd74511": ("c3 RESC", "0x38e6da25e91fe7fc023bf2689a5bd0154e2f810a", 18, 0.8),
    "0x530a8d3fdf61112f8a879d753fe02e9e37ec36aa": ("c4 oETHV2", None, 18, 0.8),
    "0xe9391d8e1d5c970f7648852ffeda1a9f42833857": ("c4 weETH", "0x04c0599ae5a44757c0af6f9ec3b93da8976c150a", 18, 0.0),
    "0x7878c119f08052789f84cf4fdd3c3642fa291257": ("c4 DETH", "0x1da40c742f32bbee81694051c0ee07485fc630f6", 18, 0.0),
}
ETH_PSEUDO = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"

MARKET_CASH = {
    "0xf92996ddc677a8dcb032ac5fe62bbf00f92ae2ec": (43988628869122, 501107363454389877),
    "0x9aecedcd6a82d26f2f86d331b17a1c1676442a87": (63723584275331133032497, 459651566071149631863818474),
    "0xf9b3b455f5d900f62bc1792a6ca6e1d47b989389": (53825135219381941563, 293857649780349245476521),
    "0x0872b71efc37cb8dde22b2118de3d800427fdba0": (143471291963961746088, 876798331281321451907777),
    "0x8c415331761063e5d6b1c8e700f996b13603fc2e": (489430, 5315292807),
    "0x795dcd51eac6eb3123b7a4a1f906992eaa54cb0e": (9174863762532532945, 44342935848786060923994),
    "0x4991b902f397dc16b0bbd21b0057a20b4b357ae2": (8220120131778910544, 41100600658894552662769),
    "0xb51b76c73fb24f472e0dd63bb8195bd2170bc65d": (341061647564991163, 2365553754801414702352),
    "0xafabd582e82042f4a8574f75c36409abea916ac5": (0, 1),
    "0x9bbba6322fe5f3968c1f27c8b860727d683194c8": (1265548077755198259, 6285782610479507956481),
    "0xd55634a79e571dc4c7cdd2f2c0a5857bf7a8a782": (500955589781465776, 7549459302844168774666),
    "0xfb661cdcfcb62b4ed7bbef6f70068863e213cb6b": (24812034129007478, 111385566507240107170),
    "0xa3135b76c28b3971b703a5e6cd451531b187eb5a": (285041392884344883, 3182370817408458107978344),
    "0x4adf85e2e760c9211894482df74ba535bcae50a4": (15845955806501657, 3913608453541602533012899192),
    "0x3a61f4bf054cdfac3a3436a21c4463c6d85c2408": (1892217752813832621371, 151290414835385749614355420),
    "0x7732e29e35e8a8b26e7f026c0865c7c2d88cf853": (1234636237480297414715, 6172481187401487697550372),
    "0x586abb06179535de9eb6c6d968a355128dd74511": (9985211600000000000000, 50393719999994942996350109),
    "0x530a8d3fdf61112f8a879d753fe02e9e37ec36aa": (538497764765334795, 2826055523806824386864),
    "0xe9391d8e1d5c970f7648852ffeda1a9f42833857": (206703000000000004, 1033515000000000020000),
    "0x7878c119f08052789f84cf4fdd3c3642fa291257": (100000000000000000, 500000000000000000000),
}

FALLBACK_PRICES = {
    ETH_PSEUDO: 2509.42, "0x4300000000000000000000000000000000000003": 0.99506,
    "0x2416092f143378750bb29b79ed961ab195cceea5": 2511.0,
    "0x1da40c742f32bbee81694051c0ee07485fc630f6": 2511.36,
    "0xe7903b1f75c534dd8159b313d92cdcfbc62cb3cd": 2511.0,
    "0x04c0599ae5a44757c0af6f9ec3b93da8976c150a": 2511.0,
    "0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34": 0.99962,
    "0x1a3d9b2fa5c6522c8c071dc07125ce55df90b253": 0.99506,
    "0x38e6da25e91fe7fc023bf2689a5bd0154e2f810a": 0.0,
    "0x66714db8f3397c767d0a602458b5b4e3c0fe7dd1": 2.1999,
    "0xf7bc58b8d8f97adc129cfc4c9f45ce3c0e1d2692": 83280.82,
}


def pad(a):
    return a[2:].rjust(64, "0")


def words(h):
    h = h[2:] if isinstance(h, str) and h.startswith("0x") else ""
    return [h[i:i + 64] for i in range(0, len(h) - 63, 64)]


_DEAD_URLS = set()


def batch_call(items, chunk=10, retries=2):
    """items: list of (to, data). Returns list of results (or '__REVERT__'/None).

    Uses JSON-RPC batches; skips endpoints that keep failing/slow.
    """
    out = [None] * len(items)
    urls = [u for u in RPCS if u not in _DEAD_URLS] or RPCS
    for start in range(0, len(items), chunk):
        part = items[start:start + chunk]
        reqs = [{"jsonrpc": "2.0", "id": j, "method": "eth_call",
                 "params": [{"to": t, "data": d}, "latest"]} for j, (t, d) in enumerate(part)]
        body = json.dumps(reqs).encode()
        done = False
        for attempt in range(retries):
            for url in urls:
                t0 = time.time()
                try:
                    req = urllib.request.Request(url, data=body, headers={
                        "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
                    with urllib.request.urlopen(req, timeout=20) as r:
                        res = json.loads(r.read())
                    if isinstance(res, list):
                        for o in res:
                            if "result" in o:
                                out[start + o["id"]] = o["result"]
                            elif "error" in o:
                                out[start + o["id"]] = "__REVERT__"
                        done = True
                        break
                except Exception:  # noqa: BLE001
                    if time.time() - t0 > 15:
                        _DEAD_URLS.add(url)
                    continue
            if done:
                break
            time.sleep(0.3)
    return out


def fetch_prices():
    prices = {}
    ids = [f"blast:{t.lower()}" for t in {v[1] for v in MARKET_INFO.values() if v[1]}]
    try:
        url = "https://coins.llama.fi/prices/current/" + ",".join(ids + ["coingecko:ethereum"])
        with urllib.request.urlopen(url, timeout=30) as r:
            pj = json.loads(r.read())
        for k, v in pj.get("coins", {}).items():
            prices[k.split(":", 1)[1]] = v["price"]
    except Exception as e:  # noqa: BLE001
        print("price fetch failed:", e, flush=True)
    eth = prices.get("coingecko:ethereum") or prices.get("ethereum")
    if eth:
        prices[ETH_PSEUDO] = eth
    for k, v in FALLBACK_PRICES.items():
        prices.setdefault(k, v)
    return prices


def main():
    prices = fetch_prices()
    print("prices loaded:", len(prices), flush=True)
    cands = []
    with open(CAND) as f:
        for line in f:
            line = line.strip()
            if line and "," in line:
                comp, bor = line.split(",")
                cands.append((comp.lower(), bor.lower()))
    print(f"candidates: {len(cands)}", flush=True)

    results = []
    t0 = time.time()
    for start in range(0, len(cands), 20):
        part = cands[start:start + 20]
        # 1) getAssetsIn for the chunk
        assets_res = batch_call([(c, "0xabfceffc" + pad(b)) for c, b in part])
        asset_lists = []
        snap_items = []
        snap_index = []
        for k, (c, b) in enumerate(part):
            h = assets_res[k]
            assets = []
            if h and h != "__REVERT__" and words(h):
                ws = words(h)
                n = int(ws[1], 16) if len(ws) > 1 else 0
                assets = ["0x" + x[-40:] for x in ws[2:2 + n]]
            asset_lists.append(assets)
            for m in assets:
                snap_index.append((k, m))
                snap_items.append((m, "0xc37f68e2" + pad(b)))
        # 2) snapshots for the chunk
        snaps = batch_call(snap_items) if snap_items else []
        snap_by = {}
        for (k, m), h in zip(snap_index, snaps):
            snap_by.setdefault(k, {})[m.lower()] = h

        for k, (c, b) in enumerate(part):
            r = {"comptroller": c, "borrower": b, "assets": asset_lists[k], "positions": {},
                 "sumCollateral": 0.0, "sumBorrow": 0.0, "shortfall_usd": 0.0, "ok": True}
            for m in asset_lists[k]:
                ml = m.lower()
                info = MARKET_INFO.get(ml)
                h = snap_by.get(k, {}).get(ml)
                if not h or h == "__REVERT__" or not words(h):
                    r["ok"] = False
                    r["positions"][ml] = {"error": h}
                    continue
                ws = words(h)
                cbal = int(ws[1], 16)
                bbal = int(ws[2], 16)
                xrate = int(ws[3], 16)
                und = info[1] if info else None
                dec = info[2] if info else 18
                cf = info[3] if info else 0.0
                price = prices.get(und.lower() if und else ETH_PSEUDO) or 0.0
                tokensToDenom = cf * (xrate / 1e18) * price
                coll = tokensToDenom * (cbal / 1e18)
                debt = price * (bbal / 1e18)
                cash_ts = MARKET_CASH.get(ml)
                realizable = 0.0
                rho = None
                if cash_ts and cash_ts[1] > 0:
                    rho = cash_ts[0] / cash_ts[1]
                    realizable = (cbal * rho) / 10 ** dec * price
                r["sumCollateral"] += coll
                r["sumBorrow"] += debt
                r["positions"][ml] = {"cTokens": cbal, "borrow": bbal, "xrate": xrate, "cf": cf,
                                      "price": price, "collateral_usd": round(coll, 2),
                                      "debt_usd": round(debt, 2), "realizable_usd": round(realizable, 2),
                                      "rho": round(rho, 8) if rho is not None else None,
                                      "label": info[0] if info else ml}
            r["shortfall_usd"] = round(max(0.0, r["sumBorrow"] - r["sumCollateral"]), 2)
            r["sumCollateral"] = round(r["sumCollateral"], 2)
            r["sumBorrow"] = round(r["sumBorrow"], 2)
            results.append(r)
        if (start // 20 + 1) % 25 == 0:
            print(f"  {len(results)}/{len(cands)} ({time.time()-t0:.0f}s)", flush=True)

    underwater = [r for r in results if r["shortfall_usd"] > 1]
    underwater.sort(key=lambda r: -r["shortfall_usd"])
    # realizable collateral in profitable markets (rho>0.95)
    for r in underwater:
        r["realizable_collateral_usd"] = round(sum(
            p.get("realizable_usd", 0) for p in r["positions"].values() if (p.get("rho") or 0) > 0.95), 2)
    summary = {
        "candidates": len(cands),
        "scanned_ok": sum(1 for r in results if r["ok"]),
        "underwater_count": len(underwater),
        "underwater_with_realizable_collateral": sum(1 for r in underwater if r.get("realizable_collateral_usd", 0) > 1),
        "total_shortfall_usd": round(sum(r["shortfall_usd"] for r in underwater), 2),
        "total_realizable_collateral_usd": round(sum(r.get("realizable_collateral_usd", 0) for r in underwater), 2),
        "underwater_top": underwater[:40],
    }
    os.makedirs(OUTDIR, exist_ok=True)
    with open(os.path.join(OUTDIR, "positions2.json"), "w") as f:
        json.dump({"summary": summary, "all": results}, f, indent=1)
    print(json.dumps({k: v for k, v in summary.items() if k != "underwater_top"}, indent=1), flush=True)


if __name__ == "__main__":
    main()
