import json, time, urllib.request, urllib.error

RPCS = {
    "flare": ["https://flare.rpc.thirdweb.com", "https://flare-api.flare.network/ext/C/rpc", "https://flare.drpc.org"],
    "songbird": ["https://songbird-api.flare.network/ext/C/rpc", "https://songbird.drpc.org"],
    "arbitrum": ["https://arb1.arbitrum.io/rpc"],
    "telos": ["https://rpc.telos.net"],
    "syscoin": ["https://rpc.syscoin.org"],
    "chiliz": ["https://rpc.chiliz.com"],
    "wemix": ["https://api.wemix.com"],
    "fuse": ["https://rpc.fuse.io"],
}

def rpc(chain, method, params, endpoint=None, tries=4):
    urls = [endpoint] if endpoint else RPCS[chain]
    last = None
    for u in urls:
        for i in range(tries):
            try:
                req = urllib.request.Request(
                    u,
                    data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                    headers={"content-type": "application/json", "user-agent": "Mozilla/5.0"},
                )
                with urllib.request.urlopen(req, timeout=40) as r:
                    d = json.load(r)
                if "error" in d:
                    raise RuntimeError(d["error"])
                return d["result"]
            except Exception as e:
                last = (u, repr(e))
                time.sleep(0.7 * (i + 1))
    raise RuntimeError(f"all rpc failed for {chain}/{method}: {last}")

def rpc_raw(chain, method, params, endpoint=None, tries=3):
    """Return (result, error) without raising."""
    urls = [endpoint] if endpoint else RPCS[chain]
    last = None
    for u in urls:
        for i in range(tries):
            try:
                req = urllib.request.Request(
                    u,
                    data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                    headers={"content-type": "application/json", "user-agent": "Mozilla/5.0"},
                )
                with urllib.request.urlopen(req, timeout=40) as r:
                    d = json.load(r)
                return d.get("result"), d.get("error")
            except Exception as e:
                last = (u, repr(e))
                time.sleep(0.7 * (i + 1))
    return None, {"transport": repr(last)}

def hexword(x):
    if isinstance(x, str):
        x = int(x, 16) if x.startswith("0x") else int(x)
    if x < 0:
        x = (1 << 256) + x
    return format(x, "064x")

def addr(a):
    return a.lower().replace("0x", "").rjust(64, "0")

def call(chain, to, selector, args=(), block="latest", endpoint=None):
    data = selector + "".join(args)
    return rpc(chain, "eth_call", [{"to": to, "data": data}, block], endpoint=endpoint)

def call_raw(chain, to, selector, args=(), block="latest", endpoint=None):
    return rpc_raw(chain, "eth_call", [{"to": to, "data": selector + "".join(args)}, block], endpoint=endpoint)

def word(h, i=0):
    h = h[2:] if h.startswith("0x") else h
    return int(h[i*64:(i+1)*64], 16) if len(h) >= (i+1)*64 else 0

def dec_str(h):
    h = h[2:] if h.startswith("0x") else h
    if len(h) < 128: return ""
    ln = int(h[64:128], 16)
    return bytes.fromhex(h[128:128+ln*2]).decode(errors="replace")
