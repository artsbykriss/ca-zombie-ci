#!/usr/bin/env bash
# Cellana semantic + live-state checks. Read-only; no key, no transaction.
set -euo pipefail
python3 ci/cellana_checks.py
