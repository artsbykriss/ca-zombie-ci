#!/usr/bin/env bash
# LeetSwap CI job: full variant/excess scan across chains + LEET ecosystem probes (read-only).
set -uo pipefail
cd "$(dirname "$0")/.."
echo "== leetswap scan (base full) =="
LEET_MAX_PAIRS="${LEET_MAX_PAIRS:-4600}" python3 ci/scan.py
echo "== scan exit $? =="
echo "== leet ecosystem =="
python3 ci/leet_eco.py || echo "leet_eco failed"
echo "== done =="
ls -la ci-out/
