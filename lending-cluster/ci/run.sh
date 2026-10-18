#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
python3 -m pip install --quiet --disable-pip-version-check eth_abi requests
python3 ci/recon.py | tee ci-out/recon.log
