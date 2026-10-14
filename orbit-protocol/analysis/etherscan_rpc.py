"""Etherscan V2 proxy JSON-RPC adapter for Blast (chainid 81457) — reliable eth_call source.

Read-only. API key from env only.
"""
import json
import os
import time
import urllib.parse
import urllib.request

KEY = os.environ.get("ETHERSCANV2_API_KEY", "")
BASE = "https://api.etherscan.io/v2/api"

_last = [0.0]
_MIN_INTERVAL = 0.21  # ~5 req/s


def _throttle():
    dt = time.time() - _last[0]
    if dt < _MIN_INTERVAL:
        time.sleep(_MIN_INTERVAL - dt)
    _last[0] = time.time()


def eth_call(to, data, tag="latest"):
    q = urllib.parse.urlencode({"chainid": 81457, "module": "proxy", "action": "eth_call",
                                "to": to, "data": data, "tag": str(tag), "apikey": KEY})
    for _ in range(3):
        _throttle()
        try:
            req = urllib.request.Request(f"{BASE}?{q}", headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=30) as r:
                out = json.loads(r.read())
            if "result" in out:
                return out["result"]
            err = out.get("error") or {}
            msg = (err.get("message") or "") + str(err.get("data") or "")
            if err.get("code") == 3 or "revert" in msg.lower() or "invalid opcode" in msg.lower():
                return "__REVERT__"
            time.sleep(1.5)
        except Exception:  # noqa: BLE001
            time.sleep(1.5)
    return None


def block_number():
    q = urllib.parse.urlencode({"chainid": 81457, "module": "proxy", "action": "eth_blockNumber",
                                "apikey": KEY})
    for _ in range(3):
        _throttle()
        try:
            req = urllib.request.Request(f"{BASE}?{q}", headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=30) as r:
                out = json.loads(r.read())
            if "result" in out:
                return int(out["result"], 16)
        except Exception:  # noqa: BLE001
            time.sleep(1.5)
    return None


def get_balance(addr, tag="latest"):
    q = urllib.parse.urlencode({"chainid": 81457, "module": "account", "action": "balance",
                                "address": addr, "tag": str(tag), "apikey": KEY})
    for _ in range(3):
        _throttle()
        try:
            req = urllib.request.Request(f"{BASE}?{q}", headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=30) as r:
                out = json.loads(r.read())
            if "result" in out:
                return int(out["result"], 16)
        except Exception:  # noqa: BLE001
            time.sleep(1.5)
    return None
