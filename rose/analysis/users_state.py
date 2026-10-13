#!/usr/bin/env python3
import json, urllib.request, time
RPC='https://mainnet.aurora.dev'
def rpc_batch(calls, retries=4):
    out=[]
    for i in range(0,len(calls),8):
        chunk=calls[i:i+8]
        payload=[{"jsonrpc":"2.0","id":j,"method":"eth_call","params":[{"to":to,"data":data},"latest"]} for j,(to,data) in enumerate(chunk)]
        for att in range(retries):
            try:
                req=urllib.request.Request(RPC,data=json.dumps(payload).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
                r=json.load(urllib.request.urlopen(req,timeout=60))
                res={x["id"]:x.get("result") for x in r}
                out.extend(res.get(j) for j in range(len(chunk))); break
            except Exception as e: time.sleep(2)
        else: out.extend([None]*len(chunk))
        time.sleep(0.2)
    return out
def u(x): return int(x,16) if x and x!='0x' else None
logs=json.load(open('garden_logs.json'))
GARDENS={'gardenNear':'0x64C922E3824ab40cbbEdd6C8092d148C283d3D3D','gardenUsdc':'0xfbAF3eBF228eB712b1267285787e51aDd70086bB','gardenUsdt':'0x0F44fCD177098Cb2B063B50f6C62e4F1E1f9d596','gardenWeth':'0x084355FDd5fcfd55d60C5B8626756a6906576f13','gardenAtust':'0xe8F7F08D50e12145Cb722cfF861e6A9b43EADBA1'}
# gather users per garden
allusers={}
for lab in GARDENS:
    us=set()
    for l in logs[lab]:
        t=l['topics']
        for tt in t[1:]:
            us.add('0x'+tt[-40:])
    allusers[lab]=sorted(us)
calls=[];keys=[]
for lab,g in GARDENS.items():
    for usr in allusers[lab]:
        calls.append((g,'0x1c9e379b'+usr[2:].rjust(64,'0'))); keys.append((lab,usr,'col'))
        calls.append((g,'0x48e4163e'+usr[2:].rjust(64,'0'))); keys.append((lab,usr,'bor'))
res=rpc_batch(calls)
state={}
for (lab,usr,k),r in zip(keys,res):
    state.setdefault(lab,{}).setdefault(usr,{})[k]=u(r) or 0
# garden params
params={
 'gardenNear':dict(colrate=85000,liq=107500,rate=883773466660105532450182,tc=5220754027247457588684263,tbe=14154979768211595753079),
 'gardenUsdc':dict(colrate=90000,liq=107500,rate=1000034,tc=8718605422,tbe=5797516435030667164804),
 'gardenUsdt':dict(colrate=90000,liq=107500,rate=1000624,tc=29316395,tbe=3419327981324378233),
 'gardenWeth':dict(colrate=85000,liq=107500,rate=611936159116369,tc=7417495791935697213,tbe=10542136512564150822128),
 'gardenAtust':dict(colrate=85000,liq=107500,rate=111111111111111111111,tc=116947307815268874701,tbe=29733347345877260159804),
}
print(f"{'garden':12s} {'user':44s} {'collateralShare':>22s} {'borrowPart':>22s} {'solvent?':>9s}")
for lab in GARDENS:
    for usr,st in sorted(state[lab].items(), key=lambda x:-(x[1]['bor'] or 0)):
        c=st['col']; b=st['bor']
        if c==0 and b==0: continue
        p=params[lab]
        LHS = c*10**13*p['colrate']
        RHS = b*p['rate']
        sol = 'SOLVENT' if LHS>=RHS else 'LIQUIDATABLE'
        print(f"{lab:12s} {usr:44s} {c:>22d} {b:>22d} {sol:>9s}")
