#!/usr/bin/env python3
"""Derive an Alephium contract address from a contract id (base58 of [0x03]+id).
Mirrors DefiLlama helper projects/helper/chain/alephium.js addressFromContractId."""
import sys

B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

def b58encode(b: bytes) -> str:
    n = int.from_bytes(b, "big")
    out = ""
    while n > 0:
        n, r = divmod(n, 58)
        out = B58[r] + out
    # leading zero bytes
    for byte in b:
        if byte == 0:
            out = "1" + out
        else:
            break
    return out

def address_from_contract_id(cid_hex: str) -> str:
    raw = bytes.fromhex(cid_hex)
    assert len(raw) == 32, f"contract id must be 32 bytes, got {len(raw)}"
    return b58encode(b"\x03" + raw)

def contract_id_from_address(addr: str) -> str:
    n = 0
    for ch in addr:
        n = n * 58 + B58.index(ch)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big")
    # leading '1's are zero bytes
    pad = len(addr) - len(addr.lstrip("1"))
    b = b"\x00" * pad + b
    assert b[0] == 0x03, f"not a contract address (type byte {b[0]:#x})"
    return b[1:].hex()

if __name__ == "__main__":
    if len(sys.argv) > 1:
        arg = sys.argv[1]
    else:
        arg = "6dc961b59aae53c768fe6f608e6bea30f6747041af3fd800c8c6533766e54f00"
    if arg.startswith("0x") or (len(arg) == 64 and all(c in "0123456789abcdefABCDEF" for c in arg)):
        addr = address_from_contract_id(arg)
        print(addr)
        # round trip
        assert contract_id_from_address(addr) == arg.lower()
    else:
        print(contract_id_from_address(arg))
