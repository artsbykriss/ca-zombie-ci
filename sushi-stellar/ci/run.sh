#!/usr/bin/env bash
# Custom heavy job for CI (GitHub Actions, public repo). READ-ONLY, keyless endpoints only.
# Installs python deps and runs the self-contained Soroban verification.
set -uo pipefail
cd "$(dirname "$0")/.."

echo "[ci] python: $(python3 --version)"
python3 -m pip install --quiet --disable-pip-version-check "stellar-sdk>=16,<17" 2>&1 | tail -3 || true
python3 -c "import stellar_sdk; print('[ci] stellar_sdk', stellar_sdk.__version__ if hasattr(stellar_sdk,'__version__') else 'ok')"

mkdir -p ci-out
echo "[ci] running verification (read-only: simulateTransaction + ledger/event reads only)"
python3 -u ci/verify.py
rc=$?
echo "[ci] verify exit code: $rc"
ls -la ci-out/ || true
exit $rc
