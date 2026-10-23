#!/usr/bin/env bash
# Lightweight read-only live-state snapshot for the Metropolis DLMM VaultFactory (Sonic 146).
# No secrets. Public RPC only. Writes ci-out/live_state.json (uploaded as a CI artifact).
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p ci-out
RPC="${SONIC_RPC_URL:-https://rpc.soniclabs.com}"
F=0x197d40B36677248E82939f96930bf4E7Fe8aD1c2
V=0x6bE5a84D4A92269eC0Eb228B6c4dAdecED4C7D54
S=0x3CD06627E5DAf698F81fdaaD24b6d16DAF209450

call() { cast call "$1" "$2" "${@:3}" --rpc-url "$RPC" 2>/dev/null | tr -d '\n'; }

BLK=$(cast block-number --rpc-url "$RPC" 2>/dev/null)
cat > ci-out/live_state.json <<JSON
{
  "chain": "sonic",
  "chain_id": 146,
  "block": ${BLK:-0},
  "factory": "$F",
  "factory_native_balance": "$(cast balance $F --rpc-url "$RPC" 2>/dev/null)",
  "factory_owner": "$(call $F 'owner()(address)')",
  "factory_impl_oracle": "$(call $F 'getVaultImplementation(uint8)(address)' 2)",
  "factory_impl_simple": "$(call $F 'getVaultImplementation(uint8)(address)' 1)",
  "factory_impl_strategy": "$(call $F 'getStrategyImplementation(uint8)(address)' 1)",
  "factory_creation_fee": "$(call $F 'getCreationFee()(uint256)')",
  "factory_num_oracle_vaults": "$(call $F 'getNumberOfVaults(uint8)(uint256)' 2)",
  "vault": "$V",
  "vault_strategy": "$(call $V 'getStrategy()(address)')",
  "vault_pair": "$(call $V 'getPair()(address)')",
  "vault_total_supply": "$(call $V 'totalSupply()(uint256)')",
  "vault_operators": "$(call $V 'getOperators()(address,address)')",
  "vault_deposits_paused": "$(call $V 'isDepositsPaused()(bool)')",
  "strategy_operator": "$(call $S 'getOperator()(address)')",
  "strategy_aum_annual_fee": "$(call $S 'getAumAnnualFee()(uint256)')",
  "strategy_balances": "$(call $S 'getBalances()(uint256,uint256)')"
}
JSON
echo "[ci] wrote ci-out/live_state.json (block ${BLK:-?})"
cat ci-out/live_state.json
