"""Minimal, dependency-free secp256k1 for BIP32 + BIP341 taproot verification.

Pure Python (Jacobian coordinates). No pip installs required — safe for CI.
Not constant-time; verification-only use.
"""
P = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
Gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
Gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8
G = (Gx, Gy)

def _inv(a, m=P):
    return pow(a % m, m - 2, m)

def _jac_double(pt):
    # pt = (X, Y, Z); returns (X, Y, Z)
    X, Y, Z = pt
    if Y == 0:
        return (0, 0, 0)
    A = (X * X) % P
    B = (Y * Y) % P
    C = (B * B) % P
    D = (2 * (((X + B) % P) ** 2 - A - C)) % P
    E = (3 * A) % P
    F = (E * E) % P
    X3 = (F - 2 * D) % P
    Y3 = (E * (D - X3) - 8 * C) % P
    Z3 = (2 * Y * Z) % P
    return (X3, Y3, Z3)

def _jac_add(p1, p2):
    X1, Y1, Z1 = p1; X2, Y2, Z2 = p2
    if Z1 == 0: return p2
    if Z2 == 0: return p1
    Z1Z1 = (Z1 * Z1) % P; Z2Z2 = (Z2 * Z2) % P
    U1 = (X1 * Z2Z2) % P; U2 = (X2 * Z1Z1) % P
    S1 = (Y1 * Z2Z2 * Z2) % P; S2 = (Y2 * Z1Z1 * Z1) % P
    if U1 == U2:
        if S1 != S2:
            return (0, 0, 0)
        return _jac_double(p1)
    H = (U2 - U1) % P; I = (2 * H) % P; I = (I * I) % P
    J = (H * I) % P
    r = (2 * (S2 - S1)) % P
    V = (U1 * I) % P
    X3 = (r * r - J - 2 * V) % P
    Y3 = (r * (V - X3) - 2 * S1 * J) % P
    Z3 = (((Z1 + Z2) % P) ** 2 - Z1Z1 - Z2Z2) % P
    Z3 = (Z3 * H) % P
    return (X3, Y3, Z3)

def _to_affine(pt):
    X, Y, Z = pt
    if Z == 0:
        return None
    zi = _inv(Z)
    zi2 = (zi * zi) % P
    return ((X * zi2) % P, (Y * zi2 * zi) % P)

def mul(k, pt=G):
    """scalar * point (Jacobian double-and-add)."""
    k %= N
    if k == 0 or pt is None:
        return (0, 0, 0)
    result = (0, 0, 0)
    addend = (pt[0], pt[1], 1)
    while k:
        if k & 1:
            result = _jac_add(result, addend)
        addend = _jac_double(addend)
        k >>= 1
    return result

def mul_affine(k, pt=G):
    return _to_affine(mul(k, pt))

def add(P1, P2):
    return _to_affine(_jac_add((P1[0], P1[1], 1), (P2[0], P2[1], 1)))

def lift_x(x):
    if x >= P:
        return None
    y2 = (pow(x, 3, P) + 7) % P
    y = pow(y2, (P + 1) // 4, P)
    if (y * y) % P != y2:
        return None
    if y & 1:
        y = P - y
    return (x, y)

def ser_p(pt):
    return bytes([2 + (pt[1] & 1)]) + pt[0].to_bytes(32, 'big')

def parse_pub(b):
    x = int.from_bytes(b[1:33], 'big')
    pt = lift_x(x)
    if pt is None:
        raise ValueError("bad pubkey")
    if (pt[1] & 1) != (b[0] & 1):
        pt = (pt[0], P - pt[1])
    return pt

def xonly_tweak(internal_x32, tweak32):
    """BIP341: Q = lift_x(P) + t*G, return x-only 32 bytes (even-y output key)."""
    Ppt = lift_x(int.from_bytes(internal_x32, 'big'))
    t = int.from_bytes(tweak32, 'big')
    if t >= N:
        return None
    Q = add(Ppt, _to_affine(mul(t)))
    return Q[0].to_bytes(32, 'big')
