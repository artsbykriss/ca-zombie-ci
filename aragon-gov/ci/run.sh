#!/usr/bin/env bash
# Aragon-gov — heavy CI job: full on-chain enumeration of the Aragon-legacy
# governance class (permission-manager re-read for all funded DAOs + token
# liquidity scan for the manager-funded set).  Keyless RPC only.
set -uo pipefail
cd "$(dirname "$0")/.."   # -> aragon-gov/
mkdir -p ci-out

echo "== python deps =="
python3 -m pip install --quiet pycryptodome 2>/dev/null || pip3 install --quiet pycryptodome 2>/dev/null || true
python3 -c "import Crypto; print('pycryptodome ok')"

echo "== full enumeration scan =="
CI_OUT="$(pwd)/ci-out" python3 analysis/full_scan.py 2>&1 | tee ci-out/full_scan.log

echo "== governance-token supply scan (STUCK classification) =="
python3 analysis/supply_scan.py 2>&1 | tee ci-out/supply_scan.log

echo "== files =="
ls -la ci-out/
