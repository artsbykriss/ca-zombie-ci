#!/usr/bin/env python3
"""
Independent verification that every CBTC (Canton) Bitcoin deposit address is a
P2TR output whose script leaf is the constant `<group_xonly> OP_CHECKSIG`
threshold key and whose key path is a NUMS-derived unspendable key.

Reimplements DLC-link/cbtc-por-tools/calculate-bitcoin-addresses.ts and asserts
that the derived addresses equal the operator-reported ones. No trust in the
reported `address_for_verification` field. Dependency-free (see ec.py).

Reads the API response from analysis/cbtc_addresses_api.json (falls back to the
live endpoint).
"""
import hashlib, hmac, json, os, sys, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ec

HERE = os.path.dirname(os.path.abspath(__file__))
API = "https://api.mainnet.bitsafe.finance/cbtc/v1/address-calculation-data"
# BIP-341 NUMS key H (provably unspendable; no known discrete log)
NUMS = bytes.fromhex("0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0")

def load():
    p = os.path.join(HERE, "cbtc_addresses_api.json")
    if os.path.exists(p):
        return json.load(open(p))
    req = urllib.request.Request(API, headers={"User-Agent": "verify/1.0"})
    return json.loads(urllib.request.urlopen(req, timeout=30).read())

def b58dec(s):
    A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"; n = 0
    for c in s: n = n * 58 + A.index(c)
    return b'\x00' * (len(s) - len(s.lstrip('1'))) + n.to_bytes((n.bit_length() + 7) // 8, 'big')

def tag(t, d):
    th = hashlib.sha256(t.encode()).digest()
    return hashlib.sha256(th + th + d).digest()

def ckd(pub33, cc, idx):
    I = hmac.new(cc, pub33 + idx.to_bytes(4, 'big'), hashlib.sha512).digest()
    child = ec.add(ec.parse_pub(pub33), ec.mul_affine(int.from_bytes(I[:32], "big")))
    return ec.ser_p(child), I[32:]

def internal_key(dep_id):
    p, c = ckd(NUMS, hashlib.sha256(dep_id.encode()).digest(), 0)
    p, c = ckd(p, c, 0)
    return p[1:]

CH = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
def _pm(v):
    G = [0x3b6a57b2,0x26508e6d,0x1ea119fa,0x3d4233dd,0x2a1462b3]; chk = 1
    for x in v:
        b = chk >> 25; chk = (chk & 0x1ffffff) << 5 ^ x
        for i in range(5): chk ^= G[i] if ((b >> i) & 1) else 0
    return chk
def _he(h): return [ord(x) >> 5 for x in h] + [0] + [ord(x) & 31 for x in h]
def _cb(d, f, t):
    a = b = 0; r = []; m = (1 << t) - 1
    for v in d:
        a = (a << f) | v; b += f
        while b >= t: b -= t; r.append((a >> b) & m)
    if b: r.append((a << (t - b)) & m)
    return r
def p2tr(x):
    d = [1] + _cb(list(x), 8, 5); v = _he("bc") + d
    pm = _pm(v + [0] * 6) ^ 0x2bc830a3
    chk = [(pm >> 5 * (5 - i)) & 31 for i in range(6)]
    return "bc1" + ''.join(CH[q] for q in d + chk)

def addr(dep_id, leafh):
    Px = internal_key(dep_id)
    Qx = ec.xonly_tweak(Px, tag("TapTweak", Px + leafh))
    return None if Qx is None else p2tr(Qx)

def main():
    data = load()
    ok = 0; bad = []
    for c in data["chains"]:
        gx = b58dec(c["xpub"])[45:78][1:]
        script = bytes([32]) + gx + bytes([0xac])
        leafh = tag("TapLeaf", bytes([0xc0]) + bytes([len(script)]) + script)
        print(f"chain={c['chain']} n={len(c['addresses'])} group_xonly={gx.hex()}")
        print(f"  tapscript={script.hex()}")
        for a in c["addresses"]:
            got = addr(a["id"], leafh)
            if got == a["address_for_verification"]: ok += 1
            else: bad.append((a["id"][:24], a["address_for_verification"], got))
    tot = sum(len(c["addresses"]) for c in data["chains"])
    print(f"MATCH {ok}/{tot}")
    for b in bad[:10]: print("MISMATCH", b)
    sys.exit(0 if ok == tot else 1)

if __name__ == "__main__":
    main()
