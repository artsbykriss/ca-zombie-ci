#!/usr/bin/env bash
# Keyless public RPC helper for ShimmerEVM (148) — read-only eth_call only.
# Usage: ./rpc_shimmer.sh <to> <data> [block]
RPC="${SHIMMER_RPC:-https://json-rpc.evm.shimmer.network}"
TO="$1"; DATA="$2"; BLOCK="${3:-latest}"
curl -s -m 30 -X POST "$RPC" -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_call\",\"params\":[{\"to\":\"$TO\",\"data\":\"$DATA\"},\"$BLOCK\"]}" | jq -r '.result // .error'
