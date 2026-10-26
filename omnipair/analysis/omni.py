#!/usr/bin/env python3
"""Omnipair read-only decode helpers (keyless public RPC only).

Program: omnixgS8fnqHfCcTGKWj6JtKjzpJZ1Y5y9pyFkQDkYE  (BPFLoaderUpgradeable)
All offsets derived from the Anchor IDL embedded in analysis/dl-adapter.js
(metadata name=omnipair version=0.9.9).
"""
import base64
import hashlib
import struct

A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

PID = "omnixgS8fnqHfCcTGKWj6JtKjzpJZ1Y5y9pyFkQDkYE"
PD = "CtdTN3od14hyJm7DwmZABPxZBLiuUi7kKrHoNUkSQuMM"
UPGRADE_AUTHORITY = "4JpPs9Mi11qoj6GthQPiTjUc4gXq8BAoSs3AD6NVjQUZ"
LP_MINT = "omfgRBnxHsNJh6YeGbGAmWenNkenzsXyBXm3WDhmeta"

TOKEN_PROGRAM = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
TOKEN_2022 = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
ATA_PROGRAM = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
SYSTEM_PROGRAM = "11111111111111111111111111111111"
EVENT_AUTHORITY_SEED = b"__event_authority"

DISC_PAIR = bytes([85, 72, 49, 176, 182, 228, 141, 82])
DISC_POSITION = bytes([251, 248, 209, 245, 83, 234, 17, 27])
DISC_AUTHORITY = bytes([175, 247, 160, 182, 140, 128, 211, 226])
DISC_RATE_MODEL = bytes([94, 3, 203, 219, 107, 137, 4, 162])

RESERVE_VAULT_SEED = b"reserve_vault"
COLLATERAL_VAULT_SEED = b"collateral_vault"
PAIR_SEED = b"gamm_pair"
POSITION_SEED = b"gamm_position"
FUTARCHY_SEED = b"futarchy_authority"

# instruction discriminators
IX = {
    "add_collateral": bytes([127, 82, 121, 42, 161, 176, 249, 206]),
    "add_liquidity": bytes([181, 157, 89, 67, 143, 182, 52, 72]),
    "borrow": bytes([228, 253, 131, 202, 207, 116, 89, 18]),
    "claim_protocol_fees": bytes([34, 142, 219, 112, 109, 54, 133, 23]),
    "flashloan": bytes([105, 33, 1, 3, 42, 158, 246, 67]),
    "init_futarchy_authority": bytes([133, 110, 154, 29, 240, 206, 71, 100]),
    "initialize": bytes([175, 175, 109, 31, 13, 152, 155, 237]),
    "liquidate": bytes([223, 179, 226, 125, 48, 46, 39, 74]),
    "remove_collateral": bytes([86, 222, 130, 86, 92, 20, 72, 65]),
    "remove_liquidity": bytes([80, 85, 209, 72, 24, 206, 177, 108]),
    "repay": bytes([234, 103, 67, 82, 208, 234, 219, 166]),
    "set_global_reduce_only": bytes([242, 151, 123, 139, 239, 87, 249, 98]),
    "set_pair_reduce_only": bytes([147, 113, 16, 50, 64, 88, 175, 18]),
    "swap": bytes([248, 198, 158, 145, 225, 117, 135, 200]),
    "update_futarchy_authority": bytes([15, 196, 157, 217, 113, 226, 89, 25]),
    "update_protocol_revenue": bytes([176, 139, 131, 197, 40, 225, 125, 200]),
    "update_revenue_recipients": bytes([116, 179, 137, 47, 118, 167, 65, 217]),
    "view_pair_data": bytes([30, 231, 169, 73, 19, 161, 44, 252]),
    "view_user_position_data": bytes([203, 218, 173, 213, 43, 31, 211, 152]),
}

# constants
CLOSE_FACTOR_BPS = 5000
LIQUIDATION_INCENTIVE_BPS = 50
LIQUIDATION_PENALTY_BPS = 300
MAX_COLLATERAL_FACTOR_BPS = 8500
LTV_BUFFER_BPS = 500
FLASHLOAN_FEE_BPS = 5
NAD = 1_000_000_000
LIQUIDITY_WITHDRAWAL_FEE_BPS = 100


