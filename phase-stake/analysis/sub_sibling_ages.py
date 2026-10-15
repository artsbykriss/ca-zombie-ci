#!/usr/bin/env python3
"""Sibling-pool age check (same manager family) for a yield cross-reference."""
import json, time, urllib.request, sys

URL = "https://api.mainnet-beta.solana.com"

def post(method, params, timeout=50):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(URL, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def call(method, params, tries=12, tag=""):
    for i in range(tries):
        try:
            d = post(method, params)
            if "result" in d:
                return d["result"]
            print(" ", tag, "try", i, str(d.get("error"))[:90], flush=True)
        except Exception as e:
            print(" ", tag, "try", i, "exc", str(e)[:70], flush=True)
        time.sleep(min(35, 7 + i * 4))
    return None

ps = json.load(open("/home/heisenberg/CA/phase-stake/analysis/pools_scan.json"))
targets = {}
for p in ps["pools"]:
    if p["address"] in ("hy1oDeVCVRDGkxS26qLVDvRhDpZGfWJ6w9AMvwMegwL",
                        "prt1stdbFCFXpEcx9rxwJK63zhYo43V5JCXzGWXkPGn",
                        "hy1o2kiYu9rUDFqHJSqwJH4j5ZkM23tBJsaEmqkP9sT"):
        targets[p["address"]] = p

out = {}
for addr, p in targets.items():
    vl = p["validator_list"]
    sigs = []
    before = None
    for page in range(10):
        params = [vl, {"limit": 1000}]
        if before:
            params[1]["before"] = before
        r = call("getSignaturesForAddress", params, tag=addr[:6])
        if r is None:
            break
        sigs.extend(r)
        if len(r) < 1000:
            break
        before = r[-1]["signature"]
        time.sleep(3)
    oldest = sigs[-1] if sigs else None
    out[addr] = {"mint": p["pool_mint"], "tvlsol": p["total_lamports"] / 1e9,
                 "supply": p["pool_token_supply"], "nav": p["nav_ratio"],
                 "vlist": vl, "vlist_sigs_fetched": len(sigs),
                 "oldest_sig": oldest}
    print(f'{addr[:12]} mint={p["pool_mint"][:12]} TVL={p["total_lamports"]/1e9:,.1f} NAV={p["nav_ratio"]:.4f} vlist_sigs={len(sigs)} oldest_bt={oldest["blockTime"] if oldest else None}')
json.dump(out, open("/home/heisenberg/CA/phase-stake/analysis/sibling_ages.json", "w"), indent=2)
print("saved sibling_ages.json")
