"""Minimal pure-python base58 (Bitcoin alphabet), API-compatible with the `base58` package:
b58encode(bytes)->bytes, b58decode(str|bytes)->bytes."""
_ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
_INDEX = {c: i for i, c in enumerate(_ALPHABET)}

def b58encode(data):
    if isinstance(data, str):
        data = data.encode()
    data = bytes(data)
    if not data:
        return b""
    n = int.from_bytes(data, "big")
    out = ""
    while n > 0:
        n, r = divmod(n, 58)
        out = _ALPHABET[r] + out
    pad = 0
    for b in data:
        if b == 0:
            pad += 1
        else:
            break
    return ("1" * pad + out).encode()

def b58decode(s):
    if isinstance(s, bytes):
        s = s.decode()
    if s == "":
        return b""
    n = 0
    for c in s:
        n = n * 58 + _INDEX[c]
    full = n.to_bytes((n.bit_length() + 7) // 8, "big") if n else b""
    pad = 0
    for c in s:
        if c == "1":
            pad += 1
        else:
            break
    return b"\x00" * pad + full
