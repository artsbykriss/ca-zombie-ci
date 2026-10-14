#!/usr/bin/env python3
"""Fetch current cToken holders for the 4 Telos markets via Teloscan token API.
Writes telos-holders.json. HTTP only, no secrets."""
import json, os, sys, time, urllib.request

OUT = os.path.dirname(os.path.abspath(__file__))
API = "https://api.teloscan.io/api"
MARKETS = {
    "rfUSDC": "0xa6a5fe78a12ae40bed9300da6de624c089f77ac2",
    "rfUSDT": "0x3d187a993d946f196429c83f9a1831513ac2d2be",
    "rfETH": "0xce08cff82fb1b6902a7dca2ccd2d164bc2b5b1cd",
    "rfTLOS": "0x7d94d2f6f91ed5ed0104d89b3d263026d990ac5f",
}

def api_get(url, tries=5):
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 research"})
            with urllib.request.urlopen(req, timeout=45) as r:
                return json.loads(r.read())
        except Exception as e:
            last = e
            time.sleep(1.0 * (i + 1))
    raise last

def main():
    out = {}
    all_holders = set()
    for name, addr in MARKETS.items():
        holders = []
        page = 1
        while True:
            j = api_get(f"{API}?module=token&action=getTokenHolders&contractaddress={addr}&page={page}&offset=100")
            res = j.get("result") or []
            if not res:
                break
            holders.extend(res)
            if len(res) < 100:
                break
            page += 1
            if page > 50:
                break
        out[name] = holders
        for h in holders:
            all_holders.add(h["address"].lower())
        print(name, "holders:", len(holders), flush=True)
    out["_all_holders"] = sorted(all_holders)
    with open(os.path.join(OUT, "telos-holders.json"), "w") as f:
        json.dump(out, f, indent=1)
    print("unique holders total:", len(all_holders))

if __name__ == "__main__":
    main()
