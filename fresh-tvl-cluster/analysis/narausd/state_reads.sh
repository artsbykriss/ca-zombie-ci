#!/usr/bin/env bash
# Read-only live state dump (public RPC). No keys.
RPC=${RPC:-https://ethereum-rpc.publicnode.com}
MCT=0x4eD90999f558Fdc28606b7F7f9AFc7044befb803
NARAUSD=0x5C6263904CCFD3Bcf1aAa6e7063dDd29743b3Bb7
NARAUSDPLUS=0x1aa23CDFC941f6b54251C72012A9Bfa4bF5394D6
BV=0x15e2579B1F0cBe973889a76826D3a2313b6509c6
ACCT=0xda594876BA13BCC22065E03fFcFB24A22E5c6724
SAFE=0xaB05c0DB9D26e96A9dcEDCAFCA23341316F6fe6F
echo "block=$(cast block-number --rpc-url $RPC)"
echo "== MCT getSupportedAssets =="
cast call $MCT 'getSupportedAssets()(address[])' --rpc-url $RPC
echo "== MCT totalSupply =="
cast call $MCT 'totalSupply()(uint256)' --rpc-url $RPC
echo "== MCT owner/roles =="
MINTER=$(cast keccak 'MINTER_ROLE')
COLLMGR=$(cast keccak 'COLLATERAL_MANAGER_ROLE')
ADMIN=0x0000000000000000000000000000000000000000000000000000000000000000
echo "MINTER_ROLE=$MINTER COLLATERAL_MANAGER_ROLE=$COLLMGR"
cast call $MCT 'hasRole(bytes32,address)(bool)' $MINTER $NARAUSD --rpc-url $RPC
cast call $MCT 'hasRole(bytes32,address)(bool)' $MINTER $NARAUSDPLUS --rpc-url $RPC
cast call $MCT 'hasRole(bytes32,address)(bool)' $COLLMGR $SAFE --rpc-url $RPC
cast call $MCT 'getRoleMemberCount(bytes32)(uint256)' $MINTER --rpc-url $RPC
cast call $MCT 'getRoleMemberCount(bytes32)(uint256)' $COLLMGR --rpc-url $RPC
echo "== NaraUSD core =="
cast call $NARAUSD 'paused()(bool)' --rpc-url $RPC
cast call $NARAUSD 'mct()(address)' --rpc-url $RPC
cast call $NARAUSD 'redeemSilo()(address)' --rpc-url $RPC
cast call $NARAUSD 'totalSupply()(uint256)' --rpc-url $RPC
cast call $NARAUSD 'maxMintPerBlock()(uint256)' --rpc-url $RPC
cast call $NARAUSD 'maxRedeemPerBlock()(uint256)' --rpc-url $RPC
cast call $NARAUSD 'minMintAmount()(uint256)' --rpc-url $RPC
cast call $NARAUSD 'minRedeemAmount()(uint256)' --rpc-url $RPC
cast call $NARAUSD 'mintFeeBps()(uint16)' --rpc-url $RPC
cast call $NARAUSD 'redeemFeeBps()(uint16)' --rpc-url $RPC
cast call $NARAUSD 'feeTreasury()(address)' --rpc-url $RPC
cast call $NARAUSD 'keyringAddress()(address)' --rpc-url $RPC
echo "== NaraUSDPlus core =="
cast call $NARAUSDPLUS 'asset()(address)' --rpc-url $RPC
cast call $NARAUSDPLUS 'totalAssets()(uint256)' --rpc-url $RPC
cast call $NARAUSDPLUS 'totalSupply()(uint256)' --rpc-url $RPC
cast call $NARAUSDPLUS 'cooldownDuration()(uint24)' --rpc-url $RPC
cast call $NARAUSDPLUS 'silo()(address)' --rpc-url $RPC
cast call $NARAUSDPLUS 'paused()(bool)' --rpc-url $RPC
echo "== BoringVault =="
cast call $BV 'name()(string)' --rpc-url $RPC
cast call $BV 'decimals()(uint8)' --rpc-url $RPC
cast call $BV 'totalSupply()(uint256)' --rpc-url $RPC
cast call $BV 'owner()(address)' --rpc-url $RPC
cast call $BV 'authority()(address)' --rpc-url $RPC
cast call $BV 'hook()(address)' --rpc-url $RPC
echo "== Accountant =="
cast call $ACCT 'owner()(address)' --rpc-url $RPC
cast call $ACCT 'authority()(address)' --rpc-url $RPC
cast call $ACCT 'base()(address)' --rpc-url $RPC
cast call $ACCT 'vault()(address)' --rpc-url $RPC
cast call $ACCT 'decimals()(uint8)' --rpc-url $RPC
cast call $ACCT 'getRate()(uint256)' --rpc-url $RPC
cast call $ACCT 'getRateSafe()(uint256)' --rpc-url $RPC
echo "-- accountantState --"
cast call $ACCT 'accountantState()(address,uint128,uint128,uint96,uint16,uint16,uint64,bool,uint32,uint16)' --rpc-url $RPC
echo "-- lendingInfo --"
cast call $ACCT 'lendingInfo()(uint256,uint256)' --rpc-url $RPC
echo "== Safe =="
cast call $SAFE 'getThreshold()(uint256)' --rpc-url $RPC
cast call $SAFE 'getOwners()(address[])' --rpc-url $RPC
