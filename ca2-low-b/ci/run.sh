#!/usr/bin/env bash
# ca2-low-b — off-chain verification jobs for the three LOW findings.
# Runs from the folder root inside GitHub Actions. Read-only; no secrets are written.
set -uo pipefail
mkdir -p ci-out

echo "=== [1/3] BlueMove Sui full Pool scan ==="
python3 ci/bluemove_scan.py > ci-out/bluemove_scan.log 2>&1
BRC=$?
echo "bluemove exit=$BRC"; tail -n 25 ci-out/bluemove_scan.log

echo "=== [2/3] Few-and-Far NEAR live guard/collection check ==="
python3 ci/near_check.py > ci-out/near_check.log 2>&1
NRC=$?
echo "near exit=$NRC"; tail -n 25 ci-out/near_check.log

echo "=== [3/3] SatoHook live storage snapshot ==="
python3 ci/satohook_live.py > ci-out/satohook_live.log 2>&1
SRC=$?
echo "satohook exit=$SRC"; tail -n 25 ci-out/satohook_live.log

echo "=== summary ==="
echo "bluemove=$BRC near=$NRC satohook=$SRC"
ls -la ci-out
