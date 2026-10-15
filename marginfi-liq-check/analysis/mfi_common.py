#!/usr/bin/env python3
"""Shared helpers for marginfi liquidation-realisability analysis.
Read-only Solana RPC. No secrets (public endpoints only).
"""
import base64, json, os, struct, sys, time, urllib.request

PROGRAM = "MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA"
I80F48 = float(1 << 48)
RPC_ENDPOINTS = [
    os.environ.get("SOLANA_RPC", ""),
    "https://api.mainnet-beta.solana.com",
    "https://solana-rpc.publicnode.com",
]
RPC_ENDPOINTS = [e for e in RPC_ENDPOINTS if e]

_B58_ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
_B58_MAP = {c: i for i, c in enumerate(_B58_ALPHABET)}


def b58decode(s: str) -> bytes:
    n = 0
    for c in s:
        n = n * 58 + _B58_MAP[c]
    b = n.to_bytes((n.bit_length() + 7) // 8, "big") if n else b""
    pad = len(s) - len(s.lstrip("1"))
    return b"\x00" * pad + b


def b58encode(b: bytes) -> str:
    n = int.from_bytes(b, "big")
    out = ""
    while n:
        n, r = divmod(n, 58)
        out = _B58_ALPHABET[r] + out
    pad = len(b) - len(b.lstrip(b"\x00"))
    return "1" * pad + (out or "")


def rpc(method, params, tries=6, timeout=90):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for i in range(tries):
        ep = RPC_ENDPOINTS[i % len(RPC_ENDPOINTS)]
        try:
            req = urllib.request.Request(ep, data=body, headers={"Content-Type": "application/json",
                                                                 "User-Agent": "Mozilla/5.0 research"})
            with urllib.request.urlopen(req, timeout=timeout) as f:
                r = json.load(f)
            if "error" in r:
                last = r["error"]
                time.sleep(1 + i)
                continue
            return r["result"]
        except urllib.error.HTTPError as e:
            last = f"HTTP {e.code}"
            time.sleep(5 + 5 * i)          # rate limits: back off harder
        except Exception as e:
            last = str(e)
            time.sleep(1 + 2 * i)
    raise RuntimeError(f"rpc {method} failed: {last}")


def get_accounts(pubkeys, offset=None, length=None):
    """getMultipleAccounts; returns list of (pubkey, lamports, owner, data_bytes) or None."""
    out = []
    cfg = {"encoding": "base64"}
    if offset is not None:
        cfg["dataSlice"] = {"offset": offset, "length": length}
    for i in range(0, len(pubkeys), 100):
        chunk = pubkeys[i:i + 100]
        res = rpc("getMultipleAccounts", [chunk, cfg])
        for pk, v in zip(chunk, res["value"]):
            if v is None:
                out.append(None)
            else:
                out.append((pk, v["lamports"], v["owner"], base64.b64decode(v["data"][0])))
    return out


def i80(b: bytes) -> float:
    return int.from_bytes(b, "little", signed=True) / I80F48


def decode_balances(raw: bytes, base: int = 72):
    """Balances region of a MarginfiAccount (16 x 104 bytes). Returns list of dicts."""
    out = []
    for i in range(16):
        o = base + i * 104
        if o + 104 > len(raw):
            break
        if not raw[o]:
            continue
        bank = b58encode(raw[o + 1:o + 33])
        bank_asset_tag = raw[o + 33]
        # tag u16 at 34, premium_rate u32 at 36, shares at 40/56, premium_outstanding 72, last_update 88
        a = i80(raw[o + 40:o + 56])
        l = i80(raw[o + 56:o + 72])
        prem = i80(raw[o + 72:o + 88])
        out.append({"bank": bank, "bank_asset_tag": bank_asset_tag, "asset_shares": a,
                    "liability_shares": l, "premium_outstanding": prem,
                    "last_update": struct.unpack_from("<Q", raw, o + 88)[0]})
    return out


def pda(seeds, program=PROGRAM):
    prog_bytes = b58decode(program)
    for bump in range(255, -1, -1):
        data = b"".join(seeds) + bytes([bump]) + prog_bytes + b"ProgramDerivedAddress"
        import hashlib
        h = hashlib.sha256(data).digest()
        if not on_curve(h):
            return b58encode(h), bump
    raise RuntimeError("no pda")


# --- ed25519 on-curve check (for PDA derivation) ---
_P = 2 ** 255 - 19
_D = (-121665 * pow(121666, _P - 2, _P)) % _P
_I = pow(2, (_P - 1) // 4, _P)


def _recover_x(y, sign):
    if y >= _P:
        return None
    xx = (y * y - 1) * pow(_D * y * y + 1, _P - 2, _P)
    x = pow(xx, (_P + 3) // 8, _P)
    if (x * x - xx) % _P != 0:
        x = (x * _I) % _P
    if (x * x - xx) % _P != 0:
        return None
    if x % 2 != sign:
        x = _P - x
    return x


def on_curve(b: bytes) -> bool:
    if len(b) != 32:
        return False
    y = int.from_bytes(b, "little") & ((1 << 255) - 1)
    sign = b[31] >> 7
    return _recover_x(y, sign) is not None


if __name__ == "__main__":
    print("slot", rpc("getSlot", []))
    print("pda liquidity_vault_auth", pda([b"liquidity_vault_auth", b58decode("CCKtUs6Cgwo4aaQUmBPmyoApH2gUDErxNZCAntD6LYGh")]))
