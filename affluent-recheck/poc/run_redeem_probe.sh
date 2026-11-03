#!/usr/bin/env bash
# Read-only TVM redeem probe. No keys, no broadcast.
set -uo pipefail
cd "$(dirname "$0")/.."
python3 analysis/recheck.py
python3 analysis/verify_saved.py
