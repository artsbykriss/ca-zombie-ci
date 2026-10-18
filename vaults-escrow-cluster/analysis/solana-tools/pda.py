#!/usr/bin/env python3
"""PDA helpers for Solana."""
import hashlib
from base58 import b58encode, b58decode

# Solana uses curve25519-dalek CompressedEdwardsY::decompress (accepts small-order
# and non-canonical encodings). nacl's is_valid_point is stricter, so implement
# the decompression check directly over GF(2^255-19).
_P = 2**255 - 19
_D = (-121665 * pow(121666, _P - 2, _P)) % _P

def _is_on_curve(b):
    y = int.from_bytes(b, "little") & ((1 << 255) - 1)
    if y >= _P:
        y %= _P
    y2 = (y * y) % _P
    num = (y2 - 1) % _P
    den = (_D * y2 + 1) % _P
    x2 = (num * pow(den, _P - 2, _P)) % _P
    if x2 == 0:
        return True
    return pow(x2, (_P - 1) // 2, _P) == 1

def create_program_address(seeds, program_id):
    h = hashlib.sha256(b"".join(seeds) + program_id + b"ProgramDerivedAddress").digest()
    if _is_on_curve(h):
        raise ValueError("on curve")
    return h

def find_program_address(seeds, program_id):
    for bump in range(255, -1, -1):
        try:
            return b58encode(create_program_address(seeds + [bytes([bump])], program_id)).decode(), bump
        except ValueError:
            continue
    raise ValueError("no pda")

def user_pda(owner):
    return find_program_address([b"user", b58decode(owner)], b58decode("offerbkFMvVfpQhL8ZQ5iromnjct5rz3r52B9ewu3ie"))

ATA = b58decode("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")

def ata(wallet_pubkey, token_program, mint):
    return find_program_address([b58decode(wallet_pubkey), b58decode(token_program), b58decode(mint)], ATA)
