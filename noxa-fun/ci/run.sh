#!/usr/bin/env bash
# NOXA Fun — live state capture (read-only, public RPC only, no secrets).
set -uo pipefail
mkdir -p ci-out
R="${RH_RPC_URL:-https://rpc.mainnet.chain.robinhood.com}"
L=0x7F03effbd7ceB22A3f80Dd468f67eF27826acD85
F=0xD9eC2db5f3D1b236843925949fe5bd8a3836FCcB
NPM=0x73991a25C818Bf1f1128dEAaB1492D45638DE0D3
TOK=0x77Bd112a399F833F76cad118a74b7Fcc8108Dcc2
PFR=0x9eFdC1A8e6E94f16A228e44f3025E1f346EE0417
ATT=0x1111111111111111111111111111111111111111

BLOCK=$(cast block-number --rpc-url "$R")
OWNER=$(cast call "$L" 'owner()(address)' --rpc-url "$R")
FACT=$(cast call "$L" 'factory()(address)' --rpc-url "$R")
PFS=$(cast call "$L" 'protocolFeeShare()(uint256)' --rpc-url "$R" | sed -E 's/ \[[^]]*\]$//')
PFR=$(cast call "$L" 'protocolFeeRecipient()(address)' --rpc-url "$R")
FC_OK=$(cast call "$L" 'feeCollectors(address)(bool)' "$PFR" --rpc-url "$R")
FC_ATT=$(cast call "$L" 'feeCollectors(address)(bool)' "$ATT" --rpc-url "$R")
NFT_BAL=$(cast call "$NPM" 'balanceOf(address)(uint256)' "$L" --rpc-url "$R" | sed -E 's/ \[[^]]*\]$//')
NFT_OWNER=$(cast call "$NPM" 'ownerOf(uint256)(address)' 212 --rpc-url "$R")
NFT_APPROVED=$(cast call "$NPM" 'getApproved(uint256)(address)' 212 --rpc-url "$R")

COLLECT_ATT=$(cast call "$L" 'collectFees(address)' "$TOK" --from "$ATT" --rpc-url "$R" 2>&1 | head -1)
REDIR_ATT=$(cast call "$L" 'setFeeRedirect(address,address)' "$TOK" "$ATT" --from "$ATT" --rpc-url "$R" 2>&1 | head -1)
LOCK_ATT=$(cast call "$L" 'lockPosition(address)' "$TOK" --from "$ATT" --rpc-url "$R" 2>&1 | head -1)
XFER_ATT=$(cast call "$NPM" 'transferFrom(address,address,uint256)' "$L" "$ATT" 212 --from "$ATT" --rpc-url "$R" 2>&1 | head -1)

cat > ci-out/state.json <<JSON
{
  "chain": "robinhood",
  "chain_id": 4663,
  "block": $BLOCK,
  "locker": "$L",
  "factory": "$FACT",
  "owner": "$OWNER",
  "owner_code_size": $(cast code "$OWNER" --rpc-url "$R" | awk '{n=(length($0)-2)/2; if(n<0)n=0; print n}'),
  "protocolFeeShare": $PFS,
  "protocolFeeRecipient": "$PFR",
  "feeCollectors_protocolFeeRecipient": $FC_OK,
  "feeCollectors_attacker": $FC_ATT,
  "npm_balanceOf_locker": $NFT_BAL,
  "npm_ownerOf_212": "$NFT_OWNER",
  "npm_getApproved_212": "$NFT_APPROVED",
  "collectFees_attacker_result": "$COLLECT_ATT",
  "setFeeRedirect_attacker_result": "$REDIR_ATT",
  "lockPosition_attacker_result": "$LOCK_ATT",
  "transferFrom_attacker_result": "$XFER_ATT"
}
JSON
cat ci-out/state.json
