#!/usr/bin/env bash
# CI heavy job for ca3-open-vesper.
# - refreshes the fleet snapshot from a public RPC (falls back to the committed snapshot)
# - renders the fleet table + booked-vs-realisable backing table
# - runs a secret scan over the folder
# Everything written here is public: no keys, no keyed URLs.
set -uo pipefail

mkdir -p ci-out
RPC_ETH="${FORK_RPC_URL:-${RPC_URL:-https://ethereum-rpc.publicnode.com}}"
RPC_BASE="${BASE_RPC_URL:-https://base-rpc.publicnode.com}"

echo "== refresh Ethereum fleet snapshot"
python3 analysis/scan.py 1 analysis/api-pools.json analysis/state-1.ci.json "$RPC_ETH" || echo "WARN: eth rescan failed, keeping committed snapshot"
echo "== refresh Base fleet snapshot"
python3 analysis/scan.py 8453 analysis/api-base-pools.json analysis/state-8453.ci.json "$RPC_BASE" || echo "WARN: base rescan failed, keeping committed snapshot"
if [ -s analysis/state-1.ci.json ]; then mv analysis/state-1.ci.json analysis/state-1.json; fi
if [ -s analysis/state-8453.ci.json ]; then mv analysis/state-8453.ci.json analysis/state-8453.json; fi

echo "== refresh Optimism fleet snapshot"
python3 analysis/scan.py 10 analysis/api-op-pools.json analysis/state-10.ci.json "${OP_RPC_URL:-https://optimism-rpc.publicnode.com}" || echo "WARN: op rescan failed, keeping committed snapshot"
if [ -s analysis/state-10.ci.json ]; then mv analysis/state-10.ci.json analysis/state-10.json; fi

echo "== fleet table"
python3 analysis/report.py --out ci-out/fleet.json | tee ci-out/fleet-table.txt

echo "== booked vs realisable backing"
python3 analysis/backing.py --out ci-out/backing.json | tee ci-out/backing.txt

echo "== secret scan"
if grep -rInE "(api[_-]?key|apikey|secret|private[_-]?key|PRIVATE KEY|alchemy\.com/v2/|infura\.io/v3/|drpc\.org/[A-Za-z0-9]{8,}|quiknode|bearer [A-Za-z0-9]{16,})" \
     --include="*.sol" --include="*.py" --include="*.sh" --include="*.json" --include="*.md" --include="*.toml" \
     --exclude-dir=lib --exclude-dir=out --exclude-dir=cache --exclude-dir=ci-artifacts \
     . 2>/dev/null | grep -v "^./ci/run.sh" | grep -viE "no (api|secret)|never|redact|api\.vesper" ; then
  echo "SECRET-SCAN: review above lines"
else
  echo "SECRET-SCAN: clean"
fi
echo "== done"
