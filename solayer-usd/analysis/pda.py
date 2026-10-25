#!/usr/bin/env python3
"""pda.py - Solana PDA derivation + ATA helpers (pure python)."""
import hashlib, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solsim import b58dec, b58enc

P = 2**255 - 19
D = (-121665 * pow(121666, P - 2, P)) % P
I = pow(2, (P - 1) // 4, P)

def _is_on_curve(yb):
    y = int.from_bytes(yb, "little") & ((1 << 255) - 1)
    if y >= P: return False
    y2 = y * y % P
    u = (y2 - 1) % P
    v = (D * y2 + 1) % P
    x2 = u * pow(v, P - 2, P) % P
    if x2 == 0: return True
    x = pow(x2, (P + 3) // 8, P)
    if (x * x - x2) % P != 0:
        x = x * I % P
    return (x * x - x2) % P == 0

def find_pda(seeds, program):
    prog = b58dec(program)
    for bump in range(255, -1, -1):
        h = hashlib.sha256(b"".join(seeds) + bytes([bump]) + prog + b"ProgramDerivedAddress").digest()
        if not _is_on_curve(h):
            return b58enc(h), bump
    raise RuntimeError("no pda")

ATA_PROG = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
def ata(owner, mint, token_program="TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"):
    a, _ = find_pda([b58dec(owner), b58dec(token_program), b58dec(mint)], ATA_PROG)
    return a

def pool_pda(usdc_mint, susd_mint, program):
    a, _ = find_pda([b"pool", b58dec(usdc_mint), b58dec(susd_mint)], program)
    return a

def proof_pda(kind, pool, user, nonce, program):
    a, _ = find_pda([kind.encode(), b58dec(pool), b58dec(user), nonce.to_bytes(8, "big")], program)
    return a

if __name__ == "__main__":
    PROG="s1aysqpEyZyijPybUV89oBGeooXrR22wMNLjnG2SWJA"
    USDC="EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
    SUSD="susdabGDNbhrnCa6ncrYo81u4s9GM8ecK2UwMyZiq4X"
    T22="TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
    print("pool", pool_pda(USDC, SUSD, PROG), "expect FhVcYNEe58SMtxpZGnTu2kpYJrTu2vwCZDGpPLqbd2yG")
    A="743QjwzJdZwRibbPAc4ie73JeM7aWyCZtFT3ZVJXuVN8"
    print("usdc ata", ata(A, USDC))
    print("susd ata", ata(A, SUSD, T22))
    print("susd vault of pool", ata("FhVcYNEe58SMtxpZGnTu2kpYJrTu2vwCZDGpPLqbd2yG", SUSD, T22), "expect FfELPrBpJBzyND1xTM6NmXRaQJbuP8c5J8jmJWZvDJds")
