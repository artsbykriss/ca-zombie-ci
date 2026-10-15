#!/usr/bin/env bash
# Fetch actor histories: routerSetter EOA, attacker contract, attacker EOA, plus factory source.
# READ-ONLY. Requires ETHERSCANV2_API_KEY:  source /home/heisenberg/CA/.env
set -u
cd "$(dirname "$0")"
: "${ETHERSCANV2_API_KEY:?source /home/heisenberg/CA/.env first}"
BASE="https://api.etherscan.io/v2/api?chainid=1"
RS=0xCA90D843288E35beeADfCe14E5F906e3F1AFc7cB
FACTORY=0x9a27cb5ae0B2cEe0bb71f9A85C0D60f3920757B4
ATT=0x469424b628A9D2036e41496E814dB500d683b120
ATTEOA=0xbbf8f3fe8e4fdf6b594e6107144d78293d2018fa
DRAIN=0xb2c7332d9e1be6a86d9d37083aa4cc0d94b60eb95cc9b29494555a3c09764930
mkdir -p raw

get() { local out=$1; shift; curl -sS "$BASE&$*&apikey=$ETHERSCANV2_API_KEY" -o "raw/$out"; sleep 0.3; }

get routerSetter_txlist.json         "module=account&action=txlist&address=$RS&sort=asc"
get routerSetter_txlistinternal.json "module=account&action=txlistinternal&address=$RS&sort=asc"
get attacker_txlist.json             "module=account&action=txlist&address=$ATT&sort=asc"
get attacker_txlistinternal.json     "module=account&action=txlistinternal&address=$ATT&sort=asc"
get attacker_tokentx.json            "module=account&action=tokentx&address=$ATT&sort=asc"
get attackerEOA_txlist.json          "module=account&action=txlist&address=$ATTEOA&sort=asc"
get attackerEOA_tokentx.json         "module=account&action=tokentx&address=$ATTEOA&sort=asc"
get factory_source.json              "module=contract&action=getsourcecode&address=$FACTORY"
get drain_internal.json              "module=account&action=txlistinternal&txhash=$DRAIN"
echo "done"
