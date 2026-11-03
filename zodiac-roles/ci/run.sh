#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
python3 analysis/ci_scan.py > ci-out/scan.json
python3 analysis/ci_assert.py | tee ci-out/assert.txt
