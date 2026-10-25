#!/usr/bin/env bash
# ci/run.sh — light pre-job for Parallel Protocol V3 (Diamond) oracle/collateral recon.
# Snapshots live Ethereum state (facets, collaterals, oracle configs/values, feed freshness)
# into ci-out/live-state.json. NO secrets are written (RPC comes from env; only the URL host is noted).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$HERE/ci-out"
mkdir -p "$OUT"

RPC="${FORK_RPC_URL:-${RPC_URL:-https://ethereum-rpc.publicnode.com}}"
# only record the host, never a keyed URL
RPC_HOST="$(printf '%s' "$RPC" | sed -E 's#^https?://##; s#/.*##; s#\?.*##')"
echo "[ci] using RPC host: $RPC_HOST"

D=0x6efeDDF9269c3683Ba516cb0e2124FE335F262a2
TP=0x9B3a8f7CEC208e247d97dEE13313690977e24459
COLS="0xCAcd6fd266aF91b8AeD52aCCc382b4e165586E29 0xcf62F905562626CfcDD2261162a51fd02Fc9c5b6 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497"
FEEDS="0x9B4a96210bc8D9D55b1908B465D8B0de68B7fF83 0xa569d910839Ae8865Da8F8e70FfFb0cBA869F961 0xFF3BC18cCBd5999CE63E788A1c250a88626aD099"

BLK="$(cast block-number --rpc-url "$RPC" 2>/dev/null || echo 0)"
echo "[ci] block $BLK"

{
  echo "{"
  echo "  \"block\": $BLK,"
  echo "  \"rpc_host\": \"$RPC_HOST\","
  echo "  \"diamond\": \"$D\","
  echo "  \"tokenP\": \"$(cast call "$D" 'tokenP()(address)' --rpc-url "$RPC" --block "$BLK" 2>/dev/null)\","
  echo "  \"accessManager\": \"$(cast call "$D" 'accessManager()(address)' --rpc-url "$RPC" --block "$BLK" 2>/dev/null)\","
  echo "  \"swapRouter\": \"$(cast call "$D" 'getSwapRouter()(address)' --rpc-url "$RPC" --block "$BLK" 2>/dev/null)\","
  echo "  \"collatRatio\": \"$(cast call "$D" 'getCollateralRatio()(uint64,uint256)' --rpc-url "$RPC" --block "$BLK" 2>/dev/null | tr '\n' ' ')\","
  echo "  \"totalIssued\": \"$(cast call "$D" 'getTotalIssued()(uint256)' --rpc-url "$RPC" --block "$BLK" 2>/dev/null)\","
  echo "  \"usdpTotalSupply\": \"$(cast call "$TP" 'totalSupply()(uint256)' --rpc-url "$RPC" --block "$BLK" 2>/dev/null)\","
  echo "  \"facets\": ["
  for F in $(cast call "$D" 'facetAddresses()(address[])' --rpc-url "$RPC" --block "$BLK" 2>/dev/null | tr -d '[]' | tr ',' ' '); do
    echo "    {\"facet\": \"$F\", \"selectors\": \"$(cast call "$D" 'facetFunctionSelectors(address)(bytes4[])' "$F" --rpc-url "$RPC" --block "$BLK" 2>/dev/null | tr -d '[]' | tr -d ' ')\"},"
  done
  echo "    null"
  echo "  ],"
  echo "  \"collaterals\": ["
  for C in $COLS; do
    echo "    {"
    echo "      \"address\": \"$C\","
    echo "      \"symbol\": $(cast call "$C" 'symbol()(string)' --rpc-url "$RPC" --block "$BLK" 2>/dev/null || echo '\"?\"'),"
    echo "      \"mintPaused\": $(cast call "$D" 'isPaused(address,uint8)(bool)' "$C" 0 --rpc-url "$RPC" --block "$BLK" 2>/dev/null || echo true),"
    echo "      \"burnPaused\": $(cast call "$D" 'isPaused(address,uint8)(bool)' "$C" 1 --rpc-url "$RPC" --block "$BLK" 2>/dev/null || echo true),"
    echo "      \"whitelisted\": $(cast call "$D" 'isWhitelistedCollateral(address)(bool)' "$C" --rpc-url "$RPC" --block "$BLK" 2>/dev/null || echo true),"
    echo "      \"stablecoinCap\": \"$(cast call "$D" 'getStablecoinCap(address)(uint256)' "$C" --rpc-url "$RPC" --block "$BLK" 2>/dev/null)\","
    echo "      \"issuedByCollateral\": \"$(cast call "$D" 'getIssuedByCollateral(address)(uint256,uint256)' "$C" --rpc-url "$RPC" --block "$BLK" 2>/dev/null | head -1)\","
    echo "      \"parBalance\": \"$(cast call "$C" 'balanceOf(address)(uint256)' "$D" --rpc-url "$RPC" --block "$BLK" 2>/dev/null)\","
    echo "      \"oracleValues_mint_burn_ratio_minRatio_redeem\": \"$(cast call "$D" 'getOracleValues(address)(uint256,uint256,uint256,uint256,uint256)' "$C" --rpc-url "$RPC" --block "$BLK" 2>/dev/null | tr '\n' ' ')\","
    echo "      \"mintPrice_quoteIn_1000e18\": \"$(cast call "$D" 'quoteIn(uint256,address,address)(uint256)' 1000000000000000000000 "$C" "$TP" --rpc-url "$RPC" --block "$BLK" 2>/dev/null)\","
    echo "      \"oracleType_targetType\": \"$(cast call "$D" 'getOracle(address)(uint8,uint8,bytes,bytes,bytes)' "$C" --rpc-url "$RPC" --block "$BLK" 2>/dev/null | head -2 | tr '\n' ',')\""
    echo "    },"
  done
  echo "    null"
  echo "  ],"
  echo "  \"feeds\": ["
  for F in $FEEDS; do
    echo "    {"
    echo "      \"address\": \"$F\","
    echo "      \"description\": $(cast call "$F" 'description()(string)' --rpc-url "$RPC" --block "$BLK" 2>/dev/null || echo '\"?\"'),"
    echo "      \"latestRoundData\": \"$(cast call "$F" 'latestRoundData()(uint80,int256,uint256,uint256,uint80)' --rpc-url "$RPC" --block "$BLK" 2>/dev/null | tr '\n' ' ')\","
    echo "      \"blockTimestamp\": \"$(cast block "$BLK" --rpc-url "$RPC" --field timestamp 2>/dev/null)\""
    echo "    },"
  done
  echo "    null"
  echo "  ]"
  echo "}"
} > "$OUT/live-state.json"

echo "[ci] wrote $OUT/live-state.json"
python3 -c "import json;d=json.load(open('$OUT/live-state.json'));print('block',d['block'],'facets',len([x for x in d['facets'] if x]),'collaterals',len([x for x in d['collaterals'] if x]),'feeds',len([x for x in d['feeds'] if x]))" || true
