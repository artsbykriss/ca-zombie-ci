#!/usr/bin/env python3
"""Minimal bech32m encode/decode for Radix addresses (offline utility)."""
CHARSET = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"

def bech32_polymod(values):
    GEN = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3]
    chk = 1
    for v in values:
        b = chk >> 25
        chk = (chk & 0x1ffffff) << 5 ^ v
        for i in range(5):
            chk ^= GEN[i] if ((b >> i) & 1) else 0
    return chk

def hrp_expand(hrp):
    return [ord(x) >> 5 for x in hrp] + [0] + [ord(x) & 31 for x in hrp]

def convertbits(data, frombits, tobits, pad=True):
    acc = 0; bits = 0; ret = []
    maxv = (1 << tobits) - 1
    for value in data:
        acc = (acc << frombits) | value
        bits += frombits
        while bits >= tobits:
            bits -= tobits
            ret.append((acc >> bits) & maxv)
    if pad and bits:
        ret.append((acc << (tobits - bits)) & maxv)
    return ret

def encode(hrp, data_bytes, const=0x2bc830a3):
    data5 = convertbits(list(data_bytes), 8, 5)
    values = hrp_expand(hrp) + data5
    polymod = bech32_polymod(values + [0, 0, 0, 0, 0, 0]) ^ const
    checksum = [(polymod >> 5 * (5 - i)) & 31 for i in range(6)]
    return hrp + '1' + ''.join(CHARSET[d] for d in data5 + checksum)

def decode(addr):
    pos = addr.rfind('1')
    hrp, data = addr[:pos], addr[pos + 1:]
    vals = [CHARSET.find(c) for c in data]
    assert bech32_polymod(hrp_expand(hrp) + vals) in (1, 0x2bc830a3), "bad checksum"
    data5 = vals[:-6]
    return hrp, bytes(convertbits(data5, 5, 8, pad=False))

if __name__ == "__main__":
    import sys
    for a in sys.argv[1:]:
        hrp, b = decode(a)
        print(f"{a[:40]:42s} hrp={hrp:28s} type_byte=0x{b[0]:02x} len={len(b)} hex={b.hex()}")
