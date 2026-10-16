#!/usr/bin/env bash
RPC=${RPC:-https://ethereum-rpc.publicnode.com}
MCT=0x4eD90999f558Fdc28606b7F7f9AFc7044befb803
NARAUSD=0x5C6263904CCFD3Bcf1aAa6e7063dDd29743b3Bb7
NARAUSDPLUS=0x1aa23CDFC941f6b54251C72012A9Bfa4bF5394D6
BV=0x15e2579B1F0cBe973889a76826D3a2313b6509c6
SAFE=0xaB05c0DB9D26e96A9dcEDCAFCA23341316F6fe6F
SILO1=0x69e0e02b31B5623c6db029b531d4D55837098326
SILO2=0x12E4915C52E2d02e1c5477582577727E6fA35d13
USDC=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
USDT=0xdAC17F958D2ee523a2206206994597C13D831ec7
SUSDS=0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD
MGLOBAL=0x7433806912Eae67919e66aea853d46Fa0aef98A8
echo "block=$(cast block-number --rpc-url $RPC)"
echo "== MCT booked collateral =="
cast call $MCT 'collateralBalance(address)(uint256)' $USDC --rpc-url $RPC
cast call $MCT 'collateralBalance(address)(uint256)' $USDT --rpc-url $RPC
echo "== actual token balances =="
for t in USDC USDT SUSDS MGLOBAL BV; do
  a=$(eval echo \$$t)
  echo "$t: MCT=$(cast call $a 'balanceOf(address)(uint256)' $MCT --rpc-url $RPC) NaraUSD=$(cast call $a 'balanceOf(address)(uint256)' $NARAUSD --rpc-url $RPC)"
  echo "$t: Safe=$(cast call $a 'balanceOf(address)(uint256)' $SAFE --rpc-url $RPC) NaraUSDPlus=$(cast call $a 'balanceOf(address)(uint256)' $NARAUSDPLUS --rpc-url $RPC)"
done
echo "== silos =="
echo "SILO1 vault=$(cast call $SILO1 'vault()(address)' --rpc-url $RPC) naraUsd=$(cast call $SILO1 'naraUsd()(address)' --rpc-url $RPC) owner=$(cast call $SILO1 'owner()(address)' --rpc-url $RPC)"
echo "SILO1 naraUsd bal=$(cast call $NARAUSD 'balanceOf(address)(uint256)' $SILO1 --rpc-url $RPC)"
echo "SILO2 vault=$(cast call $SILO2 'vault()(address)' --rpc-url $RPC) owner=$(cast call $SILO2 'owner()(address)' --rpc-url $RPC)"
echo "SILO2 shares bal=$(cast call $NARAUSDPLUS 'balanceOf(address)(uint256)' $SILO2 --rpc-url $RPC)"
echo "== keyring =="
cast call $NARAUSD 'keyringPolicyId()(uint256)' --rpc-url $RPC
KRY=0xb0B5E2176E10B12d70e60E3a68738298A7DFe666
PID=$(cast call $NARAUSD 'keyringPolicyId()(uint256)' --rpc-url $RPC)
echo "checkCredential(policyId, vitalik)=$(cast call $KRY 'checkCredential(uint256,address)(bool)' $PID 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045 --rpc-url $RPC)"
echo "checkCredential(policyId, fresh)=$(cast call $KRY 'checkCredential(uint256,address)(bool)' $PID 0x1111111111111111111111111111111111111112 --rpc-url $RPC)"
echo "hasValidCredentials(fresh)=$(cast call $NARAUSD 'hasValidCredentials(address)(bool)' 0x1111111111111111111111111111111111111112 --rpc-url $RPC)"
echo "== fees =="
cast call $NARAUSD 'minMintFeeAmount()(uint256)' --rpc-url $RPC
cast call $NARAUSD 'minRedeemFeeAmount()(uint256)' --rpc-url $RPC
echo "== NaraUSDPlus extra =="
cast call $NARAUSDPLUS 'vestingAmount()(uint256)' --rpc-url $RPC
cast call $NARAUSDPLUS 'vestingPeriod()(uint256)' --rpc-url $RPC
cast call $NARAUSDPLUS 'convertToAssets(uint256)(uint256)' 1000000000000000000 --rpc-url $RPC
echo "== BV holder check =="
echo "BV totalSupply=$(cast call $BV 'totalSupply()(uint256)' --rpc-url $RPC)"
echo "== Safe code size =="
cast code $SAFE --rpc-url $RPC | wc -c
