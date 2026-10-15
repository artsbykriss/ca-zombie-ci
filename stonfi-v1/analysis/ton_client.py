#!/usr/bin/env python3
"""Minimal TON client helpers for the STON.fi v1 audit (read-only, keyless endpoints).

Uses toncenter v3 (keyless, rate-limited) and tonapi.io v2 (keyless).
No secrets. No transactions are ever sent.
"""
import json
import time
import urllib.request
import urllib.parse

TC = "https://toncenter.com/api/v3"
TA = "https://tonapi.io/v2"
UA = {"User-Agent": "zombie-hunt-research/1.0"}


def _get(url, tries=6, base_sleep=1.5):
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=40) as r:
                return json.loads(r.read().decode())
        except Exception as e:  # noqa
            last = e
            time.sleep(base_sleep * (i + 1))
    raise RuntimeError(f"GET failed: {url}: {last}")


def _post(url, payload, tries=6, base_sleep=1.5):
    last = None
    for i in range(tries):
        try:
            data = json.dumps(payload).encode()
            req = urllib.request.Request(url, data=data, headers={**UA, "Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=40) as r:
                return json.loads(r.read().decode())
        except Exception as e:  # noqa
            last = e
            time.sleep(base_sleep * (i + 1))
    raise RuntimeError(f"POST failed: {url}: {last}")


def masterchain_head():
    return _get(f"{TC}/masterchainInfo")["last"]


def run_get_method(address, method, stack=None):
    """tonapi runGetMethod; returns (exit_code, decoded, raw_stack)."""
    r = _post(f"{TA}/blockchain/accounts/{urllib.parse.quote(address)}/methods/{method}",
              {"args": stack or []})
    return r.get("exit_code"), r.get("decoded"), r.get("stack")


def account_states(address, include_boc=True):
    q = urllib.parse.urlencode({"address": address, "include_boc": str(include_boc).lower()})
    return _get(f"{TC}/accountStates?{q}")["accounts"][0]


def account(address):
    return _get(f"{TA}/accounts/{urllib.parse.quote(address)}")


def jetton_balance(account_addr, jetton_master):
    return _get(f"{TA}/accounts/{urllib.parse.quote(account_addr)}/jettons/{urllib.parse.quote(jetton_master)}")


def txs(address, limit=50):
    return _get(f"{TA}/blockchain/accounts/{urllib.parse.quote(address)}/transactions?limit={limit}")["transactions"]


def friendly(addr):
    """Convert 'wc:hex' to bounceable base64url user-friendly form."""
    import base64
    if ":" in addr:
        wc, hx = addr.split(":")
    else:
        return addr
    tag = 0x11 if int(wc) >= 0 else 0x51
    b = bytes([tag]) + bytes([int(wc) % 256]) + bytes.fromhex(hx)
    s = base64.urlsafe_b64encode(b).decode().rstrip("=")
    return s


if __name__ == "__main__":
    h = masterchain_head()
    print("masterchain seqno:", h["seqno"], "gen_utime:", h["gen_utime"])
