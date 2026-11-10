#!/usr/bin/env bash
# CA3 residual reconciliation validator. Light, offline, deterministic.
# Reads analysis/candidates.json, checks register integrity + OPEN completeness
# + README coverage + secret scan, writes ci-out/recon-report.json + SUMMARY.txt.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 ci/validate.py
