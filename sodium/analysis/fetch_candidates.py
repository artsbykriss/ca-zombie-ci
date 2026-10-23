#!/usr/bin/env python3
"""Fetch the full list of Sodium account addresses created by the factory family
(Etherscan V2 internal-tx list; CREATE2 creations). Saves analysis/sodium_factory_accounts.json.
The Etherscan key is read from /home/heisenberg/CA/.env at runtime and never stored."""
import json, time, urllib.request, urllib.parse

FACTORIES = [
    "0x5eb4bcaeb78a7a765fa3f7285ee6b3e08ccb2c09",
    "0xa225f7262a654f1fe2518ab8933f1b9d8023d6df",
]


def _key():
    for line in open("/home/heisenberg/CA/.env"):
        line = line.strip()
        if line.startswith("ETHERSCANV2_API_KEY="):
            return line.split("=", 1)[1].strip().strip('"').strip("'")
    return ""


KEY = _key()


def etherscan(params):
    p = dict(params); p["apikey"] = KEY
    url = "https://api.etherscan.io/v2/api?" + urllib.parse.urlencode(p)
    for _ in range(4):
        try:
            with urllib.request.urlopen(urllib.request.Request(
                    url, headers={"User-Agent": "Mozilla/5.0"}), timeout=45) as r:
                return json.loads(r.read())
        except Exception:
            time.sleep(1.5)
    return {}


def creations(addr, max_pages=20):
    out, seen = [], set()
    for page in range(1, max_pages + 1):
        r = etherscan({"chainid": 42161, "module": "account", "action": "txlistinternal",
                       "address": addr, "startblock": 0, "endblock": 999999999,
                       "sort": "asc", "page": page, "offset": 1000})
        res = r.get("result")
        if not isinstance(res, list) or not res:
            break
        new = 0
        for t in res:
            k = (t.get("hash"), t.get("traceId", ""))
            if k in seen:
                continue
            seen.add(k); new += 1
            if t.get("from", "").lower() == addr.lower() and t.get("type") in ("create", "create2"):
                ca = t.get("contractAddress")
                if ca:
                    out.append(ca.lower())
        print(f"# {addr} page {page}: {len(res)} rows, +{new} new, creations so far {len(out)}", flush=True)
        if len(res) < 1000 or new == 0:
            break
    return out


if __name__ == "__main__":
    allc = {}
    for f in FACTORIES:
        allc[f] = creations(f)
    flat = sorted(set(a for v in allc.values() for a in v))
    json.dump({"factories": allc, "accounts": flat},
              open("/home/heisenberg/CA/sodium/analysis/sodium_factory_accounts.json", "w"), indent=1)
    print(f"# total unique candidate accounts: {len(flat)}")
