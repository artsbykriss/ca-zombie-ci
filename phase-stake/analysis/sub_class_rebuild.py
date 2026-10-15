#!/usr/bin/env python3
"""Rebuild top-15 owner classification (fast)."""
import json, sys, time, base64
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import rpc, b58decode, on_curve

A = "/home/heisenberg/CA/phase-stake/analysis/"
tg = json.load(open(A + "token_gpa_holders.json"))
accs = tg["accounts"]
KNOWN = {
    "1oopBoJG58DgkUVKkEzKgyG9dvRmpgeEm1AVjoHkF78": "Loopscale program",
    "5ocnV1qiCgaQR8Jb8xWnVbApfaygJ8tNoZfgPwsgx9kx": "Sanctum S-Controller (INF)",
    "7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1": "Squads vault (Phase manager)",
    "SQDS4ep65T869zMMBKyuUq6aD6EgTu8psMjkvj52pCf": "Squads v4",
}
out = {}
for h in accs[:15]:
    o = h["owner"]
    time.sleep(1.1)
    try:
        r = rpc("getAccountInfo", [o, {"encoding": "base64"}])
        v = r.get("value")
        if v is None:
            out[o] = {"exists": False, "on_curve": on_curve(b58decode(o))}
        else:
            dl = len(base64.b64decode(v["data"][0])) if v["data"] else 0
            out[o] = {"exists": True, "owner_program": v["owner"], "executable": v["executable"],
                      "lamports": v["lamports"], "datalen": dl, "on_curve": on_curve(b58decode(o)),
                      "known_program": KNOWN.get(v["owner"])}
    except Exception as e:
        out[o] = {"error": str(e)[:120]}
    print(h["amount"], o, json.dumps(out[o])[:140])
json.dump(out, open(A + "holder_class.json", "w"), indent=2)
print("saved holder_class.json")
