#!/usr/bin/env python3
"""Decode Solstice YieldVault state accounts and Anchor events (read-only)."""
import struct, base64
from sim import b58enc

def dec_escrow(raw):
    d = raw[8:]
    o = 0
    user = b58enc(d[o:o+32]); o += 32
    bump = d[o]; o += 1
    mint = b58enc(d[o:o+32]); o += 32
    amount = struct.unpack_from('<Q', d, o)[0]; o += 8
    cooldown_end = struct.unpack_from('<Q', d, o)[0]; o += 8
    return dict(user=user, bump=bump, asset_mint=mint, asset_amount=amount, cooldown_end=cooldown_end)

def dec_pool(raw):
    d = raw[8:]; o = 0
    bump = d[o]; o += 1
    mint = b58enc(d[o:o+32]); o += 32
    dec = d[o]; o += 1
    vault = b58enc(d[o:o+32]); o += 32
    vb = d[o]; o += 1
    ta = int.from_bytes(d[o:o+16], 'little'); o += 16
    ss = int.from_bytes(d[o:o+16], 'little'); o += 16
    return dict(bump=bump, asset_mint=mint, decimals=dec, asset_vault=vault, vault_bump=vb,
                total_assets=ta, shares_supply=ss)

def dec_token(raw):
    d = raw
    mint = b58enc(d[0:32])
    owner = b58enc(d[32:64])
    amount = struct.unpack_from('<Q', d, 64)[0]
    return dict(mint=mint, owner=owner, amount=amount)

def dec_vesting(raw):
    d = raw[8:]; o = 0
    bump = d[o]; o += 1
    amt = struct.unpack_from('<Q', d, o)[0]; o += 8
    st = struct.unpack_from('<Q', d, o)[0]; o += 8
    en = struct.unpack_from('<Q', d, o)[0]; o += 8
    return dict(bump=bump, vesting_amount=amt, start_time=st, end_time=en)

def dec_unlock_event(b):
    # controller(32) yield_pool(32) user(32) asset_amount u64 share_amount u64 unvested u64
    # total_assets_before u128 shares_supply_before u128 total_assets_after u128 shares_supply_after u128
    # cooldown_escrow_asset_amount u64 cooldown_end u64 is_init_needed bool
    o = 0
    out = {}
    for k in ("controller", "yield_pool", "user"):
        out[k] = b58enc(b[o:o+32]); o += 32
    for k in ("asset_amount", "share_amount", "unvested_amount"):
        out[k] = struct.unpack_from('<Q', b, o)[0]; o += 8
    for k in ("total_assets_before", "shares_supply_before", "total_assets_after", "shares_supply_after"):
        out[k] = int.from_bytes(b[o:o+16], 'little'); o += 16
    out["cooldown_escrow_asset_amount"] = struct.unpack_from('<Q', b, o)[0]; o += 8
    out["cooldown_end"] = struct.unpack_from('<Q', b, o)[0]; o += 8
    out["is_init_needed"] = bool(b[o]); o += 1
    return out

def dec_lock_event(b):
    o = 0; out = {}
    for k in ("controller", "yield_pool", "user"):
        out[k] = b58enc(b[o:o+32]); o += 32
    for k in ("asset_amount", "share_amount", "unvested_amount"):
        out[k] = struct.unpack_from('<Q', b, o)[0]; o += 8
    for k in ("total_assets_before", "shares_supply_before", "total_assets_after", "shares_supply_after"):
        out[k] = int.from_bytes(b[o:o+16], 'little'); o += 16
    return out
