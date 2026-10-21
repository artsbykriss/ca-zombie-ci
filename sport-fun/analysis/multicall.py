#!/usr/bin/env python3
"""Minimal Multicall3 aggregate3 encoder/decoder (stdlib only)."""
import json, subprocess, time, urllib.request

MULTICALL3 = "0xcA11bde05977b3631167028862bE2a173976CA11"
RPC_DEFAULT = "https://base.drpc.org"


def sel(sig):
    return subprocess.check_output(["cast", "sig", sig]).decode().strip()


def _pad(b):
    return b + b"\x00" * ((32 - len(b) % 32) % 32)


def encode_aggregate3(calls):
    # calls: list of (target, calldata_hex)
    n = len(calls)
    elems = []
    for target, cd in calls:
        cd_b = bytes.fromhex(cd[2:]) if cd.startswith("0x") else bytes.fromhex(cd)
        elem = (bytes.fromhex("00" * 12 + target[2:].lower()) +
                (1).to_bytes(32, "big") +          # allowFailure = true
                (0x60).to_bytes(32, "big") +       # offset to bytes within element
                len(cd_b).to_bytes(32, "big") + _pad(cd_b))
        elems.append(elem)
    offsets = []
    acc = 32 * n
    for e in elems:
        offsets.append(acc)
        acc += len(e)
    body = b"".join(o.to_bytes(32, "big") for o in offsets) + b"".join(elems)
    data = ((0x20).to_bytes(32, "big") + n.to_bytes(32, "big") + body)
    return "0x82ad56cb" + data.hex()


def decode_aggregate3(res_hex):
    b = bytes.fromhex(res_hex[2:])
    off = int.from_bytes(b[:32], "big")
    n = int.from_bytes(b[off:off + 32], "big")
    base = off + 32
    out = []
    for i in range(n):
        eo = int.from_bytes(b[base + 32 * i:base + 32 * (i + 1)], "big")
        e = base + eo
        ok = int.from_bytes(b[e:e + 32], "big") != 0
        bo = int.from_bytes(b[e + 32:e + 64], "big")
        bl = int.from_bytes(b[e + bo:e + bo + 32], "big")
        out.append((ok, "0x" + b[e + bo + 32:e + bo + 32 + bl].hex()))
    return out


def rpc(method, params, rpc_url=None, retries=6):
    url = rpc_url or RPC_DEFAULT
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                                         headers={"content-type": "application/json", "User-Agent": "Mozilla/5.0"})
            r = json.load(urllib.request.urlopen(req, timeout=90))
            if "error" in r:
                if r["error"].get("code") == 429:
                    time.sleep(2 + attempt * 2)
                    continue
                raise RuntimeError(r["error"])
            return r["result"]
        except urllib.error.HTTPError as e:
            if e.code == 429:
                time.sleep(3 + attempt * 3)
                continue
            if attempt == retries - 1:
                raise
            time.sleep(1 + attempt)
    raise RuntimeError("rpc failed")


def multicall(calls, block="latest", rpc_url=None):
    data = encode_aggregate3(calls)
    res = rpc("eth_call", [{"to": MULTICALL3, "data": data}, block], rpc_url)
    return decode_aggregate3(res)


def dec_u(hexstr):
    return int(hexstr, 16) if hexstr and hexstr != "0x" else 0


def dec_u_array(hexstr):
    if not hexstr or hexstr == "0x":
        return []
    b = bytes.fromhex(hexstr[2:])
    off = int.from_bytes(b[:32], "big")
    n = int.from_bytes(b[off:off + 32], "big")
    return [int.from_bytes(b[off + 32 + 32 * i:off + 64 + 32 * i], "big") for i in range(n)]


def enc_u(n):
    return hex(n)[2:].rjust(64, "0")


def enc_a(x):
    return "0" * 24 + x[2:].lower()
