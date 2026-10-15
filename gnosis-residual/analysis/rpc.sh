#!/bin/bash
# Helper: cast call with gnosis public rpc, retry on failure
RPC="${RPC:-https://rpc.gnosischain.com}"
call() { cast call --rpc-url "$RPC" "$@"; }
