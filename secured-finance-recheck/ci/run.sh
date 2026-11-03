#!/usr/bin/env bash
# Secured Finance re-check — light CI state dump. No secrets, no keyed URLs on disk.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
echo "=== live state ==="
python3 analysis/live_state.py 2>&1 | tee ci-out/live-state.log
echo "=== done ==="
exit 0
