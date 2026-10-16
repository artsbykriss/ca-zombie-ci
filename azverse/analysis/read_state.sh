#!/bin/bash
# Read AZverse live state (keyless public RPC; no secrets). Records block number.
set -u
RPC="${1:-https://arbitrum-one-rpc.publicnode.com}"
P=0x91ba525861c16aa8cd4d6974e4058cc846f42ebe
OUT="$(dirname "$0")/state_read_$(date +%s).txt"
exec > >(tee "$OUT")
echo "RPC=$RPC"
echo "BLOCK=$(cast block-number --rpc-url $RPC)"
echo "=== vault core ==="
echo "paused=$(cast call $P 'paused()(bool)' --rpc-url $RPC)"
echo "challengePeriod=$(cast call $P 'pendingWithdrawChallengePeriod()(uint256)' --rpc-url $RPC)"
echo "rebalanceReceiver=$(cast call $P 'rebalanceReceiver()(address)' --rpc-url $RPC)"
echo "balanceETH=$(cast balance $P --rpc-url $RPC)"
echo "=== role holders (hasRole checks) ==="
for pair in "OPERATOR_ROLE 0x32fcff5c9bbcf45f4efe50219ce9f24df2889af3" "OPERATOR_ROLE 0x9276609d5bce373938ae20f7c1eab7f0c1220701" "OPERATOR_ROLE 0x9bbc8a82e24fd4434103302edf0f0758d51c575f" "ADMIN_ROLE 0x7a1b6891269ed1699f93e25296a6e23d6f4f7386" "UPGRADE_ROLE 0x92996ea56590b0e659d695d9736db62cae843b51" "VALIDATOR_ROLE 0x383a6439f966d67edc6140d12024334616ddc276" "TOKEN_ROLE 0x4a335bb7f44fc27bf4fbb5705e71014bace924ec" "DEPOSIT_ROLE 0x4a335bb7f44fc27bf4fbb5705e71014bace924ec" "PAUSE_ROLE 0x4a335bb7f44fc27bf4fbb5705e71014bace924ec"; do
  set -- $pair
  echo "$1($2)=$(cast call $P "hasRole(bytes32,address)(bool)" "$(cast keccak "$1")" "$2" --rpc-url $RPC)"
done
echo "DEFAULT_ADMIN(0x4a335bb7)=$(cast call $P 'hasRole(bytes32,address)(bool)' 0x0000000000000000000000000000000000000000000000000000000000000000 0x4a335bb7f44fc27bf4fbb5705e71014bace924ec --rpc-url $RPC)"
echo "=== validators registration ==="
VHASH=0x8141d873ff9759ed4e5a2eeb4aadd259f6110c82b662e5f0ed52886b16e3355a
echo "availableValidators[hash]=$(cast call $P 'availableValidators(bytes32)(uint256)' $VHASH --rpc-url $RPC)"
echo "validatorRequiredPowers[hash]=$(cast call $P 'validatorRequiredPowers(bytes32)(uint256)' $VHASH --rpc-url $RPC)"
echo "=== stale pending withdrawals (never executed) ==="
for id in 664069738506862848 664074101526741248 664074311472903296 664075284429796480 664078265124516992 664078799168192768 664078868991046784 664342947185947776; do
  echo "id=$id -> $(cast call $P 'withdrawals(uint256)(bool,bool,bool,uint256,address,uint256,address,uint256)' $id --rpc-url $RPC | tr '\n' ' ')"
done
echo "=== supported tokens (TokenInfo + balances + symbol) ==="
for t in 0x0000000000000000000000000000000000000000 0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9 0xaf88d065e77c8cc2239327c5edb3a432268e5831 0x0f77a61e2f01d3cf8cf216bae87e6c40b77e651b 0x2663feae1b9c2d529537949b2e98907ef93f1641 0x583160121e477727d78bafcedd85b63ddbb66617 0xd2b1c70a01f96cbecf4aa40b00d7ed4b1ba3fa57 0x3701424e2caa3649420c00c000387b1798e866db 0xc5a0a5fbc3ad0f7a3430b7a7a8418eb2176757d9 0x30c8b835309b2bb13faadeb4f60445af81303ea5 0xfc0f91173e6e0b88f06191c2ad160c490aa77b14 0xf0264b0798902a3db655c326b70325391ad1748f 0x849c22d0146209c88419b5cfe736f9b4769b5280 0xa0635ee8154e67827affc4558a763d2c10b66007 0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34; do
  if [ "$t" = "0x0000000000000000000000000000000000000000" ]; then
    bal=$(cast balance $P --rpc-url $RPC); sym=ETH; dec=18
  else
    bal=$(cast call $t 'balanceOf(address)(uint256)' $P --rpc-url $RPC 2>/dev/null | awk '{print $1}')
    sym=$(cast call $t 'symbol()(string)' --rpc-url $RPC 2>/dev/null | head -1)
    dec=$(cast call $t 'decimals()(uint8)' --rpc-url $RPC 2>/dev/null | head -1)
  fi
  info=$(cast call $P 'supportedTokens(address)(address,uint256,uint256,uint256,uint256)' $t --rpc-url $RPC | tr '\n' ' ')
  echo "$t sym=$sym dec=$dec bal=$bal info=[$info]"
done
