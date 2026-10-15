#!/usr/bin/env python3
"""Read-only Solana helpers: base58, PDA derivation, RPC via public endpoints."""
import json, subprocess, base64, hashlib, struct, time

ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

def b58encode(b: bytes) -> str:
    n = int.from_bytes(b, "big")
    res = ""
    while n:
        n, r = divmod(n, 58)
        res = ALPHABET[r] + res
    pad = 0
    for c in b:
        if c == 0:
            pad += 1
        else:
            break
    return "1" * pad + res

def b58decode(s: str) -> bytes:
    n = 0
    for c in s:
        n = n * 58 + ALPHABET.index(c)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big") if n else b""
    pad = 0
    for c in s:
        if c == "1":
            pad += 1
        else:
            break
    return b"\x00" * pad + b

RPC_LIST = [
    "https://solana-rpc.publicnode.com",
    "https://api.mainnet-beta.solana.com",
    "https://solana.api.onfinality.io/public",
    "https://rpc.ankr.com/solana",
]

def rpc(method, params, _tries=4):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
    last = None
    for attempt in range(_tries):
        for u in RPC_LIST:
            try:
                out = subprocess.run(
                    ["curl", "-s", "-m", "40", "-X", "POST", u, "-H", "Content-Type: application/json", "-d", body],
                    capture_output=True, text=True, timeout=50)
                last = out.stdout
                d = json.loads(last)
                if "result" in d:
                    return d["result"]
            except Exception as e:
                last = str(e)
        time.sleep(2 + attempt * 2)
    raise RuntimeError(f"RPC failed: {method} {params}: {last}")

def get_account(pubkey, encoding="base64"):
    r = rpc("getAccountInfo", [pubkey, {"encoding": encoding}])
    return r["value"]

def get_data(pubkey):
    v = get_account(pubkey)
    if v is None:
        return None, None
    return v["owner"], base64.b64decode(v["data"][0])

def pda(seeds, program_id):
    pid = b58decode(program_id)
    marker = b"ProgramDerivedAddress"
    for bump in range(255, -1, -1):
        h = hashlib.sha256(b"".join(seeds) + bytes([bump]) + pid + marker).digest()
        if not on_curve(h):
            return b58encode(h), bump
    raise ValueError("no pda")

# --- ed25519 on-curve check (RFC 8032 decompression) ---
P = 2**255 - 19
D = (-121665 * pow(121666, P - 2, P)) % P
SQRT_M1 = pow(2, (P - 1) // 4, P)

def on_curve(comp: bytes) -> bool:
    """True if the 32-byte compressed Edwards-Y point decompresses to a curve point."""
    if len(comp) != 32:
        return False
    y = int.from_bytes(comp, "little")
    sign = (y >> 255) & 1
    y &= (1 << 255) - 1
    if y >= P:
        return False
    yy = (y * y) % P
    u = (yy - 1) % P
    v = (D * yy + 1) % P
    if v == 0:
        return False
    inv_v = pow(v, P - 2, P)
    x2 = (u * inv_v) % P
    x = pow(x2, (P + 3) // 8, P)
    if (x * x) % P != x2:
        x = (x * SQRT_M1) % P
    if (x * x) % P != x2:
        return False
    if x == 0 and sign == 1:
        return False
    return True

def _selftest():
    # ed25519 base point compressed
    bp = bytes.fromhex("5866666666666666666666666666666666666666666666666666666666666666")
    assert on_curve(bp), "base point must be on curve"
    # identity (y=1, x=0): 0x01 followed by zeros
    ident = b"\x01" + b"\x00" * 31
    assert on_curve(ident), "identity must be on curve"
    # all 0xff: y >= P
    assert not on_curve(b"\xff" * 32)
    # base point with sign bit set (x sign=1) still on curve
    bp_sign = bytearray(bp); bp_sign[31] |= 0x80
    assert on_curve(bytes(bp_sign))
    return True

_selftest()

def create_with_seed(base, seed, program_id):
    if len(seed) > 32:
        raise ValueError("seed too long")
    return b58encode(hashlib.sha256(base + seed + program_id).digest())
