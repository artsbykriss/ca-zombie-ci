#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
python3 analysis/live_checks.py > ci-out/live_checks.json
python3 analysis/ton_checks.py > ci-out/ton_state.json
python3 analysis/assert_gates.py ci-out/live_checks.json ci-out/ton_state.json | tee ci-out/assert.txt
