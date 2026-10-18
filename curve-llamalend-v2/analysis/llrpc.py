"""Read-only JSON-RPC / Etherscan helper (LL-v2 subagent).

Never contains URLs or keys. Reads them from the environment:
  ETH RPC: ETH_RPC or FORK_RPC_URL or BLOCKPI_RPC_URL (default public endpoint)
  OP  RPC: OP_RPC or public OP endpoint
  Etherscan V2: ETHERSCANV2_API_KEY
"""
import json, os, time, urllib.parse, urllib.request

PUBLIC_ETH = "https://ethereum-rpc.publicnode.com"
PUBLIC_OP = "https://mainnet.optimism.io"


def eth_url():
    return os.environ.get("ETH_RPC") or os.environ.get("FORK_RPC_URL") or os.environ.get("BLOCKPI_RPC_URL") or PUBLIC_ETH


def op_url():
    return os.environ.get("OP_RPC") or PUBLIC_OP


def rpc(url, method, params, tries=6):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(
                url, data=body,
                headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"},
            )
            d = json.load(urllib.request.urlopen(req, timeout=40))
            if "result" in d:
                return d["result"]
            last = d
        except Exception as e:  # noqa: BLE001
            last = e
        time.sleep(1.5 * (i + 1))
    raise RuntimeError(f"rpc failed {method}: {last}")


def batch(url, calls):
    """calls: list of (to, data, block_hex). Returns list of raw hex or None."""
    body = json.dumps([{"jsonrpc": "2.0", "id": i, "method": "eth_call",
                        "params": [{"to": t, "data": d}, b]} for i, (t, d, b) in enumerate(calls)]).encode()
    for _ in range(3):
        try:
            req = urllib.request.Request(url, data=body,
                                         headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            res = json.load(urllib.request.urlopen(req, timeout=90))
            out = [None] * len(calls)
            for item in res:
                out[item["id"]] = item.get("result")
            return out
        except Exception:  # noqa: BLE001
            time.sleep(1.5)
    raise RuntimeError("batch failed")


def batch_chunked(url, calls, size=8):
    out = []
    for i in range(0, len(calls), size):
        chunk = calls[i:i + size]
        try:
            out.extend(batch(url, chunk))
        except Exception:  # noqa: BLE001
            for to, data, blk in chunk:
                try:
                    out.append(call(url, to, data, blk))
                except Exception:  # noqa: BLE001
                    out.append(None)
    return out


def call(url, to, data, block="latest"):
    return rpc(url, "eth_call", [{"to": to, "data": data}, block])


def block_number(url):
    return int(rpc(url, "eth_blockNumber", []), 16)


def code(url, addr, block="latest"):
    return rpc(url, "eth_getCode", [addr, block])


def balance(url, addr, block="latest"):
    return int(rpc(url, "eth_getBalance", [addr, block]), 16)


def etherscan(params):
    p = dict(params)
    p["apikey"] = os.environ["ETHERSCANV2_API_KEY"]
    url = "https://api.etherscan.io/v2/api?" + urllib.parse.urlencode(p)
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=60))
