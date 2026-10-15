#!/bin/bash
# BDEX V3 / RocketSwap-Anubis — evidence dump (keyless public RPCs only).
# Writes JSON snapshots into ci-out/ for the artifact.
set -u
OUT="ci-out"
mkdir -p "$OUT"
ANU="https://rpc.anubispace.org"
BOT="https://rpc.botchain.ai"

call() { # rpc to sig args...
  local rpc="$1" to="$2" sig="$3"; shift 3
  for i in 1 2 3; do
    out=$(cast call "$to" "$sig" "$@" --rpc-url "$rpc" 2>/dev/null) && { echo "$out" | head -1; return; }
    sleep 2
  done
  echo "RPC_FAIL"
}

ANU_BLK=$(cast block-number --rpc-url "$ANU" 2>/dev/null || echo 0)
BOT_BLK=$(cast block-number --rpc-url "$BOT" 2>/dev/null || echo 0)

DAI=0x83fd06F0846d9D90B3016bF670Efe2E0B11cDe14
AUSDT=0xDfb6a28BC6DC51fed17c27C880F2c66cDd040A3e
PAIR=0xF14C0e3Da42Fc36A416E6036dC4c7cA0375B734f
PUB_BRIDGE=0x8932fe7726C1EE743F662f485C3e5a5D1D595F71
PRIV_BRIDGE=0x250BA4E73A365CEfdd170a2b1ff9fc03097D64f3
ISM=0x966b26267AADfC1be995803d09797E523352465D
RESERVE=0x27Cb55eE75E777fF972B74B6E68782D12Bd4ec46
RSWAP_FACTORY=0xaf6F4e641C86A25518509BC840051A8652Af598A

WBOT=0xD5452816194a3784dBa983426cCe7c122F4abd30
BUSDT=0xaBabc7Ddc03e501d190C676BF3d92ef0e6e87a3C
USDT0=0x9841194c1f6f8359d0ff1a98fb2c3a6a17357ce0
V3_FACTORY=0x1C51c173323ec11BB4e3C4fD2314c225Dc4b5419
V3_POOL=0x64F418471a1A7932a190E10da5A8551dB5AbeC05

cat > "$OUT/anubis_state.json" <<EOF
{
  "chain": "anubis",
  "chain_id": 6714,
  "block": $ANU_BLK,
  "rpc": "public-keyless",
  "rocketswap_factory": "$RSWAP_FACTORY",
  "rocketswap_pairs": "$(call "$ANU" $RSWAP_FACTORY 'allPairsLength()(uint256)')",
  "factory_feeTo": "$(call "$ANU" $RSWAP_FACTORY 'feeTo()(address)')",
  "factory_feeToSetter": "$(call "$ANU" $RSWAP_FACTORY 'feeToSetter()(address)')",
  "dai_totalSupply": "$(call "$ANU" $DAI 'totalSupply()(uint256)')",
  "usdt_totalSupply": "$(call "$ANU" $AUSDT 'totalSupply()(uint256)')",
  "dai_usdt_pair_dai": "$(call "$ANU" $DAI 'balanceOf(address)(uint256)' $PAIR)",
  "dai_usdt_pair_usdt": "$(call "$ANU" $AUSDT 'balanceOf(address)(uint256)' $PAIR)",
  "public_bridge_owner": "$(call "$ANU" $PUB_BRIDGE 'owner()(address)')",
  "public_bridge_paused": "$(call "$ANU" $PUB_BRIDGE 'paused()(bool)')",
  "public_bridge_whitelistEnabled": "$(call "$ANU" $PUB_BRIDGE 'whitelistEnabled()(bool)')",
  "private_bridge_owner": "$(call "$ANU" $PRIV_BRIDGE 'owner()(address)')",
  "private_bridge_whitelistEnabled": "$(call "$ANU" $PRIV_BRIDGE 'whitelistEnabled()(bool)')",
  "ism_moduleType": "$(call "$ANU" $ISM 'moduleType()(uint8)')",
  "protocol_reserve_dai": "$(call "$ANU" $DAI 'balanceOf(address)(uint256)' $RESERVE)"
}
EOF

cat > "$OUT/bot_state.json" <<EOF
{
  "chain": "bot",
  "chain_id": 677,
  "block": $BOT_BLK,
  "rpc": "public-keyless",
  "v3_factory": "$V3_FACTORY",
  "v3_factory_owner": "$(call "$BOT" $V3_FACTORY 'owner()(address)')",
  "v3_pool": "$V3_POOL",
  "v3_pool_usdt": "$(call "$BOT" $BUSDT 'balanceOf(address)(uint256)' $V3_POOL)",
  "v3_pool_wbot": "$(call "$BOT" $WBOT 'balanceOf(address)(uint256)' $V3_POOL)",
  "v3_pool_liquidity": "$(call "$BOT" $V3_POOL 'liquidity()(uint128)')",
  "usdt_totalSupply": "$(call "$BOT" $BUSDT 'totalSupply()(uint256)')",
  "usdt0_totalSupply": "$(call "$BOT" $USDT0 'totalSupply()(uint256)')",
  "wbot_totalSupply": "$(call "$BOT" $WBOT 'totalSupply()(uint256)')",
  "v2_factory": "0x117115f3B72C8d1989178089A67D0C26f8EE0AA3",
  "v2_pairs": "$(call "$BOT" 0x117115f3B72C8d1989178089A67D0C26f8EE0AA3 'allPairsLength()(uint256)')"
}
EOF

echo "wrote:"
ls -la "$OUT"
cat "$OUT/anubis_state.json"
cat "$OUT/bot_state.json"
