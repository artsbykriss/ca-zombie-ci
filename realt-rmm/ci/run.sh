#!/usr/bin/env bash
# CI custom job — RealT RMM v3 + RealTokenWrapper (Gnosis, chain 100). Read-only.
# Artifacts: ci-out/*.json + ci-out/*.log. No secrets are printed or written.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

echo "[ci] start $(date -u +%FT%TZ)"
python3 -c "import requests, eth_abi, eth_utils; from eth_utils import keccak; keccak(text='x')" 2>/dev/null || \
  python3 -m pip install --quiet --disable-pip-version-check requests eth-abi eth-utils "eth-hash[pycryptodome]"

# 1. Compact live re-check (core state, RU03 gate, Yam sample/fills, IBP switch)
python3 ci/ci_check.py > ci-out/ci_check.log 2>&1
RC_CHECK=$?
echo "[ci] ci_check rc=$RC_CHECK"
tail -35 ci-out/ci_check.log

# 2. Borrower census (Blockscout holders -> Multicall getUserAccountData)
python3 analysis/census.py > ci-out/census.log 2>&1
RC_CENSUS=$?
echo "[ci] census rc=$RC_CENSUS"
tail -15 ci-out/census.log
[ -f analysis/census.json ] && cp analysis/census.json ci-out/census.json

# 3. Detailed recipient-gate probes (40 tokens x 8 destinations)
python3 analysis/gate_probe.py > ci-out/gate_probe.log 2>&1
RC_GATE=$?
echo "[ci] gate_probe rc=$RC_GATE"
tail -16 ci-out/gate_probe.log
[ -f analysis/gate_probe.json ] && cp analysis/gate_probe.json ci-out/gate_probe.json

# 3b. Exhaustive gate census (all 623 tokens x 4 destinations)
python3 analysis/gate_all.py > ci-out/gate_all.log 2>&1
RC_GATE_ALL=$?
echo "[ci] gate_all rc=$RC_GATE_ALL"
tail -12 ci-out/gate_all.log
[ -f analysis/gate_all.json ] && cp analysis/gate_all.json ci-out/gate_all.json

# 3c. Public-contract whitelist probe (Yam, bridges, routers, Multicall3, ...)
python3 analysis/public_contracts.py > ci-out/public_contracts.log 2>&1
RC_PUBLIC=$?
echo "[ci] public_contracts rc=$RC_PUBLIC"
tail -8 ci-out/public_contracts.log
[ -f analysis/public_contracts_probe.json ] && cp analysis/public_contracts_probe.json ci-out/public_contracts_probe.json

# 4. Yam book re-sample + 30-day fill census
python3 analysis/yam_book.py > ci-out/yam_book.log 2>&1
RC_YAM=$?
echo "[ci] yam_book rc=$RC_YAM"
tail -25 ci-out/yam_book.log
[ -f analysis/yam_book.json ] && cp analysis/yam_book.json ci-out/yam_book.json

# 5. Incumbent cluster + last-30-day liquidation flow
python3 analysis/incumbent.py > ci-out/incumbent.log 2>&1
RC_INC=$?
echo "[ci] incumbent rc=$RC_INC"
tail -8 ci-out/incumbent.log
[ -f analysis/incumbent.json ] && cp analysis/incumbent.json ci-out/incumbent.json

echo "[ci] summary rc: check=$RC_CHECK census=$RC_CENSUS gate=$RC_GATE gate_all=$RC_GATE_ALL public=$RC_PUBLIC yam=$RC_YAM inc=$RC_INC"
echo "[ci] done $(date -u +%FT%TZ)"
# Always exit 0 so the foundry PoC step still runs; failures are visible in the logs above.
exit 0
