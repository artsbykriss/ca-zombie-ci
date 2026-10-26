#!/usr/bin/env python3
"""Minimal Solana legacy message builder + base58 shortvec. Read-only (never sends)."""
import base64
from b58 import b58dec

def cu(n):
    out = bytearray()
    while True:
        b = n & 0x7f
        n >>= 7
        if n:
            out.append(b | 0x80)
        else:
            out.append(b)
            break
    return bytes(out)

def build(keys_flags, blockhash, instructions):
    """keys_flags: ordered list of (pubkey, is_signer, is_writable).
    instructions: list of (program_id, [account pubkeys], data bytes).
    Returns base64 of a fully-signed-shaped (zero-sig) legacy tx."""
    keys = [k for k, _, _ in keys_flags]
    idx = {k: i for i, k in enumerate(keys)}
    n_sign = sum(1 for _, s, _ in keys_flags if s)
    n_ro_sign = sum(1 for _, s, w in keys_flags if s and not w)
    n_ro_unsign = sum(1 for _, s, w in keys_flags if not s and not w)
    msg = bytearray([n_sign, n_ro_sign, n_ro_unsign])
    msg += cu(len(keys))
    for k in keys:
        msg += b58dec(k)
    msg += b58dec(blockhash)
    msg += cu(len(instructions))
    for pid, accts, data in instructions:
        msg += bytes([idx[pid]])
        msg += cu(len(accts))
        for a in accts:
            msg += bytes([idx[a]])
        msg += cu(len(data))
        msg += data
    sigs = b"\x00" * 64 * n_sign
    return base64.b64encode(cu(n_sign) + sigs + bytes(msg)).decode()

def order_keys(keys_flags):
    """Return keys in canonical order: payer, other writable signers, readonly signers,
    writable non-signers, readonly non-signers."""
    payer = keys_flags[0]
    rest = keys_flags[1:]
    ws = [k for k in rest if k[1] and k[2]]
    rs = [k for k in rest if k[1] and not k[2]]
    wu = [k for k in rest if not k[1] and k[2]]
    ru = [k for k in rest if not k[1] and not k[2]]
    return [payer] + ws + rs + wu + ru
