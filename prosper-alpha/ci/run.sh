#!/usr/bin/env bash
# Heavy job for prosper-alpha: enumerate live markets via logs + dump on-chain state.
# Runs on GitHub Actions (CPU/network heavy). Keyless public RPC only. No secrets.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

echo "== python =="
python3 --version || true

echo "== enumerate markets (log scan + state dump) =="
python3 ci/enumerate.py 2>&1 | tee ci-out/enumerate.log || echo "enumerate failed (non-fatal)"

echo "== pull protocol deployment + vault catalog (public API, read-only) =="
curl -s --max-time 60 "https://api.pros-per.xyz/api/v1/deployment" -o ci-out/api_deployment.json || true
curl -s --max-time 60 "https://api.pros-per.xyz/api/v1/vaults?pageNumber=1&pageSize=100" -o ci-out/api_vaults.json || true
curl -s --max-time 60 "https://api.llama.fi/protocol/prosper-alpha" -o ci-out/llama.json || true

echo "== read-only PoC simulation (eth_call) =="
export PATH="$HOME/.foundry/bin:$PATH"
python3 ci/poc_sim.py ci-out
POC_RC=$?
echo "poc_sim exit=$POC_RC"
ls -la ci-out
echo "== done =="
exit $POC_RC
