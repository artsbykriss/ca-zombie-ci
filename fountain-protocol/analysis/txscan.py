#!/usr/bin/env python3
"""Scan Nexus tx history for Fountain contracts: decode selectors, find admin/pause/borrow/liquidate calls.
Read-only. Caches pages under analysis/nexus/.
"""
import json, base64, urllib.request, os, sys, time

BASE = "https://nexus.oasis.io/v1/emerald"
CACHE = os.path.join(os.path.dirname(__file__), "nexus")
os.makedirs(CACHE, exist_ok=True)

def get(url, cache_name):
    path = os.path.join(CACHE, cache_name)
    if os.path.exists(path) and os.path.getsize(path) > 0:
        return json.load(open(path))
    for a in range(4):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "fountain-probe/1.0"})
            with urllib.request.urlopen(req, timeout=60) as r:
                d = json.loads(r.read())
            json.dump(d, open(path, "w"))
            return d
        except Exception as e:
            if a == 3: raise
            time.sleep(2)
    return {}

# selector map: computed with cast sig offline
SEL = {
    "0xc2998238": "enterMarkets(address[])",
    "0x2d70db78": "_setSeizePaused(bool)",
    "0x8ebf6364": "_setTransferPaused(bool)",
    "0x3bcf7ec1": "_setMintPaused(address,bool)",
    "0x18c882a5": "_setBorrowPaused(address,bool)",
    "0x5f5af1aa": "_setPauseGuardian(address)",
    "0x55ee1fe1": "_setPriceOracle(address)",
    "0xc1e80334": "_acceptImplementation()",
    "0xe992a041": "_setPendingImplementation(address)",
    "0xbb82aa5e": "comptrollerImplementation()",
    "0xf5e3c462": "liquidateBorrow(address,uint256,address)",
    "0xaae40a2a": "liquidateBorrow(address,address)",
    "0x2608f818": "repayBorrowBehalf(address,uint256)",
    "0xc5ebeaec": "borrow(uint256)",
    "0x0e752702": "repayBorrow(uint256)",
    "0xa0712d68": "mint(uint256)",
    "0xdb006a75": "redeem(uint256)",
    "0x852a12e3": "redeemUnderlying(uint256)",
    "0x1249c58b": "mint()",
    "0x8da5cb5b": "owner()",
    "0xde45f5c2": "_setCompSpeeds(address[],uint256[],uint256[])",
    "0x5b14f183": "_setCollateralFactor(address,uint256)",
    "0x2c1e8796": "_setLiquidationIncentive(uint256)",
    "0x3d9b4f2e": "_setCloseFactor(uint256)",
    "0xda3d454c": "borrowAllowed(address,address,uint256)",
    "0xb6a8f0a9": "grantCompInternal(address,uint256)",
    "0x598d6b09": "_grantComp(address,uint256)",
    "0x3223ca2b": "_addReserves(uint256)",
    "0x601a0bf1": "_reduceReserves(uint256)",
    "0x1bce1950": "isComptroller()",
    "0x0cfbeb95": "startSpeedTime()",
    "0x1a34a67d": "initMining(uint256)",
    "0xc37f68e2": "getAccountSnapshot(address)",
    "0x4dec04e7": "accrueInterest()",
    "0x09a5cb22": "redeemUnderlying(uint256)",
    "0x0f22674a": "exchangeRateCurrent()",
    "0x5ec88c79": "getAccountLiquidity(address)",
    "0x6c7f0b0a": "claimComp(address)",
    "0x1c3db2e0": "claimComp(address,address[])",
}

def decode(data_b64):
    try:
        b = base64.b64decode(data_b64)
        return "0x" + b[:4].hex()
    except Exception:
        return None

def scan(addr, label, max_pages=30):
    out = []
    total = None
    for page in range(max_pages):
        url = f"{BASE}/transactions?rel={addr}&limit=100&offset={page*100}"
        d = get(url, f"{label}-tx-{page}.json")
        txs = d.get("transactions", [])
        if total is None:
            total = d.get("total_count")
        if not txs: break
        for t in txs:
            data = (t.get("body") or {}).get("data")
            sel = decode(data) if data else None
            out.append({
                "ts": t.get("timestamp"), "round": t.get("round"),
                "sel": sel, "name": SEL.get(sel, "?"),
                "sender": t.get("sender_0_eth"), "to": t.get("to_eth"),
                "success": t.get("success"), "eth_hash": t.get("eth_hash"),
                "data": data,
            })
        if len(txs) < 100: break
    return {"total_count": total, "n": len(out), "txs": out}

if __name__ == "__main__":
    targets = {
        "comptroller-classic": "0xA7684aE7e07Dac91113900342b3ef25B9Fd1D841",
        "comptroller-usd": "0x1C0C30795802Bf2B3232a824f41629BbBCF63127",
        "comptroller-lpt": "0x7c4d0c834701C6E7F57b8c1424d30aDC46eA0840",
        "fusdt-classic": "0x352cc3320debffa3046cf66a4e0a80d528f00285",
        "frose-classic": "0xd7d588babfb99e82cd6dd0ca7677a5599aa678b5",
        "feth-classic": "0x275b88547185d955f66e5dd1066e040af468fc66",
        "fusdc-classic": "0x61d90f6ab2b2b1baffa39bebb5d8ad57028da258",
        "frose-lpt": "0x63f1fe2e1da490611fc16e4a5d92b7ec7d0911a9",
        "fusdt-usd": "0x2552707d66c102c12b0f8284824f80e1299cb6b7",
    }
    res = {}
    for label, addr in targets.items():
        r = scan(addr, label)
        res[label] = r
        print(f"{label}: total={r['total_count']} fetched={r['n']}")
        # summarize interesting
        interesting = [t for t in r["txs"] if t["name"] not in ("?",)]
        from collections import Counter
        c = Counter(t["name"] for t in r["txs"])
        print("   ", dict(c.most_common(12)))
    json.dump(res, open(os.path.join(CACHE, "summary.json"), "w"), indent=1)
