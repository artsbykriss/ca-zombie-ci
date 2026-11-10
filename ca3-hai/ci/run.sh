#!/usr/bin/env bash
# Read-only state snapshot for the HAI governance re-check. Writes ci-out/op_state.json.
# No secrets are printed or written: the RPC URL stays in the env var.
set -uo pipefail
mkdir -p ci-out
R="${OP_RPC_URL:-https://mainnet.optimism.io}"
B=$(cast block-number --rpc-url "$R" 2>/dev/null || echo 0)
TS=$(cast block "$B" --rpc-url "$R" -f timestamp 2>/dev/null || echo 0)

GOV=0xe807f3282f3391d237BA8B9bECb0d8Ea3ba23777
TL=0xd68e7D20008a223dD48A6076AAf5EDd4fe80a899
SAFE=0xDCb421Cc4Cbb7267F3b2cAcAb44Ec18AEbEd6724
KITE=0xf467C7d5a4A9C4687fFc7986aC6aD5A4c81E1404
HAI=0x10398AbC267496E49106B07dd6BE13364D10dC71
OP=0x4200000000000000000000000000000000000042
WETH=0x4200000000000000000000000000000000000006
VELO=0x9560e827aF36c94D2Ac33a39bCE1Fe78631088Db
SE=0x9Ff826860689483181C5FAc9628fd2F70275A700

call() { cast call "$1" "$2" ${3:+$3} --rpc-url "$R" --block "$B" 2>/dev/null | head -1 | awk '{print $1}'; }

cat > ci-out/op_state.json <<JSON
{
  "block": $B,
  "timestamp": $TS,
  "governor": {
    "quorumNumerator": "$(call $GOV 'quorumNumerator()(uint256)')",
    "proposalThreshold": "$(call $GOV 'proposalThreshold()(uint256)')",
    "votingDelay": "$(call $GOV 'votingDelay()(uint256)')",
    "votingPeriod": "$(call $GOV 'votingPeriod()(uint256)')",
    "quorum_at_ts_minus_1": "$(cast call $GOV 'quorum(uint256)(uint256)' $((TS-1)) --rpc-url $R --block $B 2>/dev/null | awk '{print $1}')",
    "lateQuorumVoteExtension": "$(call $GOV 'lateQuorumVoteExtension()(uint48)')"
  },
  "timelock": {
    "minDelay": "$(call $TL 'getMinDelay()(uint256)')",
    "isProposerGov": "$(cast call $TL 'hasRole(bytes32,address)(bool)' 0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1 $GOV --rpc-url $R --block $B 2>/dev/null | awk '{print $1}')"
  },
  "kite": {
    "totalSupply": "$(call $KITE 'totalSupply()(uint256)')",
    "treasuryBalance": "$(cast call $KITE 'balanceOf(address)(uint256)' $SAFE --rpc-url $R --block $B 2>/dev/null | awk '{print $1}')",
    "treasuryVotes": "$(cast call $KITE 'getVotes(address)(uint256)' $SAFE --rpc-url $R --block $B 2>/dev/null | awk '{print $1}')",
    "stakingManagerBalance": "$(cast call $KITE 'balanceOf(address)(uint256)' 0x1250f2326F04ac61Ee5aEd92fEf74BcAC6E6BC90 --rpc-url $R --block $B 2>/dev/null | awk '{print $1}')"
  },
  "treasury": {
    "op": "$(cast call $OP 'balanceOf(address)(uint256)' $SAFE --rpc-url $R --block $B 2>/dev/null | awk '{print $1}')",
    "weth": "$(cast call $WETH 'balanceOf(address)(uint256)' $SAFE --rpc-url $R --block $B 2>/dev/null | awk '{print $1}')",
    "velo": "$(cast call $VELO 'balanceOf(address)(uint256)' $SAFE --rpc-url $R --block $B 2>/dev/null | awk '{print $1}')",
    "safeNonce": "$(call $SAFE 'nonce()(uint256)')",
    "safeThreshold": "$(call $SAFE 'getThreshold()(uint256)')"
  },
  "hai": {
    "totalSupply": "$(call $HAI 'totalSupply()(uint256)')",
    "timelockAuthorizedOnToken": "$(cast call $HAI 'authorizedAccounts(address)(bool)' $TL --rpc-url $R --block $B 2>/dev/null | awk '{print $1}')",
    "timelockAuthorizedOnSafeEngine": "$(cast call $SE 'authorizedAccounts(address)(bool)' $TL --rpc-url $R --block $B 2>/dev/null | awk '{print $1}')",
    "contractEnabled": "$(call $SE 'contractEnabled()(bool)')"
  },
  "pools": {
    "kite_hai_reserves": "$(cast call 0xf2d3941b6E1cbD3616061E556Eb06986147715d1 'getReserves()(uint256,uint256,uint256)' --rpc-url $R --block $B 2>/dev/null | tr '\n' ' ')",
    "op_kite_reserves": "$(cast call 0xf4638dC488F9C826DC40250515592E678E447238 'getReserves()(uint256,uint256,uint256)' --rpc-url $R --block $B 2>/dev/null | tr '\n' ' ')"
  }
}
JSON

cat ci-out/op_state.json
