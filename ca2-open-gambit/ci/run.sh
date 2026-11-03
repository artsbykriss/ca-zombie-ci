#!/usr/bin/env bash
# Light live-state dump; the heavyweight fork tests run via `forge test` from ../poc.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 analysis/ci_state.py
