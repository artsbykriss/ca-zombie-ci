#!/usr/bin/env bash
# Plasma USD Vault — live state capture (read-only, public RPCs only, no secrets).
set -uo pipefail
mkdir -p ci-out
P="${PLASMA_RPC_URL:-https://rpc.plasma.to}"
E="${FORK_RPC_URL:-${RPC_URL:-https://ethereum-rpc.publicnode.com}}"
V=0xd1074E0AE85610dDBA0147e29eBe0D8E5873a000
T=0x4E7d2186eB8B75fBDcA867761636637E05BaeF1E
A=0x737f2522d09E58a3Ea9dcCFDB127dD0dF5eB3F18
AU=0xb381DE863dadFEA44738E7179f0d1Fc73b59e278
USDT0=0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb
AT=0x5D72a9d9A9510Cd8cBdBA12aC62593A58930a948
USDT=0xdAC17F958D2ee523a2206206994597C13D831ec7
USDC=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
USDS=0xdC035D45d973E3EC169d2276DDab16f1e407384F
DAI=0x6B175474E89094C44Da98b954EedeAC495271d0F
ATT=0x1111111111111111111111111111111111111111

export PB=$(cast block-number --rpc-url "$P")
export EB=$(cast block-number --rpc-url "$E")
export RATE=$(cast call "$A" 'getRate()(uint256)' --rpc-url "$P")
export PSUP=$(cast call "$V" 'totalSupply()(uint256)' --rpc-url "$P")
export ATB=$(cast call "$AT" 'balanceOf(address)(uint256)' "$V" --rpc-url "$P")
export IDLE=$(cast call "$USDT0" 'balanceOf(address)(uint256)' "$V" --rpc-url "$P")
export ESUP=$(cast call "$V" 'totalSupply()(uint256)' --rpc-url "$E")
export EUSDT=$(cast call "$USDT" 'balanceOf(address)(uint256)' "$V" --rpc-url "$E")
export EUSDC=$(cast call "$USDC" 'balanceOf(address)(uint256)' "$V" --rpc-url "$E")
export EUSDS=$(cast call "$USDS" 'balanceOf(address)(uint256)' "$V" --rpc-url "$E")
export EDAI=$(cast call "$DAI" 'balanceOf(address)(uint256)' "$V" --rpc-url "$E")
export RATEQ=$(cast call "$A" 'getRateInQuoteSafe(address)(uint256)' "$USDT0" --rpc-url "$P")
BW=$(cast sig 'bulkWithdraw(address,uint256,uint256,address)')
export CAN_BW=$(cast call "$AU" 'canCall(address,address,bytes4)(bool)' "$ATT" "$T" "$BW" --rpc-url "$P")
export BW_RES=$(cast call "$T" 'bulkWithdraw(address,uint256,uint256,address)' "$USDT0" 1000000 0 "$ATT" --from "$ATT" --rpc-url "$P" 2>&1 | head -1)
export DEP_RES=$(cast call "$T" 'deposit(address,uint256,uint256)' "$USDT0" 1000000 0 --from "$ATT" --rpc-url "$P" 2>&1 | head -1)
export LZ=$(cast call "$T" 'idToChains(uint32)((bool,bool,uint128))' 30101 --rpc-url "$P" 2>&1 | head -1)

python3 ci/compute.py | tee ci-out/state.json
