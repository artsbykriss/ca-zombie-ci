#!/usr/bin/env bash
# Thin wrapper around cast with block pinning. Usage: ./c.sh <to> "<sig>" [args...]  (block via $BLK)
set -euo pipefail
RPC="${RPC_URL:-https://ethereum-rpc.publicnode.com}"
BLK="${BLK:-latest}"
to="$1"; sig="$2"; shift 2
cast call "$to" "$sig" "$@" --rpc-url "$RPC" --block "$BLK"
