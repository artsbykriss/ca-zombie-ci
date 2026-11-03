"""Read-only TON helpers (tonapi.io + toncenter v3 keyless). No secrets, no broadcast."""
import json, os, time, hashlib, urllib.parse
import requests

CACHE = os.path.join(os.path.dirname(__file__), "cache")
os.makedirs(CACHE, exist_ok=True)
S = requests.Session()
S.headers.update({"User-Agent": "affluent-recheck/1.0 (research; read-only)"})

def _cache_path(url):
    return os.path.join(CACHE, hashlib.sha256(url.encode()).hexdigest()[:32] + ".json")

def get(url, ttl=3600, retries=3):
    p = _cache_path(url)
    if os.path.exists(p) and time.time() - os.path.getmtime(p) < ttl:
        return json.load(open(p))
    last = None
    for i in range(retries):
        try:
            r = S.get(url, timeout=40)
            if r.status_code == 200:
                j = r.json()
                json.dump(j, open(p, "w"))
                return j
            last = f"HTTP {r.status_code}: {r.text[:200]}"
        except Exception as e:
            last = repr(e)
        time.sleep(2 + 3 * i)
    raise RuntimeError(f"GET {url} failed: {last}")

def post(url, payload, retries=3):
    last = None
    for i in range(retries):
        try:
            r = S.post(url, json=payload, timeout=90)
            if r.status_code == 200:
                return r.json()
            last = f"HTTP {r.status_code}: {r.text[:400]}"
        except Exception as e:
            last = repr(e)
        time.sleep(3 + 4 * i)
    raise RuntimeError(f"POST {url} failed: {last}")

TONAPI = "https://tonapi.io/v2"

def account(addr):
    return get(f"{TONAPI}/accounts/{addr}", ttl=120)

def jettons(addr):
    return get(f"{TONAPI}/accounts/{addr}/jettons?currencies=usd", ttl=120)

def account_events(addr, limit=100, before_lt=None):
    u = f"{TONAPI}/accounts/{addr}/events?limit={limit}"
    if before_lt:
        u += f"&before_lt={before_lt}"
    return get(u, ttl=3600)

def trace(tx_hash):
    return get(f"{TONAPI}/traces/{tx_hash}", ttl=86400)

def tx(tx_hash):
    return get(f"{TONAPI}/blockchain/transactions/{tx_hash}", ttl=86400)

def run_getmethod(addr, method, stack=None, seqno=None):
    """toncenter v3 runGetMethod (keyless). stack = list of [type, value]."""
    body = {"address": addr, "method": method, "stack": stack or []}
    if seqno is not None:
        body["seqno"] = seqno
    j = post("https://toncenter.com/api/v3/runGetMethod", body)
    return j

def fmt_addr(a):
    """raw 0:hex -> EQ... user friendly (bounceable, workchain 0)."""
    import base64
    wc, h = a.split(":")
    tag = bytes([0x11 if int(wc) == 0 else 0x51]) + bytes([int(wc) & 0xff]) + bytes.fromhex(h)
    chk = crc16(tag)
    return base64.urlsafe_b64encode(tag + chk).decode().rstrip("=")

def crc16(data):
    crc = 0
    for b in data:
        crc ^= b << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0x1021) if (crc & 0x8000) else (crc << 1)
            crc &= 0xffff
    return crc.to_bytes(2, "big")

if __name__ == "__main__":
    import sys
    print(json.dumps(account(sys.argv[1]), indent=2))
