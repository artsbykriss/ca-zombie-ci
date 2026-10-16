#!/usr/bin/env bash
# Z3-H17 fresh-tvl-cluster — CI live-state snapshot (keyless public RPCs only; no secrets).
# Writes ci-out/live_state.json + ci-out/live_state.txt. Never fails the job on an RPC error.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
OUT=ci-out/live_state.json
TXT=ci-out/live_state.txt
: > "$TXT"

RHO=${RHO_RPC:-https://rpc.mainnet.chain.robinhood.com}
ARC=${ARC_RPC:-https://rpc.mainnet.arc.io}
RISE=${RISE_RPC:-https://rpc.risechain.com}
BSC=${BSC_RPC:-https://bsc-rpc.publicnode.com}
ETH=${FORK_RPC_URL:-https://ethereum-rpc.publicnode.com}

echo "{" > "$OUT"
first=1
emit() { # emit <key> <value-json-or-null>
  if [ $first -eq 0 ]; then echo "," >> "$OUT"; fi
  first=0
  printf '  "%s": %s' "$1" "$2" >> "$OUT"
  printf '%s = %s\n' "$1" "$2" >> "$TXT"
}
rd() { # rd <rpc> <to> <sig> [args...]
  local rpc="$1" to="$2"; shift 2
  cast call "$to" "$@" --rpc-url "$rpc" 2>/dev/null | awk '{print $1}'
}
num() { # num <value> -> raw int string or null
  case "$1" in ''|*[!0-9]*) echo null;; *) echo "$1";; esac
}
q() { # q <value> -> quoted string or null
  case "$1" in ''|*[!0-9a-zA-Zx]*) echo null;; *) echo "\"$1\"";; esac
}

emit block_ethereum "$(num "$(cast block-number --rpc-url "$ETH" 2>/dev/null)")"
emit block_robinhood "$(num "$(cast block-number --rpc-url "$RHO" 2>/dev/null)")"
emit block_arc "$(num "$(cast block-number --rpc-url "$ARC" 2>/dev/null)")"
emit block_rise "$(num "$(cast block-number --rpc-url "$RISE" 2>/dev/null)")"
emit block_bsc "$(num "$(cast block-number --rpc-url "$BSC" 2>/dev/null)")"

# --- Fang ---
emit fang_fangRedeem_usdg_balance "$(num "$(rd "$RHO" 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168 'balanceOf(address)(uint256)' 0x6EF1e61E39195fA53189A9A880A89eF1D06E6F47)")"
emit fang_poolEndTime "$(num "$(rd "$RHO" 0xC01B68919Cd0297B1bf43E4942880E98682D3bbF 'poolEndTime()(uint256)')")"
emit fang_farm_owner "$(q "$(rd "$RHO" 0xC01B68919Cd0297B1bf43E4942880E98682D3bbF 'owner()(address)')")"

# --- NaraUSD ---
emit narausd_mct_supply "$(num "$(rd "$ETH" 0x4eD90999f558Fdc28606b7F7f9AFc7044befb803 'totalSupply()(uint256)')")"
emit narausd_usdc_booked "$(num "$(rd "$ETH" 0x4eD90999f558Fdc28606b7F7f9AFc7044befb803 'collateralBalance(address)(uint256)' 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)")"
emit narausd_usdt_booked "$(num "$(rd "$ETH" 0x4eD90999f558Fdc28606b7F7f9AFc7044befb803 'collateralBalance(address)(uint256)' 0xdAC17F958D2ee523a2206206994597C13D831ec7)")"

# --- SUBFROST ---
emit subfrost_totalAssets0 "$(num "$(rd "$ETH" 0x95779e7e1c943042255b8a78273fe6de4823cf06 'totalAssets(uint8)(uint256)' 0)")"
emit subfrost_totalAssets1 "$(num "$(rd "$ETH" 0x95779e7e1c943042255b8a78273fe6de4823cf06 'totalAssets(uint8)(uint256)' 1)")"
emit subfrost_defaultPublicKey "$(q "$(rd "$ETH" 0x95779e7e1c943042255b8a78273fe6de4823cf06 'defaultPublicKey()(bytes32)')")"

# --- up v3 ---
emit upv3_allPools "$(num "$(rd "$RHO" 0x1ac9dB4a2608ba45D6127B1737949b51Bb54B7F3 'allPoolsLength()(uint256)')")"
emit upv3_capMode "$(num "$(rd "$RHO" 0x7F749fDD351C1Ceed82d76d7699CB631Eb8332a7 'capMode()(uint8)')")"
emit upv3_pendingCapMode "$(num "$(rd "$RHO" 0x7F749fDD351C1Ceed82d76d7699CB631Eb8332a7 'pendingCapMode()(uint8)')")"

# --- Aero Lite ---
emit aerolite_allPools "$(num "$(rd "$ARC" 0xb89Df768aF2CFE637ceB352c587Fe8edAf491d03 'allPoolsLength()(uint256)')")"
emit aerolite_voter "$(q "$(rd "$ARC" 0xb89Df768aF2CFE637ceB352c587Fe8edAf491d03 'voter()(address)')")"

# --- Icarus CL ---
emit icarus_allPools "$(num "$(rd "$RISE" 0x6f7DA11c13Ba09A153dA06d376044e5859Db607B 'allPoolsLength()(uint256)')")"
emit icarus_owner "$(q "$(rd "$RISE" 0x6f7DA11c13Ba09A153dA06d376044e5859Db607B 'owner()(address)')")"

# --- HertzFlow ---
emit hertz_hfusd1_bank_bal "$(num "$(rd "$BSC" 0x8d0D000Ee44948FC98c9B98A4FA4921476f08B0d 'balanceOf(address)(uint256)' 0xAB96931f9d151bE6Ff313449a926390cA292db62)")"
emit hertz_hfusd1_supply "$(num "$(rd "$BSC" 0x026C39Ab4B07f4C8C62b5824F0F9D7BE5087405a 'totalSupply()(uint256)')")"

# --- Longbow ---
emit longbow_morpho_usdg "$(num "$(rd "$RHO" 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168 'balanceOf(address)(uint256)' 0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010)")"

# --- Meridian ---
emit meridian_merusd_supply "$(num "$(rd "$RHO" 0xad221259d4a1f2d7376dc1012c561bc86640f009 'totalSupply()(uint256)')")"
emit meridian_usde_backing "$(num "$(rd "$RHO" 0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34 'balanceOf(address)(uint256)' 0xad221259d4a1f2d7376dc1012c561bc86640f009)")"

# --- Scorch (Solana) ---
emit scorch_note "\"see analysis/scorch/raw/** (Solana; no EVM)\""

echo "" >> "$OUT"
echo "}" >> "$OUT"
cat "$OUT"
