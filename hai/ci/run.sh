#!/usr/bin/env bash
# ZH4-01 HAI: read-only live-state verification + fork simulation via eth_call state override.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 ci/verify_state.py 2>&1 | tee ci-out/verify.log
