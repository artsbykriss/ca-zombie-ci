#!/usr/bin/env python3
"""Fetch verified contract metadata from Etherscan V2 for the Printr main contract.
Saves only the JSON *response* (no API key) into analysis/.
"""
import json, os, sys, urllib.request, urllib.parse, time

KEY = os.environ.get("ETHERSCANV2_API_KEY", "")
BASE = "https://api.etherscan.io/v2/api"
C = "0xb77726291b125515d0a7affeea2b04f2ff243172"
CHAINS = {"ethereum": 1, "bsc": 56, "arbitrum": 42161, "base": 8453,
          "avalanche": 43114, "mantle": 5000, "monad": 143}

def get(params):
    params = dict(params); params["apikey"] = KEY
    url = BASE + "?" + urllib.parse.urlencode(params)
    for i in range(3):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.loads(r.read())
        except Exception as e:
            if i == 2: return {"error": str(e)}
            time.sleep(2)

def main():
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    out = {}
    for chain, cid in CHAINS.items():
        if what in ("all", "source"):
            r = get({"chainid": cid, "module": "contract", "action": "getsourcecode", "address": C})
            out.setdefault(chain, {})["source"] = r
        if what in ("all", "abi"):
            r = get({"chainid": cid, "module": "contract", "action": "getabi", "address": C})
            out.setdefault(chain, {})["abi"] = r
        if what == "txlist":
            r = get({"chainid": cid, "module": "account", "action": "txlist", "address": C,
                     "startblock": 0, "endblock": 99999999, "page": 1, "offset": 100, "sort": "asc"})
            out.setdefault(chain, {})["txlist"] = r
        time.sleep(0.3)
    fn = f"etherscan_{what}.json"
    with open(os.path.join(os.path.dirname(__file__), fn), "w") as f:
        json.dump(out, f, indent=1)
    # short summary
    for chain, d in out.items():
        for k, v in d.items():
            if isinstance(v, dict) and v.get("status") == "1":
                res = v["result"]
                if k == "source" and isinstance(res, list):
                    it = res[0]
                    print(chain, k, "OK name=", it.get("ContractName"), "compiler=", it.get("CompilerVersion"),
                          "proxy=", it.get("Proxy"), "impl=", it.get("Implementation"))
                elif k == "abi":
                    print(chain, k, "OK abi_bytes=", len(res))
                else:
                    print(chain, k, "OK n=", len(res) if isinstance(res, list) else res)
            else:
                print(chain, k, "FAIL", str(v)[:160])

if __name__ == "__main__":
    main()
