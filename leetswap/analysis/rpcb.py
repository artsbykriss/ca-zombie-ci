#!/usr/bin/env python3
"""Batch JSON-RPC reads (read-only) with IPv4 preference."""
import json, time, urllib.request, socket, sys

_orig_gai = socket.getaddrinfo
def _gai4(host, port, family=0, type=0, proto=0, flags=0):
    try:
        res = _orig_gai(host, port, socket.AF_INET, type, proto, flags)
        if res: return res
    except Exception: pass
    return _orig_gai(host, port, family, type, proto, flags)
socket.getaddrinfo = _gai4

RPCS = {
    "op_bnb": ["https://opbnb.publicnode.com", "https://opbnb-mainnet-rpc.bnbchain.org", "https://opbnb.drpc.org"],
    "manta": ["https://pacific-rpc.manta.network/http", "https://manta-pacific.drpc.org"],
    "scroll": ["https://rpc.scroll.io", "https://scroll.drpc.org"],
    "linea": ["https://rpc.linea.build", "https://linea.drpc.org"],
    "polygon_zkevm": ["https://zkevm-rpc.com", "https://polygon-zkevm.drpc.org"],
    "shibarium": ["https://rpc.shibarium.shib.io"],
    "canto": ["https://canto.gravitychain.io"],
    "base": ["https://mainnet.base.org", "https://base.publicnode.com"],
}

def _post(url, payload, timeout=60):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json",
                                          "User-Agent": "Mozilla/5.0 (research; read-only)"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def batch(chain, calls, tries=3):
    """calls: list of (method, params). Returns list of results (None on error)."""
    payload = [{"jsonrpc": "2.0", "id": i, "method": m, "params": p} for i, (m, p) in enumerate(calls)]
    last = None
    for url in RPCS[chain]:
        for att in range(tries):
            try:
                d = _post(url, payload)
                if isinstance(d, dict): d = [d]
                by = {x.get("id"): x for x in d}
                out = []
                for i in range(len(calls)):
                    x = by.get(i)
                    out.append(x.get("result") if x and "result" in x else None)
                return out
            except Exception as e:
                last = e
                time.sleep(0.6 + 0.6 * att)
    raise RuntimeError(f"{chain} batch failed: {last}")

def block_number(chain):
    r = batch(chain, [("eth_blockNumber", [])])[0]
    return int(r, 16)

def code(chain, addr):
    return batch(chain, [("eth_getCode", [addr, "latest"])])[0]

def pad_addr(a): return a.lower().replace("0x", "").rjust(64, "0")
def pad_uint(n): return hex(int(n))[2:].rjust(64, "0")
def words(h):
    h = h[2:] if h.startswith("0x") else h
    return [h[i:i+64] for i in range(0, len(h)-63, 64)]
def dec_addr(w): return "0x" + w[-40:]
def dec_uint(w): return int(w, 16)
def dec_str(raw):
    try:
        ws = words(raw); off = dec_uint(ws[0]); ln = dec_uint(ws[off//32])
        data = raw[2+off*2:2+off*2+ln*2]
        return bytes.fromhex(data).decode("utf-8", "replace")
    except Exception:
        try: return bytes.fromhex(raw[2:].rstrip("0")).decode("utf-8", "replace")
        except Exception: return "?"

if __name__ == "__main__":
    for ch in RPCS:
        try:
            print(ch, block_number(ch), flush=True)
        except Exception as e:
            print(ch, "FAIL", str(e)[:100], flush=True)
