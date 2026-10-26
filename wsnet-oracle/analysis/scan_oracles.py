#!/usr/bin/env python3
"""Enumerate every Morpho-Blue market on Robinhood Chain (4663) and classify each oracle.

Goal: confirm wsNET is the ONLY *funded* market whose oracle embeds a thin-pool spot read
(UniV2 `getReserves()` 0x0902f1ac or UniV3 `slot0()` 0x3850c7bd), i.e. that the LoopbackOracle
finding has no funded sibling.

Read-only: Morpho Blue API (GraphQL) + eth_getCode. Writes JSON to stdout (ci-out/oracle_scan.json).
"""
import concurrent.futures as cf
import json
import os
import sys
import time
import urllib.request

RPC = os.environ.get("RH_RPC_URL", "https://robinhood.drpc.org")
API = "https://blue-api.morpho.org/graphql"
SEL = {
    "getReserves": "0902f1ac",
    "slot0": "3850c7bd",
    "latestRoundData": "feaf968c",
    "latestAnswer": "50d25bcd",
    "observe": "883bdbfd",
}


def post(url, payload):
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode(),
        headers={"content-type": "application/json", "User-Agent": "Mozilla/5.0"},
    )
    return json.load(urllib.request.urlopen(req, timeout=90))


def rpc(batch, tries=4):
    for t in range(tries):
        try:
            req = urllib.request.Request(
                RPC,
                data=json.dumps(batch).encode(),
                headers={"content-type": "application/json", "User-Agent": "Mozilla/5.0"},
            )
            return json.load(urllib.request.urlopen(req, timeout=90))
        except Exception:  # noqa: BLE001
            time.sleep(1.5 * (t + 1))
    return None


def get_codes(addrs):
    out = {}
    r = rpc([{"jsonrpc": "2.0", "id": i, "method": "eth_getCode", "params": [a, "latest"]}
             for i, a in enumerate(addrs)])
    if r is None:
        for a in addrs:
            rr = rpc([{"jsonrpc": "2.0", "id": 0, "method": "eth_getCode", "params": [a, "latest"]}])
            out[a] = rr[0].get("result", "0x") if rr else "0x"
        return out
    for m in r:
        if "id" in m:
            out[addrs[m["id"]]] = m.get("result", "0x")
    return out


def fetch_markets():
    q = (
        "{ markets(where:{chainId_in:[4663]}, first:600){ items{ marketId lltv "
        "collateralAsset{symbol address} loanAsset{symbol address} oracle{address} "
        "state{ supplyAssetsUsd borrowAssetsUsd liquidityAssetsUsd } } } }"
    )
    d = post(API, {"query": q})
    return d["data"]["markets"]["items"]


def main():
    items = fetch_markets()
    by_oracle = {}
    for i in items:
        o = (i.get("oracle") or {}).get("address")
        by_oracle.setdefault(o, []).append(i)
    oracles = [o for o in by_oracle if o]
    codes = {}
    chunks = [oracles[i : i + 10] for i in range(0, len(oracles), 10)]
    with cf.ThreadPoolExecutor(max_workers=4) as ex:
        for d in ex.map(get_codes, chunks):
            codes.update(d)

    def classify(code):
        c = (code or "").lower()
        return [k for k, s in SEL.items() if s in c]

    rows = []
    for o, ms in by_oracle.items():
        if not o:
            continue
        cls = classify(codes.get(o, ""))
        for m in ms:
            st = m.get("state") or {}
            rows.append({
                "marketId": m["marketId"],
                "coll": (m.get("collateralAsset") or {}).get("symbol"),
                "loan": (m.get("loanAsset") or {}).get("symbol"),
                "oracle": o,
                "lltv": m.get("lltv"),
                "supplyUsd": st.get("supplyAssetsUsd"),
                "borrowUsd": st.get("borrowAssetsUsd"),
                "liquidityUsd": st.get("liquidityAssetsUsd"),
                "oracle_selectors": cls,
                "thin_pool": any(k in ("getReserves", "slot0") for k in cls),
            })

    thin = [r for r in rows if r["thin_pool"]]
    funded_thin = [r for r in thin if (r.get("supplyUsd") or 0) > 100]
    funded_thin_v2 = [r for r in thin if "getReserves" in r["oracle_selectors"] and (r.get("supplyUsd") or 0) > 100]
    out = {
        "chain": 4663,
        "markets_total": len(rows),
        "distinct_oracles": len([o for o in by_oracle if o]),
        "oracles_with_getReserves": [o for o in by_oracle if "0902f1ac" in (codes.get(o, "") or "").lower()],
        "oracles_with_slot0": len([o for o in by_oracle if "3850c7bd" in (codes.get(o, "") or "").lower()]),
        "oracles_with_latestRoundData": len([o for o in by_oracle if "feaf968c" in (codes.get(o, "") or "").lower()]),
        "thin_pool_markets": len(thin),
        "funded_thin_pool_markets": len(funded_thin),
        "funded_getReserves_markets": len(funded_thin_v2),
        "funded_thin_pool_detail": sorted(
            funded_thin, key=lambda r: -(r.get("supplyUsd") or 0)
        )[:25],
        "wsnet_markets": [r for r in rows if r["coll"] == "wsNET"],
    }
    json.dump(out, sys.stdout, indent=1)
    print()


if __name__ == "__main__":
    main()
