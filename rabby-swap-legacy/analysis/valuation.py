#!/usr/bin/env python3
"""Value the live Rabby Swap legacy allowances found by census.py.

Reads ci-out/raw/census_*.json, prices every live position's token via DefiLlama
(coins.llama.fi), and writes ci-out/live_allowance_valuation.json.
Read-only; no secrets.
"""
import json, glob, os, sys, urllib.request

LLAMA = {
    "ethereum": "ethereum", "bsc": "bsc", "polygon": "polygon", "avalanche": "avax",
    "fantom": "fantom", "optimism": "optimism", "arbitrum": "arbitrum", "gnosis": "xdai",
    "cronos": "cronos", "aurora": "aurora", "harmony": "harmony", "metis": "metis",
    "moonbeam": "moonbeam", "arbitrum-nova": "arbitrum-nova", "klaytn": "klaytn",
    "astar": "astar", "boba": "boba", "heco": "heco", "celo": "celo",
}


def llama_prices(keys):
    if not keys:
        return {}
    out = {}
    for i in range(0, len(keys), 50):
        chunk = keys[i:i + 50]
        url = "https://coins.llama.fi/prices/current/" + ",".join(chunk)
        try:
            with urllib.request.urlopen(url, timeout=60) as r:
                out.update(json.load(r).get("coins", {}))
        except Exception as e:
            print("llama error", e)
    return out


def main(indir, outfile):
    positions = []
    for path in sorted(glob.glob(os.path.join(indir, "census_*.json"))):
        d = json.load(open(path))
        for p in d.get("live_positions", []):
            positions.append(p)
    keys = []
    for p in positions:
        lc = LLAMA.get(p["chain"])
        if lc:
            keys.append(f"{lc}:{p['token']}")
    prices = llama_prices(sorted(set(keys)))
    total = 0.0
    per_chain = {}
    for p in positions:
        lc = LLAMA.get(p["chain"])
        key = f"{lc}:{p['token']}" if lc else None
        pr = prices.get(key, {}).get("price") if key else None
        dec = p.get("decimals", 18)
        amount = int(p["extractable_raw"]) / (10 ** dec)
        usd = amount * pr if pr is not None else 0.0
        p["price_usd"] = pr
        p["amount"] = amount
        p["usd"] = round(usd, 4)
        total += usd
        per_chain[p["chain"]] = per_chain.get(p["chain"], 0.0) + usd
    out = {"live_positions": positions, "total_live_allowance_usd": round(total, 2),
           "per_chain_usd": {k: round(v, 2) for k, v in per_chain.items()},
           "note": "extractable = min(allowance, balance) per (token,owner); unpriced tokens valued at $0"}
    os.makedirs(os.path.dirname(outfile), exist_ok=True)
    json.dump(out, open(outfile, "w"), indent=1)
    print(json.dumps(out, indent=1))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "ci-out/raw",
         sys.argv[2] if len(sys.argv) > 2 else "ci-out/live_allowance_valuation.json")
