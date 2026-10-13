#!/bin/bash
# Public keyless Aurora RPC helper (no secrets)
RPC="${AURORA_RPC:-https://mainnet.aurora.dev}"
call() { cast call "$1" "$2" "${@:3}" --rpc-url "$RPC" 2>/dev/null; }
