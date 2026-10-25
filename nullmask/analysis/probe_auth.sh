#!/usr/bin/env bash
# Read-only auth probe of the Nullmask pool from a fresh, unprivileged EOA.
# Uses a KEYLESS public Base RPC. No tx is signed or sent (eth_call only).
set -u
RPC="${BASE_RPC_PUBLIC:-https://base-rpc.publicnode.com}"
P=0xd64EF1417EB047ed0b54736a5a41F01178C391c6
FROM=0x000000000000000000000000000000000000dEaD   # fresh EOA, no keys, no privileges
Z=0x0000000000000000000000000000000000000000

echo "# Nullmask pool $P  from=$FROM  rpc=$RPC"
echo "# block: $(cast block-number --rpc-url "$RPC")"
echo

probe() { # name, signature, args...
  local name="$1"; shift
  local sig="$1"; shift
  local out
  out=$(cast call "$P" "$sig" "$@" --from "$FROM" --rpc-url "$RPC" 2>&1 | head -1)
  printf '%-28s %s\n' "$name" "$out"
}

echo "== privileged setters =="
probe "setGuard"            "setGuard(address)" "$FROM"
probe "setRelayer"          "setRelayer(address,bool)" "$FROM" true
probe "setTreasury"         "setTreasury(address)" "$FROM"
probe "setVerifiers"        "setVerifiers(address,address,address)" "$FROM" "$FROM" "$FROM" "$FROM"
probe "setWhitelistManager" "setWhitelistManager(address)" "$FROM"
probe "setUpgradeController" "setUpgradeController(address)" "$FROM"
probe "setFeeConfig"        "setFeeConfig(uint16,uint16,bool,uint32)" 100 100 true 0
probe "setTokenParams"      "setTokenParams(address,uint256,uint256,uint256)" "$Z" 0 0 0
probe "setDepositLimits"    "setDepositLimits(address,uint256,uint256)" "$Z" 0 0
probe "setTokenWhitelist"   "setTokenWhitelist(address,uint8)" "$Z" 1
probe "setPaused"           "setPaused(bool)" true
probe "setWithdrawalsPaused" "setWithdrawalsPaused(bool)" true
probe "upgradeToAndCall"    "upgradeToAndCall(address,bytes)" "$FROM" 0x

echo
echo "== guard-only =="
probe "approveDeposit"      "approveDeposit(uint256,address,address,uint256,address,uint256,uint256,uint256,uint256)" 0 "$FROM" "$Z" 0 "$FROM" 0 0 0 0
probe "rejectDeposit"       "rejectDeposit(uint256,address,address,uint256,address,uint256,uint256)" 0 "$FROM" "$Z" 0 "$FROM" 0 0

echo
echo "== user paths =="
probe "withdrawPendingDeposit" "withdrawPendingDeposit(uint256,address,address,uint256,uint256)" 0 "$FROM" "$Z" 0 0
probe "initialize"          "initialize(address,address,address,address,address)" "$FROM" "$FROM" "$FROM" "$FROM" "$FROM"
probe "deposit(no key)"     "deposit(uint256,address)" 10000000000000000 "$Z"

echo
echo "== permissionless (expected to succeed but send to treasury) =="
probe "sweepProtocolFees(ETH)" "sweepProtocolFees(address)" "$Z"
probe "sweepProtocolFees(0x0)" "sweepProtocolFees(address)" "$Z"
