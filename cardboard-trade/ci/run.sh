#!/usr/bin/env bash
# Cardboard Trade — custom CI job: run the read-only negative auth PoC and emit ci-out/cardboard-auth.json.
# Best-effort: never fails the workflow (we still want the artifact/log).
set -u
cd "$(dirname "$0")/.."
echo "[cardboard] installing solders (best effort)"
python3 -m pip install --quiet --disable-pip-version-check solders 2>&1 | tail -2 || true
echo "[cardboard] running poc/cardboard_auth_test.py"
python3 poc/cardboard_auth_test.py 2>&1 | tail -40 || true
echo "[cardboard] ci-out:"; ls -la ci-out 2>/dev/null
exit 0
