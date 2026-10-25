#!/usr/bin/env python3
"""READ-ONLY. Query Blockscout token balances for all vault proxies. Public endpoints only."""
import json, os, sys, time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = "https://unichain.blockscout.com/api/v2"
H = {"User-Agent": "Mozilla/5.0 (research; read-only)"}

def get(url, tries=4):
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers=H)
            with urllib.request.urlopen(req, timeout=40) as r:
                return json.loads(r.read())
        except Exception:
            time.sleep(1.0*(i+1))
    return None

def main():
    vs = json.load(open(os.path.join(HERE, "vault_scan.json")))
    vaults = [r for r in vs if r["impl"] == "0x3fd339e58769a56d08dcd2683f9012e881287476"]
    out = []
    for i, r in enumerate(vaults):
        d = get(f"{BASE}/addresses/{r['addr']}/token-balances")
        toks = []
        if isinstance(d, list):
            for t in d:
                toks.append({"token": (t.get("token") or {}).get("address_hash"),
                             "symbol": (t.get("token") or {}).get("symbol"),
                             "value": t.get("value")})
        out.append({"addr": r["addr"], "tokens": toks})
        if toks:
            print(r["addr"], toks, flush=True)
        if i % 25 == 0:
            print(f"...{i}/{len(vaults)}", file=sys.stderr, flush=True)
        time.sleep(0.12)
    json.dump(out, open(os.path.join(HERE, "vault_token_balances.json"), "w"), indent=1)
    nz = [o for o in out if o["tokens"]]
    print("vaults with any token balance:", len(nz), "/", len(out))

if __name__ == "__main__":
    main()
