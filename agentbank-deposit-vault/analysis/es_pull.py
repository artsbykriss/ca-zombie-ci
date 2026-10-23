#!/usr/bin/env python3
# Read-only Etherscan V2 pulls for the World Chain vault. Key read from env; never written to file.
import json, os, sys, urllib.request, urllib.parse

KEY = os.environ.get("ETHERSCANV2_API_KEY", "")
V = "0x5C6F9354b6176C14f7dF1C1e16a0DC4A0Ff9c3E1"
BASE = "https://api.etherscan.io/v2/api"

def get(params):
    params = dict(params); params["chainid"] = 480; params["apikey"] = KEY
    url = BASE + "?" + urllib.parse.urlencode(params)
    for _ in range(4):
        try:
            with urllib.request.urlopen(url, timeout=40) as r:
                return json.loads(r.read().decode())
        except Exception as e:
            err = e
    return {"status": "0", "message": f"exc {err}", "result": []}

def ev_topic(sig):
    # keccak via cast would be easier; hardcode later. Use sha3 not available -> pass topic externally.
    return sig

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "tokentx":
        out = []
        for page in range(1, 8):
            d = get({"module": "account", "action": "tokentx", "contractaddress": V,
                     "page": page, "offset": 1000, "sort": "asc"})
            r = d.get("result") or []
            if not isinstance(r, list) or not r:
                break
            out += r
            if len(r) < 1000:
                break
        json.dump(out, open("tokentx_all.json", "w"))
        print("tokentx total:", len(out))
    elif cmd == "logs":
        topic0 = sys.argv[2]
        label = sys.argv[3]
        out = []
        # scan in 400k-block windows with topic filter
        start, end = 36291900, 36703000
        step = 400000
        b = start
        while b <= end:
            d = get({"module": "logs", "action": "getLogs", "address": V,
                     "fromBlock": b, "toBlock": min(b + step - 1, end), "topic0": topic0})
            r = d.get("result")
            if isinstance(r, list):
                out += r
            else:
                print("warn", label, b, d.get("message"), d.get("result"))
            b += step
        json.dump(out, open(f"logs_{label}.json", "w"))
        print(f"logs {label}: {len(out)}")