def b58dec(s):
    n = 0
    for c in s:
        n = n * 58 + A.index(c)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big") if n else b""
    pad = 0
    for c in s:
        if c == "1":
            pad += 1
        else:
            break
    return b"\x00" * pad + b


def b58enc(b):
    n = int.from_bytes(b, "big")
    s = ""
    while n > 0:
        n, r = divmod(n, 58)
        s = A[r] + s
    pad = 0
    for c in b:
        if c == 0:
            pad += 1
        else:
            break
    return "1" * pad + (s or "")


def create_pda(seeds, program_id=PID):
    """create_program_address: sha256(concat(seeds) + program_id + 'ProgramDerivedAddress')."""
    h = hashlib.sha256()
    for s in seeds:
        h.update(s)
    h.update(b58dec(program_id))
    h.update(b"ProgramDerivedAddress")
    return h.digest()


def _is_on_curve(b):
    """True if the 32-byte compressed ed25519 point is a valid curve point."""
    p = 2**255 - 19
    d = (-121665 * pow(121666, p - 2, p)) % p
    y = int.from_bytes(b, "little") & ((1 << 255) - 1)
    if y >= p:
        return False
    u = (y * y - 1) % p
    v = (d * y * y + 1) % p
    if v == 0:
        return False
    x2 = (u * pow(v, p - 2, p)) % p
    if x2 == 0:
        return False
    x = pow(x2, (p + 3) // 8, p)
    if (x * x) % p != x2:
        sqrtm1 = pow(2, (p - 1) // 4, p)
        x = (x * sqrtm1) % p
    return (x * x) % p == x2


def find_pda(seeds, program_id=PID):
    """find_program_address: first bump (255..0) yielding an off-curve point."""
    pid = b58dec(program_id)
    for bump in range(255, -1, -1):
        h = hashlib.sha256()
        for s in seeds:
            h.update(s)
        h.update(bytes([bump]))
        h.update(pid)
        h.update(b"ProgramDerivedAddress")
        d = h.digest()
        if not _is_on_curve(d):
            return d, bump
    raise RuntimeError("unable to find PDA")


def find_pda_str(seeds, program_id=PID):
    return b58enc(find_pda(seeds, program_id)[0])


def ata(owner, mint, token_program=TOKEN_PROGRAM):
    return find_pda_str([b58dec(owner), b58dec(token_program), b58dec(mint)], ATA_PROGRAM)


def pair_pda(token0, token1, params_hash):
    return create_pda([PAIR_SEED, b58dec(token0), b58dec(token1), params_hash])


def position_pda(pair, owner):
    return create_pda([POSITION_SEED, b58dec(pair), b58dec(owner)])


def futarchy_pda():
    return create_pda([FUTARCHY_SEED])


def reserve_vault_pda(pair, mint, bump):
    return create_pda([RESERVE_VAULT_SEED, b58dec(pair), b58dec(mint), bytes([bump])])


def collateral_vault_pda(pair, mint, bump):
    return create_pda([COLLATERAL_VAULT_SEED, b58dec(pair), b58dec(mint), bytes([bump])])


EVENT_AUTHORITY_PDA = "FWdP9yTogKbuXvEqQNNHYw2TYm38MbinAZ2iTHeZWX8H"  # bump 255


def event_authority_pda():
    return create_pda([EVENT_AUTHORITY_SEED, bytes([255])])


def _u64(raw, o):
    return struct.unpack_from("<Q", raw, o)[0]


def _u128(raw, o):
    return struct.unpack_from("<QQ", raw, o)


def _u16(raw, o):
    return struct.unpack_from("<H", raw, o)[0]


def _pk(raw, o):
    return b58enc(raw[o:o + 32])


def decode_pair(raw):
    """Decode a Pair account.

    IMPORTANT: `fixed_cf_bps: Option<u16>` is Borsh-encoded with variable
    length (1 byte for None, 3 bytes for Some).  The account is allocated at
    the Some-size (3 bytes), so a None pair carries 2 unused trailing zero
    bytes and every field after the option sits 2 bytes earlier.  This is
    verified on-chain: 113/113 pairs satisfy reserve - cash_reserve ==
    total_debt in whichever variant their byte 146 selects.
    """
    sft = 2 if raw[146] == 1 else 0
    o = lambda b: b + sft  # noqa: E731
    return {
        "variant": "Some" if sft else "None",
        "token0": _pk(raw, 8),
        "token1": _pk(raw, 40),
        "lp_mint": _pk(raw, 72),
        "rate_model": _pk(raw, 104),
        "swap_fee_bps": _u16(raw, 136),
        "half_life": _u64(raw, 138),
        "fixed_cf_bps": (None if raw[146] == 0 else _u16(raw, 147)),
        "reserve0": _u64(raw, o(147)),
        "reserve1": _u64(raw, o(155)),
        "cash_reserve0": _u64(raw, o(163)),
        "cash_reserve1": _u64(raw, o(171)),
        "last_price0_ema_sym": _u64(raw, o(179)),
        "last_price0_ema_dir": _u64(raw, o(187)),
        "last_price1_ema_sym": _u64(raw, o(195)),
        "last_price1_ema_dir": _u64(raw, o(203)),
        "last_update": _u64(raw, o(211)),
        "last_rate0": _u64(raw, o(219)),
        "last_rate1": _u64(raw, o(227)),
        "total_debt0": _u64(raw, o(235)),
        "total_debt1": _u64(raw, o(243)),
        "total_debt0_shares": _u128(raw, o(251)),
        "total_debt1_shares": _u128(raw, o(267)),
        "total_supply": _u64(raw, o(283)),
        "total_collateral0": _u64(raw, o(291)),
        "total_collateral1": _u64(raw, o(299)),
        "token0_decimals": raw[o(307)],
        "token1_decimals": raw[o(308)],
        "params_hash": raw[o(309):o(341)].hex(),
        "version": raw[o(341)],
        "bump": raw[o(342)],
        "vault_bumps": {"reserve0": raw[o(343)], "reserve1": raw[o(344)],
                        "collateral0": raw[o(345)], "collateral1": raw[o(346)]},
        "reduce_only": bool(raw[o(347)]),
    }


def decode_position(raw):
    return {
        "owner": _pk(raw, 8),
        "pair": _pk(raw, 40),
        "collateral0_liquidation_cf_bps": _u16(raw, 72),
        "collateral1_liquidation_cf_bps": _u16(raw, 74),
        "collateral0": _u64(raw, 76),
        "collateral1": _u64(raw, 84),
        "debt0_shares": _u128(raw, 92),
        "debt1_shares": _u128(raw, 108),
        "bump": raw[124],
    }


def decode_authority(raw):
    return {
        "version": raw[8],
        "authority": _pk(raw, 9),
        "futarchy_treasury": _pk(raw, 41),
        "buybacks_vault": _pk(raw, 73),
        "team_treasury": _pk(raw, 105),
        "revenue_share_swap_bps": _u16(raw, 137),
        "revenue_share_interest_bps": _u16(raw, 139),
        "revenue_distribution": {
            "futarchy_treasury_bps": _u16(raw, 141),
            "buybacks_vault_bps": _u16(raw, 143),
            "team_treasury_bps": _u16(raw, 145),
        },
        "global_reduce_only": bool(raw[147]),
        "bump": raw[148],
    }


def decode_rate_model(raw):
    return {
        "exp_rate": _u64(raw, 8),
        "target_util_start": _u64(raw, 16),
        "target_util_end": _u64(raw, 24),
        "half_life_ms": _u64(raw, 32),
        "min_rate": _u64(raw, 40),
        "max_rate": _u64(raw, 48),
        "initial_rate": _u64(raw, 56),
    }


def acct_data(a):
    return base64.b64decode(a["account"]["data"][0])
