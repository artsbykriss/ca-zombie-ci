#!/usr/bin/env bash
# usage: rpc.sh <chain-env-var> <method> <params-json>
# reads the RPC URL from env (never written to disk)
set -euo pipefail
V="$1"; M="$2"; P="$3"
U="${!V:?missing $V}"
curl -s -m 25 -X POST -H 'content-type: application/json' --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$M\",\"params\":$P}" "$U"
