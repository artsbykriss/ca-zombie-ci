#!/usr/bin/env python3
"""For every distinct (token, spender) the GPv2Settlement has ever approved, read the CURRENT
allowance(settlement, spender). Report non-zero. Read-only. No secrets printed."""
import json, os, sys, urllib.request, time

RPC = os.environ["NODEREAL_ETH_RPC_URL"]
SETTLE = "0x9008d19f58aabd9ed0d60971565aa8510560ab41"
RAW = "/home/heisenberg/CA/cow-gpv2/analysis/approvals_raw.jsonl"
OUT = "/home/heisenberg/CA/cow-gpv2/analysis/live_allowances.json"

def rpc_batch(calls):
    body = json.dumps(calls)
    req = urllib.request.Request(RPC, data=body.encode(),
                                 headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
    for a in range(5):
        try:
            with urllib.request.urlopen(req, timeout=90) as r:
                return json.load(r)
        except Exception:
            if a == 4: raise
            time.sleep(2*(a+1))

# distinct (token, spender) with latest approval value by (block, logIndex)
latest = {}
for line in open(RAW):
    r = json.loads(line)
    k = (r["token"].lower(), r["spender"].lower())
    cur = latest.get(k)
    if cur is None or (r["b"], int(r["li"],16)) > cur[0]:
        latest[k] = ((r["b"], int(r["li"],16)), r["value"], r["tx"])

pairs = sorted(latest.keys())
print("distinct (token,spender) pairs:", len(pairs), file=sys.stderr)

# pad addresses
def pad(a): return "0x" + a[2:].rjust(64,"0")
sel = "0xdd62ed3e"  # allowance(address,address)

results = []
B = 40
for i in range(0, len(pairs), B):
    chunk = pairs[i:i+B]
    calls = []
    for tok, sp in chunk:
        data = sel + pad(SETTLE)[2:] + pad(sp)[2:]
        calls.append({"jsonrpc":"2.0","id":tok+"|"+sp,"method":"eth_call",
                      "params":[{"to":tok,"data":data},"latest"]})
    resp = rpc_batch(calls)
    for c in resp:
        tok, sp = c["id"].split("|")
        v = c.get("result")
        if v is None or v == "0x":
            results.append({"token":tok,"spender":sp,"allowance":"ERR","latest_value":latest[(tok,sp)][1]})
            continue
        results.append({"token":tok,"spender":sp,"allowance":int(v,16),
                        "latest_value":latest[(tok,sp)][1],"last_block":latest[(tok,sp)][0][0],
                        "last_tx":latest[(tok,sp)][2]})
    time.sleep(0.15)

nz = [r for r in results if isinstance(r["allowance"],int) and r["allowance"]>0]
print("NON-ZERO current allowances:", len(nz), file=sys.stderr)
for r in sorted(nz, key=lambda x:-x["allowance"]):
    print(f'  token={r["token"]} spender={r["spender"]} allowance={r["allowance"]} last_blk={r["last_block"]}')
json.dump({"settlement":SETTLE,"pairs":len(pairs),"nonzero":nz,"all":results},
          open(OUT,"w"), indent=1)
print("wrote", OUT, file=sys.stderr)
