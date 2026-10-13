#!/usr/bin/env python3
"""Batched on-chain probe of Rose (Aurora). Read-only, keyless RPC."""
import json, urllib.request, time, sys

RPC = "https://mainnet.aurora.dev"
def rpc_batch(calls, retries=4):
    """calls: list of (to,data). returns list of results."""
    out = []
    for i in range(0, len(calls), 8):
        chunk = calls[i:i+8]
        payload = [{"jsonrpc":"2.0","id":j,"method":"eth_call","params":[{"to":to,"data":data},"latest"]} for j,(to,data) in enumerate(chunk)]
        for att in range(retries):
            try:
                req = urllib.request.Request(RPC, data=json.dumps(payload).encode(),
                                             headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
                r = json.load(urllib.request.urlopen(req, timeout=60))
                res = {x["id"]: x.get("result") for x in r}
                out.extend(res.get(j) for j in range(len(chunk)))
                break
            except Exception as e:
                print("ERR", e, file=sys.stderr); time.sleep(2)
        else:
            out.extend([None]*len(chunk))
        time.sleep(0.3)
    return out

def u(x): return int(x,16) if x and x!="0x" else None
def addr(x): return "0x"+x[-40:] if x and len(x)>=42 else None
def u64(x,i):
    if not x or len(x)<2+64*(i+1): return None
    return int(x[2+64*i:2+64*(i+1)],16)

SEL={"coins":"0xc6610657","balances":"0x4903b0d1","A":"0xf446c1d0","A_precise":"0x76a2f0f0","fee":"0xddca3f43",
     "admin_fee":"0xfee3f7f9","owner":"0x8da5cb5b","lp_token":"0x82c63066","fee_receiver":"0xcab4d3db",
     "token":"0xfc0c546a","get_virtual_price":"0xbb7b8b80","base_pool":"0x6d5b0d0b","base_virtual_price":"0x95ccc02f",
     "base_coins":"0x87cb4f57","totalSupply":"0x18160ddd","paused":"0x5c975abb","pendingOwner":"0xe30c3978",
     "admin_actions_deadline":"0x405e28f8","transfer_ownership_deadline":"0xe0a0b586","future_owner":"0x1ec0cdc1",
     "future_A":"0xb4b577ad","future_fee":"0x58680d0b","initial_A":"0x5409491a","future_A_time":"0x14052288",
     "initial_A_time":"0x2081066c","kill_me":"0xe3698853","admin":"0xf851a440"}

POOLS = {
 "0xc90dB0d8713414d78523436dC347419164544A3f":"poolA-3coin",
 "0x8fe44f5cce02D5BE44e3446bBc2e8132958d22B8":"meta-UST",
 "0xa34315F1ef49392387Dd143f4578083A9Bd33E94":"meta-FRAX",
 "0x65a761136815B45A9d78d9781d22d47247B49D23":"meta-MAI",
 "0xee793001Ce9Fa988712B15a59CCf5dC7d54b22FF":"poolB-bentobox?",
}
calls=[]; keys=[]
for p in POOLS:
    for i in range(4):
        calls.append((p, SEL['coins']+f"{i:064x}")); keys.append((p,'coins',i))
    for i in range(4):
        calls.append((p, SEL['balances']+f"{i:064x}")); keys.append((p,'balances',i))
    for s in ['A','A_precise','fee','admin_fee','owner','pendingOwner','lp_token','fee_receiver','token',
              'get_virtual_price','base_pool','base_virtual_price','totalSupply','paused',
              'admin_actions_deadline','transfer_ownership_deadline','future_owner','future_A','future_fee','initial_A','admin']:
        calls.append((p, SEL[s])); keys.append((p,s,None))
res = rpc_batch(calls)
data={p:{} for p in POOLS}
for (p,kind,i),r in zip(keys,res):
    if kind in ('coins','balances'):
        data[p][f"{kind}{i}"] = (addr(r) if kind=='coins' else u(r))
    else:
        v = r
        if kind in ('owner','pendingOwner','lp_token','fee_receiver','token','future_owner','admin'):
            v = addr(r)
        else:
            v = u(r)
        data[p][kind]=v
for p,lab in POOLS.items():
    d=data[p]
    print(f"\n===== {lab} {p}")
    for i in range(4):
        c=d.get(f'coins{i}'); b=d.get(f'balances{i}')
        if c and c!='0x0000000000000000000000000000000000000000':
            print(f"  coins({i})={c} bal={b}")
    print("  A=",d['A'],"A_precise=",d['A_precise'],"fee=",d['fee'],"admin_fee=",d['admin_fee'])
    print("  owner=",d['owner'],"pendingOwner=",d['pendingOwner'],"admin=",d['admin'])
    print("  lp_token=",d['lp_token'],"fee_receiver=",d['fee_receiver'],"token=",d['token'])
    print("  vprice=",d['get_virtual_price'],"totalSupply=",d['totalSupply'])
    print("  base_pool=",d['base_pool'],"base_vprice=",d['base_virtual_price'])
    print("  paused=",d['paused'],"admin_deadline=",d['admin_actions_deadline'],"transfer_deadline=",d['transfer_ownership_deadline'])
    print("  future_owner=",d['future_owner'],"future_A=",d['future_A'],"future_fee=",d['future_fee'],"initial_A=",d['initial_A'])
json.dump(data, open("probe_pools.json","w"), indent=1)
