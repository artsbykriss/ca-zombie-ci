#!/usr/bin/env python3
"""GoldRush balances for Printr treasury + core across chains. Saves JSON (no key)."""
import json, os, sys, time, urllib.request

KEY = os.environ.get("GOLD_RUSH_API_KEY", "")
CHAINS = ["eth-mainnet", "base-mainnet", "bsc-mainnet", "arbitrum-mainnet",
          "avalanche-mainnet", "mantle-mainnet", "monad-mainnet"]
ADDRS = {
    "treasury": "0x8c843012b347664caf84b907053754208a933fee",
    "core": "0xb77726291b125515d0a7affeea2b04f2ff243172",
}

def get(url):
    for i in range(3):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=40) as r:
                return json.loads(r.read())
        except Exception as e:
            if i == 2: return {"error": str(e)}
            time.sleep(2)

def main():
    out = {}
    for chain in CHAINS:
        out[chain] = {}
        for name, addr in ADDRS.items():
            url = f"https://api.covalenthq.com/v1/{chain}/address/{addr}/balances_v2/?key={KEY}"
            d = get(url)
            if d.get("error") or not d.get("data"):
                out[chain][name] = {"error": (d.get("error") or d)[:200] if isinstance(d.get("error"), str) else "unknown"}
                print(chain, name, "ERR", str(d)[:150])
                continue
            items = d["data"]["items"]
            keep = []
            total = 0.0
            for it in items:
                bal = it.get("balance")
                if bal is None or int(bal) == 0:
                    continue
                q = it.get("quote") or 0
                keep.append({"symbol": it.get("contract_ticker_symbol"), "contract": it.get("contract_address"),
                             "decimals": it.get("contract_decimals"), "balance": bal, "quote": q,
                             "is_spam": it.get("is_spam"), "type": it.get("type")})
                if not it.get("is_spam"):
                    total += q or 0
            out[chain][name] = {"items": keep, "total_quote_usd": round(total, 2)}
            print(chain, name, "n_nonzero:", len(keep), "usd(non-spam):", round(total, 2))
            time.sleep(0.4)
    fn = os.path.join(os.path.dirname(__file__), "goldrush_balances.json")
    with open(fn, "w") as f:
        json.dump(out, f, indent=1)
    print("saved", fn)

if __name__ == "__main__":
    main()
