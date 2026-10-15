#!/usr/bin/env python3
"""Enumerate all BloctoTokenStaking staker records in slices via public Flow Access API.
Read-only. No secrets. Writes aggregate JSON to ../staker_enum.json
"""
import json, base64, urllib.request, sys, time, os

ENDPOINT = "https://rest-mainnet.onflow.org/v1/scripts"
HERE = os.path.dirname(os.path.abspath(__file__))
CODE = open(os.path.join(HERE, "scripts", "staker_slice.cdc")).read()

def enc(t, v):
    return base64.b64encode(json.dumps({"type": t, "value": str(v)}).encode()).decode()

def run(start, end):
    body = json.dumps({
        "script": base64.b64encode(CODE.encode()).decode(),
        "arguments": [enc("UInt64", start), enc("UInt64", end)],
    }).encode()
    req = urllib.request.Request(ENDPOINT, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=180) as r:
        data = json.loads(r.read())
    if isinstance(data, str):
        data = json.loads(base64.b64decode(data).decode())
    out = {}
    for f in data["value"]:
        k = f["key"]["value"]
        v = f["value"]["value"]
        t = f["value"]["type"]
        out[k] = float(v) if t == "UFix64" else v
    return out

def main():
    total = int(sys.argv[1]) if len(sys.argv) > 1 else 29762
    step = int(sys.argv[2]) if len(sys.argv) > 2 else 2000
    agg = {"sumStaked": 0.0, "sumCommitted": 0.0, "sumUnstaked": 0.0, "sumRewarded": 0.0,
           "sumRequestedToUnstake": 0.0, "nWithStaked": 0, "nWithAnyTokens": 0, "count": 0,
           "blockHeight": 0, "slices": []}
    start = 0
    while start < total:
        end = min(start + step, total)
        r = run(start, end)
        agg["blockHeight"] = r["blockHeight"]
        for k in ["sumStaked", "sumCommitted", "sumUnstaked", "sumRewarded", "sumRequestedToUnstake"]:
            agg[k] += r[k]
        agg["nWithStaked"] += int(r["nWithStaked"])
        agg["nWithAnyTokens"] += int(r["nWithAnyTokens"])
        agg["count"] += int(r["count"])
        agg["slices"].append({"start": start, "end": end, "sumStaked": r["sumStaked"],
                              "sumUnstaked": r["sumUnstaked"], "sumRewarded": r["sumRewarded"],
                              "sumCommitted": r["sumCommitted"], "nWithStaked": r["nWithStaked"]})
        print(f"slice {start}-{end}: staked={r['sumStaked']:.4f} unstaked={r['sumUnstaked']:.4f} "
              f"rewarded={r['sumRewarded']:.4f} committed={r['sumCommitted']:.4f} nStaked={r['nWithStaked']}", flush=True)
        start = end
        time.sleep(0.3)
    with open(os.path.join(HERE, "staker_enum.json"), "w") as f:
        json.dump(agg, f, indent=1)
    print("TOTALS:", json.dumps({k: agg[k] for k in agg if k != "slices"}, indent=1))

if __name__ == "__main__":
    main()
