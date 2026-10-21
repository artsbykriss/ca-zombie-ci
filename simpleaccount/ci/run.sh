#!/usr/bin/env bash
# Custom heavy job for the SimpleAccount factory deep-dive (Arbitrum One).
# Read-only: only eth_getCode / eth_getBalance / eth_call / Etherscan GETs. No signing.
# Writes results to ci-out/ (uploaded as a CI artifact).
set -uo pipefail

echo "=== SimpleAccount factory — live census at CI time ==="
python3 ci/census-ci.py || echo "WARN: census failed (see above)"
echo "=== done ==="
