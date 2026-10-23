#!/usr/bin/env python3
"""Identify account types by Anchor account-discriminator = sha256('account:<Name>')[:8]."""
import hashlib

def ad(name): return hashlib.sha256(("account:" + name).encode()).digest()[:8]

TARGETS = {
    "eab4f1fc8be0a008": "RLP 266-byte (Asset)",
    "42261140bc504481": "RLP 105-byte (Pool)",
    "c3ad502028d84e6e": "RLP 55-byte",
    "32a65ec0ea4098d0": "RLP 168-byte",
    "19bdbb56fbf97b5d": "RLP/PROXY 75-byte",
    "dfb3a3beb1e043ad": "RLP 379-byte (Settings)",
}
NAMES = ["Asset", "LiquidityPool", "UserPermissions", "Cooldown", "Settings", "StreamPrice",
         "PriceAccount", "OraclePrice", "Permissions", "Receipt", "ReceiptToken", "Deposit",
         "Lockup", "LockupState", "Tranche", "Pool", "State", "Config", "GlobalConfig",
         "AssetRegistry", "AssetAccount", "Killswitch", "AccessMap", "LevelRoles", "Role",
         "ProxyState", "Price", "Oracle", "Stream", "OracleState", "FeedPrice", "Intent",
         "WithdrawalIntent", "DepositIntent", "TrancheConfig", "Market", "MarketState",
         "Vault", "VaultState", "Position", "UserPosition", "Account", "Registry",
         "OracleAccount", "StreamPriceAccount", "AssetOracle", "PriceBook", "OracleConfig"]
rev = {}
for n in NAMES:
    rev[ad(n).hex()] = n
for h, lab in TARGETS.items():
    print(f"{h}  {lab:26} -> {rev.get(h, '??')}")
