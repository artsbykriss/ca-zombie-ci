#!/usr/bin/env bash
# PurrSwap (HyperEVM, chainid 999) — custom CI job.
# Read-only: queries the keyless public HyperEVM RPC and writes a state snapshot
# to ci-out/. NO secrets, NO keyed URLs, NO transactions.
set -uo pipefail

RPC="${HYPER_RPC_URL:-https://rpc.hyperliquid.xyz/evm}"
OUT="ci-out"
mkdir -p "$OUT"

FACTORY=0x802762e604CE08a79DA2BA809281D727A690Fa0d
POOL1=0x4E90767E92E58170F6732a7Fa652e03B82e5bb44
POOL2=0x7B3959da5d74648Af48B8D69e19ea6a9812cdFDB

BLK=$(cast block-number --rpc-url "$RPC")
echo "[purrswap-ci] rpc=$RPC block=$BLK"

call() { cast call "$1" "$2" --block "$BLK" --rpc-url "$RPC" 2>/dev/null | tr '\n' ' ' | sed 's/ *$//'; }
# string-returning calls: strip the surrounding double quotes and trailing space
str() { call "$1" "$2" | sed 's/^"//; s/"$//'; }

{
  echo "{"
  echo "  \"chain\": \"hyperevm\","
  echo "  \"chain_id\": 999,"
  echo "  \"block\": $BLK,"
  echo "  \"rpc\": \"(keyless public)\","
  echo "  \"factory\": {"
  echo "    \"address\": \"$FACTORY\","
  echo "    \"implementation\": \"$(call $FACTORY 'implementation()(address)')\","
  echo "    \"owner\": \"$(call $FACTORY 'owner()(address)')\""
  echo "  },"
  for P in "$POOL1" "$POOL2"; do
    echo "  \"pool_$P\": {"
    echo "    \"name\": \"$(str $P 'name()(string)')\","
    echo "    \"version\": \"$(str $P 'version()(string)')\","
    echo "    \"base_token\": \"$(call $P '_BASE_TOKEN_()(address)')\","
    echo "    \"quote_token\": \"$(call $P '_QUOTE_TOKEN_()(address)')\","
    echo "    \"oracle\": \"$(call $P '_ORACLE_()(address)')\","
    echo "    \"I\": \"$(call $P '_I_()(uint256)')\","
    echo "    \"getEffectiveI\": \"$(call $P 'getEffectiveI()(uint256)')\","
    echo "    \"totalSupply\": \"$(call $P 'totalSupply()(uint256)')\","
    echo "    \"reserves\": \"$(call $P 'getReserves()(uint256,uint256)')\""
    echo "  },"
  done
  echo '  "note": "read-only snapshot; E-U extractable = 0 (dust only)"'
  echo "}"
} > "$OUT/live-state-ci.json"

echo "[purrswap-ci] wrote $OUT/live-state-ci.json"
cat "$OUT/live-state-ci.json"
