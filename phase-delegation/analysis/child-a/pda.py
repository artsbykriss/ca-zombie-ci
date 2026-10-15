#!/usr/bin/env python3
"""Solana PDA derivation (ed25519), pure python. Used to verify spoo1 PDAs."""
import hashlib
from itertools import count

P = 2**255 - 19
D = (-121665 * pow(121666, P - 2, P)) % P
I = pow(2, (P - 1) // 4, P)


def _xrecover(y):
    xx = (y * y - 1) * pow(D * y * y + 1, P - 2, P)
    x = pow(xx, (P + 3) // 8, P)
    if (x * x - xx) % P != 0:
        x = (x * I) % P
    if (x * x - xx) % P != 0:
        return None
    return x


def is_on_curve(b: bytes) -> bool:
    if len(b) != 32:
        return False
    y = int.from_bytes(b, "little") & ((1 << 255) - 1)
    if y >= P:
        return False
    return _xrecover(y) is not None


def find_program_address(seeds, program_id: bytes):
    for bump in range(255, -1, -1):
        h = hashlib.sha256(
            b"".join(seeds) + bytes([bump]) + program_id + b"ProgramDerivedAddress"
        ).digest()
        if not is_on_curve(h):
            return h, bump
    raise RuntimeError("no pda")


def create_program_address(seeds, program_id: bytes):
    h = hashlib.sha256(b"".join(seeds) + program_id + b"ProgramDerivedAddress").digest()
    return h, not is_on_curve(h)


_A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"


def b58e(b: bytes) -> str:
    n = int.from_bytes(b, "big")
    s = ""
    while n:
        n, r = divmod(n, 58)
        s = _A[r] + s
    return "1" * (len(b) - len(b.lstrip(b"\0"))) + s


def b58d(s: str) -> bytes:
    n = 0
    for c in s:
        n = n * 58 + _A.index(c)
    return n.to_bytes(32, "big")


if __name__ == "__main__":
    POOL = b58d("aero2ePURjuEgLKTzcUmF6RypBncBGd7pMUYCoSsVJ6")
    PROG = b58d("SPoo1Ku8WFXoNDMHPsrGSTSG1Y47rzgn41SLUNakuHy")
    print("account_type(pool) tag check: is_on_curve(pool) =", is_on_curve(POOL))
    for name, seed in [("withdraw", b"withdraw"), ("deposit", b"deposit")]:
        pk, bump = find_program_address([POOL, seed], PROG)
        print(f"{name:9s} PDA = {b58e(pk)}  bump={bump}")
    # withdraw authority known: AKJt3m2xJ6ANda9adBGqb5BMrheKJSwxyCfYkLuZNmjn
    pk, bump = create_program_address([POOL, b"withdraw", bytes([255])], PROG)
    print("create_program_address([pool,'withdraw',255]) =", b58e(pk), "valid=", bump)
    print("matches claimed withdraw authority AKJt...ZNmjn:",
          b58e(pk) == "AKJt3m2xJ6ANda9adBGqb5BMrheKJSwxyCfYkLuZNmjn", "bump256?", bump)
    print()
    print("deposit authority 4Y6XeEZ2Dg2zXU9NJgdmAG9xpwAsNusLReSTLzJzxtZJ8 is the pool deposit PDA?",
          b58e(find_program_address([POOL, b"deposit"], PROG)[0]) == "4Y6XeEZ2Dg2zXU9NJgdmAG9xpwAsNusLReSTLzJzxtZJ8")
    print("deposit authority on curve (i.e. a normal keypair)?",
          is_on_curve(b58d("4Y6XeEZ2Dg2zXU9NJgdmAG9xpwAsNusLReSTLzJzxtZJ8")))
