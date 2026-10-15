#!/usr/bin/env python3
"""Minimal Solana JSON-RPC client for the Phase Delegation (ex-AeroPool) audit.

Read-only. Public keyless endpoints only (no API keys here — this folder is synced
to a PUBLIC CI repo, so never place keyed URLs/secrets in this tree).
"""
import json, time, urllib.request, itertools

ENDPOINTS = [
    "https://solana-rpc.publicnode.com",
    "https://api.mainnet-beta.solana.com",
]

_cycle = itertools.cycle(ENDPOINTS)
_last = {}


def rpc(method, params, tries=6, timeout=40):
    """POST a JSON-RPC request, round-robin endpoints, backoff on 429/err."""
    last_err = None
    for attempt in range(tries):
        url = next(_cycle)
        body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
        req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json", "User-Agent": "zombie-research/1.0"})
        try:
            with urllib.request.urlopen(req, timeout=timeout) as r:
                raw = r.read().decode()
            out = json.loads(raw)
            if "error" in out:
                last_err = out["error"]
                # rate limit or transient -> backoff and retry
                time.sleep(1.0 + attempt)
                continue
            return out.get("result")
        except Exception as e:  # noqa
            last_err = str(e)
            time.sleep(1.0 + attempt)
    raise RuntimeError(f"rpc {method} failed after {tries} tries: {last_err}")


B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"


def b58dec(s):
    n = 0
    for ch in s:
        n = n * 58 + B58.index(ch)
    pad = len(s) - len(s.lstrip("1"))
    return b"\x00" * pad + n.to_bytes((n.bit_length() + 7) // 8, "big")


def b58enc(b):
    n = int.from_bytes(b, "big")
    out = ""
    while n:
        n, r = divmod(n, 58)
        out = B58[r] + out
    pad = len(b) - len(b.lstrip(b"\x00"))
    return "1" * pad + (out or "")


def pk(b):
    return b58enc(b)


def u64(b):
    return int.from_bytes(b, "little")


def get_account(addr):
    res = rpc("getAccountInfo", [addr, {"encoding": "base64", "commitment": "finalized"}])
    return res["value"], res["context"]["slot"] if "context" in res else None


def slot():
    return rpc("getSlot", [{"commitment": "finalized"}])


if __name__ == "__main__":
    import sys
    m = sys.argv[1] if len(sys.argv) > 1 else "getHealth"
    print(json.dumps(rpc(m, sys.argv[2:] and json.loads(sys.argv[2]) or []), indent=2)[:4000])
