#!/usr/bin/env bash
# pass2-recon CI job — read-only validation of the reconciliation deliverable.
# No network calls, no secrets. Writes results to ci-out/.
set -euo pipefail
cd "$(dirname "$0")/.."   # folder root

mkdir -p ci-out
python3 - <<'PY'
import json, collections, os

path = "analysis/candidates.json"
d = json.load(open(path))
C = d["candidates"]
cnt = collections.Counter(c["disposition"] for c in C)

expected = {
    "enumerated": 269,
    "README-FINDING": 3,
    "README-CLOSED": 38,
    "LANE-CLOSED": 88,
    "PRIOR-COVERED": 98,
    "PRIOR-PARTIAL": 1,
    "NOT-A-PROTOCOL": 32,
    "OPEN": 9,
}

open_list = [c for c in C if c["disposition"] == "OPEN"]
lanes = sorted(set(c["lane"] for c in C))
ok = (len(C) == expected["enumerated"]) and all(cnt.get(k,0) == v for k,v in expected.items() if k!="enumerated")
# summary.json consistency
s = json.load(open("summary.json"))
s_ok = s["counts"]["enumerated"] == len(C) and s["counts"]["OPEN"] == len(open_list)

out = {
    "job": "pass2-recon",
    "candidates": len(C),
    "lanes": lanes,
    "lane_count": len(lanes),
    "counts": dict(cnt),
    "expected": expected,
    "counts_match": ok,
    "summary_consistent": s_ok,
    "open_list": [c["candidate"] for c in open_list],
    "open_count": len(open_list),
    "status": "PASS" if (ok and s_ok and len(lanes) == 16) else "FAIL",
}
json.dump(out, open("ci-out/recon-summary.json","w"), indent=2)
print(json.dumps(out, indent=2))
if out["status"] != "PASS":
    raise SystemExit("VALIDATION FAILED")
PY
echo "pass2-recon CI OK"
