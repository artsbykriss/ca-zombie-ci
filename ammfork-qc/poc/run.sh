#!/usr/bin/env bash
# Read-only negative-control fork test for Enosys AMM V3.
set -euo pipefail
cd "$(dirname "$0")"
export FLARE_RPC="${FLARE_RPC:-https://flare-api.flare.network/ext/C/rpc}"
export FLARE_BLOCK="${FLARE_BLOCK:-0}"
forge test -vv --match-contract EnosysNegativePoC
