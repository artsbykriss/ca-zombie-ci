#!/usr/bin/env bash
# Loopscale Curation (Exponent strategy-vaults program) — read-only CI job.
# Re-runs the live-state decode, exposure valuation and the fresh-signer auth probe,
# and extracts the audit-fix markers from the deployed program ELF strings.
# Writes results to ci-out/. No transactions are signed for broadcast or sent.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$HERE"
mkdir -p ci-out

python3 -m pip install --quiet --disable-pip-version-check solders requests 2>/dev/null \
  || pip3 install --quiet solders requests 2>/dev/null || true

echo "== decode vaults =="
python3 analysis/decode_vaults.py > ci-out/decode_vaults.out 2>&1 || echo "decode_vaults failed"
echo "== quantify exposure =="
python3 analysis/quantify.py > ci-out/quantify.out 2>&1 || echo "quantify failed"
cp analysis/loopscale_exposure.json ci-out/ 2>/dev/null || true
echo "== fresh-signer auth probe (read-only simulateTransaction) =="
python3 analysis/sim_auth_probe.py > ci-out/sim_results.txt 2>&1 || echo "sim probe failed"

echo "== audit-fix markers present in deployed ELF strings =="
grep -aE "Cannot remove the last price manager|Invalid vault creator|YVault creators capacity exceeded|Live wrapper setup only supports additive|Direct policy changes require an empty vault|Signer is not authorized for this role|Invalid price manager" \
  analysis/elf_strings.txt > ci-out/fix_markers.txt 2>/dev/null || true
cat ci-out/fix_markers.txt

echo "== sanity summary =="
python3 - <<'PY' | tee ci-out/sanity.json
import json, os, re
out = {"ok": True}
try:
    ex = json.load(open("ci-out/loopscale_exposure.json"))
    out["slot"] = ex["slot"]; out["vaults"] = len(ex["vaults"]); out["total_usd"] = ex["total_usd"]
except Exception as e:
    out["ok"] = False; out["exposure_error"] = str(e)
sim = open("ci-out/sim_results.txt").read() if os.path.exists("ci-out/sim_results.txt") else ""
out["unauthorized_role_hits"] = len(re.findall(r"Signer is not authorized for this role", sim))
out["invalid_price_manager_hits"] = len(re.findall(r"Invalid price manager", sim))
out["sim_probe_lines"] = len(sim.splitlines())
out["fix_markers"] = open("ci-out/fix_markers.txt").read().splitlines() if os.path.exists("ci-out/fix_markers.txt") else []
print(json.dumps(out, indent=1))
PY
echo "DONE"
