#!/usr/bin/env python3
"""Price the live tranche mints via DefiLlama coins API + Jupiter, and compute tranche TVL."""
import sys, os, json, urllib.request, urllib.parse

MINTS = {
    "AvZZF1YaZDziPY2RCK4oJrRVrbN3mTD9NL24hPeaZeUj": "asset idx0",
    "Awc6DCoHBcUz7xqUiVNZA4eM77E8aCA7asQRKtnZvava": "asset idx1",
    "9ZmGVafcUS3fAS779iu9oqwpLTuLLKeSkf6tJHPQkJMS": "asset idx2",
    "HnnGv3HrSqjRpgdFmx7vQGjntNEoex1SU4e9Lxcxuihz": "asset idx3 (eHYUSD)",
    "3b8X44fLF9ooXaUm3hhSgjpmVs6rZZ3pPoGnGahc3Uu7": "asset idx4",
    "2uxaYT1fVrp6Fg2BrxQcyKSW91hefM6dG9krpbeDiirT": "asset idx5",
    "9YEKjRbRFE3bkvCu3QiuznqK6y9mddqD73qfA2MKv5Dp": "asset idx6",
}

def http(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=60))

# DefiLlama coins
q = ",".join(f"solana:{m}" for m in MINTS)
try:
    dl = http("https://coins.llama.fi/prices/current/" + urllib.parse.quote(q, safe=",:"))
    coins = dl.get("coins", {})
except Exception as e:
    coins = {}; print("llama err", e)
# Jupiter
try:
    jup = http("https://api.jup.ag/price/v3?ids=" + ",".join(MINTS))
except Exception as e:
    jup = {}; print("jup err", e)

print("=== DefiLlama")
for m, v in MINTS.items():
    c = coins.get("solana:" + m)
    print(f"  {v:22} {m} -> {c['price'] if c else None}")
print("=== Jupiter")
for m, v in MINTS.items():
    e = jup.get(m) if isinstance(jup, dict) else None
    print(f"  {v:22} {m} -> {e}")

json.dump({"llama": coins, "jupiter": jup}, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "prices.json"), "w"), indent=2)
