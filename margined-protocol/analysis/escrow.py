#!/usr/bin/env python3
"""Query the Neutron redemption escrow (margined-locust-redemption-queue) thoroughly."""
import json, base64, urllib.request, urllib.error, sys

UA = {"User-Agent": "Mozilla/5.0 (research)"}
BASES = ["https://lcd-neutron.keplr.app", "https://neutron-api.polkachu.com"]
ESCROW = "neutron1rl7key2jr285vwz79hgkusgtw3ylcgateux5p8ajkk4rya067dkserkva8"

def http_get(url, timeout=15):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def try_ep(path):
    last = None
    for b in BASES:
        try:
            return http_get(b + path)
        except urllib.error.HTTPError as e:
            last = {"_http": e.code, "_body": e.read().decode()[:400]}
        except Exception as e:
            last = {"_err": str(e)}
    return last

def smart(addr, q):
    qb = base64.b64encode(json.dumps(q).encode()).decode()
    return try_ep(f"/cosmwasm/wasm/v1/contract/{addr}/smart/{qb}")

def raw(addr, key):
    kb = base64.b64encode(key.encode()).decode()
    return try_ep(f"/cosmwasm/wasm/v1/contract/{addr}/raw/{kb}")

out = {}
ci = try_ep(f"/cosmwasm/wasm/v1/contract/{ESCROW}")
out["contract_info"] = ci.get("contract_info", ci)
out["bank"] = try_ep(f"/cosmos/bank/v1beta1/balances/{ESCROW}?pagination.limit=200").get("balances")
for name, q in [
    ("config", {"config": {}}),
    ("all_redemptions_30", {"all_redemptions": {"limit": 30}}),
    ("all_redemptions_100", {"all_redemptions": {"limit": 100}}),
    ("owner", {"owner": {}}),
    ("get_ownership_proposal", {"get_ownership_proposal": {}}),
]:
    r = smart(ESCROW, q)
    out[name] = r.get("data", r)
for key in ("config", "state", "owner"):
    r = raw(ESCROW, key)
    if r.get("data"):
        try:
            out["raw_" + key] = json.loads(base64.b64decode(r["data"]))
        except Exception:
            out["raw_" + key] = r["data"][:300]
print(json.dumps(out, indent=1)[:12000])
json.dump(out, open("/home/heisenberg/CA/margined-protocol/analysis/escrow.json", "w"), indent=1)
