#!/usr/bin/env bash
# ca2-low-c CI: re-run the three live-state verifications (read-only).
# Public chain reads only; no API keys are required and none are written to disk.
set -uo pipefail
mkdir -p ci-out
STATUS=0

echo "=== aperture: live approval / position re-read ==="
if ( cd aperture && python3 analysis/verify_live.py > ../ci-out/aperture_verify.json ); then
  cat ci-out/aperture_verify.json
else
  echo "aperture verification FAILED" | tee ci-out/aperture_error.txt
  STATUS=1
fi

echo "=== coffer: deployed program / pool verification ==="
if ( cd coffer && python3 analysis/verify.py > ../ci-out/coffer_verify.json ); then
  cat ci-out/coffer_verify.json
else
  echo "coffer verification FAILED" | tee ci-out/coffer_error.txt
  STATUS=1
fi

echo "=== zklink: pause / payout-gate verification ==="
if ( cd zklink && bash analysis/verify.sh > ../ci-out/zklink_verify.txt ); then
  cat ci-out/zklink_verify.txt
else
  echo "zklink verification FAILED" | tee ci-out/zklink_error.txt
  STATUS=1
fi

python3 - <<'PY' > ci-out/summary.json
import json, os
out = {"finding": "CA2-LOW-C", "targets": {}}
ap = "ci-out/aperture_verify.json"
if os.path.exists(ap):
    d = json.load(open(ap))
    out["targets"]["aperture"] = {k: {
        "head": v["head"], "code_hex_chars": v["code_hex_chars"],
        "native_wei": v["native_wei"], "erc20_pairs": v["erc20_pairs"],
        "erc20_live_both": v["erc20_live_both"],
        "nft_approved": v["nft_approved"],
        "nft_approved_with_value": v["nft_approved_with_value"]}
        for k, v in d["chains"].items()}
co = "ci-out/coffer_verify.json"
if os.path.exists(co):
    d = json.load(open(co))
    out["targets"]["coffer"] = {k: d.get(k) for k in
        ("current_slot", "last_deploy_slot", "last_deploy_blocktime",
         "programdata_sha256", "pools_total", "defillama_tvl_usd",
         "max_one_raw_unit_usd")}
zk = "ci-out/zklink_verify.txt"
if os.path.exists(zk):
    kv = {}
    for line in open(zk):
        if "=" in line:
            k, v = line.strip().split("=", 1)
            kv[k] = v
    out["targets"]["zklink"] = kv
print(json.dumps(out, indent=1))
PY

cat ci-out/summary.json
exit $STATUS
