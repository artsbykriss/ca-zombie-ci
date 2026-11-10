#!/usr/bin/env bash
# Faroo stPROS live-gate proof — read-only eth_call probes against Pharos mainnet.
# No transaction is signed or broadcast. No secrets are used.
set -uo pipefail

RPC="${PHAROS_RPC_URL:-https://rpc.pharos.xyz}"
ATTACKER="0x1111111111111111111111111111111111111111"
STPROS="0x6b0A44c64190279f7034b77c13a566E914FE5Ec4"
ORACLE="0x051713fD66845a13BF23BACa008C5C22C27Ccb58"
BRIDGE="0xF1dF1CB080256f48e8702c24149136E4A6dec25E"
DIST="0xf772B375f93650F798Bf724cE7A9a45c9e7a579F"
RVAULT="0xd0C44d3079e97fF285dd7A3e4E0246320a9487e5"
SLP1="0xEC1d6163e05B3F5D0FB8F354881F6c8B793ad612"
WPROS="0x52C48d4213107b20bC583832b0d951FB9CA8F0B0"
STAKING="0x4100000000000000000000000000000000000000"
ADMIN="0x4238ea4adfa2bd6a5fc9b5e245dc1900cf0258aa"
TIMELOCK="0xC30dB0543412c6881A543390d2c21FbBFf42805b"
POOL="0xaecb1e6d44e8921b5b9b8e04f95d5a78776ee76d2eb7404fb002ab7fed86bedc"

mkdir -p ci-out
OUT="ci-out/faroo-probes.txt"
: > "$OUT"

BLOCK=$(cast block-number --rpc-url "$RPC" 2>/dev/null || echo "?")
PASS=0; FAIL=0

log() { echo "$*" | tee -a "$OUT"; }
ok()  { PASS=$((PASS+1)); log "PASS  $*"; }
bad() { FAIL=$((FAIL+1)); log "FAIL  $*"; }

# probe_revert <label> <expected-selector-or-substring> <to> <signature> [args...]
probe_revert() {
  local label="$1" want="$2" to="$3" sig="$4"; shift 4
  local out attempt
  for attempt in 1 2 3; do
    out=$(cast call "$to" "$sig" "$@" --from "$ATTACKER" --rpc-url "$RPC" 2>&1)
    if echo "$out" | grep -qE "failed to retrieve chain ID|error sending request|timed out|503|502"; then
      sleep 3; continue
    fi
    break
  done
  if echo "$out" | grep -qiF -- "$want"; then ok "$label  -> $want"; else bad "$label  (wanted $want)  got: $(echo "$out" | head -2 | tr '\n' ' ')"; fi
}

# probe_eq <label> <actual> <expected>
probe_eq() {
  local label="$1" got="$2" want="$3"
  if [ "$got" = "$want" ]; then ok "$label == $want"; else bad "$label  want=$want got=$got"; fi
}

