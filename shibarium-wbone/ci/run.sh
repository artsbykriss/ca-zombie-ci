#!/usr/bin/env bash
# Light state snapshot for the ZH4-03 CI run.  Public RPCs only; never fails the job.
set -uo pipefail
mkdir -p ci-out
python3 analysis/collect_state.py > ci-out/collect_state.log 2>&1 || true
cp analysis/state.json ci-out/state.json 2>/dev/null || true
exit 0
