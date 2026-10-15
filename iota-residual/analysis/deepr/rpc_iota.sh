#!/usr/bin/env bash
# Keyless public RPC helper for IOTA EVM (8822) — read-only eth_call only.
# Usage: ./rpc_iota.sh <to> <data> [from] [block]
RPC="${IOTA_RPC:-https://rpc.ankr.com/iota_evm}"
TO="$1"; DATA="$2"; FROM="${3:-0x0000000000000000000000000000000000000000}"; BLOCK="${4:-latest}"
if [ -n "$BLOCK" ] && [ "$BLOCK" != "latest" ]; then
  PARAMS="[{\"to\":\"$TO\",\"from\":\"$FROM\",\"data\":\"$DATA\"},\"$BLOCK\"]"
else
  PARAMS="[{\"to\":\"$TO\",\"from\":\"$FROM\",\"data\":\"$DATA\"},\"latest\"]"
fi
curl -s -m 30 -X POST "$RPC" -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_call\",\"params\":$PARAMS}" | jq -r '.result // .error'
