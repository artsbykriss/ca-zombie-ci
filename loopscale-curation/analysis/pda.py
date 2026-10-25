#!/usr/bin/env python3
"""Pure-python Solana PDA finder (no deps beyond hashlib)."""
import hashlib
try:
    import base58 as b58
except Exception:
    import b58

p = 2**255 - 19
d = (-121665 * pow(121666, p-2, p)) % p
I = pow(2, (p-1)//4, p)

def is_on_curve(s):
    if len(s)!=32: return False
    y = int.from_bytes(s,'little') & ((1<<255)-1)
    if y >= p: return False
    # x^2 = (y^2 - 1) / (d y^2 + 1)
    y2 = (y*y) % p
    u = (y2 - 1) % p
    v = (d*y2 + 1) % p
    if v == 0: return False
    x2 = (u * pow(v, p-2, p)) % p
    if x2 == 0: return True
    # check if x2 is a square: x = x2^((p+3)/8)
    x = pow(x2, (p+3)//8, p)
    if (x*x - x2) % p != 0:
        x = (x * I) % p
    return (x*x - x2) % p == 0

def create_program_address(seeds, program_id):
    h = hashlib.sha256()
    for s in seeds:
        h.update(s)
    h.update(b"ProgramDerivedAddress")
    h.update(program_id)
    return h.digest()

def find_program_address(seeds, program_id):
    for bump in range(255, -1, -1):
        addr = create_program_address(seeds+[bytes([bump])], program_id)
        if not is_on_curve(addr):
            return b58.b58encode(addr).decode(), bump
    raise Exception("no PDA")

if __name__=="__main__":
    import sys
    pid = b58.b58decode(sys.argv[1]) if len(sys.argv)>1 else b58.b58decode("RAtEwzA1rerjeWip6uMuheQtzykxYCrEQRaSFCCrf2D")
    for seeds in [[b"anchor:idl", pid], [b"anchor:idl"], [b"__event_authority"]]:
        try:
            a,b = find_program_address(seeds, pid)
            print("seeds",seeds[:1] if len(seeds)>1 else seeds, "->", a, "bump", b)
        except Exception as e:
            print("err",e)
