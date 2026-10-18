#!/usr/bin/env bash
set -uo pipefail
echo "[exotic-legacy] read-only verification at $(date -u +%FT%TZ)"
python3 ci/verify.py
