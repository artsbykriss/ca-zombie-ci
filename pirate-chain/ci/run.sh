#!/usr/bin/env bash
# Pirate Chain (ARRR) non-EVM consensus finding — CI verification job.
# Read-only: recomputes the source asymmetry, the on-chain mint deltas,
# peer-version adoption, exit-rail status and mining economics.
set -euo pipefail

cd "$(dirname "$0")/.."

python3 analysis/build_evidence.py
python3 ci/verify.py
