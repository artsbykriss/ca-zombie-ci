#!/usr/bin/env python3
"""Compare on-chain MultiLockMoat runtime bytecode vs local viaIR recompile, masking immutable slots."""
import json, urllib.request, sys

UA={"Content-Type":"application/json","User-Agent":"Mozilla/5.0 research"}

def rpc(url,method,params):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req=urllib.request.Request(url,data=body,headers=UA)
    return json.loads(urllib.request.urlopen(req,timeout=60).read())["result"]

def getcode(url,addr,block="latest"):
    return rpc(url,"eth_getCode",[addr,block])

art=json.load(open('/home/heisenberg/CA/moats/poc/out/MultiLockMoat.sol/MultiLockMoat.json'))
comp=art['deployedBytecode']['object']
if comp.startswith('0x'): comp=comp[2:]
imm=art['deployedBytecode']['immutableReferences']
ranges=[]
for k,v in imm.items():
    for r in v:
        ranges.append((r['start']*2, r['length']*2))

def mask(hexstr):
    h=list(hexstr)
    for s,l in ranges:
        for i in range(s,s+l):
            if i < len(h): h[i]='0'
    return ''.join(h)

compm=mask(comp)

# gather addresses
d=json.load(open('/home/heisenberg/CA/moats/analysis/childA/enum-all.json'))
targets=[("avax","https://avalanche-c-chain-rpc.publicnode.com",m['address']) for m in d['chains']['avax']['moats']]
rh=["0x57e7e1D6eb7C9E3A5D2a5B4d8FfF0d667c840272","0x56B6864eBf43d8fa5F4B729Fd706627D466115E9","0x527C5FF76247FeC4d26D3fc664C0192313786b0E","0x989ea8325138026c80D11167F0e04eA5ce6047da","0x1cc326b8a13F89E7dE64dD073E5A1a9FdcdD1D28"]
targets += [("robinhood","https://robinhood.drpc.org",a) for a in rh]

results=[]
for chain,url,addr in targets:
    code=getcode(url,addr)
    if code.startswith('0x'): code=code[2:]
    if len(code)!=len(comp):
        results.append((chain,addr,"LEN_MISMATCH",len(code)//2,len(comp)//2,None)); continue
    cm=mask(code)
    if cm==compm:
        results.append((chain,addr,"MATCH",None,None,None))
    else:
        # find diffs
        diffs=[i for i in range(len(cm)) if cm[i]!=compm[i]]
        results.append((chain,addr,"DIFF",len(diffs),None,diffs[:20]))

for r in results:
    print(r)
print("TOTAL", len(results))
