#!/usr/bin/env python3
"""Fetch logs (read-only) for Gardens v2 analysis. Writes gardens-logs-*.json"""
import json, urllib.request, time, sys

RPC = "https://rpc.gnosischain.com"
OUT = "/home/heisenberg/CA/gnosis-residual/analysis"

def rpc(method, params):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    for a in range(6):
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                d = json.load(r)
            if "error" in d: raise RuntimeError(d["error"])
            return d["result"]
        except Exception as e:
            print("retry", a, str(e)[:100], file=sys.stderr); time.sleep(2*(a+1))
    raise RuntimeError("failed")

def getlogs(address, topics, fromblk=0, toblk="latest"):
    return rpc("eth_getLogs", [{"address":address,"topics":topics,"fromBlock":hex(fromblk),"toBlock":toblk if isinstance(toblk,str) else hex(toblk)}])

STRAT="0x9Fb2f1813228a97f559E29A6492EE27357FAF8A2"
RC="0xE2396fe2169ca026962971d3B2E373Ba925B6257"
HNY="0x71850b7E9Ee3f13Ab46d67167341E4bDc905Eef9"
FACT="0x08Df82f74D1f56F650E98da2dd4240F1A31711bc"
ROLE_AL="0xc3b06835cd5ac011ddecef53631f2e5cc1849fe36234eeb2726c56e7a3eae49b"  # ALLOWLIST||27

TRANSFER = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
ROLEGRANTED = "0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d"

out = {}

print("1) RoleGranted (any) on RC ...", file=sys.stderr)
out["rc_roleGranted_all"] = getlogs(RC, [ROLEGRANTED, None])
print("   got", len(out["rc_roleGranted_all"]), file=sys.stderr)

print("2) RoleGranted for ALLOWLIST||27 (topic1=role) on RC ...", file=sys.stderr)
out["rc_roleGranted_allowlist27"] = getlogs(RC, [ROLEGRANTED, ROLE_AL])

print("3) HNY transfers INTO strategy ...", file=sys.stderr)
out["hny_into_strategy"] = getlogs(HNY, [TRANSFER, None, "0x"+"00"*12+STRAT[2:].lower()])

print("4) HNY transfers OUT of strategy ...", file=sys.stderr)
out["hny_out_strategy"] = getlogs(HNY, [TRANSFER, "0x"+"00"*12+STRAT[2:].lower(), None])

print("5) HNY transfers INTO RC ...", file=sys.stderr)
out["hny_into_rc"] = getlogs(HNY, [TRANSFER, None, "0x"+"00"*12+RC[2:].lower()])

print("6) HNY transfers OUT of RC ...", file=sys.stderr)
out["hny_out_rc"] = getlogs(HNY, [TRANSFER, "0x"+"00"*12+RC[2:].lower(), None])

with open(f"{OUT}/gardens-logs-transfers.json","w") as f:
    json.dump(out, f, indent=1)
for k,v in out.items():
    print(k, len(v))
