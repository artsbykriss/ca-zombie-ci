#!/usr/bin/env python3
"""For every distinct (token,spender) the GPv2Settlement has ever approved, read the CURRENT
allowance(settlement,spender) AND settlement balanceOf(token). Report the DRAINABLE set
(allowance>0 and balance>0). Read-only. No secrets printed."""
import json, os, sys, urllib.request, time

RPC = os.environ["NODEREAL_ETH_RPC_URL"]
SETTLE = "0x9008d19f58aabd9ed0d60971565aa8510560ab41"
RAW = "/home/heisenberg/CA/cow-gpv2/analysis/approvals_raw.jsonl"
OUT = "/home/heisenberg/CA/cow-gpv2/analysis/atrisk.json"

def rpc_batch(calls):
    body = json.dumps(calls)
    req = urllib.request.Request(RPC, data=body.encode(),
                                 headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
    for a in range(5):
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                return json.load(r)
        except Exception:
            if a == 4: raise
            time.sleep(2*(a+1))

latest = {}
for line in open(RAW):
    r = json.loads(line)
    k = (r["token"].lower(), r["spender"].lower())
    cur = latest.get(k)
    if cur is None or (r["b"], int(r["li"],16)) > cur[0]:
        latest[k] = ((r["b"], int(r["li"],16)), r["value"], r["tx"])

pairs = sorted(latest.keys())
tokens = sorted(set(t for t,_ in pairs))
print(f"pairs={len(pairs)} distinct tokens={len(tokens)} distinct spenders={len(set(s for _,s in pairs))}", file=sys.stderr)

def pad(a): return a[2:].rjust(64,"0")

def calls_for(sel, args_pairs):
    out=[]
    for tok, a1, a2 in args_pairs:
        out.append({"jsonrpc":"2.0","id":tok+"|"+a1+"|"+a2,"method":"eth_call",
                    "params":[{"to":tok,"data":sel+pad(a1)+pad(a2)},"latest"]})
    return out

def run(calls):
    res={}
    for i in range(0,len(calls),50):
        for c in rpc_batch(calls[i:i+50]):
            res[c["id"]]=c.get("result")
        time.sleep(0.12)
    return res

# allowance(settlement, spender)
allow_calls=[]
for tok,sp in pairs:
    allow_calls.append({"jsonrpc":"2.0","id":tok+"|"+sp+"|allow","method":"eth_call",
                        "params":[{"to":tok,"data":"0xdd62ed3e"+pad(SETTLE)+pad(sp)},"latest"]})
allow = run(allow_calls)

# balanceOf(settlement) per token
bal_calls=[{"jsonrpc":"2.0","id":tok+"|bal","method":"eth_call",
            "params":[{"to":tok,"data":"0x70a08231"+pad(SETTLE)},"latest"]} for tok in tokens]
bal = run(bal_calls)

def num(h):
    if not h or h=="0x": return None
    try: return int(h,16)
    except: return None

atrisk=[]
for tok,sp in pairs:
    a = num(allow.get(tok+"|"+sp+"|allow"))
    b = num(bal.get(tok+"|bal"))
    if a is None or b is None: continue
    if a>0 and b>0:
        atrisk.append({"token":tok,"spender":sp,"allowance":a,"balance":b,
                       "drainable":min(a,b),"last_block":latest[(tok,sp)][0][0]})

print("AT-RISK pairs (allowance>0 AND settlement balance>0):", len(atrisk), file=sys.stderr)
for r in sorted(atrisk,key=lambda x:-x["drainable"]):
    print(f'  token={r["token"]} spender={r["spender"]} bal={r["balance"]} allow={r["allowance"]} drainable={r["drainable"]}')
json.dump({"settlement":SETTLE,"pairs":len(pairs),"atrisk":atrisk},open(OUT,"w"),indent=1)
print("wrote",OUT,file=sys.stderr)
