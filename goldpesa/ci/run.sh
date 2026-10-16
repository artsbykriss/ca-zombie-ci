#!/usr/bin/env bash
# GoldPesa Z3-H5 — CI side-job: raw on-chain state dump at the pinned Base block.
# Writes JSON evidence to ci-out/. Uses $BASE_RPC_URL when provided (never printed), public fallback otherwise.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

BLK=52660634
BLK_HEX=$(printf '0x%x' $BLK)

# --- select a working Base RPC (the workflow BASE_RPC_URL secret may point at another chain) ---
probe_base() {
  local url="$1"
  [ -z "$url" ] && return 1
  local cid
  cid=$(curl -s -m 10 -X POST -H 'Content-Type: application/json' \
        --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' "$url" 2>/dev/null) || return 1
  case "$cid" in *'"0x2105"'*) ;; *) return 1;; esac
  # pinned block must be served with state (recent full node / archive), and survive a small burst
  local i st
  for i in 0 1 2 3 4; do
    st=$(curl -s -m 12 -X POST -H 'Content-Type: application/json' \
         --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getStorageAt\",\"params\":[\"0x4519e2b040ff1B64fa03aBe2AeF0BC99D7CcEaA8\",\"0x$i\",\"$BLK_HEX\"],\"id\":1}" "$url" 2>/dev/null) || return 1
    case "$st" in *'"result"'*) ;; *) return 1;; esac
  done
  return 0
}

RPC=""
for u in "${BASE_RPC_URL:-}" "https://base.gateway.tenderly.co" "https://base-mainnet.public.blastapi.io" \
         "https://mainnet.base.org" "https://base-pokt.nodies.app" "https://base.api.onfinality.io/public" \
         "${FORK_RPC_URL:-}"; do
  if probe_base "$u"; then
    RPC="$u"
    echo "selected a working Base RPC for pinned block $BLK"
    if [ -n "${GITHUB_ENV:-}" ]; then echo "BASE_RPC_URL=$u" >> "$GITHUB_ENV"; fi
    break
  fi
done
if [ -z "$RPC" ]; then
  echo "WARNING: no Base RPC served pinned block $BLK; falling back to publicnode (tests may fail)" >&2
  RPC="https://base-rpc.publicnode.com"
fi

HOOK=0x4519e2b040ff1B64fa03aBe2AeF0BC99D7CcEaA8
GPX=0x454F8c3f1FC79a98363DB6104A20AC59A02A3133
USDC=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
POSM=0x7C5f5A4bBd8fD63184577525326123B519429bDc
PM=0x498581fF718922c3f8e6A244956aF099B2652b2b
PERMIT2=0x000000000022D473030F116dDEE9F6B43aC78BA3
TREASURY=0xa76b99311bc399d5fA7AeEd3bed0644eEd652866
POOLID=0xe33d2ac4d30348f62723c6a065c34a071970a2cf3776679fc90b07b9a990dcac

c() { cast call "$@" --rpc-url "$RPC" --block "$BLK"; }

BASE_SLOT=$(cast keccak $(cast abi-encode "f(bytes32,uint256)" $POOLID 6))
LIQ_SLOT=$(python3 -c "print(hex(int('$BASE_SLOT',16)+3))")

{
  echo "{"
  echo "  \"chain\": \"base\","
  echo "  \"block\": $BLK,"
  echo "  \"hook\": \"$HOOK\","
  echo "  \"positionId\": \"$(c $HOOK 'positionId()(uint256)')\","
  echo "  \"lastRebalance\": \"$(c $HOOK 'lastRebalance()(uint256)')\","
  echo "  \"lowerTick\": \"$(c $HOOK 'lowerTick()(int24)')\","
  echo "  \"gpxReserves\": \"$(c $HOOK 'gpxReserves()(uint256)')\","
  echo "  \"liquidityLocked\": \"$(c $HOOK 'liquidityLocked()(bool)')\","
  echo "  \"positionOwner\": \"$(c $POSM 'ownerOf(uint256)(address)' 3106206)\","
  echo "  \"positionLiquidity\": \"$(c $POSM 'getPositionLiquidity(uint256)(uint128)' 3106206)\","
  echo "  \"positionInfo\": \"$(c $POSM 'positionInfo(uint256)(uint256)' 3106206)\","
  echo "  \"poolLiquidity\": \"$(c $PM 'extsload(bytes32)(bytes32)' $LIQ_SLOT)\","
  echo "  \"poolSlot0\": \"$(c $PM 'extsload(bytes32)(bytes32)' $BASE_SLOT)\","
  echo "  \"gpxTotalSupply\": \"$(c $GPX 'totalSupply()(uint256)')\","
  echo "  \"hookGpxBalance\": \"$(c $GPX 'balanceOf(address)(uint256)' $HOOK)\","
  echo "  \"treasuryGpxBalance\": \"$(c $GPX 'balanceOf(address)(uint256)' $TREASURY)\","
  echo "  \"hookUsdcBalance\": \"$(c $USDC 'balanceOf(address)(uint256)' $HOOK)\","
  echo "  \"permit2AllowanceGpxToPosm\": \"$(c $PERMIT2 'allowance(address,address,address)(uint160,uint48,uint48)' $HOOK $GPX $POSM | tr '\n' ' ')\","
  echo "  \"permit2AllowanceUsdcToPosm\": \"$(c $PERMIT2 'allowance(address,address,address)(uint160,uint48,uint48)' $HOOK $USDC $POSM | tr '\n' ' ')\","
  echo "  \"erc20AllowanceGpxToPermit2\": \"$(c $GPX 'allowance(address,address)(uint256)' $HOOK $PERMIT2)\","
  echo "  \"erc20AllowanceUsdcToPermit2\": \"$(c $USDC 'allowance(address,address)(uint256)' $HOOK $PERMIT2)\","
  echo "  \"note\": \"raw reads at pinned block; see analysis/gpx_math.py for derived checkRebalance values\""
  echo "}"
} > ci-out/state.json

python3 -m json.tool ci-out/state.json > ci-out/state.pretty.json 2>/dev/null || true
echo "state dump written to ci-out/state.json"
cat ci-out/state.pretty.json 2>/dev/null | head -30 || cat ci-out/state.json
