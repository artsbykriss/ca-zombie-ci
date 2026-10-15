#!/usr/bin/env bash
# Deep-pass state dump for Deepr Finance (IOTA EVM 8822). Read-only cast calls.
set -u
RPC=https://rpc.ankr.com/iota_evm
C=0xee07121d97FDEA35675e02017837a7a43aeDa48F
IMPL=0x4b13e770b29b80d8aea25ab909d2cdb8b935c20d
ORACLE=0x580bef00fa3ae215913cccc62a8d0e74160569e8
SUPRA=0xD02cc7a670047b6b012556A88e275c685d25e0c9
BLK=$(cast block-number --rpc-url $RPC)
echo "{\"block\": $BLK, \"block_hex\": \"$(cast to-hex $BLK)\"}"
echo "--- unitroller ---"
echo "admin=$(cast call $C 'admin()(address)' --rpc-url $RPC)"
echo "pendingAdmin=$(cast call $C 'pendingAdmin()(address)' --rpc-url $RPC)"
echo "comptrollerImplementation=$(cast call $C 'comptrollerImplementation()(address)' --rpc-url $RPC)"
echo "pendingComptrollerImplementation=$(cast call $C 'pendingComptrollerImplementation()(address)' --rpc-url $RPC)"
echo "admin_code_len=$(cast code 0x84456E99Fe3e0C0b06E6e48854f9a6D2c56a7cBD --rpc-url $RPC | wc -c)"
echo "--- comptroller misc ---"
echo "pauseGuardian=$(cast call $C 'pauseGuardian()(address)' --rpc-url $RPC)"
echo "borrowCapGuardian=$(cast call $C 'borrowCapGuardian()(address)' --rpc-url $RPC)"
echo "maxAssets=$(cast call $C 'maxAssets()(uint256)' --rpc-url $RPC)"
echo "compRate=$(cast call $C 'compRate()(uint256)' --rpc-url $RPC)"
echo "compAddress=$(cast call $C 'compAddress()(address)' --rpc-url $RPC)"
echo "linearRateModel=$(cast call $C 'linearRateModel()(address)' --rpc-url $RPC)"
echo "nextEpochTimestamp=$(cast call $C 'nextEpochTimestamp()(uint256)' --rpc-url $RPC)"
echo "teamAddress=$(cast call $C 'teamAddress()(address)' --rpc-url $RPC)"
echo "compTeamSpeed=$(cast call $C 'compTeamSpeed()(uint256)' --rpc-url $RPC)"
echo "lastTeamTimestamp=$(cast call $C 'lastTeamTimestamp()(uint256)' --rpc-url $RPC)"
echo "transferGuardianPaused=$(cast call $C 'transferGuardianPaused()(bool)' --rpc-url $RPC)"
echo "seizeGuardianPaused=$(cast call $C 'seizeGuardianPaused()(bool)' --rpc-url $RPC)"
echo "timestamp=$(cast block latest --field timestamp --rpc-url $RPC)"
echo "--- supra feed ---"
for p in 19 171 89; do
  echo "pair $p: $(cast call $SUPRA 'getSvalue(uint256)((uint256,uint256,uint256,uint256))' $p --rpc-url $RPC | tr '\n' ' ')"
done
echo "--- markets ---"
for m in 0x5041af7b6461717d97ea3422dfc61553c1f8f8b4 0x0f571c5f3c328f57cdddf204d752c7ddb49686d5 0x260817581206317e2665080a2e66854e922269d0 0xf96adbfcd3eb9fd61fada3f2ed70ac47e3e1e045; do
  echo "market $m"
  echo "  name=$(cast call $m 'name()(string)' --rpc-url $RPC) symbol=$(cast call $m 'symbol()(string)' --rpc-url $RPC) decimals=$(cast call $m 'decimals()(uint8)' --rpc-url $RPC)"
  echo "  admin=$(cast call $m 'admin()(address)' --rpc-url $RPC) pendingAdmin=$(cast call $m 'pendingAdmin()(address)' --rpc-url $RPC)"
  echo "  borrowIndex=$(cast call $m 'borrowIndex()(uint256)' --rpc-url $RPC)"
  echo "  accrualBlockTimestamp=$(cast call $m 'accrualBlockTimestamp()(uint256)' --rpc-url $RPC)"
  echo "  initialExchangeRateMantissa=$(cast call $m 'initialExchangeRateMantissa()(uint256)' --rpc-url $RPC)"
  echo "  protocolSeizeShareMantissa=$(cast call $m 'protocolSeizeShareMantissa()(uint256)' --rpc-url $RPC)"
  echo "  totalSupply=$(cast call $m 'totalSupply()(uint256)' --rpc-url $RPC)"
  echo "  totalBorrows=$(cast call $m 'totalBorrows()(uint256)' --rpc-url $RPC)"
  echo "  totalReserves=$(cast call $m 'totalReserves()(uint256)' --rpc-url $RPC)"
  echo "  getCash=$(cast call $m 'getCash()(uint256)' --rpc-url $RPC)"
  echo "  exchangeRateStored=$(cast call $m 'exchangeRateStored()(uint256)' --rpc-url $RPC)"
  echo "  exchangeRateCurrent=$(cast call $m 'exchangeRateCurrent()(uint256)' --rpc-url $RPC)"
  echo "  borrowRatePerSecond=$(cast call $m 'borrowRatePerSecond()(uint256)' --rpc-url $RPC)"
  echo "  supplyRatePerSecond=$(cast call $m 'supplyRatePerSecond()(uint256)' --rpc-url $RPC)"
  echo "  reserveFactorMantissa=$(cast call $m 'reserveFactorMantissa()(uint256)' --rpc-url $RPC)"
  echo "  implementation=$(cast call $m 'implementation()(address)' --rpc-url $RPC)"
  echo "  weightCompSpeeds=$(cast call $C 'weightCompSpeeds(address)(uint256)' $m --rpc-url $RPC)"
  echo "  weightCompBorrowSpeeds=$(cast call $C 'weightCompBorrowSpeeds(address)(uint256)' $m --rpc-url $RPC)"
  echo "  compSpeedsPerSecond=$(cast call $C 'compSpeedsPerSecond(address)(uint256,uint256)' $m --rpc-url $RPC | tr '\n' ' ')"
  echo "  compSupplyState=$(cast call $C 'compSupplyState(address)(uint224,uint256)' $m --rpc-url $RPC | tr '\n' ' ')"
  echo "  compBorrowState=$(cast call $C 'compBorrowState(address)(uint224,uint256)' $m --rpc-url $RPC | tr '\n' ' ')"
  echo "  borrowCaps=$(cast call $C 'borrowCaps(address)(uint256)' $m --rpc-url $RPC)"
  echo "  mintGuardianPaused=$(cast call $C 'mintGuardianPaused(address)(bool)' $m --rpc-url $RPC)"
  echo "  borrowGuardianPaused=$(cast call $C 'borrowGuardianPaused(address)(bool)' $m --rpc-url $RPC)"
  echo "  isDeprecated=$(cast call $C 'isDeprecated(address)(bool)' $m --rpc-url $RPC)"
done
