#!/usr/bin/env bash
# ci/run.sh — bigshot: read-only live-state + sibling sweep. Writes JSON to ci-out/.
# NEVER prints or writes keyed RPC URLs (env values are used but only chain NAMES are emitted).
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
B=0x274D146c910dCe811805E08fF8F61a1c3A931c4a
OP="${OP_RPC_URL:-https://mainnet.optimism.io}"

# --- BigShot live state on Optimism ---
OUT=ci-out/bigshot_live_state.json
code=$(cast code "$B" --rpc-url "$OP" 2>/dev/null)
size=$(( (${#code} - 2) / 2 ))
{
  echo "{"
  echo "  \"target\": \"$B\","
  echo "  \"chain\": \"optimism\","
  echo "  \"block\": $(cast block-number --rpc-url "$OP" 2>/dev/null),"
  echo "  \"codesize\": $size,"
  echo "  \"codehash\": \"$(cast keccak "$code" 2>/dev/null)\","
  echo "  \"native_wei\": \"$(cast balance "$B" --rpc-url "$OP" 2>/dev/null)\","
  echo "  \"owner\": \"$(cast call "$B" 'owner()(address)' --rpc-url "$OP" 2>/dev/null)\","
  echo "  \"weth9\": \"$(cast call "$B" 'WETH9()(address)' --rpc-url "$OP" 2>/dev/null)\","
  echo "  \"factory\": \"$(cast call "$B" 'factory()(address)' --rpc-url "$OP" 2>/dev/null)\","
  echo "  \"sel_sweepToken\": $(echo "$code" | grep -c df2ab5bb),"
  echo "  \"sel_unwrapWETH9\": $(echo "$code" | grep -c 49404b7c),"
  echo "  \"sel_refundETH\": $(echo "$code" | grep -c 12210e8a),"
  echo "  \"token_balances\": $(curl -sL -m 15 "https://optimism.blockscout.com/api/v2/addresses/$B/token-balances" -H 'User-Agent: Mozilla/5.0' 2>/dev/null || echo 'null')"
  echo "}"
} > "$OUT"
echo "[ci] wrote $OUT"

# --- sibling sweep: same address on other chains (expect all empty) ---
SIB=ci-out/bigshot_sibling_sweep.json
{
  echo "{"
  echo "  \"note\": \"BigShot address on other chains (expect codesize 0: deployed by a nonce CREATE from a 7702 smart EOA)\","
  echo "  \"address\": \"$B\","
  echo "  \"chains\": {"
  first=1
  for pair in \
    "ethereum|${FORK_RPC_URL:-https://ethereum-rpc.publicnode.com}" \
    "base|${BASE_RPC_URL:-https://mainnet.base.org}" \
    "arbitrum|${ARB_RPC_URL:-https://arb1.arbitrum.io/rpc}" \
    "bsc|${BSC_RPC_URL:-https://bsc-rpc.publicnode.com}" \
    "gnosis|${GNOSIS_RPC_URL:-https://rpc.gnosischain.com}" \
    "polygon|${POLYGON_RPC_URL:-https://polygon-bor-rpc.publicnode.com}" \
    "linea|https://rpc.linea.build" "scroll|https://rpc.scroll.io" "mantle|https://rpc.mantle.xyz" \
    "zksync|https://mainnet.era.zksync.io" "blast|https://rpc.blast.io" "mode|https://mainnet.mode.network" \
    "unichain|https://mainnet.unichain.org" "soneium|https://rpc.soneium.org" "celo|https://forno.celo.org" \
    "avalanche|https://api.avax.network/ext/bc/C/rpc" "fantom|https://rpcapi.fantom.network" \
    "worldchain|https://worldchain-mainnet.g.alchemy.com/public" "metis|https://metis-rpc.publicnode.com" \
    "polygon-zkevm|https://zkevm-rpc.com" "arbitrum-nova|https://nova.arbitrum.io/rpc" \
    "manta|https://pacific-rpc.manta.network/http" "opbnb|https://opbnb-mainnet-rpc.bnbchain.org" \
    "fraxtal|https://rpc.frax.com" "cronos|https://evm.cronos.org" "boba|https://mainnet.boba.network" \
    "aurora|https://mainnet.aurora.dev" "core|https://rpc.coredao.org" "xlayer|https://rpc.xlayer.tech" \
    "zetachain|https://zetachain-evm.blockpi.network/v1/rpc/public" "apechain|https://rpc.apechain.com/http" \
    "sonic|https://rpc.soniclabs.com" "ink|https://rpc-gel.inkonchain.com" "taiko|https://rpc.mainnet.taiko.xyz" \
    "kava|https://evm.kava.io" "sei|https://evm-rpc.sei-apis.com" "astar|https://rpc.astar.network" \
    "zora|https://rpc.zora.energy" "bob|https://rpc.gobob.xyz" "flare|https://flare-api.flare.network/ext/C/rpc" \
    "ronin|https://api.roninchain.com/rpc" "rootstock|https://public-node.rsk.co" "lisk|https://rpc.api.lisk.com" ; do
    c=${pair%%|*}; u=${pair##*|}
    sz=$(cast codesize "$B" --rpc-url "$u" 2>/dev/null || echo ERR)
    [ -z "$sz" ] && sz=ERR
    case "$sz" in
      ''|*[!0-9]*) printf '%s    "%s": "%s"\n' "$([ $first -eq 0 ] && echo ',')" "$c" "$sz" ;;
      *)           printf '%s    "%s": %s\n' "$([ $first -eq 0 ] && echo ',')" "$c" "$sz" ;;
    esac
    first=0
  done
  echo "  }"
  echo "}"
} > "$SIB"
echo "[ci] wrote $SIB"

# --- class-level siblings: canonical Uniswap V3 periphery (public sweepToken by design) ---
CLS=ci-out/uniswap_v3_periphery_class.json
{
  echo "{"
  echo "  \"note\": \"Canonical Uniswap V3 periphery also exposes public sweepToken/unwrapWETH9/refundETH (empty or spam-only at rest)\","
  echo "  \"optimism_npm_0xC36442b4a4522E871399CD717aBDD847Ab11FE88_native_wei\": \"$(cast balance 0xC36442b4a4522E871399CD717aBDD847Ab11FE88 --rpc-url "$OP" 2>/dev/null)\","
  echo "  \"optimism_swaprouter_0xE592427A0AEce92De3Edee1F18E0157C05861564_native_wei\": \"$(cast balance 0xE592427A0AEce92De3Edee1F18E0157C05861564 --rpc-url "$OP" 2>/dev/null)\","
  echo "  \"optimism_swaprouter02_0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45_native_wei\": \"$(cast balance 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45 --rpc-url "$OP" 2>/dev/null)\""
  echo "}"
} > "$CLS"
echo "[ci] wrote $CLS"
