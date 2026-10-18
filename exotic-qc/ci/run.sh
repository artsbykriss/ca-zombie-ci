#!/usr/bin/env bash
set -uo pipefail
echo "[exotic-qc] independent read-only QC gate at $(date -u +%FT%TZ)"
python3 ci/verify_qc.py
