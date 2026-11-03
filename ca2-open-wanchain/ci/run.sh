#!/usr/bin/env bash
# Heavy CI job for ca2-open-wanchain (Cardano / Wanchain TreasuryCheck).
# Runs on the GitHub Actions runner. Read-only against public APIs.
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p ci-out
echo "== python =="
python3 -V
python3 -m venv .venv-ci
# shellcheck disable=SC1091
. .venv-ci/bin/activate
export PYTHONNOUSERSITE=1
python -V
python -m pip install --quiet --upgrade pip
# Pin pycardano 0.11.0: newer versions pull a cbor2pure shim that fails on py3.14
# (the runner only ships 3.14).  cbor2 5.6.5 still exports CBORDecodeValueError.
python -m pip install --quiet "setuptools<81" "cbor2==5.6.5" "pycardano==0.11.0" uplc ecdsa pycryptodome
python -m pip list 2>/dev/null | grep -iE "uplc|pycardano|cbor2" || true
python -c "import uplc, pycardano, sys; print('deps ok:', pycardano.__file__, sys.executable)"

echo "== 1/4 live state =="
python poc/live_state.py | tee ci-out/live_state.log

echo "== 2/4 UPLC disassembly + builtin inventory =="
python poc/scan_scripts.py | tee ci-out/script_scan.log

echo "== 3/4 encoding PoC =="
python poc/poc_encoding.py | tee ci-out/poc.log

echo "== 4/4 post-rotation signature census =="
python poc/signature_census.py | tee ci-out/signature_census.log

echo "== done =="
ls -la ci-out
