#!/usr/bin/env bash
# Light CI job: re-read the live MYT vault + Alchemist state at the CI run's head blocks.
# Writes ci-out/live_state.json (uploaded as an artifact). No secrets are printed or written.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 analysis/ci_live_state.py
