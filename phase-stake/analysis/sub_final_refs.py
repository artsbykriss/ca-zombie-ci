#!/usr/bin/env python3
"""Final references: pdSOL vlist age, jupSOL epoch yield benchmark."""
import json, time, urllib.request, sys, base64, struct
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")

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

out = {}
# pdSOL vlist
VL = "aero4efZ7zHhWpqXQj4Uqw59koxj8KXqMCPUuvmhgUQ"
sigs = []
before = None
for page in range(8):
    params = [VL, {"limit": 1000}]
    if before:
        params[1]["before"] = before
    r = call("getSignaturesForAddress", params, tag="pdsol_vl")
    if r is None:
        break
    sigs.extend(r)
    if len(r) < 1000:
        break
    before = r[-1]["signature"]
    time.sleep(3)
out["pdsol_vlist_sigs"] = {"n": len(sigs), "newest": sigs[0] if sigs else None, "oldest": sigs[-1] if sigs else None}
print("pdSOL vlist sigs:", len(sigs), "oldest bt:", sigs[-1]["blockTime"] if sigs else None, "oldest slot:", sigs[-1]["slot"] if sigs else None)

# jupSOL pool state
time.sleep(2)
r = call("getAccountInfo", ["8VpRhuxa7sUUepdY3kQiTmX9rS5vx4WgaXiAnXq4KCtr", {"encoding": "base64"}], tag="jupsol")
if r:
    d = base64.b64decode(r["value"]["data"][0])
    def u64(off): return struct.unpack_from("<Q", d, off)[0]
    j = {"total_lamports": u64(258), "supply": u64(266), "last_update_epoch": u64(274),
         "last_epoch_supply": u64(483), "last_epoch_total": u64(491), "len": len(d)}
    j["nav"] = j["total_lamports"] / j["supply"] if j["supply"] else None
    j["epoch_growth"] = (j["total_lamports"] / j["last_epoch_total"] - 1) if j["last_epoch_total"] else None
    out["jupsol"] = j
    print("jupSOL:", json.dumps(j, indent=1))
json.dump(out, open("/home/heisenberg/CA/phase-stake/analysis/final_refs.json", "w"), indent=2)

# also compute time deltas for the phase pool
ei = call("getEpochInfo", [], tag="epoch")
bt = call("getBlockTime", [ei["absoluteSlot"]], tag="bt") if ei else None
print("chain now:", bt, "epoch", ei["epoch"] if ei else None)
out["chain_now"] = {"blockTime": bt, "epoch": ei}
json.dump(out, open("/home/heisenberg/CA/phase-stake/analysis/final_refs.json", "w"), indent=2)
