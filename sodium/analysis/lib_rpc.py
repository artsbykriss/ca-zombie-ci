#!/usr/bin/env python3
"""Minimal keyless Arbitrum JSON-RPC helper for the Sodium census/PoC.

No API keys, no secrets: uses public endpoints only. Never write a keyed RPC URL
into a saved artifact (SUBAGENT-BRIEF rule 7).
"""
import json, urllib.request, urllib.error, itertools, time

ENDPOINTS = [
    "https://arbitrum-one-rpc.publicnode.com",
    "https://arb1.arbitrum.io/rpc",
    "https://arbitrum.drpc.org",
    "https://1rpc.io/arb",
]
_ids = itertools.count(1)


def _post(url, payload, timeout=45):
    req = urllib.request.Request(
        url, data=json.dumps(payload).encode(),
        headers={"content-type": "application/json", "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())


def rpc(method, params, url=None):
    urls = [url] if url else ENDPOINTS
    last = None
    for u in urls:
        try:
            r = _post(u, {"jsonrpc": "2.0", "id": next(_ids), "method": method, "params": params})
            if "result" in r or "error" in r:
                return r
            last = r
        except Exception as e:
            last = {"error": str(e)}
            time.sleep(0.3)
    return last


def batch(calls, url=None):
    """calls: list of (method, params). Returns list of results in order (or error dicts)."""
    urls = [url] if url else ENDPOINTS
    last = None
    for u in urls:
        try:
            payload = [{"jsonrpc": "2.0", "id": i, "method": m, "params": p}
                       for i, (m, p) in enumerate(calls)]
            r = _post(u, payload)
            if isinstance(r, list):
                out = [None] * len(calls)
                for item in r:
                    out[item["id"]] = item
                return out
            last = r
        except Exception as e:
            last = {"error": str(e)}
            time.sleep(0.3)
    return [last] * len(calls)


def batch_retry(calls, tries=5, chunk=None):
    """Batch with retry; verifies every id has a 'result' and retries the missing
    ones (public endpoints rate-limit large bursts)."""
    out = [None] * len(calls)
    idx = list(range(len(calls)))
    for attempt in range(tries):
        pending = [i for i in idx if not (out[i] and "result" in out[i])]
        if not pending:
            break
        for k in range(0, len(pending), chunk or 200):
            sub = pending[k:k + (chunk or 200)]
            res = batch([calls[i] for i in sub])
            for i, r in zip(sub, res):
                if r and "result" in r:
                    out[i] = r
        if any(not (out[i] and "result" in out[i]) for i in idx):
            time.sleep(1.5 * (attempt + 1))
    return out


def latest():
    return int(rpc("eth_blockNumber", [])["result"], 16)


def code(a, block="latest"):
    return rpc("eth_getCode", [a, block]).get("result", "0x")


def balance(a, block="latest"):
    return int(rpc("eth_getBalance", [a, block]).get("result", "0x0"), 16)


def storage(a, slot, block="latest"):
    return rpc("eth_getStorageAt", [a, slot, block]).get("result", "0x0")


if __name__ == "__main__":
    print("latest block:", latest())
