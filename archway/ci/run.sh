#!/usr/bin/env bash
# C2-09 / CWA-2026-006 — archway CI entry.
#
# Default job (this task): the archwayd v10.1.0 native-chain PORT analysis
#   (heavy: 105 MB download + ~15 min objdump) -> archway/ci-out/port/
#   -> bash /home/heisenberg/CA/ci/ci-run.sh archway
#
# Optional legacy campaign (heavy Rust/wasmvm build, historical M1-M4 sweep):
#   set RUN_CAMPAIGN=1 to also run harness/campaign_wpn.sh.
set -uo pipefail
cd "$(dirname "$0")/.."          # -> archway/
mkdir -p ci-out

echo "=== archwayd port analysis ==="
bash live/ci/port_analysis.sh 2>&1 | tee ci-out/port_analysis.log

if [ "${RUN_CAMPAIGN:-0}" = "1" ]; then
  echo "=== legacy campaign_wpn.sh (RUN_CAMPAIGN=1) ==="
  bash harness/campaign_wpn.sh 2>&1 | tee ci-out/campaign_wpn.log || true
fi

echo "=== outputs ==="
find ci-out -type f | sort | head -80
exit 0
