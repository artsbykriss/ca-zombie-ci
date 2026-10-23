#!/usr/bin/env bash
# Read-only state dump for the World Chain "AgentBank Deposit Vault" (Morpho VaultV2 code).
# Uses a KEYLESS public RPC only. No keys, no writes.
set -uo pipefail
R="${RPC:-https://worldchain-mainnet.g.alchemy.com/public}"
V=0x5C6F9354b6176C14f7dF1C1e16a0DC4A0Ff9c3E1
ASSET=0x2cFc85d8E48F8EAB294be644d9E25C3030863003
c() { cast call --rpc-url "$R" "$@" 2>&1; }

BLK=$(cast block-number --rpc-url "$R")
echo "rpc_head=$BLK"
echo "=== code length (hex chars) ==="
cast code "$V" --rpc-url "$R" | wc -c
echo "=== vault metadata ==="
printf 'name                       %s\n' "$(c "$V" 'name()(string)')"
printf 'symbol                     %s\n' "$(c "$V" 'symbol()(string)')"
printf 'decimals                   %s\n' "$(c "$V" 'decimals()(uint8)')"
printf 'asset                      %s\n' "$(c "$V" 'asset()(address)')"
printf 'totalAssets                %s\n' "$(c "$V" 'totalAssets()(uint256)')"
printf 'totalSupply                %s\n' "$(c "$V" 'totalSupply()(uint256)')"
printf '_totalAssets               %s\n' "$(c "$V" '_totalAssets()(uint128)')"
printf 'owner                      %s\n' "$(c "$V" 'owner()(address)')"
printf 'curator                    %s\n' "$(c "$V" 'curator()(address)')"
printf 'receiveSharesGate          %s\n' "$(c "$V" 'receiveSharesGate()(address)')"
printf 'sendSharesGate             %s\n' "$(c "$V" 'sendSharesGate()(address)')"
printf 'receiveAssetsGate          %s\n' "$(c "$V" 'receiveAssetsGate()(address)')"
printf 'sendAssetsGate             %s\n' "$(c "$V" 'sendAssetsGate()(address)')"
printf 'adapterRegistry            %s\n' "$(c "$V" 'adapterRegistry()(address)')"
printf 'liquidityAdapter           %s\n' "$(c "$V" 'liquidityAdapter()(address)')"
printf 'liquidityData              %s\n' "$(c "$V" 'liquidityData()(bytes)')"
printf 'maxRate                    %s\n' "$(c "$V" 'maxRate()(uint64)')"
printf 'virtualShares              %s\n' "$(c "$V" 'virtualShares()(uint256)')"
printf 'lastUpdate                 %s\n' "$(c "$V" 'lastUpdate()(uint64)')"
printf 'performanceFee             %s\n' "$(c "$V" 'performanceFee()(uint96)')"
printf 'performanceFeeRecipient    %s\n' "$(c "$V" 'performanceFeeRecipient()(address)')"
printf 'managementFee              %s\n' "$(c "$V" 'managementFee()(uint96)')"
printf 'managementFeeRecipient     %s\n' "$(c "$V" 'managementFeeRecipient()(address)')"
printf 'adaptersLength             %s\n' "$(c "$V" 'adaptersLength()(uint256)')"
printf 'DOMAIN_SEPARATOR           %s\n' "$(c "$V" 'DOMAIN_SEPARATOR()(bytes32)')"
echo "=== asset (WLD) ==="
printf 'WLD name                   %s\n' "$(c "$ASSET" 'name()(string)')"
printf 'WLD symbol                 %s\n' "$(c "$ASSET" 'symbol()(string)')"
printf 'WLD decimals               %s\n' "$(c "$ASSET" 'decimals()(uint8)')"
printf 'WLD balanceOf(vault)       %s\n' "$(c "$ASSET" 'balanceOf(address)(uint256)' "$V")"
printf 'WLD balanceOf(asset_self)  %s\n' "$(c "$ASSET" 'balanceOf(address)(uint256)' "$ASSET")"
echo "=== vault native balance (wei) ==="
cast balance "$V" --rpc-url "$R"
echo "=== role flags ==="
OWNER=$(c "$V" 'owner()(address)')
CURATOR=$(c "$V" 'curator()(address)')
echo "owner=$OWNER curator=$CURATOR"
printf 'isSentinel(owner)   %s\n' "$(c "$V" 'isSentinel(address)(bool)' "$OWNER")"
printf 'isSentinel(curator) %s\n' "$(c "$V" 'isSentinel(address)(bool)' "$CURATOR")"
printf 'isAllocator(owner)  %s\n' "$(c "$V" 'isAllocator(address)(bool)' "$OWNER")"
printf 'isAllocator(curator)%s\n' "$(c "$V" 'isAllocator(address)(bool)' "$CURATOR")"
echo "=== adapters ==="
N=$(c "$V" 'adaptersLength()(uint256)' | awk '{print $1}')
if [ -n "$N" ] && [ "$N" != "0" ]; then
  for i in $(seq 0 $((N-1))); do
    echo "adapter[$i]=$(c "$V" 'adapters(uint256)(address)' "$i")"
  done
fi
