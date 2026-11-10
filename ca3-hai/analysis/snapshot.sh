#!/usr/bin/env bash
set -uo pipefail
R=https://optimism-rpc.publicnode.com
B=$(cast block-number --rpc-url $R); TS=$(cast block $B --rpc-url $R -f timestamp)
GOV=0xe807f3282f3391d237BA8B9bECb0d8Ea3ba23777
TL=0xd68e7D20008a223dD48A6076AAf5EDd4fe80a899
SAFE=0xDCb421Cc4Cbb7267F3b2cAcAb44Ec18AEbEd6724
KITE=0xf467C7d5a4A9C4687fFc7986aC6aD5A4c81E1404
HAI=0x10398AbC267496E49106B07dd6BE13364D10dC71
SE=0x9Ff826860689483181C5FAc9628fd2F70275A700
c() { cast call "$1" "$2" ${3:-} --rpc-url $R --block $B 2>/dev/null | head -1 | awk '{print $1}'; }
cat > live_state.json <<JSON
{
 "chain":"optimism","chainId":10,"block":$B,"timestamp":$TS,
 "governor":{"address":"$GOV","name":"HaiGovernor","quorumNumerator":$(c $GOV 'quorumNumerator()(uint256)'),
   "quorum_at_ts_minus_1":"$(cast call $GOV 'quorum(uint256)(uint256)' $((TS-1)) --rpc-url $R --block $B 2>/dev/null | awk '{print $1}')",
   "proposalThreshold":$(c $GOV 'proposalThreshold()(uint256)'),"votingDelay":$(c $GOV 'votingDelay()(uint256)'),
   "votingPeriod":$(c $GOV 'votingPeriod()(uint256)'),"lateQuorumVoteExtension":"$(c $GOV 'lateQuorumVoteExtension()(uint48)')",
   "guardian":"none (guardian() reverts)","clock":"timestamp"},
 "timelock":{"address":"$TL","minDelay":$(c $TL 'getMinDelay()(uint256)'),
   "roles":{"PROPOSER_GOV":"$(cast call $TL 'hasRole(bytes32,address)(bool)' 0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1 $GOV --rpc-url $R --block $B 2>/dev/null|awk '{print $1}')",
             "EXECUTOR_GOV":"$(cast call $TL 'hasRole(bytes32,address)(bool)' 0xd8aa0f3194971a2a116679f7c2090f6939c8d4e01a2a8d7e41d55e5351469e63 $GOV --rpc-url $R --block $B 2>/dev/null|awk '{print $1}')",
             "CANCELLER_GOV":"$(cast call $TL 'hasRole(bytes32,address)(bool)' 0xfd643c72710c63c0180259aba6b2d05451e3591a24e58b62239378085726f783 $GOV --rpc-url $R --block $B 2>/dev/null|awk '{print $1}')",
             "TIMELOCK_ADMIN_GOV":"$(cast call $TL 'hasRole(bytes32,address)(bool)' 0x5f58e3a2316349923ce3780f8d587db2d72378aed66a8261c916544fa6846ca5 $GOV --rpc-url $R --block $B 2>/dev/null|awk '{print $1}')"}},
 "kite":{"address":"$KITE","totalSupply":"$(c $KITE 'totalSupply()(uint256)')","paused":$(c $KITE 'paused()(bool)'),
   "treasuryBalance":"$(cast call $KITE 'balanceOf(address)(uint256)' $SAFE --rpc-url $R --block $B 2>/dev/null|awk '{print $1}')",
   "treasuryDelegates":"$(cast call $KITE 'delegates(address)(address)' $SAFE --rpc-url $R --block $B 2>/dev/null|awk '{print $1}')",
   "treasuryVotes":"$(cast call $KITE 'getVotes(address)(uint256)' $SAFE --rpc-url $R --block $B 2>/dev/null|awk '{print $1}')",
   "stakingManager":"0x1250f2326F04ac61Ee5aEd92fEf74BcAC6E6BC90",
   "stakingManagerBalance":"$(cast call $KITE 'balanceOf(address)(uint256)' 0x1250f2326F04ac61Ee5aEd92fEf74BcAC6E6BC90 --rpc-url $R --block $B 2>/dev/null|awk '{print $1}')",
   "timelockMintAuthority":"$(cast call $KITE 'authorizedAccounts(address)(bool)' $TL --rpc-url $R --block $B 2>/dev/null|awk '{print $1}')"},
 "treasurySafe":{"address":"$SAFE","threshold":$(c $SAFE 'getThreshold()(uint256)'),"nonce":$(c $SAFE 'nonce()(uint256)'),
   "owners":"[0xd68e7D20008a223dD48A6076AAf5EDd4fe80a899]",
   "op":"$(cast call 0x4200000000000000000000000000000000000042 'balanceOf(address)(uint256)' $SAFE --rpc-url $R --block $B 2>/dev/null|awk '{print $1}')",
   "weth":"$(cast call 0x4200000000000000000000000000000000000006 'balanceOf(address)(uint256)' $SAFE --rpc-url $R --block $B 2>/dev/null|awk '{print $1}')",
   "velo":"$(cast call 0x9560e827aF36c94D2Ac33a39bCE1Fe78631088Db 'balanceOf(address)(uint256)' $SAFE --rpc-url $R --block $B 2>/dev/null|awk '{print $1}')"},
 "hai":{"token":"$HAI","totalSupply":"$(c $HAI 'totalSupply()(uint256)')","timelockAuthorizedOnToken":"$(cast call $HAI 'authorizedAccounts(address)(bool)' $TL --rpc-url $R --block $B 2>/dev/null|awk '{print $1}')",
   "safeEngine":"$SE","contractEnabled":"$(c $SE 'contractEnabled()(bool)')","timelockAuthorizedOnSafeEngine":"$(cast call $SE 'authorizedAccounts(address)(bool)' $TL --rpc-url $R --block $B 2>/dev/null|awk '{print $1}')"}
}
JSON
cat live_state.json
