#!/usr/bin/env bash
# Read-only eth_call gate map for SyncSwap Vault V1. No transactions are signed or sent.
set -u
R="${RPC:-https://mainnet.era.zksync.io}"
A=0x621425a1Ef6abE91058E9712575dcc4258F8d091
B="${BLOCK:-72542708}"
FRESH=0x1111111111111111111111111111111111111111
USDC=0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4
USDT=0x493257fD37EDB34451f62EDf8D2a0C418852bA4C
WETH=0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91
ZK=0x5A7d6b2F92C77FAD6CA344748E3b1d6d3e2deA9b
OUT=analysis/gates.txt
: > "$OUT"
run() { desc="$1"; shift; printf '\n### %s\n' "$desc" >> "$OUT"; cast call "$@" --block "$B" --rpc-url "$R" >> "$OUT" 2>&1; printf '  -> %s\n' "$(tail -1 "$OUT" | cut -c1-160)"; }

run "withdraw(USDC,attacker,1) from fresh"            "$A" "withdraw(address,address,uint256)" "$USDC" "$FRESH" 1 --from "$FRESH"
run "withdraw(USDT,attacker,185e6) from fresh"        "$A" "withdraw(address,address,uint256)" "$USDT" "$FRESH" 185000000 --from "$FRESH"
run "withdrawETH(attacker,1e18) from fresh"           "$A" "withdrawETH(address,uint256)" "$FRESH" 1000000000000000000 --from "$FRESH"
run "withdrawAlternative(USDC,attacker,1e6,0) fresh"  "$A" "withdrawAlternative(address,address,uint256,uint8)" "$USDC" "$FRESH" 1000000 0 --from "$FRESH"
run "withdrawAlternative(USDC,attacker,1e6,2) fresh"  "$A" "withdrawAlternative(address,address,uint256,uint8)" "$USDC" "$FRESH" 1000000 2 --from "$FRESH"
run "withdrawAlternative(ETH,attacker,1e18,2) fresh"  "$A" "withdrawAlternative(address,address,uint256,uint8)" 0x0000000000000000000000000000000000000000 "$FRESH" 1000000000000000000 2 --from "$FRESH"
run "transfer(USDC,attacker,1e6) from fresh"         "$A" "transfer(address,address,uint256)" "$USDC" "$FRESH" 1000000 --from "$FRESH"
run "transferAndDeposit(USDC,attacker,1e6) fresh"    "$A" "transferAndDeposit(address,address,uint256)" "$USDC" "$FRESH" 1000000 --from "$FRESH"
run "transferAndDeposit(ETH,attacker,1) value=0"     "$A" "transferAndDeposit(address,address,uint256)" 0x0000000000000000000000000000000000000000 "$FRESH" 1 --from "$FRESH"
run "deposit(USDC,attacker) from fresh"              "$A" "deposit(address,address)(uint256)" "$USDC" "$FRESH" --from "$FRESH"
run "deposit(ETH,attacker) value=0"                  "$A" "deposit(address,address)(uint256)" 0x0000000000000000000000000000000000000000 "$FRESH" --from "$FRESH"
run "deposit(wETH,attacker) from fresh"              "$A" "deposit(address,address)(uint256)" "$WETH" "$FRESH" --from "$FRESH"
run "depositETH(attacker) value=1 wei"               "$A" "depositETH(address)(uint256)" "$FRESH" --value 1 --from "$FRESH"
run "flashLoan(freshEOA,USDC,1e6,0x)"                "$A" "flashLoan(address,address,uint256,bytes)" "$FRESH" "$USDC" 1000000 0x --from "$FRESH"
run "flashLoan(vault,USDC,1e6,0x)"                   "$A" "flashLoan(address,address,uint256,bytes)" "$A" "$USDC" 1000000 0x --from "$FRESH"
run "setPaused(true) from fresh"                     "$A" "setPaused(bool)" true --from "$FRESH"
run "setFlashLoanFeePercentage(0) from fresh"        "$A" "setFlashLoanFeePercentage(uint256)" 0 --from "$FRESH"
run "setFlashLoanFeeRecipient(fresh) from fresh"     "$A" "setFlashLoanFeeRecipient(address)" "$FRESH" --from "$FRESH"
run "transferOwnership(fresh) from fresh"            "$A" "transferOwnership(address)" "$FRESH" --from "$FRESH"
run "renounceOwnership() from fresh"                 "$A" "renounceOwnership()" --from "$FRESH"
run "balanceOf(USDC,fresh)"                          "$A" "balanceOf(address,address)(uint256)" "$USDC" "$FRESH"
run "balanceOf(USDC,USDC-token)"                     "$A" "balanceOf(address,address)(uint256)" "$USDC" "$USDC"
run "maxFlashLoan(USDC)"                             "$A" "maxFlashLoan(address)(uint256)" "$USDC"
run "flashFee(USDC,1e6)"                             "$A" "flashFee(address,uint256)(uint256)" "$USDC" 1000000
cat "$OUT"
