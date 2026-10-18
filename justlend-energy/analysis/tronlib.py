#!/usr/bin/env python3
"""Read-only TRON helper for the JustLend Energy Rental (MarketG1) review.

No keys. Public TronGrid / Tronscan endpoints only. Never sends a transaction:
only `getnowblock`, `getcontract`, `getaccount`, `triggerconstantcontract`
(simulation, no broadcast) and v1 read endpoints.
"""
import json, time, urllib.request, urllib.error
from hashlib import sha256

ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

def b58decode(s: str) -> bytes:
    n = 0
    for ch in s:
        n = n * 58 + ALPHABET.index(ch)
    raw = n.to_bytes((n.bit_length() + 7) // 8, "big")
    pad = 0
    for ch in s:
        if ch == "1":
            pad += 1
        else:
            break
    return b"\x00" * pad + raw

def b58encode(b: bytes) -> str:
    n = int.from_bytes(b, "big")
    out = ""
    while n:
        n, r = divmod(n, 58)
        out = ALPHABET[r] + out
    pad = 0
    for byte in b:
        if byte == 0:
            pad += 1
        else:
            break
    return "1" * pad + out

def addr_hex(a: str) -> str:
    """Base58 TRON address (25 bytes incl. 4-byte checksum) -> 41-prefixed 21-byte hex."""
    return b58decode(a)[:21].hex()

def addr20(a: str) -> str:
    return addr_hex(a)[2:]

def hex_to_b58(h: str) -> str:
    h = h.lower().replace("0x", "")
    if len(h) == 40:
        h = "41" + h
    raw = bytes.fromhex(h)
    chk = sha256(sha256(raw).digest()).digest()[:4]
    return b58encode(raw + chk)

def keccak256(data: bytes) -> bytes:
    try:
        import sha3
        return sha3.keccak_256(data).digest()
    except Exception:
        from Crypto.Hash import keccak
        k = keccak.new(digest_bits=256); k.update(data); return k.digest()

def selector(sig: str) -> str:
    return keccak256(sig.encode()).hex()[:8]

def enc_uint(v: int) -> str:
    return format(v, "064x")

def enc_addr(a: str) -> str:
    return "0" * 24 + addr20(a)

def enc_bool(v: bool) -> str:
    return enc_uint(1 if v else 0)

def rpc(path: str, payload=None, tries=5):
    url = "https://api.trongrid.io" + path
    data = None if payload is None else json.dumps(payload).encode()
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(url, data=data,
                                         headers={"Content-Type": "application/json",
                                                  "Accept": "application/json"})
            with urllib.request.urlopen(req, timeout=45) as r:
                return json.loads(r.read().decode())
        except Exception as e:
            last = e
            time.sleep(1.5 * (i + 1))
    raise last

def constant(contract: str, sig: str, args_hex: str = "", owner: str = "TU2MJ5Veik1LRAgjeSzEdvmDYx7mefJZvd"):
    """triggerconstantcontract: executes read-only, never broadcasts."""
    return rpc("/wallet/triggerconstantcontract", {
        "owner_address": owner,
        "contract_address": contract,
        "function_selector": sig,
        "parameter": args_hex,
        "visible": True,
    })

def call_uint(contract, sig, args_hex="", owner="TU2MJ5Veik1LRAgjeSzEdvmDYx7mefJZvd"):
    r = constant(contract, sig, args_hex, owner)
    res = r.get("constant_result") or []
    if not res or res[0] == "":
        return {"ok": False, "raw": r}
    return {"ok": True, "value": int(res[0], 16), "raw": r}

def call_multi(contract, sig, args_hex="", n=3):
    r = constant(contract, sig, args_hex)
    res = (r.get("constant_result") or [""])[0]
    if not res:
        return {"ok": False, "raw": r}
    words = [res[i:i+64] for i in range(0, len(res), 64)]
    return {"ok": True, "values": [int(w, 16) for w in words[:n]], "raw": r}

def now_block():
    r = rpc("/wallet/getnowblock")
    return {"number": r["block_header"]["raw_data"]["number"],
            "timestamp": r["block_header"]["raw_data"]["timestamp"] // 1000,
            "blockID": r.get("blockID")}

if __name__ == "__main__":
    print(now_block())
    print("selector rentResource", selector("rentResource(address,uint256,uint256)"))
