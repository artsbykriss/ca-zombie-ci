#!/usr/bin/env bash
# L2-25 kava-iota-misc — CI custom heavy job.
# Runs the Kava Earn live-state invariant check (public LCD only; no secrets).
# Results land in ci-out/ and are uploaded as artifacts.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
echo "=== Kava Earn accounting invariant check ==="
python3 ci/kava_earn_check.py 2>&1 | tee ci-out/kava_earn_check.log
echo "=== done (exit $?) ==="
