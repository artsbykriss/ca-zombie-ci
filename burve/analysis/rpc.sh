#!/usr/bin/env bash
# Keyless public Berachain RPC helper (read-only).
RPC="${BERA_RPC:-https://rpc.berachain.com}"
call() { # to data
  curl -s -m 25 -X POST -H 'Content-Type: application/json' -H 'User-Agent: Mozilla/5.0' \
    --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_call\",\"params\":[{\"to\":\"$1\",\"data\":\"$2\"},\"latest\"]}" "$RPC"
}
rpc() { # method params
  curl -s -m 25 -X POST -H 'Content-Type: application/json' -H 'User-Agent: Mozilla/5.0' \
    --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$1\",\"params\":$2}" "$RPC"
}
"$@"
