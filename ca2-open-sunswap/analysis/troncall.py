#!/usr/bin/env python3
"""Read-only TronGrid helper: constant calls, contract info, events. No keys. No transactions."""
import json, urllib.request, urllib.error, time, sys

API = "https://api.trongrid.io"
HDR = {"User-Agent": "Mozilla/5.0", "Content-Type": "application/json"}

def post(path, body, retries=4):
    url = API + path
    for i in range(retries):
        try:
            req = urllib.request.Request(url, data=json.dumps(body).encode(), headers=HDR)
            return json.load(urllib.request.urlopen(req, timeout=45))
        except urllib.error.HTTPError as e:
            if e.code == 429:
                time.sleep(2 + 3*i); continue
            return {"http_error": e.code, "body": e.read().decode()[:300]}
        except Exception as e:
            if i == retries-1: return {"error": str(e)}
            time.sleep(1.5)

def get(path, retries=5):
    for i in range(retries):
        try:
            req = urllib.request.Request(API + path, headers=HDR)
            return json.load(urllib.request.urlopen(req, timeout=45))
        except urllib.error.HTTPError as e:
            if e.code == 429:
                time.sleep(2 + 3*i); continue
            return {"http_error": e.code}
        except Exception as e:
            if i == retries-1: return {"error": str(e)}
            time.sleep(1.5)

def constant(contract, selector, parameter="", owner="TVjuTE3V5bMVdpfNhid8kD2v35T2k1u1Br", visible=True):
    b = {"owner_address": owner, "contract_address": contract,
         "function_selector": selector, "parameter": parameter, "visible": visible}
    return post("/wallet/triggerconstantcontract", b)

def account(addr, visible=True):
    return post("/wallet/getaccount", {"address": addr, "visible": visible})

def contract(addr, visible=True):
    return post("/wallet/getcontract", {"value": addr, "visible": visible})

def decode_words(h):
    if not h: return []
    h = h[2:] if h.startswith("0x") else h
    return [h[i:i+64] for i in range(0, len(h), 64)]

def addr_from_word(w):
    return "0x" + w[-40:]

def event_pages(addr, name, pages=3, limit=200):
    out = []; fp = ""
    for _ in range(pages):
        p = f"/v1/contracts/{addr}/events?limit={limit}&event_name={name}"
        if fp: p += "&fingerprint=" + urllib.parse.quote(fp)
        d = get(p); data = d.get("data", [])
        out += data
        fp = (d.get("meta") or {}).get("fingerprint", "")
        if not fp or len(data) < limit: break
        time.sleep(0.3)
    return out

if __name__ == "__main__":
    import urllib.parse
    print(json.dumps(constant(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else ""), indent=1)[:1500])
