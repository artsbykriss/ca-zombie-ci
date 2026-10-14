#!/usr/bin/env python3
"""Enumerate treasury + core holdings per chain via Etherscan V2 tokentx + balanceOf reads.
Saves JSON to analysis/. No API key written to output.
"""
import json, os, sys, time, urllib.request, urllib.parse

KEY = os.environ.get("ETHERSCANV2_API_KEY", "")
BASE = "https://api.etherscan.io/v2/api"
TREASURY = "0x8c843012b347664caf84b907053754208a933fee"
CORE = "0xb77726291b125515d0a7affeea2b04f2ff243172"
CHAINS = {"ethereum": 1, "bsc": 56, "arbitrum": 42161, "base": 8453,
          "avalanche": 43114, "mantle": 5000, "monad": 143}

def api(params):
    params = dict(params); params["apikey"] = KEY
    url = BASE + "?" + urllib.parse.urlencode(params)
    for i in range(3):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=40) as r:
                return json.loads(r.read())
        except Exception as e:
            if i == 2: return {"error": str(e)}
            time.sleep(2)

def tokentx(chain, cid, addr):
    out = []
    page = 1
    while True:
        d = api({"chainid": cid, "module": "account", "action": "tokentx", "address": addr,
                 "startblock": 0, "endblock": 99999999, "page": page, "offset": 500, "sort": "asc"})
        if d.get("status") != "1":
            break
        res = d["result"]
        out.extend(res)
        if len(res) < 500 or page >= 20:
            break
        page += 1
    return out

def main():
    result = {}
    for chain, cid in CHAINS.items():
        r = {"chain": chain, "chainid": cid}
        try:
            txs = tokentx(chain, cid, TREASURY)
            tokens = {}
            for t in txs:
                c = t["contractAddress"].lower()
                tokens.setdefault(c, {"symbol": t.get("tokenSymbol"), "decimals": int(t.get("tokenDecimal") or 18),
                                      "name": t.get("tokenName")})
            r["treasury_token_count_seen"] = len(tokens)
            r["tokens_seen"] = tokens
            r["n_transfers"] = len(txs)
        except Exception as e:
            r["error"] = str(e)
        result[chain] = r
        print(chain, "tokens seen:", r.get("treasury_token_count_seen"), "transfers:", r.get("n_transfers"), r.get("error",""))
        time.sleep(0.3)
    with open(os.path.join(os.path.dirname(__file__), "treasury_tokens_seen.json"), "w") as f:
        json.dump(result, f, indent=1)

if __name__ == "__main__":
    main()
