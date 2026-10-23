#!/usr/bin/env bash
# Read-only evidence reads for Venus Flux (Instadapp Fluid) on BSC.
# Keyless public RPC only. No transactions are signed or sent.
set -u
R="${BSC_RPC_URL:-https://bsc-rpc.publicnode.com}"
LIQ=0x52Aa899454998Be5b000Ad077a46Bbe360F4e497
LR=0xca13A15de31235A37134B4717021C35A3CF25C60
VR=0xA5C3E16523eeeDDcC34706b0E6bE88b4c6EA95cC
DR=0xAf572EfC84d905926F7b05C1B7bE04e4E89542B0
WSTUSR=0x4254813524695def4163A169e901f3d7a1a55429
USDT=0x55d398326f99059fF775485246999027B3197955
USDC=0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d
SYRUP=0x8E9d4cEa39299323FE8eda678cAD449718556c4e

echo "block:"; cast block-number --rpc-url "$R"
echo "--- listedTokens()"; cast call $LR "listedTokens()(address[])" --rpc-url "$R"
echo "--- total vaults"; cast call $VR "getTotalVaults()(uint256)" --rpc-url "$R"
echo "--- wstUSR/USDT vault oracle (GenericOracle_WSTUSR_USDT) getExchangeRate"
cast call 0xc0767760627E88Eef7f653bce49e660a351E95eD "getExchangeRate()(uint256)" --rpc-url "$R"
echo "--- underlying CappedRateChainlink_WSTUSR getExchangeRate"
cast call 0x4c38911E3797Ba0ebD9a1D40673CA1A993445EDF "getExchangeRate()(uint256)" --rpc-url "$R"
echo "--- CappedRateChainlink_WSTUSR configData (liquidity,minUpdateDiff,minHeartbeat,lastUpdate,rateSource,invert,avoidCol,avoidDebt,maxAPR%,maxDownCol,maxDownDebt,maxDebtUpCap)"
cast call 0x4c38911E3797Ba0ebD9a1D40673CA1A993445EDF "configData()(address,uint16,uint24,uint40,address,bool,bool,bool,uint256,uint24,uint24,uint256)" --rpc-url "$R"
echo "--- rateSource 0xA40a0dC2 latestAnswer / decimals"
cast call 0xA40a0dC23D3A821fF5Ea9E23080B74DAC031158d "latestAnswer()(int256)" --rpc-url "$R"
echo "--- USDT/USDC/BNB/ETH/BTCB/wBETH/syrupUSDT/asBNB oracles (should match market)"
for a in 0x0F53c623C9A165d13488e1E33BDA900375De0289 0x25FcD7Ec94fEce13741Dfbd41Cc2842F3066cA89 0x9B932588777EA47710dC049C129D7b04C865B128 0x9024ac8cc0bB3F6997a533Ce1Cea5046bF88558a 0x0c7F7f621CE0C55B853ebb08c29b980856BA15F6 0x91D16960dA45f8B1E920c029576EDA327866B02c; do
  printf "  %s  " $a; cast call $a "getExchangeRate()(uint256)" --rpc-url "$R"
done
echo "--- wstUSR/USDT DEX configs (isSmartCol,isSmartDebt,fee,rev,up,low,upShift,lowShift,shiftTime,centerPrice,hook,maxCenter,minCenter,util0,util1,maxSupplyShares,maxBorrowShares)"
cast call $DR "getDexConfigs(address)((bool,bool,uint256,uint256,uint256,uint256,uint256,uint256,uint256,address,address,uint256,uint256,uint256,uint256,uint256,uint256))" 0x3C0441B42195F4aD6aa9a0978E06096ea616CDa7 --rpc-url "$R"
echo "--- wstUSR/USDT DEX prices (revert-with-data)"
cast call 0x3C0441B42195F4aD6aa9a0978E06096ea616CDa7 "getPricesAndExchangePrices()(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)" --rpc-url "$R" || true
echo "--- wstUSR/USDT DEX variables2 (bit255 = swap paused)"
cast call $DR "getDexVariables2Raw(address)(uint256)" 0x3C0441B42195F4aD6aa9a0978E06096ea616CDa7 --rpc-url "$R"
echo "--- wstUSR/USDT DEX supply/borrow shares"
cast call $DR "getTotalSupplySharesRaw(address)(uint256)" 0x3C0441B42195F4aD6aa9a0978E06096ea616CDa7 --rpc-url "$R"
cast call $DR "getTotalBorrowSharesRaw(address)(uint256)" 0x3C0441B42195F4aD6aa9a0978E06096ea616CDa7 --rpc-url "$R"
echo "--- global Liquidity-layer stablecoin availability (via USDT/USDC DEX swap-limits view)"
echo "    USDT supply/borrow/borrowable and USDC supply/borrow/borrowable are the first 8 fields:"
cast call $DR "getDexSwapLimitsAndAvailability(address)((uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,(bool,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256),(bool,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256),(bool,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256),(bool,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256),(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,(uint256,(address,uint256,uint256,uint256,uint256),(address,uint256,uint256,uint256,uint256,uint256,uint256))),(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,(uint256,(address,uint256,uint256,uint256,uint256),(address,uint256,uint256,uint256,uint256,uint256,uint256)))))" 0x0B1a513ee24972DAEf112bC777a5610d4325C9e7 --rpc-url "$R" | head -c 400
echo
echo "--- existing wstUSR positions (NFT owner + col + debt) on T1 wstUSR/USDT vault"
cast call 0xaA21a86030EAa16546A759d2d10fd3bF9D053Bc7 "getVaultPositionsForNftIds(uint256[],address)((uint256,address,uint256,uint256)[])" "[38,131,274,354,393,395,430,606]" 0x3996464c0fCCa8183e13ea5E5e74375e2c8744Dd --rpc-url "$R"
