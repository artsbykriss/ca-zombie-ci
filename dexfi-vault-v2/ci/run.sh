#!/usr/bin/env bash
# Heavy job for DexFi Aggregator Vault V2: enumerate every vault on every chain
# and value it. Runs on GitHub Actions (public repo). Read-only eth_call only.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

echo "### DexFi Vault V2 full enumeration"
python3 --version

# Base is the primary target (1895 vaults); other chains are small.
python3 analysis/scan_full.py base arbitrum ethereum bsc avax sonic 2>&1 | tee ci-out/scan.log

echo "### Valuation"
for c in base arbitrum ethereum bsc avax sonic; do
  if [ -f "ci-out/scan_${c}.json" ]; then
    echo "--- $c ---" | tee -a ci-out/value.log
    python3 analysis/value.py "ci-out/scan_${c}.json" "$c" 2>&1 | tee -a ci-out/value.log
  fi
done

echo "### DONE"
