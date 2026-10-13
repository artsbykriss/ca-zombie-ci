#!/usr/bin/env python3
"""Dump MonoSwap V2 pairs (62) - tokens, reserves, balances. Read-only."""
import json, urllib.request, concurrent.futures as cf

RPCS = ["https://blast-rpc.publicnode.com", "https://rpc.blast.io", "https://blast.drpc.org"]
V2F = "0xe27cb06a15230a7480d02956a3521e78c5bfd2d0"

def call(rpc_url, to, data, timeout=12):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":to,"data":data},"latest"]}).encode()
    req = urllib.request.Request(rpc_url, data=body, headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        d=json.loads(r.read())
    return d.get("result")

def cc(to, data, idx=0):
    for a in range(3):
        try:
            return call(RPCS[(idx+a)%len(RPCS)], to, data)
        except Exception:
            continue
    return None

def u(h): return int(h,16) if h else None
def addr(h): return "0x"+h[-40:] if h and len(h)>=42 else None

# enumerate pairs
pairs=[]
for i in range(80):
    h=cc(V2F, "0x1e3dd18b"+hex(i)[2:].rjust(64,"0"))
    a=addr(h) if h else None
    if not a or a=="0x0000000000000000000000000000000000000000": break
    pairs.append(a)
print("pairs:", len(pairs))

def info(p):
    t0=addr(cc(p,"0x0dfe1681")); t1=addr(cc(p,"0xd21220a7"))
    res=cc(p,"0x0902f1ac")
    r0=r1=None
    if res and len(res)>=130:
        r0=u(res[2:66]); r1=u(res[2+64:2+128])
    b0=u(cc(t0,"0x70a08231"+"000000000000000000000000"+p[2:])) if t0 else None
    b1=u(cc(t1,"0x70a08231"+"000000000000000000000000"+p[2:])) if t1 else None
    return p, {"t0":t0,"t1":t1,"res0":r0,"res1":r1,"bal0":b0,"bal1":b1}

out={}
with cf.ThreadPoolExecutor(max_workers=8) as ex:
    for p, rec in ex.map(info, pairs):
        out[p]=rec
json.dump(out, open("/home/heisenberg/CA/monoswap-v3/analysis/v2_pairs.json","w"), indent=1)

meta=json.load(open("/home/heisenberg/CA/monoswap-v3/analysis/tokens.json"))
mm={k.lower():v for k,v in meta["meta"].items()}
pr={k.lower():v["price"] for k,v in meta["prices"].items()}
REAL={"0x4300000000000000000000000000000000000003":"USDB","0x4300000000000000000000000000000000000004":"WETH"}
print(f"{'pair':44} {'pair':22} {'bal0':>22} {'bal1':>22} {'usd_real':>10}")
rows=[]
for p,rec in out.items():
    s0=mm.get(rec['t0'].lower(),{}).get('symbol',rec['t0'][:10]); s1=mm.get(rec['t1'].lower(),{}).get('symbol',rec['t1'][:10])
    d0=mm.get(rec['t0'].lower(),{}).get('decimals') or 18; d1=mm.get(rec['t1'].lower(),{}).get('decimals') or 18
    usd=0
    if rec['t0'].lower() in REAL and pr.get(rec['t0'].lower()): usd+=rec['bal0']/10**d0*pr[rec['t0'].lower()]
    if rec['t1'].lower() in REAL and pr.get(rec['t1'].lower()): usd+=rec['bal1']/10**d1*pr[rec['t1'].lower()]
    rows.append((p,f"{s0}/{s1}",rec['bal0'],rec['bal1'],usd))
rows.sort(key=lambda r:-r[4])
for r in rows:
    if r[4]>0 or (r[2] and r[3]):
        print(f"{r[0]:44} {r[1]:22} {str(r[2])[:22]:>22} {str(r[3])[:22]:>22} {r[4]:10.2f}")
