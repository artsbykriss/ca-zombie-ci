#!/usr/bin/env bash
# Read-only PoC: R25 WrappedVault family (Pharos 1672).
# No transactions, no secrets; public keyless RPC only.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
python3 poc/r25_poc.py ci-out/r25-poc.json | tee ci-out/summary.txt
