#!/usr/bin/env python3
"""Check CURRENT ERC-20 token balances of all 299 clones via Blockscout v2.
READ-ONLY. Public endpoint. No secrets. Writes analysis/token_balances_now.json
"""
import json, os, time
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed

H = {"User-Agent": "Mozilla/5.0 (research; read-only)"}
BASE = "https://unichain.blockscout.com/api/v2"
HERE = os.path.dirname(os.path.abspath(__file__))
CLONES = os.path.join(HERE, "..", "children", "enum", "ci-out", "clones_raw.json")


def get(url, tries=5):
    for i in range(tries):
        try:
            r = requests.get(url, headers=H, timeout=45)
            if r.status_code == 200:
                return r.json()
            if r.status_code == 404:
                return None
        except Exception:
            pass
        time.sleep(1.2 * (i + 1))
    return None


def tb(a):
    d = get(f"{BASE}/addresses/{a}/token-balances")
    if not d:
        return a, []
    out = []
    for it in d:
        t = it.get("token", {})
        v = it.get("value")
        if v and int(v) > 0:
            out.append({"symbol": t.get("symbol"), "addr": t.get("address"), "value": v, "dec": t.get("decimals")})
    return a, out


def main():
    recs = json.load(open(CLONES))
    addrs = [r["address"] for r in recs if r.get("address")]
    res = {}
    with ThreadPoolExecutor(max_workers=6) as ex:
        futs = [ex.submit(tb, a) for a in addrs]
        done = 0
        for f in as_completed(futs):
            a, out = f.result()
            res[a.lower()] = out
            done += 1
            if done % 50 == 0:
                print("done", done)
    holding = {k: v for k, v in res.items() if v}
    print("clones with any token balance:", len(holding))
    for k, v in list(holding.items())[:30]:
        print(k, v)
    json.dump({"n": len(res), "holding": holding, "all": res}, open(os.path.join(HERE, "token_balances_now.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
