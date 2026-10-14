#!/usr/bin/env python3
"""Retry GoldRush for arb/mantle treasury + legacy treasury + staking on all chains."""
import json, os, time, urllib.request
KEY = os.environ.get("GOLD_RUSH_API_KEY", "")
def get(url):
    for i in range(4):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=90) as r:
                return json.loads(r.read())
        except Exception as e:
            if i == 3: return {"error": str(e)}
            time.sleep(3)
TARGETS = [
 ("arbitrum-mainnet", "treasury", "0x8c843012b347664caf84b907053754208a933fee"),
 ("mantle-mainnet", "treasury", "0x8c843012b347664caf84b907053754208a933fee"),
 ("eth-mainnet", "legacy_treasury", "0xde420c835240216198bf4fd1eda28d7ead2a1549"),
 ("eth-mainnet", "staking", "0x49336345486268fd2e24fe8c400e0310be98b5d5"),
 ("base-mainnet", "staking", "0x49336345486268fd2e24fe8c400e0310be98b5d5"),
]
out = {}
for chain, name, addr in TARGETS:
    url = f"https://api.covalenthq.com/v1/{chain}/address/{addr}/balances_v2/?key={KEY}"
    d = get(url)
    if d.get("error") or not d.get("data"):
        out[f"{chain}:{name}"] = {"error": str(d)[:200]}
        print(chain, name, "ERR", str(d)[:120], flush=True)
        continue
    items = d["data"]["items"]
    keep=[]; tot=0
    for it in items:
        if it.get("balance") and int(it["balance"])>0:
            q=it.get("quote") or 0
            keep.append({"symbol":it["contract_ticker_symbol"],"contract":it["contract_address"],"decimals":it["contract_decimals"],"balance":it["balance"],"quote":q,"is_spam":it.get("is_spam")})
            if not it.get("is_spam"): tot += q
    out[f"{chain}:{name}"] = {"items":keep, "total_quote_usd":round(tot,2)}
    print(chain, name, "nonzero:", len(keep), "usd:", round(tot,2), flush=True)
    for k in keep[:8]:
        q=k['quote'] or 0
        if q>0.5: print("   ", k['symbol'], int(k['balance'])/10**k['decimals'], f"${q:.2f}", flush=True)
    time.sleep(0.5)
json.dump(out, open("goldrush_retry.json","w"), indent=1)
print("saved goldrush_retry.json", flush=True)
