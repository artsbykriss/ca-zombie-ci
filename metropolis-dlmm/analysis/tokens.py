#!/usr/bin/env python3
import json, urllib.request, subprocess, time
RPC="https://rpc.soniclabs.com"
def sig(s): return subprocess.check_output(["cast","sig",s]).decode().strip()
SEL_SYM=sig("symbol()"); SEL_DEC=sig("decimals()")
def rpc_batch(calls):
    payload=[{"jsonrpc":"2.0","id":i,"method":"eth_call","params":[{"to":c["to"],"data":c["data"]},"latest"]} for i,c in enumerate(calls)]
    req=urllib.request.Request(RPC,data=json.dumps(payload).encode(),headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
    with urllib.request.urlopen(req,timeout=60) as r: res=json.load(r)
    out={i.get("id"):i.get("result") for i in res}
    return [out[i] for i in range(len(calls))]
def dec_str(h):
    if not h or len(h)<130: return None
    try:
        b=bytes.fromhex(h[2:])
        off=int.from_bytes(b[0:32],'big'); ln=int.from_bytes(b[off:off+32],'big')
        return b[off+32:off+32+ln].decode('utf8','replace')
    except: return None

d=json.load(open('/home/heisenberg/CA/metropolis-dlmm/analysis/vaults_raw.json'))
toks=sorted(set([x['tokenX'] for x in d]+[x['tokenY'] for x in d]))
info={}
for i in range(0,len(toks),40):
    chunk=toks[i:i+40]
    calls=[]
    for t in chunk: calls+= [{"to":t,"data":SEL_SYM},{"to":t,"data":SEL_DEC}]
    r=rpc_batch(calls)
    for j,t in enumerate(chunk):
        info[t]={"symbol":dec_str(r[2*j]),"decimals":int(r[2*j+1],16) if r[2*j+1] and r[2*j+1]!="0x" else None}
print(json.dumps(info,indent=1))
json.dump(info,open('/home/heisenberg/CA/metropolis-dlmm/analysis/tokens.json','w'),indent=1)
EOF_MARKER = None
