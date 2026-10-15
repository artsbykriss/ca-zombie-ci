#!/usr/bin/env python3
"""Age anchors: stake account delegation epoch; full vlist sig pagination to creation."""
import json, time, urllib.request, sys, base64

URL = "https://api.mainnet-beta.solana.com"
VLIST = "phaseeExd43yGjjad2FZSigdG9UTRpMdxS4aMerx821"
POOL = "phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG"

def post(method, params, timeout=50):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(URL, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def call(method, params, tries=25):
    for i in range(tries):
        try:
            d = post(method, params)
            if "result" in d:
                return d["result"]
            print("  try", i, str(d.get("error"))[:80], flush=True)
        except Exception as e:
            print("  try", i, "exc", str(e)[:80], flush=True)
        time.sleep(min(40, 8 + i * 3))
    return None

# 1) stake account (age anchor)
sa = call("getAccountInfo", ["8QtQ1U34DPs2UKQiwUoRPMHnjJedsmdASZdbQHa7VHKh", {"encoding": "jsonParsed"}])
if sa:
    info = sa["value"]
    print("stake lamports:", info["lamports"])
    print(json.dumps(info["data"]["parsed"], indent=1)[:1200])
    json.dump(sa, open("/home/heisenberg/CA/phase-stake/analysis/stake8QtQ.json", "w"), indent=2)

time.sleep(3)
# 2) vlist pagination to creation
existing = []
try:
    existing = json.load(open("/home/heisenberg/CA/phase-stake/analysis/mb_vlist_sigs.json"))
except Exception:
    pass
sigs = existing
before = sigs[-1]["signature"] if sigs else None
page = 0
while page < 60:
    params = [VLIST, {"limit": 1000}]
    if before:
        params[1]["before"] = before
    r = call("getSignaturesForAddress", params)
    if r is None:
        break
    sigs.extend(r)
    print(f"vlist page {page}: {len(r)} (total {len(sigs)}) oldest slot {r[-1]['slot']} bt {r[-1]['blockTime']} err={r[-1]['err']}", flush=True)
    if len(r) < 1000:
        print("VLIST COMPLETE")
        break
    before = r[-1]["signature"]
    page += 1
    time.sleep(4)
    json.dump(sigs, open("/home/heisenberg/CA/phase-stake/analysis/mb_vlist_sigs.json", "w"), indent=1)

print("final vlist sigs:", len(sigs))
if sigs:
    print("OLDEST vlist sig:", json.dumps(sigs[-1]))
