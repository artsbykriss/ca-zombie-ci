#!/usr/bin/env bash
# CI job for caviarnine-lsu-pool: read-only live verification against the public Radix Gateway.
set -euo pipefail
cd "$(dirname "$0")/.."
echo "[ci] pwd=$(pwd)"
python3 --version
mkdir -p ci-out
python3 ci/verify_live.py 2>&1 | tee ci-out/scan.log
echo "[ci] done"
