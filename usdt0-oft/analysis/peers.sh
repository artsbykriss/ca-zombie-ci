#!/usr/bin/env bash
set -u
RPC=${RPC:-https://ethereum-rpc.publicnode.com}
P=0x6C96dE32CEa08842dcc4058c14d3aaAD7Fa41dee
EIDS="30101 30102 30109 30110 30111 30181 30165 30184 30214 30243 30260 30316 30322 30339 30375 30390"
for e in $EIDS; do
  pr=$(cast call $P "peers(uint32)(bytes32)" $e --rpc-url $RPC 2>/dev/null)
  echo "$e $pr"
done
