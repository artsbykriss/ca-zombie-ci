#!/usr/bin/env bash
# solana JSON-RPC helper — keyless public endpoints by default; never embed secrets.
# Usage: rpc.sh <method> '<params-json>'   (env SOLANA_RPC overrides endpoint)
RPC="${SOLANA_RPC:-https://api.mainnet-beta.solana.com}"
M="$1"; P="${2:-[]}"
curl -s -m 30 -X POST "$RPC" -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$M\",\"params\":$P}"
