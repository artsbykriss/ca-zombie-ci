#!/usr/bin/env python3
"""Complete live-allowance surface: every spender the settlement has EVER approved (from the
approval-log census) x every token the settlement currently holds (from the same census).
Reports (spender, token) with allowance>0 AND settlement balance>0. Read-only."""
import json, os, sys, urllib.request, time

RPC = os.environ["NODEREAL_ETH_RPC_URL"]
SETTLE = "0x9008d19f58aabd9ed0d60971565aa8510560ab41"
RAW = "/home/heisenberg/CA/cow-gpv2/analysis/approvals_raw.jsonl"
OUT = "/home/heisenberg/CA/cow-gpv2/analysis/live_surface.json"

def rpc_batch(calls):
    for a in range(6):
        try:
            req = urllib.request.Request(RPC, data=json.dumps(calls).encode(),
                                         headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req, timeout=120) as r:
                return json.load(r)
        except Exception:
            if a == 5: raise
            time.sleep(2*(a+1))

spenders=set(); tokens=set()
for line in open(RAW):
    r=json.loads(line)
    spenders.add(r["spender"].lower()); tokens.add(r["token"].lower())
spenders=sorted(spenders); tokens=sorted(tokens)
print(f"spenders={len(spenders)} tokens={len(tokens)}", file=sys.stderr)

def pad(a): return a[2:].rjust(64,"0")
def run(calls):
    res={}
    for i in range(0,len(calls),60):
        for c in rpc_batch(calls[i:i+60]):
            res[c["id"]]=c.get("result")
        time.sleep(0.05)
        if (i//60)%20==0: print("batch",i//60,"/",len(calls)//60,file=sys.stderr,flush=True)
    return res
def num(h):
    if not h or h=="0x": return None
    try: return int(h,16)
    except: return None

# settlement balances for all tokens
bal_calls=[{"jsonrpc":"2.0","id":t+"|bal","method":"eth_call",
            "params":[{"to":t,"data":"0x70a08231"+pad(SETTLE)},"latest"]} for t in tokens]
bal=run(bal_calls)
held={t:num(bal.get(t+"|bal")) for t in tokens}
held={t:v for t,v in held.items() if v}
print(f"tokens the settlement holds (of census set): {len(held)}", file=sys.stderr)

# allowances spender x held token
pairs=[(sp,t) for sp in spenders for t in held]
print(f"checking {len(pairs)} pairs", file=sys.stderr)
calls=[{"jsonrpc":"2.0","id":sp+"|"+t,"method":"eth_call",
        "params":[{"to":t,"data":"0xdd62ed3e"+pad(SETTLE)+pad(sp)},"latest"]} for sp,t in pairs]
al=run(calls)
out=[]
for sp,t in pairs:
    a=num(al.get(sp+"|"+t))
    if a is None: continue
    if a>0:
        out.append({"spender":sp,"token":t,"allowance":a,"settlement_balance":held[t],
                    "drainable":min(a,held[t])})
print(f"LIVE (allowance>0 and balance>0): {len(out)}", file=sys.stderr)
by_sp={}
for r in out: by_sp.setdefault(r["spender"],[]).append(r)
for sp,rs in sorted(by_sp.items(), key=lambda kv:-sum(x["drainable"] for x in kv[1])):
    print(f"  spender {sp}  tokens={len(rs)}")
json.dump({"settlement":SETTLE,"spenders":len(spenders),"tokens":len(tokens),
           "held_tokens":held,"live":out},open(OUT,"w"),indent=1)
print("wrote",OUT,file=sys.stderr)