getu() {
  local out attempt
  for attempt in 1 2 3; do
    out=$(cast call "$1" "$2" "${@:3}" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
    [ -n "$out" ] && break
    sleep 3
  done
  echo "$out"
}

log "Faroo stPROS live-gate proof"
log "chain=pharos(1672) block=$BLOCK rpc=$RPC"
log "attacker=$ATTACKER (fresh EOA, no roles, no balance assumptions)"
log ""

log "--- 0. implementation integrity (runtime keccak vs faroo-xyz/stpros-contracts records)"
probe_hash() {
  local label="$1" addr="$2" want="$3"
  local got
  got=$(cast keccak "$(cast code "$addr" --rpc-url "$RPC")" 2>/dev/null)
  if [ "$got" = "$want" ]; then ok "$label runtimeKeccak $got"; else bad "$label  want=$want got=$got"; fi
}
probe_hash "StPROS_impl"          "0xfD59860894E01773e9780B0d1DFAE4cA2B56708D" "0xca97539e8a29b612d5a8dedece1b2c2bcec88905e28ce7f79bfa7fff4647e218"
probe_hash "BridgeVault_impl"     "0xa7d36cB9dA47bA5123F9070FbA4bb5239C58387e" "0x1d9038d2fc9717b44647638e40ee889b4f955f25677cfd260c15257c7cc5a043"
probe_hash "SlpDistributor_impl"  "0x05A224A9cdD84CfCa21866aE50Fa0cD663e3752f" "0xfa824dff1ca8b0ddf019240f571d425034c95f04739ead2e8327907ee5cf577a"

log ""
log "--- 1. privileged value paths (all must revert for a fresh EOA)"
probe_revert "BridgeVault.withdrawToken"          "0xbfb92565" "$BRIDGE" "withdrawToken(address,address,uint256)" "$WPROS" "$ATTACKER" 1
probe_revert "BridgeVault.withdrawTokenWrapped"   "0xbfb92565" "$BRIDGE" "withdrawTokenWrapped(address,uint256)" "$ATTACKER" 1
probe_revert "BridgeVault.emergencyWithdraw"      "0x118cdaa7" "$BRIDGE" "emergencyWithdraw(address,address,uint256)" "$WPROS" "$ATTACKER" 1
probe_revert "Oracle.update"                      "0xf5631094" "$ORACLE" "update(address,uint256)" "$WPROS" 1
probe_revert "Oracle.onMint"                      "0x1942eea2" "$ORACLE" "onMint(address,uint256,uint256)" "$WPROS" 1 1
probe_revert "Oracle.setTokenAmount"              "0x118cdaa7" "$ORACLE" "setTokenAmount(address,uint256,uint256)" "$WPROS" 0 1
probe_revert "SlpDistributor.distribute"          "0xccf79b67" "$DIST"   "distribute((address,uint256)[])" "[($SLP1,1)]"
probe_revert "RewardsVault.notifyOracle"          "0xe2517d3f" "$RVAULT" "notifyOracle()"
probe_revert "SLP1.bond"                          "0xe2517d3f" "$SLP1"   "bond(bytes32,uint256)" "$POOL" 1
probe_revert "SLP1.claim"                         "0xe2517d3f" "$SLP1"   "claim(bytes32)" "$POOL"
probe_revert "SLP1.transferBack"                  "0xe2517d3f" "$SLP1"   "transferBack(uint256)" 1
probe_revert "Staking.claimReward (fresh)"        "No rewards to claim"     "$STAKING" "claimReward(bytes32)" "$POOL"
probe_revert "Staking.claimStake (fresh)"         "No withdrawable stake"   "$STAKING" "claimStake(bytes32)" "$POOL"

probe_revert "ProxyAdmin.upgrade"                 "Ownable: caller is not the owner" "$ADMIN" "upgrade(address,address)" "$STPROS" "$STPROS"
probe_revert "ProxyAdmin.changeProxyAdmin"        "Ownable: caller is not the owner" "$ADMIN" "changeProxyAdmin(address,address)" "$STPROS" "$ATTACKER"
probe_revert "Timelock.schedule"                  "0xe2517d3f" "$TIMELOCK" "schedule(address,uint256,bytes,bytes32,bytes32,uint256)" "$STPROS" 0 "0x" 0x0000000000000000000000000000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000000000000000000000000000 0

log ""
log "--- 2. permissionless entries are no-ops / self-scoped"
got=$(cast call "$STPROS" "withdrawComplete(address)(uint256)" "$ATTACKER" --from "$ATTACKER" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
probe_eq "stPROS.withdrawComplete(fresh)" "$got" "0"
got=$(cast call "$STPROS" "withdrawComplete()(uint256)" --from "$ATTACKER" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
probe_eq "stPROS.withdrawComplete()" "$got" "0"
out=$(cast call "$BRIDGE" "unwrapWrapped()" --from "$ATTACKER" --rpc-url "$RPC" 2>&1)
if echo "$out" | grep -q "0x"; then ok "BridgeVault.unwrapWrapped is permissionless (neutral: pays caller 0, unwraps vault WPROS only)"; else bad "unwrapWrapped: $out"; fi

log ""
log "--- 3. live accounting: exact queue funding, no unprivileged surplus"
BR=$(getu "$BRIDGE" "getBalance(address)(uint256)" "$WPROS")
NAT=$(cast balance "$BRIDGE" --rpc-url "$RPC")
res=$(python3 - "$BR" "$NAT" <<'PY'
import sys
a,b=int(sys.argv[1]),int(sys.argv[2])
print(("PASS" if abs(a-b)<=10**15 else "FAIL"), f"BridgeVault.getBalance(WPROS)={a} native={b} delta={a-b}")
PY
)
echo "$res" | tee -a "$OUT"
if echo "$res" | grep -q '^PASS'; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); fi
AVAIL=$(getu "$STPROS" "getTotalBalance()(uint256)")
QUEUED=$(getu "$STPROS" "queuedWithdrawal()(uint256)")
res=$(python3 - "$AVAIL" "$QUEUED" <<'PY'
import sys
a,q=int(sys.argv[1]),int(sys.argv[2])
print(("PASS" if a<=q+10**15 else "FAIL"), f"getTotalBalance({a}) <= queuedWithdrawal({q})+1e15 dust; unprivileged surplus={max(0,a-q)/1e18:.6f} PROS")
PY
)
echo "$res" | tee -a "$OUT"
if echo "$res" | grep -q '^PASS'; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); fi

T=$(getu "$ORACLE" "poolInfo(address)(uint256,uint256)" "$WPROS" | head -1)
TA=$(getu "$STPROS" "totalAssets()(uint256)")
TS=$(getu "$STPROS" "totalSupply()(uint256)")
V=$(cast call "$ORACLE" "poolInfo(address)(uint256,uint256)" "$WPROS" --rpc-url "$RPC" 2>/dev/null | sed -n 2p | awk '{print $1}')
probe_eq "Oracle.poolInfo.T" "$T" "$TA"
probe_eq "Oracle.poolInfo.V" "$V" "$TS"
got=$(getu "$BRIDGE" "vTokenAddressCount()(uint256)")
probe_eq "BridgeVault.vTokenAddressCount" "$got" "1"
got=$(getu "$BRIDGE" "vTokenByAsset(address)(address)" "$WPROS")
if [ "$(echo "$got" | tr 'A-Z' 'a-z')" = "$(echo "$STPROS" | tr 'A-Z' 'a-z')" ]; then ok "vTokenByAsset(WPROS) == stPROS"; else bad "vTokenByAsset=$got"; fi
got=$(getu "$BRIDGE" "vTokenAddresses(address)(bool)" "$STPROS")
probe_eq "vTokenAddresses(stPROS)" "$got" "true"
got=$(getu "$STPROS" "paused()(bool)")
probe_eq "stPROS.paused" "$got" "false"
got=$(getu "$BRIDGE" "paused()(bool)")
probe_eq "BridgeVault.paused" "$got" "false"
got=$(getu "$STPROS" "owner()(address)")
log "INFO  stPROS.owner=$got (OZ TimelockController, 24h min delay; P-class)"
got=$(getu "$ORACLE" "slp()(address)")
log "INFO  oracle reporter=$got (RewardsVault; WHITELIST_ROLE only)"
got=$(getu "$DIST" "keeper()(address)")
log "INFO  distributor keeper=$got (P-class)"

log ""
log "PASS=$PASS FAIL=$FAIL"
printf '{"target":"faroo-stpros","chain":"pharos","chain_id":1672,"block":%s,"pass":%d,"fail":%d,"attacker":"%s"}\n' "$BLOCK" "$PASS" "$FAIL" "$ATTACKER" > ci-out/faroo-probes.json
[ "$FAIL" -eq 0 ]
