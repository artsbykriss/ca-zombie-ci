#!/usr/bin/env python3
"""Fetch verified source + on-chain metadata for a list of Ethereum addresses.
Writes raw JSON into evidence/ ; never prints the API key or keyed URL."""
import json, os, sys, urllib.parse, urllib.request, time

ENV = "/home/heisenberg/CA/.env"
KEY = None
for line in open(ENV):
    line = line.strip()
    if line.startswith("ETHERSCANV2_API_KEY="):
        KEY = line.split("=", 1)[1].strip().strip('"').strip("'")
for line in open(ENV):
    line = line.strip()
    if line.startswith("RPC_URL="):
        RPC = line.split("=", 1)[1].strip().strip('"').strip("'")

def es(params):
    base = "https://api.etherscan.io/v2/api"
    params = dict(params, chainid=1, apikey=KEY)
    url = base + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=60))

def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=60))["result"]

def main(addrs):
    os.makedirs("evidence", exist_ok=True)
    blk = int(rpc("eth_blockNumber", []), 16)
    out = {"block": blk, "contracts": {}}
    if os.path.exists("evidence/sources.json"):
        try:
            prev = json.load(open("evidence/sources.json"))
            out["contracts"] = prev.get("contracts", {})
        except Exception:
            pass
    print("block", blk)
    for a in addrs:
        a = a.lower()
        rec = {}
        try:
            code = rpc("eth_getCode", [a, hex(blk)])
            rec["code_len"] = (len(code) - 2) // 2
            if rec["code_len"] == 0:
                rec["note"] = "EOA / no code"
        except Exception as e:
            rec["code_err"] = str(e)[:200]
        try:
            s = es({"module": "contract", "action": "getsourcecode", "address": a})
            r = (s.get("result") or [{}])[0]
            rec["name"] = r.get("ContractName")
            rec["compiler"] = r.get("CompilerVersion")
            rec["proxy"] = r.get("Proxy")
            rec["impl"] = r.get("Implementation")
            rec["src_len"] = len(r.get("SourceCode") or "")
            rec["abi_len"] = len(r.get("ABI") or "")
            rec["src"] = r.get("SourceCode") or ""
            rec["abi"] = r.get("ABI") or ""
            rec["funcs"] = sorted({x.get("name") for x in json.loads(r.get("ABI") or "[]") if x.get("type") == "function" and x.get("name")}) if rec["abi_len"] else []
            rec["es_status"] = s.get("status")
            rec["es_msg"] = s.get("message")
        except Exception as e:
            rec["es_err"] = str(e)[:200]
        out["contracts"][a] = rec
        print(a, rec.get("name"), "code", rec.get("code_len"), "src", rec.get("src_len"), "funcs", len(rec.get("funcs") or []))
        time.sleep(0.3)
    json.dump(out, open("evidence/sources.json", "w"), indent=1)
    print("wrote evidence/sources.json")

if __name__ == "__main__":
    main(sys.argv[1:])
