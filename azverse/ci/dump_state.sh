#!/usr/bin/env bash
# AZverse live-state dump (keyless; RPC from env, never printed).
# Writes ci-out/live_state.txt
set -u
RPC="${ARB_RPC_URL:-}"
if [ -z "$RPC" ]; then RPC="https://arbitrum-one-rpc.publicnode.com"; fi
OUT="$(dirname "$0")/../ci-out/live_state.txt"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT")

V1=0x91Ba525861c16AA8Cd4D6974E4058cc846f42eBE
V2=0x949556cb8634F9a4a8504665C3d0D9d326c600b2
USDT0=0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9
USDC=0xaf88d065e77c8cC2239327C5EDb3A432268e5831
echo "rpc=arbitrum-public"
echo "block=$(cast block-number --rpc-url "$RPC")"
for V in $V1 $V2; do
  echo "=== vault $V"
  echo "impl=$(cast storage $V 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url "$RPC")"
  echo "admin=$(cast storage $V 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103 --rpc-url "$RPC")"
  echo "paused=$(cast call $V 'paused()(bool)' --rpc-url "$RPC")"
  echo "challenge=$(cast call $V 'pendingWithdrawChallengePeriod()(uint256)' --rpc-url "$RPC")"
  echo "rebalanceReceiver=$(cast call $V 'rebalanceReceiver()(address)' --rpc-url "$RPC")"
  echo "usdt0=$(cast call $USDT0 'balanceOf(address)(uint256)' $V --rpc-url "$RPC" | awk '{print $1}')"
  echo "usdc=$(cast call $USDC 'balanceOf(address)(uint256)' $V --rpc-url "$RPC" | awk '{print $1}')"
  echo "eth=$(cast balance $V --rpc-url "$RPC")"
done
echo "=== validator hash v1 (powers 20/20/20, required 40)"
H=0x8141d873ff9759ed4e5a2eeb4aadd259f6110c82b662e5f0ed52886b16e3355a
echo "availableValidators=$(cast call $V1 'availableValidators(bytes32)(uint256)' $H --rpc-url "$RPC")"
echo "validatorRequiredPowers=$(cast call $V1 'validatorRequiredPowers(bytes32)(uint256)' $H --rpc-url "$RPC")"
echo "=== custody wallets (plain EOAs)"
for A in 0x03A7e58745874D49b3AcC770C40261A3ce206608 0xc2a290eceac480f057b6e7b45a7a949535e478ce 0xdC379823A9a3A2ca9d77C33299551ecDBaBf7A41; do
  echo "$A size=$(cast codesize $A --rpc-url "$RPC") usdt0=$(cast call $USDT0 'balanceOf(address)(uint256)' $A --rpc-url "$RPC" | awk '{print $1}') usdc=$(cast call $USDC 'balanceOf(address)(uint256)' $A --rpc-url "$RPC" | awk '{print $1}')"
done
echo "=== stale pending withdrawals on v1 (all paused -> unpayable)"
for id in 664069738506862848 664074101526741248 664074311472903296 664075284429796480 664078265124516992 664078799168192768 664078868991046784 664342947185947776; do
  echo "id=$id $(cast call $V1 'withdrawals(uint256)(bool,bool,bool,uint256,address,uint256,address,uint256)' $id --rpc-url "$RPC" | tr '\n' ' ')"
done
