#!/usr/bin/env python3
import json, base64, urllib.request, time, os
ENDPOINT = "https://rest-mainnet.onflow.org/v1/scripts"
HERE = os.path.dirname(os.path.abspath(__file__))
CODE = open(os.path.join(HERE, "big_holders.cdc")).read()
def enc(t, v):
    return base64.b64encode(json.dumps({"type": t, "value": str(v)}).encode()).decode()
def run(start, end, thr):
    body = json.dumps({"script": base64.b64encode(CODE.encode()).decode(),
                       "arguments": [enc("UInt64", start), enc("UInt64", end), enc("UFix64", thr)]}).encode()
    req = urllib.request.Request(ENDPOINT, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=180) as r:
        data = json.loads(r.read())
    if isinstance(data, str):
        data = json.loads(base64.b64decode(data).decode())
    out = []
    for row in data["value"]:
        vals = [f["value"] for f in row["value"]]
        out.append({"id": int(vals[0]), "staked": float(vals[1]), "unstaked": float(vals[2]),
                    "rewarded": float(vals[3]), "committed": float(vals[4]), "requested": float(vals[5])})
    return out
rows = []
for s in range(0, 29762, 2000):
    e = min(s + 2000, 29762)
    rows.extend(run(s, e, 100000.0))
    time.sleep(0.2)
rows.sort(key=lambda r: -(r["staked"] + r["unstaked"] + r["rewarded"] + r["committed"]))
json.dump(rows, open(os.path.join(HERE, "top_holders.json"), "w"), indent=1)
print(f"holders >100k BLT: {len(rows)}")
tot_staked = sum(r["staked"] for r in rows); tot_un = sum(r["unstaked"] for r in rows); tot_rw = sum(r["rewarded"] for r in rows)
print(f"top-group totals: staked={tot_staked:,.2f} unstaked={tot_un:,.2f} rewarded={tot_rw:,.2f}")
for r in rows[:25]:
    print(f"  id={r['id']:>6} staked={r['staked']:>14,.2f} unstaked={r['unstaked']:>14,.2f} rewarded={r['rewarded']:>12,.2f} req={r['requested']:>12,.2f}")
