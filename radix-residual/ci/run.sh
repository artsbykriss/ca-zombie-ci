#!/usr/bin/env bash
# radix-residual CI job: independent live re-verification of the headline findings.
# Read-only: public Radix Gateway queries + preview simulations only. Nothing is signed or submitted.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
python3 ci/verify_live.py 2>&1 | tee ci-out/verify.log
