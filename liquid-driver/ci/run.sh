#!/usr/bin/env bash
# Liquid Driver CI heavy job: full read-only state enumeration + fingerprinting + valuation.
set -uo pipefail
cd "$(dirname "$0")/.."
echo "[ci] working dir: $(pwd)"
python3 -c "import sys; print('python', sys.version)"
echo "=== enumerate ==="
python3 ci/enumerate.py 2>&1 | tee ci-out/enumerate.log
echo "=== fingerprint ==="
python3 ci/fingerprint.py 2>&1 | tee ci-out/fingerprint.log
echo "=== valuation ==="
python3 ci/valuation.py 2>&1 | tee ci-out/valuation.log
echo "[ci] done"
ls -la ci-out/
