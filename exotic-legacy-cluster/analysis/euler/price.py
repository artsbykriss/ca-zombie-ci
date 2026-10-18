import json, os, time, sys
import requests
from harness import *

LLAMA_CHAIN = {k: v["llama"] for k, v in CHAINS.items()}
DEC_CACHE = os.path.join(HERE, "decimals_cache.json")

def get_prices(keys):
    out = {}
    for i in range(0, len(keys), 50):
        part = keys[i:i+50]
        url = "https://coins.llama.fi/prices/current/" + ",".join(part)
        for a in range(4):
            try:
                r = requests.get(url, timeout=25)
                if r.status_code == 200:
                    j = r.json()
                    out.update(j.get("coins", {}))
                    break
                time.sleep(1 + a)
            except Exception:
                time.sleep(1 + a)
    return out

def main():
    raw = json.load(open(os.path.join(HERE, "raw_vaults.json")))
    dec_cache = json.load(open(DEC_CACHE)) if os.path.exists(DEC_CACHE) else {}
    # collect unique assets per chain and read decimals
    for chain, blob in raw.items():
        r = RPC(CHAINS[chain]["rpc"]); r.block = None
        blk = r.blocknum()
        assets = sorted({v.get("asset") for v in blob["vaults"] if v.get("asset")})
        need = [a for a in assets if f"{chain}:{a.lower()}" not in dec_cache]
        if need:
            res = r.mc([(a, sel("decimals()")) for a in need], chunksz=180)
            for a, (ok, h) in zip(need, res):
                dec_cache[f"{chain}:{a.lower()}"] = dec_uint(h) if ok else None
            json.dump(dec_cache, open(DEC_CACHE, "w"))
        print(f"[{chain}] block {blk} assets {len(assets)} decimals_missing={sum(1 for a in assets if dec_cache.get(f'{chain}:{a.lower()}') is None)}", flush=True)
        blob["read_block"] = blk

    # prices
    keys = []
    for chain, blob in raw.items():
        for v in blob["vaults"]:
            if v.get("asset"): keys.append(f"{LLAMA_CHAIN[chain]}:{v['asset'].lower()}")
            if v.get("unitOfAccount"): keys.append(f"{LLAMA_CHAIN[chain]}:{v['unitOfAccount'].lower()}")
    keys = sorted(set(keys))
    prices = get_prices(keys)
    print("price keys", len(keys), "resolved", len(prices), flush=True)
    json.dump(prices, open(os.path.join(HERE, "prices.json"), "w"))

    out = []
    for chain, blob in raw.items():
        for v in blob["vaults"]:
            key = f"{LLAMA_CHAIN[chain]}:{(v.get('asset') or '').lower()}"
            p = prices.get(key)
            dec = dec_cache.get(f"{chain}:{(v.get('asset') or '').lower()}")
            price = p.get("price") if p else None
            ta = v.get("totalAssets") or 0
            tb = v.get("totalBorrows") or 0
            bal = v.get("assetBalance")
            v2 = dict(v)
            v2["assetPrice"] = price
            v2["assetDecimals"] = dec
            v2["tvlUsd"] = (ta / (10 ** dec) * price) if (price and dec is not None) else None
            v2["borrowsUsd"] = (tb / (10 ** dec) * price) if (price and dec is not None) else None
            v2["flags"] = []
            if ta > 0 and price is None: v2["flags"].append("no_price")
            if dec is None and ta > 0: v2["flags"].append("no_decimals")
            orc = v.get("oracle")
            if not orc or orc == "0x" + "0"*40: v2["flags"].append("oracle_zero")
            if (v.get("hooks") or "0x"+"0"*40) != "0x"+"0"*40: v2["flags"].append("hooks")
            for col, lw in (v.get("ltv") or {}).items():
                b, l = lw.get("borrow"), lw.get("liq")
                if b is not None and l is not None:
                    if b > l: v2["flags"].append("ltv_inverted")
                    if l > 9500: v2["flags"].append("ltv_gt95")
                    if l == 10000: v2["flags"].append("ltv_100")
                    if l == 0: v2["flags"].append("ltv_zero")
            if ta > 0 and bal is not None and tb is not None:
                # accounting: cash + borrows should cover totalAssets (within 0.5%)
                if (bal + tb) * 1000 < ta * 995:
                    v2["flags"].append("drift_cash_borrows")
            out.append(v2)
    json.dump(out, open(os.path.join(HERE, "vaults_priced.json"), "w"))
    # quick summary
    tvl = sum(v["tvlUsd"] or 0 for v in out)
    print("vaults", len(out), "total tvl usd %.2f" % tvl, "with price", sum(1 for v in out if v["tvlUsd"] is not None))

if __name__ == "__main__":
    main()
