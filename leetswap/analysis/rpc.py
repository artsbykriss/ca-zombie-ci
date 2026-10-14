#!/usr/bin/env python3
"""Read-only JSON-RPC helper for LeetSwap L2 deep-dive.

Public/keyless endpoints only (never write keyed RPC URLs to files).
Only uses eth_call / eth_blockNumber / eth_getCode / eth_getLogs / eth_getStorageAt.
"""
import json, time, urllib.request, urllib.error, sys, socket

# Prefer IPv4: public endpoints resolve to slow IPv6 first on this host.
_orig_gai = socket.getaddrinfo


def _gai4(host, port, family=0, type=0, proto=0, flags=0):
    try:
        res = _orig_gai(host, port, socket.AF_INET, type, proto, flags)
        if res:
            return res
    except Exception:
        pass
    return _orig_gai(host, port, family, type, proto, flags)


socket.getaddrinfo = _gai4

RPCS = {
    "op_bnb": ["https://opbnb.publicnode.com", "https://opbnb-mainnet-rpc.bnbchain.org",
               "https://opbnb.drpc.org", "https://1rpc.io/opbnb"],
    "manta": ["https://pacific-rpc.manta.network/http", "https://manta-pacific.drpc.org",
              "https://1rpc.io/manta"],
    "scroll": ["https://rpc.scroll.io", "https://scroll.drpc.org", "https://1rpc.io/scroll"],
    "linea": ["https://rpc.linea.build", "https://linea.drpc.org", "https://1rpc.io/linea"],
    "polygon_zkevm": ["https://zkevm-rpc.com", "https://polygon-zkevm.drpc.org",
                      "https://1rpc.io/polygon-zkevm"],
    "shibarium": ["https://rpc.shibarium.shib.io", "https://shibarium.drpc.org"],
    "canto": ["https://canto.gravitychain.io", "https://canto-rpc.publicnode.com"],
    "base": ["https://mainnet.base.org", "https://base.publicnode.com", "https://base.drpc.org"],
}

_state = {}


def _call(url, method, params, timeout=40):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(url, data=body,
                                 headers={"Content-Type": "application/json",
                                          "User-Agent": "Mozilla/5.0 (research; read-only)"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        d = json.loads(r.read().decode())
    if "result" in d:
        return d["result"]
    raise RuntimeError(str(d.get("error")))


def rpc(chain, method, params, tries=4):
    """Try each endpoint of the chain until one works."""
    last = None
    for url in RPCS[chain]:
        for i in range(tries):
            try:
                return _call(url, method, params)
            except Exception as e:
                last = e
                time.sleep(0.5 + 0.5 * i)
    raise RuntimeError(f"{chain} rpc failed: {method}: {last}")


def block_number(chain):
    if ("blk", chain) not in _state:
        _state[("blk", chain)] = int(rpc(chain, "eth_blockNumber", []), 16)
    return _state[("blk", chain)]


def call(chain, to, data, block="latest"):
    if isinstance(block, int):
        block = hex(block)
    return rpc(chain, "eth_call", [{"to": to, "data": data}, block])


def code(chain, addr, block="latest"):
    if isinstance(block, int):
        block = hex(block)
    return rpc(chain, "eth_getCode", [addr, block])


def storage(chain, addr, slot, block="latest"):
    if isinstance(block, int):
        block = hex(block)
    if isinstance(slot, int):
        slot = hex(slot)
    return rpc(chain, "eth_getStorageAt", [addr, slot, block])


def get_logs(chain, address, topics, from_block, to_block):
    return rpc(chain, "eth_getLogs", [{"address": address, "topics": topics,
                                       "fromBlock": hex(from_block), "toBlock": hex(to_block)}])


# ---- ABI helpers (minimal decoding) ----
def pad_addr(a):
    return a.lower().replace("0x", "").rjust(64, "0")


def pad_uint(n):
    return hex(int(n))[2:].rjust(64, "0")


def words(hexstr):
    h = hexstr[2:] if hexstr.startswith("0x") else hexstr
    return [h[i:i + 64] for i in range(0, len(h) - 63, 64)]


def dec_addr(w):
    return "0x" + w[-40:]


def dec_uint(w):
    return int(w, 16)


def dec_str(raw):
    """Decode a string return value (offset+len+data)."""
    try:
        ws = words(raw)
        off = dec_uint(ws[0])
        ln = dec_uint(ws[off // 32])
        data = raw[2 + off * 2: 2 + off * 2 + ln * 2]
        return bytes.fromhex(data).decode("utf-8", "replace")
    except Exception:
        try:
            return bytes.fromhex(raw[2:].rstrip("0")).decode("utf-8", "replace")
        except Exception:
            return "?"


def balance_of(chain, token, owner):
    r = call(chain, token, "0x70a08231" + pad_addr(owner))
    return dec_uint(words(r)[0]) if r and r != "0x" else 0


def total_supply(chain, token):
    r = call(chain, token, "0x18160ddd")
    return dec_uint(words(r)[0]) if r and r != "0x" else 0


def decimals(chain, token):
    try:
        r = call(chain, token, "0x313ce567")
        return dec_uint(words(r)[0])
    except Exception:
        return 18


def symbol(chain, token):
    try:
        return dec_str(call(chain, token, "0x95d89b41"))
    except Exception:
        return "?"


def name(chain, token):
    try:
        return dec_str(call(chain, token, "0x06fdde03"))
    except Exception:
        return "?"


def reserves(chain, pair):
    r = call(chain, pair, "0x0902f1ac")
    ws = words(r)
    return dec_uint(ws[0]), dec_uint(ws[1]), dec_uint(ws[2])


if __name__ == "__main__":
    for ch in RPCS:
        try:
            print(ch, block_number(ch))
        except Exception as e:
            print(ch, "FAIL", str(e)[:120])
