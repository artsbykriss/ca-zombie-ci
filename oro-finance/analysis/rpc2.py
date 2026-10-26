"""RPC helper that reads keyed endpoints from the environment (never hardcodes secrets).
Keys are loaded from $ORO_ENV_FILE (default /home/heisenberg/CA/.env) at runtime; the
keyed URL is only ever held in memory and never written to any file in this folder.
"""
import json, urllib.request, time, random, os

ENV_FILE = os.environ.get("ORO_ENV_FILE", "/home/heisenberg/CA/.env")


def _env(k):
    try:
        for line in open(ENV_FILE):
            if line.startswith(k + "="):
                return line.split("=", 1)[1].strip().strip('"')
    except Exception:
        pass
    return None


def endpoints():
    eps = []
    ak = _env("ALCHEMY_API_KEY")
    if ak:
        eps.append("https://solana-mainnet.g.alchemy.com/v2/" + ak)
    dk = _env("DRPC_API_KEY")
    if dk:
        eps.append("https://lb.drpc.org/ogrpc?network=solana&dkey=" + dk)
    an = _env("ANKR_API_KEY")
    if an:
        eps.append("https://rpc.ankr.com/solana/" + an)
    eps.append("https://api.mainnet-beta.solana.com")
    eps.append("https://solana-rpc.publicnode.com")
    return eps


def call(method, params, retries=8, ep=None):
    eps = [ep] if ep else endpoints()
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for i in range(retries):
        url = eps[i % len(eps)]
        try:
            req = urllib.request.Request(url, data=body,
                                         headers={"Content-Type": "application/json",
                                                  "User-Agent": "Mozilla/5.0"})
            r = json.load(urllib.request.urlopen(req, timeout=90))
            if "error" in r:
                raise RuntimeError(r["error"])
            return r["result"]
        except Exception as e:
            last = e
            time.sleep(min(10, 0.6 * (2 ** i)) + random.random())
    raise last


def batch(reqs, retries=6, ep=None):
    eps = [ep] if ep else endpoints()
    body = json.dumps(reqs).encode()
    last = None
    for i in range(retries):
        url = eps[i % len(eps)]
        try:
            req = urllib.request.Request(url, data=body,
                                         headers={"Content-Type": "application/json",
                                                  "User-Agent": "Mozilla/5.0"})
            r = json.load(urllib.request.urlopen(req, timeout=120))
            if isinstance(r, dict) and "error" in r:
                raise RuntimeError(r["error"])
            return r
        except Exception as e:
            last = e
            time.sleep(min(10, 0.6 * (2 ** i)) + random.random())
    raise last


def multi(addrs, cfg=None):
    out = []
    cfg = cfg or {"encoding": "base64"}
    for i in range(0, len(addrs), 100):
        r = call("getMultipleAccounts", [addrs[i:i + 100], cfg])
        out += r["value"]
    return out
