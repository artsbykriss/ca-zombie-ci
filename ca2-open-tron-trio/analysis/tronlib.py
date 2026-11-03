#!/usr/bin/env python3
"""Small read-only Tron HTTP helpers (TronGrid public, keyless).

- base58check encode/decode (Tron 0x41-prefixed addresses)
- wallet/getnowblock, wallet/getaccount, wallet/getcontract
- wallet/triggerconstantcontract (TVM simulation, no broadcast/state commit)
- TronGrid v1 event pagination
No signing / no transaction broadcast anywhere in this file.
"""
import hashlib
import json
import os
import time

import requests

BASE = "https://api.trongrid.io"
HEAD = {"Content-Type": "application/json", "User-Agent": "ca2-tron-research/1.0"}
ALPH = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"


def b58encode(b: bytes) -> str:
    n = int.from_bytes(b, "big")
    out = ""
    while n:
        n, r = divmod(n, 58)
        out = ALPH[r] + out
    pad = 0
    for c in b:
        if c == 0:
            pad += 1
        else:
            break
    return ALPH[0] * pad + out


def b58decode(s: str) -> bytes:
    n = 0
    for c in s:
        n = n * 58 + ALPH.index(c)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big")
    pad = 0
    for c in s:
        if c == ALPH[0]:
            pad += 1
        else:
            break
    return b"\x00" * pad + b


def b58check_encode(payload: bytes) -> str:
    chk = hashlib.sha256(hashlib.sha256(payload).digest()).digest()[:4]
    return b58encode(payload + chk)


def b58check_decode(s: str) -> bytes:
    raw = b58decode(s)
    payload, chk = raw[:-4], raw[-4:]
    assert hashlib.sha256(hashlib.sha256(payload).digest()).digest()[:4] == chk, "bad checksum"
    return payload


def addr_to_hex(a: str) -> str:
    p = b58check_decode(a)
    assert p[0] == 0x41 and len(p) == 21, p.hex()
    return p[1:].hex()


def hex_to_addr(h: str) -> str:
    h = h.replace("0x", "")
    return b58check_encode(bytes.fromhex("41" + h[-40:]))


def fresh_address(seed: str = "ca2-open-tron-trio/probe/fresh-1") -> str:
    """Deterministic, unspendable probe address (no private key is used)."""
    h = hashlib.sha256(seed.encode()).digest()
    return b58check_encode(b"\x41" + h[:20])


def post(path, payload, tries=8, base=BASE, quiet=False):
    delay = 2
    last = None
    for i in range(tries):
        try:
            r = requests.post(base + path, json=payload, headers=HEAD, timeout=40)
            if r.status_code == 200:
                j = r.json()
                return j
            last = f"HTTP {r.status_code}: {r.text[:160]}"
        except Exception as e:  # noqa: BLE001
            last = str(e)[:160]
        if not quiet:
            print(f"  retry {i+1}/{tries} {path}: {last}")
        time.sleep(delay)
        delay = min(delay * 2, 45)
    raise RuntimeError(f"{path} failed: {last}")


def get(path, params, tries=8, base=BASE):
    delay = 2
    last = None
    for i in range(tries):
        try:
            r = requests.get(base + path, params=params, headers=HEAD, timeout=40)
            if r.status_code == 200:
                return r.json()
            last = f"HTTP {r.status_code}: {r.text[:160]}"
        except Exception as e:  # noqa: BLE001
            last = str(e)[:160]
        print(f"  retry {i+1}/{tries} {path}: {last}")
        time.sleep(delay)
        delay = min(delay * 2, 45)
    raise RuntimeError(f"{path} failed: {last}")


def now_block():
    j = post("/wallet/getnowblock", {})
    return j["block_header"]["raw_data"]["number"]


def get_account(addr):
    return post("/wallet/getaccount", {"address": addr, "visible": True})


def trigger(owner, contract, selector, parameter="", call_value=0, fee_limit=100000000):
    payload = {
        "owner_address": owner,
        "contract_address": contract,
        "function_selector": selector,
        "parameter": parameter,
        "visible": True,
        "call_value": call_value,
        "fee_limit": fee_limit,
    }
    return post("/wallet/triggerconstantcontract", payload)


def events(contract, event_name=None, limit=200, fingerprint=None, only_confirmed=False):
    params = {"limit": limit, "only_confirmed": str(only_confirmed).lower()}
    if event_name:
        params["event_name"] = event_name
    if fingerprint:
        params["fingerprint"] = fingerprint
    return get(f"/v1/contracts/{contract}/events", params)


def hardhat_selector(sig):
    import subprocess
    return subprocess.check_output(["cast", "sig", sig], text=True).strip()


def enc_uint(v):
    return f"{int(v):064x}"


def enc_addr(a):
    return "0" * 24 + addr_to_hex(a)


def enc_words(*words):
    return "".join(words)


if __name__ == "__main__":
    print("fresh:", fresh_address())
    print("hex:", addr_to_hex(fresh_address()))
    print("block:", now_block())
