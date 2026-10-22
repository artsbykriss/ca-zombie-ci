#!/usr/bin/env bash
# ci/run.sh — metis-multicall3router: read-only multichain sibling sweep + live-state dump.
# Runs inside GitHub Actions (foundry toolchain available). Writes JSON to ci-out/.
# NEVER prints or writes keyed RPC URLs (env values are used but only chain NAMES are emitted).
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
M=0x6222f99443A0d75bd96d40F2904606f60f37cdc2
SEL_CLEAN=3dad0c9c   # cleanupERC20(address,address)
SEL_APPR=5e069ba5    # safeApproveIfBelow(address,address,uint256)
SEL_PRM2=e13157f5    # safeApprovePermit2(address,address,uint256)
CT() { timeout 25 cast "$@" 2>/dev/null || true; }

# Deterministic deployment (Arachnid proxy 0x4e59b44847b379578588920cA78FbF26c0B4956C) => same
# address + same code on every chain where the proxy exists.
CHAINS="ethereum optimism base arbitrum bsc polygon gnosis avalanche celo linea scroll mantle zksync blast mode metis unichain soneium worldchain xlayer opbnb sonic manta taiko polygon-zkevm ink cronos sei zora bob flare ronin rootstock lisk fantom arbitrum-nova fraxtal aurora core apechain kava astar harmony oasis cyber kaia metall2 zklink shape boba"

rpc_for() {  # env RPC first (may be keyed/empty)
  case "$1" in
    ethereum)  echo "${FORK_RPC_URL:-${RPC_URL:-}}" ;;
    optimism)  echo "${OP_RPC_URL:-}" ;;
    base)      echo "${BASE_RPC_URL:-}" ;;
    arbitrum)  echo "${ARB_RPC_URL:-}" ;;
    bsc)       echo "${BSC_RPC_URL:-}" ;;
    polygon)   echo "${POLYGON_RPC_URL:-}" ;;
    gnosis)    echo "${GNOSIS_RPC_URL:-}" ;;
    sonic)     echo "${SONIC_RPC_URL:-}" ;;
    *)         echo "" ;;
  esac
}
rpc_pub() {  # keyless public fallback
  case "$1" in
    ethereum)  echo "https://ethereum-rpc.publicnode.com" ;;
    optimism)  echo "https://mainnet.optimism.io" ;;
    base)      echo "https://mainnet.base.org" ;;
    arbitrum)  echo "https://arb1.arbitrum.io/rpc" ;;
    bsc)       echo "https://bsc-rpc.publicnode.com" ;;
    polygon)   echo "https://polygon-bor-rpc.publicnode.com" ;;
    gnosis)    echo "https://rpc.gnosischain.com" ;;
    avalanche) echo "https://api.avax.network/ext/bc/C/rpc" ;;
    celo)      echo "https://forno.celo.org" ;;
    linea)     echo "https://rpc.linea.build" ;;
    scroll)    echo "https://rpc.scroll.io" ;;
    mantle)    echo "https://rpc.mantle.xyz" ;;
    zksync)    echo "https://mainnet.era.zksync.io" ;;
    blast)     echo "https://rpc.blast.io" ;;
    mode)      echo "https://mainnet.mode.network" ;;
    metis)     echo "https://metis-rpc.publicnode.com" ;;
    unichain)  echo "https://mainnet.unichain.org" ;;
    soneium)   echo "https://rpc.soneium.org" ;;
    worldchain) echo "https://worldchain-mainnet.g.alchemy.com/public" ;;
    xlayer)    echo "https://rpc.xlayer.tech" ;;
    opbnb)     echo "https://opbnb-mainnet-rpc.bnbchain.org" ;;
    sonic)     echo "https://rpc.soniclabs.com" ;;
    manta)     echo "https://pacific-rpc.manta.network/http" ;;
    taiko)     echo "https://rpc.mainnet.taiko.xyz" ;;
    polygon-zkevm) echo "https://zkevm-rpc.com" ;;
    ink)       echo "https://rpc-gel.inkonchain.com" ;;
    cronos)    echo "https://evm.cronos.org" ;;
    sei)       echo "https://evm-rpc.sei-apis.com" ;;
    zora)      echo "https://rpc.zora.energy" ;;
    bob)       echo "https://rpc.gobob.xyz" ;;
    flare)     echo "https://flare-api.flare.network/ext/C/rpc" ;;
    ronin)     echo "https://api.roninchain.com/rpc" ;;
    rootstock) echo "https://public-node.rsk.co" ;;
    lisk)      echo "https://rpc.api.lisk.com" ;;
    fantom)    echo "https://rpcapi.fantom.network" ;;
    arbitrum-nova) echo "https://nova.arbitrum.io/rpc" ;;
    fraxtal)   echo "https://rpc.frax.com" ;;
    aurora)    echo "https://mainnet.aurora.dev" ;;
    core)      echo "https://rpc.coredao.org" ;;
    apechain)  echo "https://rpc.apechain.com/http" ;;
    kava)      echo "https://evm.kava.io" ;;
    astar)     echo "https://rpc.astar.network" ;;
    harmony)   echo "https://api.harmony.one" ;;
    oasis)     echo "https://sapphire.oasis.io" ;;
    cyber)     echo "https://rpc.cyber.co" ;;
    kaia)      echo "https://public-en.node.kaia.io" ;;
    metall2)   echo "https://rpc.metall2.com" ;;
    zklink)    echo "https://rpc.zklink.io" ;;
    shape)     echo "https://mainnet.shape.network" ;;
    boba)      echo "https://mainnet.boba.network" ;;
    *)         echo "" ;;
  esac
}

