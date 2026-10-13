#!/usr/bin/env bash
# CI job for "01" (01 Exchange Solana wind-down) — read-only live verification.
# Runs on GitHub Actions (public repo). Uses public Solana RPC only. No secrets.
set -uo pipefail
cd "$(dirname "$0")"
echo "[01-ci] installing solders..."
python3 -m pip install --quiet --disable-pip-version-check solders >/dev/null 2>&1 || pip3 install --quiet solders
echo "[01-ci] python: $(python3 --version)"
echo "[01-ci] running verification (read-only simulations, public RPC)..."
python3 verify.py 2>&1 | tee ci-out/01-verify.log
echo "[01-ci] done. files:"
ls -la ci-out/ || true
