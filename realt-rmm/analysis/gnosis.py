"""Minimal keyless Gnosis JSON-RPC helpers (read-only).

No secrets. RPC endpoint is taken from GNOSIS_RPC_URL (CI) or a public fallback.
All calls are eth_call / eth_getLogs only; nothing is ever signed or sent.
"""
import json
import os
import time

import requests
from eth_abi import decode as abi_decode, encode as abi_encode
from eth_utils import keccak

RPC = os.environ.get("GNOSIS_RPC_URL") or "https://rpc.gnosischain.com"  # never fall back to an Ethereum RPC
PUBLIC_FALLBACKS = [
    "https://rpc.gnosischain.com",
    "https://gnosis-rpc.publicnode.com",
    "https://gnosis.drpc.org",
]
MULTICALL3 = "0xcA11bde05977b3631167028862bE2a173976CA11"

_session = requests.Session()
_session.headers.update({"content-type": "application/json", "user-agent": "zh4-research/1.0"})


def _base_sig(sig: str) -> str:
    """Strip an ABI-style return suffix: 'f(a,b)(c)' -> 'f(a,b)' (balanced-paren aware)."""
    start = sig.index("(")
    depth = 0
    for i in range(start, len(sig)):
        if sig[i] == "(":
            depth += 1
        elif sig[i] == ")":
            depth -= 1
            if depth == 0:
                return sig[: i + 1]
    return sig


def sel(sig: str) -> str:
    return "0x" + keccak(text=_base_sig(sig))[:4].hex()


def rpc(method, params, url=None, retries=4):
    url = url or RPC
    payload = {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}
    last = None
    for i in range(retries):
        try:
            r = _session.post(url, data=json.dumps(payload), timeout=40)
            j = r.json()
            if "result" in j:
                return j["result"]
            last = RuntimeError(str(j.get("error")))
        except Exception as e:  # noqa: BLE001
            last = e
        time.sleep(1.0 + i)
    raise last


def rpc_batch(calls, url=None, chunk=100):
    """calls: list of (method, params). Returns list of results in order."""
    url = url or RPC
    out = []
    for i in range(0, len(calls), chunk):
        part = calls[i:i + chunk]
        payload = [
            {"jsonrpc": "2.0", "id": i + k, "method": m, "params": p}
            for k, (m, p) in enumerate(part)
        ]
        for attempt in range(4):
            try:
                r = _session.post(url, data=json.dumps(payload), timeout=60)
                js = r.json()
                if isinstance(js, dict):
                    js = [js]
                by_id = {x["id"]: x for x in js}
                res = []
                for k in range(len(part)):
                    j = by_id.get(i + k, {})
                    res.append(j.get("result"))
                out.extend(res)
                break
            except Exception:  # noqa: BLE001
                if attempt == 3:
                    raise
                time.sleep(1.5)
    return out


def eth_call(to, data, block="latest", frm=None, url=None):
    tx = {"to": to, "data": data}
    if frm:
        tx["from"] = frm
    return rpc("eth_call", [tx, hex(block) if isinstance(block, int) else block], url=url)


def _norm_args(args):
    out = []
    for a in args:
        if isinstance(a, str) and a.startswith("0x") and len(a) == 42:
            out.append(a.lower())
        elif isinstance(a, (list, tuple)):
            out.append([x.lower() if isinstance(x, str) and x.startswith("0x") and len(x) == 42 else x for x in a])
        else:
            out.append(a)
    return out


def call(to, sig, args=(), block="latest", frm=None, url=None):
    data = sel(sig) + abi_encode([t for t in _types(sig)], _norm_args(list(args))).hex() if args else sel(sig)
    return eth_call(to, data, block=block, frm=frm, url=url)


def _types(sig):
    sig = _base_sig(sig)
    inner = sig[sig.index("(") + 1: sig.rindex(")")]
    if not inner:
        return []
    out, depth, cur = [], 0, ""
    for ch in inner:
        if ch == "," and depth == 0:
            out.append(cur)
            cur = ""
        else:
            if ch in "([":
                depth += 1
            elif ch in ")]":
                depth -= 1
            cur += ch
    out.append(cur)
    return out


def dec(types, data):
    if isinstance(data, str):
        data = bytes.fromhex(data[2:] if data.startswith("0x") else data)
    return abi_decode(types, data)


def latest_block(url=None):
    return int(rpc("eth_blockNumber", [], url=url), 16)


def block_ts(block, url=None):
    b = rpc("eth_getBlockByNumber", [hex(block), False], url=url)
    return int(b["timestamp"], 16)


def multicall(calls, block="latest", url=None, chunk=120):
    """calls: list of (target, calldata_hex). Returns list of (ok, bytes)."""
    out = []
    for i in range(0, len(calls), chunk):
        part = calls[i:i + chunk]
        enc = abi_encode(
            ["(address,bool,bytes)[]"],
            [[(t.lower(), True, bytes.fromhex(d[2:])) for t, d in part]],
        )
        data = sel("aggregate3((address,bool,bytes)[])") + enc.hex()
        res = eth_call(MULTICALL3, data, block=block, url=url)
        out.extend(abi_decode(["(bool,bytes)[]"], bytes.fromhex(res[2:]))[0])
    return out


def hexwords(types, values):
    return "0x" + abi_encode(types, values).hex()