OUT=ci-out/m3r_siblings.json
{
  echo "{"
  echo "  \"target\": \"$M\","
  echo "  \"cleanupERC20_selector\": \"0x$SEL_CLEAN\","
  echo "  \"chains\": {"
  first=1
  for c in $CHAINS; do
    sep=""; [ $first -eq 0 ] && sep=","
    u=""; code=""
    for cand in "$(rpc_for "$c")" "$(rpc_pub "$c")"; do
      [ -z "$cand" ] && continue
      code=$(CT code "$M" --rpc-url "$cand")
      if [ -n "$code" ]; then u="$cand"; break; fi
    done
    if [ -z "$code" ]; then
      printf '%s    "%s": {"deployed": "unknown", "note": "no RPC reachable from CI"}\n' "$sep" "$c"
      first=0; continue
    fi
    if [ "$code" = "0x" ]; then
      printf '%s    "%s": {"deployed": false}\n' "$sep" "$c"
      first=0; continue
    fi
    hash=$(CT keccak "$code")
    nat=$(CT balance "$M" --rpc-url "$u")
    has_clean=$(echo "$code" | grep -c "$SEL_CLEAN")
    has_appr=$(echo "$code" | grep -c "$SEL_APPR")
    has_prm2=$(echo "$code" | grep -c "$SEL_PRM2")
    size=$(( (${#code} - 2) / 2 ))
    printf '%s    "%s": {"deployed": true, "codesize": %s, "codehash": "%s", "native_wei": "%s", "sel_cleanupERC20": %s, "sel_safeApproveIfBelow": %s, "sel_safeApprovePermit2": %s}\n' \
      "$sep" "$c" "$size" "$hash" "$nat" "$has_clean" "$has_appr" "$has_prm2"
    first=0
  done
  echo "  }"
  echo "}"
} > "$OUT"
echo "[ci] wrote $OUT"

# token balances on reachable Blockscout hosts (best effort)
TOK=ci-out/m3r_token_balances.json
{
  echo "{"
  first=1
  for pair in "ethereum|https://eth.blockscout.com" "optimism|https://optimism.blockscout.com" "gnosis|https://gnosis.blockscout.com" "scroll|https://scroll.blockscout.com" "zksync|https://zksync.blockscout.com" "mode|https://explorer.mode.network" "metis|https://andromeda-explorer.metis.io" "unichain|https://unichain.blockscout.com" "soneium|https://soneium.blockscout.com" "celo|https://celo.blockscout.com"; do
    c=${pair%%|*}; h=${pair##*|}
    r=$(curl -sL -m 15 "$h/api/v2/addresses/$M/token-balances" -H 'User-Agent: Mozilla/5.0' 2>/dev/null)
    sep=""; [ $first -eq 0 ] && sep=","
    case "$r" in
      \[*\]) printf '%s  "%s": %s\n' "$sep" "$c" "$r" ;;
      *)     printf '%s  "%s": "unavailable"\n' "$sep" "$c" ;;
    esac
    first=0
  done
  echo "}"
} > "$TOK"
echo "[ci] wrote $TOK"

# live dust drain sanity: read the exact balances the PoC drains
{
  echo "metis_block=$(CT block-number --rpc-url https://metis-rpc.publicnode.com)"
  echo "bsc_block=$(CT block-number --rpc-url "${BSC_RPC_URL:-https://bsc-rpc.publicnode.com}")"
  echo "eth_block=$(CT block-number --rpc-url "${FORK_RPC_URL:-https://ethereum-rpc.publicnode.com}")"
  echo "bsc_wbnb=$(CT call 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c 'balanceOf(address)(uint256)' "$M" --rpc-url "${BSC_RPC_URL:-https://bsc-rpc.publicnode.com}")"
  echo "eth_hex=$(CT call 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39 'balanceOf(address)(uint256)' "$M" --rpc-url "${FORK_RPC_URL:-https://ethereum-rpc.publicnode.com}")"
} > ci-out/live_dust.txt
echo "[ci] wrote ci-out/live_dust.txt"
cat ci-out/live_dust.txt
