"""Read-only Ethereum helpers for the MakerDAO keeper analysis.

- Public RPCs only (no keyed URLs written anywhere).
- Etherscan V2 key is read from /home/heisenberg/CA/.env at runtime, never printed.
"""
import json
import os
import time
import urllib.request
import urllib.parse
from eth_abi import encode, decode

RPCS = [
    "https://ethereum-rpc.publicnode.com",
    "https://eth.drpc.org",
]
ENV_FILE = "/home/heisenberg/CA/.env"
OUT = os.path.dirname(os.path.abspath(__file__))


def _load_env_key(name):
    try:
        with open(ENV_FILE) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                if k.strip() == name:
                    return v.strip().strip('"').strip("'")
    except OSError:
        pass
    return os.environ.get(name)


def rpc(method, params, _retries=3):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for attempt in range(_retries):
        url = RPCS[attempt % len(RPCS)]
        try:
            req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json", "User-Agent": "curl/8.5.0"})
            with urllib.request.urlopen(req, timeout=60) as r:
                out = json.loads(r.read())
            if "result" in out:
                return out["result"]
            last = RuntimeError(out.get("error"))
        except Exception as e:  # noqa
            last = e
        time.sleep(0.25 * (attempt + 1))
    raise last


def _batch_once(part):
    body = json.dumps([
        {"jsonrpc": "2.0", "id": j, "method": m, "params": p}
        for j, (m, p) in enumerate(part)
    ]).encode()
    last = None
    for attempt in range(3):
        url = RPCS[attempt % len(RPCS)]
        try:
            req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json", "User-Agent": "curl/8.5.0"})
            with urllib.request.urlopen(req, timeout=90) as r:
                out = json.loads(r.read())
            by_id = {x["id"]: x for x in out}
            return [by_id.get(j, {}).get("result") for j in range(len(part))]
        except Exception as e:  # noqa
            last = e
            time.sleep(0.4 * (attempt + 1))
    raise last


def rpc_batch(calls, chunk=50):
    """calls = [(method, params), ...]; returns list of results (None on per-call error)."""
    results = []
    for i in range(0, len(calls), chunk):
        part = calls[i:i + chunk]
        try:
            results += _batch_once(part)
        except Exception:
            for m, p in part:
                try:
                    results.append(rpc(m, p))
                except Exception:
                    results.append(None)
    return results


def eth_call(to, data, block="latest"):
    return rpc("eth_call", [{"to": to, "data": data}, block])


def get_code(addr, block="latest"):
    return rpc("eth_getCode", [addr, block])


def block_number():
    return int(rpc("eth_blockNumber", []), 16)


def block_ts(n):
    b = rpc("eth_getBlockByNumber", [hex(n), False])
    return int(b["timestamp"], 16)


def etherscan(params):
    key = _load_env_key("ETHERSCANV2_API_KEY")
    if not key:
        return {"error": "no ETHERSCANV2_API_KEY"}
    q = dict(params)
    q["chainid"] = "1"
    q["apikey"] = key
    url = "https://api.etherscan.io/v2/api?" + urllib.parse.urlencode(q)
    for attempt in range(3):
        try:
            with urllib.request.urlopen(url, timeout=60) as r:
                return json.loads(r.read())
        except Exception as e:  # noqa
            time.sleep(0.5 * (attempt + 1))
    return {"error": "etherscan request failed"}


def pad_addr(a):
    a = a.lower().replace("0x", "")
    return a.rjust(64, "0")


def pad_u256(n):
    return hex(n)[2:].rjust(64, "0")


def pad_bytes32(s):
    b = s.encode() if isinstance(s, str) else s
    return b.hex().ljust(64, "0")


def word_addr(w):
    return "0x" + w[-40:]


def words(hexstr):
    h = hexstr[2:] if hexstr.startswith("0x") else hexstr
    return [h[i:i + 64] for i in range(0, len(h), 64)]


def mc3(calls, block="latest", chunk=200):
    """calls = [(target, calldata_hex), ...] -> [(success, return_bytes), ...] via Multicall3."""
    MC3 = "0xcA11bde05977b3631167028862bE2a173976CA11"
    out = []
    for i in range(0, len(calls), chunk):
        part = calls[i:i + chunk]
        arr = [(t, True, bytes.fromhex(d[2:] if d.startswith("0x") else d)) for t, d in part]
        data = "0x82ad56cb" + encode([" (address,bool,bytes)[]".strip()], [arr]).hex()
        r = eth_call(MC3, data, block)
        decoded = decode(["(bool,bytes)[]"], bytes.fromhex(r[2:]))[0]
        out += [(bool(s), b) for s, b in decoded]
    return out

