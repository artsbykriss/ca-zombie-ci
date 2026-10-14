"""Read-only Blast JSON-RPC helper (keyless public endpoints only).

Used by the Orbit Protocol L2 Phase-2 deep dive. No secrets in this file.
"""
import json
import time
import urllib.request

RPCS = [
    "https://rpc.blast.io",
    "https://blast-rpc.publicnode.com",
    "https://blast.drpc.org",
]

_last_err = [None]


def rpc(method, params, rpc_urls=RPCS, retries=4):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for attempt in range(retries):
        for url in rpc_urls:
            try:
                req = urllib.request.Request(
                    url, data=body,
                    headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"},
                )
                with urllib.request.urlopen(req, timeout=25) as r:
                    out = json.loads(r.read())
                if "result" in out:
                    return out["result"]
                last = out.get("error")
            except Exception as e:  # noqa: BLE001
                last = str(e)
        _last_err[0] = last
        time.sleep(1.0 * (attempt + 1))
    raise RuntimeError(f"rpc {method} failed: {last}")


def call(to, data, block="latest", rpc_urls=RPCS):
    blk = hex(block) if isinstance(block, int) else block
    return rpc("eth_call", [{"to": to, "data": data}, blk], rpc_urls)


def call_ok(to, data, block="latest", rpc_urls=RPCS):
    try:
        return call(to, data, block, rpc_urls)
    except Exception:  # noqa: BLE001
        return None


def code(addr, block="latest"):
    return rpc("eth_getCode", [addr, hex(block) if isinstance(block, int) else block])


def bal(addr, block="latest"):
    return int(rpc("eth_getBalance", [addr, hex(block) if isinstance(block, int) else block]), 16)


def to_int(hexstr):
    if hexstr is None:
        return None
    if isinstance(hexstr, int):
        return hexstr
    return int(hexstr, 16)


def dec(hexstr, decimals=18):
    v = to_int(hexstr)
    return None if v is None else v / 10 ** decimals


def addr_from_word(word):
    return "0x" + word[-40:]


def words(hexstr):
    h = hexstr[2:] if hexstr.startswith("0x") else hexstr
    return [h[i:i + 64] for i in range(0, len(h), 64)]
