#!/usr/bin/env bash
# zilliqa-legacy CI job: re-run the read-only verification suite against Zilliqa EVM (chain 32769).
# No secrets required (public RPC only). Writes ci-out/ artifacts.
set -uo pipefail
cd "$(dirname "$0")/.."
echo "[zilliqa-legacy] starting verification at $(date -u +%FT%TZ)"
python3 --version
python3 ci/verify.py 2>&1 | tee ci-out/verify.log
echo "[zilliqa-legacy] done; artifacts:"
ls -la ci-out/ || true
