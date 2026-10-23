#!/usr/bin/env bash
# saturn-susdat — CI sanity job (READ-ONLY; no transactions). Re-verifies live state at
# the fork block and emits ci-out/saturn-sanity.json. Uses env RPCs only (no secrets embedded).
set -euo pipefail
RPC="${FORK_RPC_URL:-${RPC_URL:-https://ethereum-rpc.publicnode.com}}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/../ci-out"; mkdir -p "$OUT"
J="$OUT/saturn-sanity.json"

VAULT=0xD166337499E176bbC38a1FBd113Ab144e5bd2Df7
QUEUE=0x4Bc9FEC04F0F95e9b42a3EF18F3C96fB57923D2e
USDAT=0x23238f20b894f29041f48D88eE91131C395Aaa71
STRCON=0xECABE1Ff8a9e1dC55899cf58dac8497ecE5Ae84c
STRCMIRROR=0xa2Cf4B9410cEbcDCeb3cFf772aC0219F6D1105C9
STRCMODULE=0x3C0f0b502aa7C2ed85620f7f52B8eFb8049b1ECf
OP_ROLE=0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929
OPERATOR_EOA=0xC35580434261f667d6abBDa9E3dC1DC31e5A1b92

call(){ cast call "$1" "$2" ${3:+"$3"} --rpc-url "$RPC" 2>/dev/null | awk '{print $1}'; }
impl=$(cast storage "$VAULT" 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url "$RPC" | sed 's/^0x000000000000000000000000//')
blk=$(cast block-number --rpc-url "$RPC")
ta=$(call "$VAULT" "totalAssets()(uint256)")
ub=$(call "$VAULT" "usdatBalance()(uint256)")
ts=$(call "$VAULT" "totalSupply()(uint256)")
mv=$(call "$STRCMIRROR" "recognizedValue()(uint256)")
cv=$(call "$STRCMODULE" "recognizedValue()(uint256)")
cva=$(call "$VAULT" "convertToAssets(uint256)(uint256)" 1000000000000000000)
mode=$(call "$VAULT" "marketMode()(uint8)")
paused=$(call "$VAULT" "paused()(bool)")
opHasRole=$(cast call "$VAULT" "hasRole(bytes32,address)(bool)" "$OP_ROLE" "$OPERATOR_EOA" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
qnext=$(call "$QUEUE" "nextTokenId()(uint256)")

cat > "$J" <<EOF
{
  "block": $blk,
  "vault_proxy": "$VAULT",
  "vault_impl": "0x$impl",
  "totalAssets": "$ta",
  "usdatBalance": "$ub",
  "totalSupply": "$ts",
  "strcMirror_recognizedValue": "$mv",
  "strcon_recognizedValue": "$cv",
  "convertToAssets_1e18": "$cva",
  "marketMode": "$mode",
  "paused": "$paused",
  "operatorEoa_has_OPERATOR_ROLE": "$opHasRole",
  "queue_nextTokenId": "$qnext",
  "decomposition_ok": $([ "$ta" = "$(python3 -c "print($ub+$mv+$cv)")" ] && echo true || echo false)
}
EOF
echo "--- saturn-susdat CI sanity @ block $blk ---"
cat "$J"
# fail the job if the deployed impl is not the audited v2 impl
[ "0x$impl" = "0x2b7074cf6681382b70e239063931ebe83c0f4e0a" ] || { echo "UNEXPECTED impl 0x$impl"; exit 1; }
echo "OK: v2 impl confirmed"
