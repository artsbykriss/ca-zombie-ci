#!/usr/bin/env bash
# Heavy job for the BitSafe CBTC (Canton) reserve scan.
# Runs on GitHub Actions (public repo). Keyless public Esplora endpoints only.
# No secrets are read or written here. No pip dependencies (pure-python secp256k1).
set -euo pipefail
cd "$(dirname "$0")/.."     # folder root

mkdir -p ci-out
echo "=== BitSafe CBTC reserve scan ==="
python3 --version

# 1) independent address-derivation verification (pure python, no deps)
python3 analysis/verify_derivation.py | tee ci-out/derive.log || true

# 2) full on-chain reserve + spend-witness scan
python3 analysis/scan.py | tee ci-out/scan.log

echo "=== done; artifacts in ci-out/ ==="
ls -la ci-out
