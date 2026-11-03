#!/usr/bin/env bash
# ca2-supplychain CI job: read-only verification of the BTCPay and Fearless Wallet findings.
# Public data only. No secrets. No transactions.
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p ci-out/btcpay ci-out/fearless-wallet
python3 -m pip install --quiet requests || true

echo "[btcpay] tracing the two vendor-named addresses..."
python3 ci/btcpay_trace.py > ci-out/btcpay/addresses.json 2> ci-out/btcpay/errors.txt
echo "[btcpay] done: $(wc -c < ci-out/btcpay/addresses.json) bytes"

echo "[fearless] verifying reported extrinsics + current balances..."
python3 ci/polkadot_verify.py > ci-out/fearless-wallet/verify.json 2> ci-out/fearless-wallet/errors.txt
echo "[fearless] done: $(wc -c < ci-out/fearless-wallet/verify.json) bytes"

echo "[fearless] checking store artifact, remote switch, DNS..."
python3 ci/store_check.py > ci-out/fearless-wallet/store.json 2> ci-out/fearless-wallet/store-errors.txt
echo "[fearless] done: $(wc -c < ci-out/fearless-wallet/store.json) bytes"

python3 ci/summarize.py > ci-out/COMBINED.md
cat ci-out/COMBINED.md

echo "[done] results in ci-out/"
