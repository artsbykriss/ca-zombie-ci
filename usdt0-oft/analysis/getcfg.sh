#!/usr/bin/env bash
set -u
RPC=${RPC:-https://ethereum-rpc.publicnode.com}
P=0x6C96dE32CEa08842dcc4058c14d3aaAD7Fa41dee
EP=0x1a44076050125825900e736c501f859c50fE728c
LIB=0xc02Ab410f0734EFa3F14628780e6e695156024C2
for e in "$@"; do
  echo "EID $e"
  cast call $EP "getConfig(address,address,uint32,uint32)(bytes)" $P $LIB $e 2 --rpc-url $RPC 2>&1
done
