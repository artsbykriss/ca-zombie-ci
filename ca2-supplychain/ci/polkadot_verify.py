#!/usr/bin/env python3
"""Read-only verification of the Fearless Wallet reported victim transactions.

Reads cases.json and accounts.json next to this script. Uses public Polkadot /
AssetHub RPCs. No keys, no transactions. Dependencies: requests + stdlib only.
"""
import hashlib, json, os, time
import requests

HERE = os.path.dirname(os.path.abspath(__file__))
RELAY = "https://polkadot.publicnode.com"
ASSET = "https://polkadot-asset-hub-rpc.polkadot.io"

# ---------- pure-python xxhash64 (for Substrate twox128) ----------
MASK = (1 << 64) - 1
P1 = 0x9E3779B185EBCA87
P2 = 0xC2B2AE3D27D4EB4F
P3 = 0x165667B19E3779F9
P4 = 0x85EBCA77C2B2AE63
P5 = 0x27D4EB2F165667C5

def _rotl(x, r):
    return ((x << r) | (x >> (64 - r))) & MASK

def _round(acc, val):
    acc = (acc + val * P2) & MASK
    acc = _rotl(acc, 31)
    return (acc * P1) & MASK

def _merge(acc, val):
    val = _round(0, val)
    acc ^= val
    return (acc * P1 + P4) & MASK

def xxh64(data: bytes, seed: int = 0) -> int:
    n = len(data)
    i = 0
    if n >= 32:
        v1 = (seed + P1 + P2) & MASK
        v2 = (seed + P2) & MASK
        v3 = seed & MASK
        v4 = (seed - P1) & MASK
        while i <= n - 32:
            v1 = _round(v1, int.from_bytes(data[i:i+8], "little")); i += 8
            v2 = _round(v2, int.from_bytes(data[i:i+8], "little")); i += 8
            v3 = _round(v3, int.from_bytes(data[i:i+8], "little")); i += 8
            v4 = _round(v4, int.from_bytes(data[i:i+8], "little")); i += 8
        h = (_rotl(v1, 1) + _rotl(v2, 7) + _rotl(v3, 12) + _rotl(v4, 18)) & MASK
        h = _merge(h, v1); h = _merge(h, v2); h = _merge(h, v3); h = _merge(h, v4)
    else:
        h = (seed + P5) & MASK
    h = (h + n) & MASK
    while i <= n - 8:
        k = _round(0, int.from_bytes(data[i:i+8], "little"))
        h ^= k
        h = (_rotl(h, 27) * P1 + P4) & MASK
        i += 8
    if i <= n - 4:
        h ^= (int.from_bytes(data[i:i+4], "little") * P1) & MASK
        h = (_rotl(h, 23) * P2 + P3) & MASK
        i += 4
    while i < n:
        h ^= (data[i] * P5) & MASK
        h = (_rotl(h, 11) * P1) & MASK
        i += 1
    h ^= h >> 33
    h = (h * P2) & MASK
    h ^= h >> 29
    h = (h * P3) & MASK
    h ^= h >> 32
    return h & MASK

def xxh64_bytes(data: bytes, seed: int) -> bytes:
    return xxh64(data, seed).to_bytes(8, "little")

def twox128(name: str) -> bytes:
    b = name.encode()
    return xxh64_bytes(b, 0) + xxh64_bytes(b, 1)

def blake2_128_concat(data: bytes) -> bytes:
    return hashlib.blake2b(data, digest_size=16).digest() + data

# ---------- pure-python base58 ----------
B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

def b58encode(b: bytes) -> str:
    n = int.from_bytes(b, "big")
    s = ""
    while n:
        n, r = divmod(n, 58)
        s = B58[r] + s
    pad = len(b) - len(b.lstrip(b"\x00"))
    return "1" * pad + s

def b58decode(s: str) -> bytes:
    n = 0
    for c in s:
        n = n * 58 + B58.index(c)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big") if n else b""
    pad = len(s) - len(s.lstrip("1"))
    return b"\x00" * pad + b

# ---------- RPC ----------
def rpc(url, method, params=None):
    if params is None:
        params = []
    last = None
    for attempt in range(6):
        try:
            r = requests.post(url, json={"jsonrpc": "2.0", "id": 1, "method": method, "params": params}, timeout=45)
            r.raise_for_status()
            j = r.json()
            if "error" in j:
                raise RuntimeError(f"{method}: {j['error']}")
            return j["result"]
        except Exception as e:
            last = e
            time.sleep(2 + attempt * 2)
    raise last

def block_at(url, number):
    h = rpc(url, "chain_getBlockHash", [number])
    return h, rpc(url, "chain_getBlock", [h])

def ext_hash(ext_hex: str) -> str:
    raw = ext_hex[2:] if ext_hex.startswith("0x") else ext_hex
    return "0x" + hashlib.blake2b(bytes.fromhex(raw), digest_size=32).hexdigest()

def compact_at(b: bytes, off: int):
    first = b[off]
    mode = first & 3
    if mode == 0:
        return first >> 2, off + 1
    if mode == 1:
        return int.from_bytes(b[off:off+2], "little") >> 2, off + 2
    if mode == 2:
        return int.from_bytes(b[off:off+4], "little") >> 2, off + 4
    ln = (first >> 2) + 4
    return int.from_bytes(b[off+1:off+1+ln], "little"), off + 1 + ln

