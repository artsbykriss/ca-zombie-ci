#!/usr/bin/env bash
# Read-only negative PoC for Enosys AMM V3 (Flare mainnet).
# Forks a public RPC; no keys, no transactions, no mainnet writes.
set -euo pipefail
cd "$(dirname "$0")"

export FLARE_RPC="${FLARE_RPC:-https://flare-api.flare.network/ext/C/rpc}"
export FLARE_BLOCK="${FLARE_BLOCK:-72382727}"

forge test -vv --match-contract EnosysNegativePoC
