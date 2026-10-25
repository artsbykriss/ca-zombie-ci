#!/usr/bin/env bash
# Read-only live-state dump for the Morpho wSPYx/AUSD market (Ethereum). No secrets written.
set -uo pipefail
RPC="${1:-https://ethereum-rpc.publicnode.com}"
MORPHO=0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb
WSPYX=0xc88FcD8B874fDb3256E8B55b3decB8c24EAb4c02
SPYX=0x90A2a4c76b5D8c0bc892A69EA28Aa775a8f2dD48
AUSD=0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a
ORACLE=0x01Fd716a703eD6A54922b1F2C8cc2Ed5a018bAC5
PYTH=0x4305FB66699C3B2702D4d05CF36551390A4c69C6
FEED=0x2817b78438c769357182c04346fddaad1178c82f4048828fe0997c3c64624e14
MID=0xbf0432567b44ef5ce013ffcd7dd756c522252503f7986a406e780715b32c74fc
B=$(cast block-number --rpc-url "$RPC")
echo "block=$B"
echo "blockTs=$(cast block "$B" --field timestamp --rpc-url "$RPC")"
echo "oracle.price=$(cast call $ORACLE 'price()(uint256)' --rpc-url "$RPC")"
echo "oracle.SCALE_FACTOR=$(cast call $ORACLE 'SCALE_FACTOR()(uint256)' --rpc-url "$RPC")"
echo "oracle.PRICE_FEED_MAX_AGE=$(cast call $ORACLE 'PRICE_FEED_MAX_AGE()(uint256)' --rpc-url "$RPC")"
echo "oracle.BASE_VAULT=$(cast call $ORACLE 'BASE_VAULT()(address)' --rpc-url "$RPC")"
echo "oracle.BASE_VAULT_CONVERSION_SAMPLE=$(cast call $ORACLE 'BASE_VAULT_CONVERSION_SAMPLE()(uint256)' --rpc-url "$RPC")"
echo "oracle.QUOTE_VAULT=$(cast call $ORACLE 'QUOTE_VAULT()(address)' --rpc-url "$RPC")"
echo "oracle.pyth=$(cast call $ORACLE 'pyth()(address)' --rpc-url "$RPC")"
echo "wspyx.asset=$(cast call $WSPYX 'asset()(address)' --rpc-url "$RPC")"
echo "wspyx.totalAssets=$(cast call $WSPYX 'totalAssets()(uint256)' --rpc-url "$RPC")"
echo "wspyx.totalSupply=$(cast call $WSPYX 'totalSupply()(uint256)' --rpc-url "$RPC")"
echo "wspyx.convertToAssets_1e6=$(cast call $WSPYX 'convertToAssets(uint256)(uint256)' 1000000 --rpc-url "$RPC")"
echo "wspyx.isPaused=$(cast call $WSPYX 'isPaused()(bool)' --rpc-url "$RPC")"
echo "wspyx.owner=$(cast call $WSPYX 'owner()(address)' --rpc-url "$RPC")"
echo "spyx.balanceOf_wspyx=$(cast call $SPYX 'balanceOf(address)(uint256)' $WSPYX --rpc-url "$RPC")"
echo "ausd.totalSupply=$(cast call $AUSD 'totalSupply()(uint256)' --rpc-url "$RPC")"
echo "morpho.market=$(cast call $MORPHO 'market(bytes32)(uint128,uint128,uint128,uint128,uint128,uint128)' $MID --rpc-url "$RPC" | tr '\n' ' ')"
echo "morpho.params=$(cast call $MORPHO 'idToMarketParams(bytes32)(address,address,address,address,uint256)' $MID --rpc-url "$RPC" | tr '\n' ' ')"
echo "pyth.getPriceUnsafe=$(cast call $PYTH 'getPriceUnsafe(bytes32)((int64,uint64,int32,uint64))' $FEED --rpc-url "$RPC" | tr '\n' ' ')"
