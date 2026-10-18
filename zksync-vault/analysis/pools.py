#!/usr/bin/env python3
"""Enumerate all SyncSwap V1 pools from factory PoolCreated logs (Blockscout), capturing tokens."""
import json, requests, sys

FACTORIES = {
    "classic": "0xf2DAd89f2788a8CD54625C60b55cD3d2D0ACa7Cb",
    "stable": "0x5b9f21d407F35b10CbfDDca17D5D84b129356ea3",
}
TOPIC = "0x9c5d829b9b23efc461f9aeef91979ec04bb903feb3bee4f26d22114abfc7335b"
BASE = "https://zksync.blockscout.com/api/v2/addresses/{}/logs"
H = {"User-Agent": "Mozilla/5.0"}

def main():
    out = {}
    for name, f in FACTORIES.items():
        pools, params, pages, oldest = {}, None, 0, None
        while pages < 400:
            r = requests.get(BASE.format(f), params=params, headers=H, timeout=60)
            d = r.json()
            items = d.get("items", [])
            if not items:
                break
            for it in items:
                if it["topics"][0] != TOPIC or len(it["topics"]) < 3:
                    continue
                t0 = "0x" + it["topics"][1][-40:]
                t1 = "0x" + it["topics"][2][-40:]
                pool = "0x" + it["data"][-40:]
                pools[pool.lower()] = {"token0": t0.lower(), "token1": t1.lower(),
                                       "block": it["block_number"]}
            pages += 1
            oldest = items[-1]["block_number"]
            params = d.get("next_page_params")
            if not params:
                break
        out[name] = pools
        print(f"{name} factory {f}: {len(pools)} pools in {pages} pages, oldest block {oldest}", flush=True)
    json.dump(out, open("analysis/pools.json", "w"), indent=1)

if __name__ == "__main__":
    main()
