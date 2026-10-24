#!/usr/bin/env python3
"""Compute Anchor 8-byte discriminators for candidate instruction names and search the ELF."""
import hashlib, sys, os

def disc(name):
    return hashlib.sha256(("global:" + name).encode()).digest()[:8]

NAMES = [
    # RLP (documented)
    "restake", "request_withdrawal", "withdraw", "swap", "deposit_rewards", "slash",
    "initialize_rlp", "initialize_lp", "initialize_lp_token_account", "add_asset",
    "update_deposit_cap", "freeze_functionality", "create_permission_account",
    "update_role_holder", "update_action_role",
    # likely extras
    "deactivate_asset", "post_oracle_price", "set_oracle", "initialize_cooldown",
    "update_settings", "update_swap_fee", "update_cooldown_duration", "suspend_deposits",
    "claim_fees", "update_authority", "update_fee", "create_proxy", "wrap", "unwrap",
    "deposit", "redeem", "mint", "burn", "transfer_authority", "pause", "unpause",
    "initialize", "set_paused", "add_role", "remove_role", "update_permissions",
    "update_role", "close_cooldown", "cancel_withdrawal", "harvest", "rebalance",
    "add_liquidity", "remove_liquidity", "collect_fees", "set_fee", "initialize_asset",
]

RLP = os.path.join(os.path.dirname(os.path.abspath(__file__)), "rlp.so")
PROXY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "proxy.so")

def scan(path, label):
    data = open(path, "rb").read()
    print(f"===== {label} ({path.split('/')[-1]}, {len(data)} bytes) =====")
    found = []
    for n in NAMES:
        d = disc(n)
        idxs = []
        start = 0
        while True:
            i = data.find(d, start)
            if i < 0:
                break
            idxs.append(i)
            start = i + 1
            if len(idxs) > 3:
                break
        if idxs:
            found.append((n, d.hex(), idxs[:3]))
    for n, h, idxs in found:
        print(f"  {n:34} {h}  at {idxs}")
    print(f"  -> {len(found)}/{len(NAMES)} discriminators present")

scan(RLP, "RLP")
scan(PROXY, "PROXY")
