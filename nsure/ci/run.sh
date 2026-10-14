#!/usr/bin/env bash
# CI-side independent verification of Nsure live state (read-only, no secrets written).
# Writes results to ci-out/ (uploaded as artifacts).
set -uo pipefail
cd "$(dirname "$0")/.."
RPC="${FORK_RPC_URL:-${RPC_URL:-https://ethereum-rpc.publicnode.com}}"
mkdir -p ci-out

BLK=$(cast block-number --rpc-url "$RPC")
{
echo "nsure live-state verification"
echo "block=$BLK"
echo "utc=$(date -u +%FT%TZ)"
echo
echo "== roles =="
for c in 0xB98eD9800fCD2982d26Cf0E4a6B53C96bbeff6A6 0x1a66f065303299d78693f122c800Ab3dEbE9c966 0x80e711b29e46d430ff1553eb2ada670e2a25593c 0xfd0D28539aeD12477dcba1575eB40fca53969440 0x702aff99b08e8891fc70811174701fb7407b4477; do
  OWN=$(cast call "$c" "owner()(address)" --rpc-url "$RPC" 2>/dev/null || echo "n/a")
  OPR=$(cast call "$c" "operator()(address)" --rpc-url "$RPC" 2>/dev/null || echo "n/a")
  SIG=$(cast call "$c" "signer()(address)" --rpc-url "$RPC" 2>/dev/null || echo "n/a")
  echo "$c owner=$OWN operator=$OPR signer=$SIG"
done
echo
echo "== WETH balances =="
for c in 0x1a66f065303299d78693f122c800Ab3dEbE9c966 0x80e711b29e46d430ff1553eb2ada670e2a25593c 0xfd0D28539aeD12477dcba1575eB40fca53969440; do
  echo "$c WETH=$(cast call 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 'balanceOf(address)(uint256)' $c --rpc-url "$RPC")"
done
echo
echo "== NSURE balances =="
for c in 0xB98eD9800fCD2982d26Cf0E4a6B53C96bbeff6A6 0x1a66f065303299d78693f122c800Ab3dEbE9c966 0xfd0D28539aeD12477dcba1575eB40fca53969440 0x200db99fe5c0f39688853d4c4d8651648d995b26 0x20945ca1df56d237fd40036d47e866c7dccd2114; do
  echo "$c NSURE=$(cast call 0x20945ca1df56d237fd40036d47e866c7dccd2114 'balanceOf(address)(uint256)' $c --rpc-url "$RPC")"
done
echo
echo "== nETH backing =="
echo "converter native=$(cast balance 0xa6b658Ce4b1CDb4E7d8f97dFFB549B8688CAFb84 --rpc-url "$RPC")"
echo "nETH totalSupply=$(cast call 0xa6b658Ce4b1CDb4E7d8f97dFFB549B8688CAFb84 'totalSupply()(uint256)' --rpc-url "$RPC")"
echo "converter smartBalance=$(cast call 0xa6b658Ce4b1CDb4E7d8f97dFFB549B8688CAFb84 'smartBalance()(uint256)' --rpc-url "$RPC")"
echo
echo "== CapitalStake pool 0 =="
cast call 0xB98eD9800fCD2982d26Cf0E4a6B53C96bbeff6A6 "poolInfo(uint256)(uint256,address,uint256,uint256,uint256,uint256)" 0 --rpc-url "$RPC"
echo
echo "== NSURE/WETH pair =="
cast call 0xed196f5f01e8c99eF4c6d77B83CCaF629032A8f2 "getReserves()(uint112,uint112,uint32)" --rpc-url "$RPC"
} > ci-out/nsure_state.txt 2>&1

echo "--- ci-out/nsure_state.txt ---"
cat ci-out/nsure_state.txt
