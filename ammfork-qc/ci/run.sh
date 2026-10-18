#!/usr/bin/env bash
# Independent QC re-read of the six AMM-fork lanes. Read-only, keyless public RPCs.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
python3 ci/qc_check.py
