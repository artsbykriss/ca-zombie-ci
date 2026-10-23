#!/usr/bin/env python3
# Decode lddw 64-bit immediates (as printed by sbpf disassemble) into pubkey bytes / base58.
# lddw rX, imm  loads imm into a register; when the compiler materialises a 32-byte
# pubkey it emits 4 consecutive lddw with little-endian 8-byte chunks.
import struct, sys

A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

def b58e(b: bytes) -> str:
    n = int.from_bytes(b, "big")
    s = ""
    while n:
        n, r = divmod(n, 58)
        s = A[r] + s
    pad = len(b) - len(b.lstrip(b"\x00"))
    return "1" * pad + s

def parse_imm(tok: str) -> int:
    tok = tok.strip()
    neg = tok.startswith("-")
    if neg:
        tok = tok[1:]
    v = int(tok, 16)
    if neg:
        v = (-v) & 0xFFFFFFFFFFFFFFFF
    return v

def quad_to_key(words):
    b = b"".join(struct.pack("<Q", w) for w in words)
    return b, b58e(b)

if __name__ == "__main__":
    # Accept 4 immediates on argv, or lines "addr: lddw rX, imm"
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    if len(args) >= 4:
        words = [parse_imm(a) for a in args[:4]]
        b, s = quad_to_key(words)
        print("hex:", b.hex())
        print("b58:", s)