def ss58(acct_hex: str) -> str:
    raw = bytes.fromhex(acct_hex[2:] if acct_hex.startswith("0x") else acct_hex)
    payload = b"\x00" + raw
    chk = hashlib.blake2b(b"SS58PRE" + payload, digest_size=64).digest()[:2]
    return b58encode(payload + chk)

def parse_ext(ext_hex: str):
    b = bytes.fromhex(ext_hex[2:] if ext_hex.startswith("0x") else ext_hex)
    declared, off = compact_at(b, 0)
    out = {"len": len(b), "declared_len": declared}
    out["version"] = b[off] & 0x7f
    out["signed"] = bool(b[off] & 0x80)
    off += 1
    if out["signed"]:
        assert b[off] == 0
        out["signer_hex"] = "0x" + b[off+1:off+33].hex()
        out["signer_ss58"] = ss58(out["signer_hex"])
        off += 33 + 1 + 64
        off += 1 if b[off] == 0 else 2
        nonce, off = compact_at(b, off)
        tip, off = compact_at(b, off)
        out["nonce"] = nonce
        out["tip"] = tip
    out["call_offset"] = off
    out["call_bytes"] = b[off:off+4].hex()
    cands = []
    for start in range(max(off, len(b) - 24), len(b)):
        try:
            v, e = compact_at(b, start)
            if e == len(b):
                cands.append(v)
        except Exception:
            pass
    out["tail_compact_candidates"] = sorted(set(cands))[:8]
    return out

def to_hex(ss58_or_hex):
    if ss58_or_hex.startswith("0x"):
        return ss58_or_hex
    raw = b58decode(ss58_or_hex)
    return "0x" + (raw[1:33].hex() if len(raw) == 35 else raw[2:34].hex())

def account_key(account_id_hex: str) -> bytes:
    acct = bytes.fromhex(account_id_hex[2:] if account_id_hex.startswith("0x") else account_id_hex)
    return twox128("System") + twox128("Account") + blake2_128_concat(acct)

def assets_account_key(asset_id: int, account_id_hex: str) -> bytes:
    acct = bytes.fromhex(account_id_hex[2:] if account_id_hex.startswith("0x") else account_id_hex)
    return (twox128("Assets") + twox128("Account")
            + blake2_128_concat(asset_id.to_bytes(4, "little"))
            + blake2_128_concat(acct))

def native_balance(url, ss58_or_hex):
    key = account_key(to_hex(ss58_or_hex))
    res = rpc(url, "state_getStorage", [("0x" + key.hex()), None])
    if not res:
        return {"account": ss58_or_hex, "free_planck": 0, "free_dot": 0.0, "raw": None}
    b = bytes.fromhex(res[2:])
    free = int.from_bytes(b[16:32], "little") if len(b) >= 32 else 0
    return {"account": ss58_or_hex, "free_planck": free, "free_dot": free / 1e10, "raw_len": len(b)}

def ded_balance(url, ss58_or_hex):
    key = assets_account_key(30, to_hex(ss58_or_hex))
    res = rpc(url, "state_getStorage", [("0x" + key.hex()), None])
    if not res:
        return {"account": ss58_or_hex, "balance_raw": 0, "balance": 0.0, "raw": None}
    b = bytes.fromhex(res[2:])
    bal = int.from_bytes(b[:16], "little")
    return {"account": ss58_or_hex, "balance_raw": bal, "balance": bal / 1e10, "raw_len": len(b)}

def main():
    cases = json.load(open(os.path.join(HERE, "cases.json")))
    accounts = json.load(open(os.path.join(HERE, "accounts.json")))
    out = {"rpc": {"relay": RELAY, "asset": ASSET}, "cases": [], "balances": {}, "heads": {}}
    out["heads"]["relay"] = int(rpc(RELAY, "chain_getHeader")["number"], 16)
    out["heads"]["asset"] = int(rpc(ASSET, "chain_getHeader")["number"], 16)
    for c in cases:
        url = RELAY if c["chain"] == "relay" else ASSET
        h, blk = block_at(url, int(c["block"]))
        found = None
        for i, e in enumerate(blk["block"]["extrinsics"]):
            if ext_hash(e) == c["hash"]:
                found = {"index": i, "parsed": parse_ext(e)}
                break
        rec = dict(c)
        rec["block_hash"] = h
        rec["found"] = bool(found)
        if found:
            rec["extrinsic_index"] = found["index"]
            rec["parsed"] = found["parsed"]
            rec["signer_matches_source"] = (found["parsed"].get("signer_ss58") == c["source"])
            expected_raw = int(round(c["amount"] * 1e10))
            rec["amount_verified_in_call"] = expected_raw in found["parsed"].get("tail_compact_candidates", [])
        out["cases"].append(rec)
    for a in accounts:
        chain = a["chain"]
        url = RELAY if chain == "relay" else ASSET
        rec = {"chain": chain, "native": native_balance(url, a["account"])}
        if chain == "asset" and a.get("ded", False):
            rec["ded"] = ded_balance(url, a["account"])
        out["balances"][a["account"]] = rec
    print(json.dumps(out, indent=2, sort_keys=True))

if __name__ == "__main__":
    main()
