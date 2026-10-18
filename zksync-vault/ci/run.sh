#!/usr/bin/env bash
# Heavy CI job for the zkSync SyncSwap Vault deep-dive. Read-only: eth_call only.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
python3 -m pip install --quiet --disable-pip-version-check --break-system-packages requests eth-abi eth-utils "eth-hash[pycryptodome]" pycryptodome 2>/dev/null \
  || python3 -m pip install --quiet --disable-pip-version-check requests eth-abi eth-utils "eth-hash[pycryptodome]" pycryptodome
python3 ci/verify.py 2>&1 | tee ci-out/verify.log
