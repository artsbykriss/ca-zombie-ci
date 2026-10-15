#!/usr/bin/env bash
# CI heavy job for g8keep: enumerate all factory-held LP pairs on Base at a pinned block,
# verify lockedTokens, compute attributable WETH, check for skim-able excess, dump roles.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
python3 ci/dump_state.py 2>&1 | tee ci-out/dump.log
exit "${PIPESTATUS[0]}"
