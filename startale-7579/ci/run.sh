#!/usr/bin/env bash
# Startale ERC-7579 re-check — light CI state dump. No secrets, no keyed URLs on disk.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
echo "=== live state ==="
python3 analysis/live_state.py 2>&1 | tee ci-out/live-state.log
cp -f analysis/prefund_scan_tok.json ci-out/prefund_scan_tok.json 2>/dev/null || true
cp -f analysis/accountcreated_logs_26234434_26334433.json ci-out/accountcreated_logs.json 2>/dev/null || true
echo "=== done ==="
exit 0
