#!/usr/bin/env python3
"""Etherscan V2 helper. Key from env ETHERSCANV2_API_KEY; never saved to disk."""
import json, os, sys, urllib.request, urllib.parse, time

KEY = os.environ.get("ETHERSCANV2_API_KEY", "")
if not KEY:
    # load from .env without printing
    for line in open("/home/heisenberg/CA/.env"):
        if line.startswith("ETHERSCANV2_API_KEY="):
            KEY = line.split("=", 1)[1].strip().strip('"')
            break

def es(chainid, params, tries=3):
    q = "&".join(f"{k}={urllib.parse.quote(str(v))}" for k, v in params.items())
    url = f"https://api.etherscan.io/v2/api?chainid={chainid}&{q}&apikey={KEY}"
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=40) as r:
                return json.loads(r.read().decode())
        except Exception as e:
            last = e
            time.sleep(1 + i)
    return {"error": str(last)}

def source(chainid, addr):
    d = es(chainid, {"module": "contract", "action": "getsourcecode", "address": addr})
    res = d.get("result")
    if isinstance(res, list) and res:
        r = res[0]
        return {"name": r.get("ContractName"), "verified": bool(r.get("SourceCode")),
                "source": r.get("SourceCode", "")[:200000], "abi": r.get("ABI", "")[:200000],
                "proxy": r.get("Proxy"), "impl": r.get("Implementation")}
    return {"raw": d}

def abi(chainid, addr):
    d = es(chainid, {"module": "contract", "action": "getabi", "address": addr})
    if d.get("status") == "1":
        return json.loads(d["result"])
    return None

if __name__ == "__main__":
    cid, addr = int(sys.argv[1]), sys.argv[2]
    s = source(cid, addr)
    print(json.dumps({"name": s.get("name"), "verified": s.get("verified"),
                      "proxy": s.get("proxy"), "impl": s.get("impl")}, indent=1))
    if len(sys.argv) > 3 and sys.argv[3] == "full":
        json.dump(s, open(sys.argv[4] if len(sys.argv) > 4 else "/tmp/opencode/src.json", "w"), indent=1)
