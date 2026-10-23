#!/usr/bin/env python3
"""Keyless Solana JSON-RPC helper for the reflect-tranches recon.

READ-ONLY. Only getAccountInfo / getMultipleAccounts / getProgramAccounts /
getSignaturesForAddress / simulateTransaction (sigVerify=false) are used.
No transaction is ever signed or sent. Endpoint is a public keyless RPC; if
$SOLANA_RPC is set in the environment it is used instead (never hard-coded,
never written to any file).
"""
import json, os, time, urllib.request, urllib.error, base64

RPC = os.environ.get("SOLANA_RPC") or "https://solana-rpc.publicnode.com"

def rpc(method, params, _retry=6):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, data=body,
                                 headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    last = None
    for i in range(_retry):
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                j = json.load(r)
            if "error" in j:
                last = j["error"]
                # rate-limit / transient -> retry
                msg = json.dumps(last)
                if "429" in msg or "rate" in msg.lower() or "limit" in msg.lower():
                    time.sleep(2 * (i + 1)); continue
                return j
            return j
        except Exception as e:  # noqa
            last = str(e)
            time.sleep(2 * (i + 1))
    return {"error": last}

A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58d(s):
    n = 0
    for c in s:
        n = n * 58 + A.index(c)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big")
    return b"\x00" * (len(s) - len(s.lstrip("1"))) + b

def b58e(b):
    n = int.from_bytes(b, "big")
    s = ""
    while n:
        n, r = divmod(n, 58)
        s = A[r] + s
    return "1" * (len(b) - len(b.lstrip(b"\x00"))) + (s or "1")

def acct(pubkey, encoding="base64"):
    r = rpc("getAccountInfo", [pubkey, {"encoding": encoding}])
    return r.get("result", {}).get("value")

def raw(pubkey):
    v = acct(pubkey)
    if not v:
        return None, None
    d = v["data"]
    if isinstance(d, list):
        return base64.b64decode(d[0]), v
    return None, v

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "version":
        print(json.dumps(rpc("getVersion", [])))
        print(json.dumps(rpc("getSlot", [])))
