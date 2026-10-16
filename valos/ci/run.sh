#!/usr/bin/env bash
# Valos Z3-H14 — CI live-state re-verification (read-only; public keyless RPC only; no secrets).
# Writes ci-out/live_state.txt + ci-out/live_state.json (uploaded as artifacts).
set -uo pipefail
mkdir -p ci-out

RPC="${MONAD_RPC_URL:-https://rpc.monad.xyz}"
V=0x8d3F9f9Eb2f5E8B48EFBB4074440D1E2A34Bc365
S=0x8dCE15fc6a98484C995Fc702cBfBdA14A30454af
A=0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a

BLK=$(cast block-number --rpc-url "$RPC" 2>/dev/null || echo "?")
OUT=ci-out/live_state.txt
: > "$OUT"
echo "rpc=$RPC" | tee -a "$OUT"
echo "block=$BLK" | tee -a "$OUT"

call() { # label, to, sig, [args...]
  local label="$1" to="$2" sig="$3"
  shift 3
  printf '%s=%s\n' "$label" "$(cast call "$to" "$sig" "$@" --rpc-url "$RPC" 2>&1 | head -c 400)"
}

{
  call vault_permissionLevel      "$V" "permissionLevel()(uint8)"
  call vault_precision            "$V" "precision()(uint256)"
  call vault_totalAssets          "$V" "totalAssets()(uint256)"
  call vault_totalSupply          "$V" "totalSupply()(uint256)"
  call vault_sharePrice           "$V" "sharePrice()(uint256)"
  call vault_totalQueuedShares    "$V" "totalQueuedShares()(uint256)"
  call vault_reservedLiquidity    "$V" "reservedLiquidity()(uint256)"
  call vault_queue                "$V" "queue()(uint128,uint128)"
  call vault_transferableShares   "$V" "transferableShares()(bool)"
  call vault_allowed_fresh        "$V" "allowed(address)(bool)" 0x00000000000000000000000000000000000F00D1
  call vault_allowed_euler        "$V" "allowed(address)(bool)" 0xd8ec5b4917fef9058545e7d1dc2ac17f1d26305d
  call vault_allowed_treasury     "$V" "allowed(address)(bool)" 0x4B07AaA370189E5603DF56C84f59c5A59181BFB1
  call vault_bal_treasury         "$V" "balanceOf(address)(uint256)" 0x4B07AaA370189E5603DF56C84f59c5A59181BFB1
  call strategy_loanState         "$S" "loanState()(uint8)"
  call strategy_paused            "$S" "paused()(bool)"
  call strategy_scaleFactor       "$S" "scaleFactor()(uint256)"
  call strategy_netPrincipal      "$S" "netPrincipal()(uint256)"
  call strategy_borrower          "$S" "borrower()(address)"
  call strategy_manager           "$S" "investmentManager()(address)"
  call strategy_dvnPublisher      "$S" "dvnPublisher()(address)"
  call strategy_safetyModule      "$S" "safetyModule()(address)"
  call strategy_securityAdminEn   "$S" "securityAdminEnabled()(bool)"
  call strategy_operationsAdminEn "$S" "operationsAdminEnabled()(bool)"
  call strategy_maxDeposit        "$S" "maxDeposit(address,address)(uint256)" "$V" 0x00000000000000000000000000000000000F00D1
  call ausd_bal_vault             "$A" "balanceOf(address)(uint256)" "$V"
  call ausd_bal_borrower          "$A" "balanceOf(address)(uint256)" 0xB83986E9F33a6De4624B18DA69cb474F6f94fc7C
} >> "$OUT" 2>&1

python3 - << 'PYEOF' > ci-out/live_state.json 2>/dev/null || true
import json, re
d = {}
for line in open("ci-out/live_state.txt"):
    line = line.strip()
    if "=" in line and not line.startswith("rpc"):
        k, v = line.split("=", 1)
        d[k] = v.strip()
print(json.dumps(d, indent=1))
PYEOF

echo "---- live_state.txt ----"
cat "$OUT"
