#!/usr/bin/env bash
# shmonad/ci/run.sh — independent live-state re-read + secret scan for the shMonad deliverable.
# Runs in CI (see ci/run.sh helper). Read-only: eth_call / eth_getCode only, no keys, no txs.
# Writes ci-out/live-state.json (uploaded as an artifact). The Foundry PoC is run by the workflow's
# `forge test -vvv` step (poc/foundry.toml pins eth_rpc_url to the keyless public Monad RPC).
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

export SHMONAD_RPC="${MONAD_RPC_URL:-https://rpc.monad.xyz}"
export SHMONAD_PROXY="${SHMONAD_PROXY:-0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c}"
export SHMONAD_IMPL="${SHMONAD_IMPL:-0x8Ee4FF5FF50198dcbB7B882A0781F42724Dd095f}"

python3 analysis/live_check.py | tee ci-out/live-state.json

echo "--- secret scan (keyed URLs / keys) ---"
if grep -rInE 'https?://[a-z0-9.-]*(alchemy|infura|ankr|quicknode|drpc|nodereal|blockpi)\.(com|io)/[A-Za-z0-9_-]{8,}|apikey=[A-Za-z0-9]{10,}|(PRIVATE_KEY|SECRET|API_KEY)\s*[:=]\s*[A-Za-z0-9_-]{16,}' \
     --include='*.md' --include='*.json' --include='*.sh' --include='*.py' --include='*.sol' --include='*.toml' \
     --exclude-dir=lib --exclude-dir=ci-artifacts --exclude-dir=out . 2>/dev/null; then
  echo "SECRET PATTERN FOUND"; exit 1
fi
echo "secret scan: clean"
