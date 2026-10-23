#!/usr/bin/env bash
# ci/run.sh — TOPS (BSC) ZH4P5 live-state snapshot.
# Runs on the CI runner with injected secrets in env (never printed).
# Writes results to ci-out/ (uploaded as an artifact). Read-only: eth_call only.
set -uo pipefail

OUT="ci-out"
mkdir -p "$OUT"

RPC="${BSC_RPC_URL:-}"
[ -z "$RPC" ] && RPC="${FORK_RPC_URL:-}"
[ -z "$RPC" ] && RPC="https://bsc-rpc.publicnode.com"

TOKEN=0x842b1bfa825cf6673fd2d98e573fdd267c3fd588
PAIR=0xbedebac3788171dc769893242a53b881041edf29
USDT=0x55d398326f99059ff775485246999027b3197955
BLOCK="${FORK_BLOCK:-129280478}"

# pick a BSC *archive* endpoint: candidate list from CI secrets, keyless last
ok_rpc(){ cast call "$TOKEN" "owner()(address)" --block "$BLOCK" --rpc-url "$1" >/dev/null 2>&1; }
PICKED=""
for u in "$BSC_RPC_URL" \
         "https://rpc.ankr.com/bsc/${ANKR_API_KEY:-}" \
         "https://lb.drpc.org/ogrpc?network=bsc&dkey=${DRPC_API_KEY:-}" \
         "https://bsc-rpc.publicnode.com"; do
  [ -z "$u" ] && continue
  case "$u" in */) continue;; esac
  if ok_rpc "$u"; then PICKED="$u"; break; fi
done
[ -n "$PICKED" ] && RPC="$PICKED"
echo "archive RPC selected: $([ -n "$PICKED" ] && echo yes || echo no)"

c(){ cast call "$1" "$2" ${3:+$3} --block "$BLOCK" --rpc-url "$RPC" 2>/dev/null | tr '\n' ',' | sed 's/,$//'; }
s(){ c "$1" "$2" ${3:+$3} | tr -d '"'; }

CODE=$(cast code $TOKEN --rpc-url "$RPC" 2>/dev/null | tr 'A-F' 'a-f')
HAS_SYNC=false
case "$CODE" in *fff6cae9*) HAS_SYNC=true;; esac
HAS_SKIM=false
case "$CODE" in *bc25cf77*) HAS_SKIM=true;; esac
LPV=$(c $TOKEN 'liquidityProvider()(address)')

{
  echo "{"
  echo "  \"rpc_provider\": \"<redacted>\","
  echo "  \"block\": $BLOCK,"
  echo "  \"chainId\": $(cast chain-id --rpc-url "$RPC" 2>/dev/null),"
  echo "  \"token0\": \"$(c $PAIR 'token0()(address)')\","
  echo "  \"token1\": \"$(c $PAIR 'token1()(address)')\","
  echo "  \"reserves\": \"$(c $PAIR 'getReserves()(uint112,uint112,uint32)' | tr '\n' ',')\","
  echo "  \"pair_usdt_balance\": \"$(c $USDT 'balanceOf(address)(uint256)' $PAIR)\","
  echo "  \"pair_tops_balance\": \"$(c $TOKEN 'balanceOf(address)(uint256)' $PAIR)\","
  echo "  \"pair_totalSupply_LP\": \"$(c $PAIR 'totalSupply()(uint256)')\","
  echo "  \"token_totalSupply\": \"$(c $TOKEN 'totalSupply()(uint256)')\","
  echo "  \"name\": \"$(s $TOKEN 'name()(string)')\","
  echo "  \"symbol\": \"$(s $TOKEN 'symbol()(string)')\","
  echo "  \"decimals\": \"$(c $TOKEN 'decimals()(uint8)')\","
  echo "  \"owner\": \"$(c $TOKEN 'owner()(address)')\","
  echo "  \"tradeController\": \"$(c $TOKEN 'tradeController()(address)')\","
  echo "  \"blockConfig_buyEnabled_sellEnabled\": \"$(c $TOKEN 'blockConfig()(bool,bool)' | tr '\n' ',')\","
  echo "  \"priceTracker\": \"$(c $TOKEN 'priceTracker()(uint128,uint128,uint32,uint32,uint64)' | tr '\n' ',')\","
  echo "  \"getPriceInfo\": \"$(c $TOKEN 'getPriceInfo()(uint128,uint128,uint32,uint32,uint64,uint256)' | tr '\n' ',')\","
  echo "  \"feeConfig\": \"$(c $TOKEN 'feeConfig()(uint16,uint16,uint16,uint16,uint16,uint16)' | tr '\n' ',')\","
  echo "  \"feeWhiteList_pair\": \"$(c $TOKEN 'feeWhiteList(address)(bool)' $PAIR)\","
  echo "  \"feeWhiteList_liqRemover\": \"$(c $TOKEN 'feeWhiteList(address)(bool)' 0x4aC4Dcc85895c762dF28726f52484dDE83789CD1)\","
  echo "  \"swapPairList_pair\": \"$(c $TOKEN 'swapPairList(address)(bool)' $PAIR)\","
  echo "  \"strictCheck\": \"$(c $TOKEN 'strictCheck()(bool)')\","
  echo "  \"liquidityProvider\": \"$LPV\","
  echo "  \"liquidityProvider_usdt\": \"$(c $USDT 'balanceOf(address)(uint256)' $LPV)\","
  echo "  \"miner\": \"$(c $TOKEN 'miner()(address)')\","
  echo "  \"node\": \"$(c $TOKEN 'node()(address)')\","
  echo "  \"bytecode_has_sync_selector_fff6cae9\": $HAS_SYNC,"
  echo "  \"bytecode_has_skim_selector_bc25cf77\": $HAS_SKIM"
  echo "}"
} > "$OUT/livestate_ci.json" 2>/dev/null

echo "wrote $OUT/livestate_ci.json"
cat "$OUT/livestate_ci.json"
