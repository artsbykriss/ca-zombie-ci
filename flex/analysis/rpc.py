#!/usr/bin/env python3
"""Tiny batched eth_call helper. RPC URL comes from env only (never persisted).

Usage: import and call `batch_calls([(to, sig, args), ...])`
"""
import json
import os
import sys
import urllib.request

from eth_utils import keccak


def _rpc_url():
    for k in ("BLOCKPI_RPC_URL", "RPC_URL"):
        u = os.environ.get(k)
        if u:
            return u
    return "https://ethereum-rpc.publicnode.com"


def selector(sig):
    return keccak(text=sig)[:4].hex()


def enc_uint(v):
    return hex(int(v))[2:].rjust(64, "0")


def enc_addr(a):
    return a.lower().replace("0x", "").rjust(64, "0")


def encode(sig, args):
    out = selector(sig)
    for a in args:
        if isinstance(a, str) and a.startswith("0x") and len(a) == 42:
            out += enc_addr(a)
        elif isinstance(a, str) and a.startswith("0x") and len(a) == 66:
            out += a[2:].lower()
        else:
            out += enc_uint(a)
    return "0x" + out


def batch_calls(calls, block="latest"):
    """calls: list of dicts {to, sig, args, key}"""
    payload = []
    for i, c in enumerate(calls):
        payload.append({
            "jsonrpc": "2.0", "id": i, "method": "eth_call",
            "params": [{"to": c["to"], "data": encode(c["sig"], c.get("args", []))}, block],
        })
    req = urllib.request.Request(
        _rpc_url(), data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "zh4-research/1.0"})
    with urllib.request.urlopen(req, timeout=110) as r:
        res = json.load(r)
    by_id = {x["id"]: x for x in res}
    out = {}
    for i, c in enumerate(calls):
        x = by_id.get(i, {})
        out[c.get("key", f"{c['to']}:{c['sig']}")] = x.get("result") if "result" in x else {"error": x.get("error")}
    return out


def dec_addr(hexstr):
    if not isinstance(hexstr, str) or len(hexstr) < 42:
        return hexstr
    return "0x" + hexstr[-40:]


def dec_uint(hexstr):
    if not isinstance(hexstr, str) or hexstr == "0x":
        return hexstr
    return int(hexstr, 16)


def dec_bool(hexstr):
    v = dec_uint(hexstr)
    return v if not isinstance(v, int) else bool(v)


if __name__ == "__main__":
    # smoke test: block number + first market's tokens
    calls = [
        {"to": "0xd82DB9893751E9C90E2a6C3bE31183048E8E2e49", "sig": "collateral_token()", "key": "coll"},
        {"to": "0xd82DB9893751E9C90E2a6C3bE31183048E8E2e49", "sig": "borrow_token()", "key": "borrow"},
        {"to": "0xd82DB9893751E9C90E2a6C3bE31183048E8E2e49", "sig": "total_debt()", "key": "debt"},
    ]
    print(json.dumps({k: (dec_addr(v) if k != "debt" else dec_uint(v)) for k, v in batch_calls(calls).items()}, indent=2))
