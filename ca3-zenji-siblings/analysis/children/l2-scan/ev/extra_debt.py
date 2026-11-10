import json,os,urllib.request
from eth_hash.auto import keccak
SEL="0x"+keccak(b"getVault(uint256)")[:4].hex()
PV="0xf9cfb8a62f50e10adde5aa888b44cf01c5957055"
def one(url,k):
    body={"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":PV,"data":SEL+hex(k)[2:].rjust(64,'0')},"latest"]}
    req=urllib.request.Request(url,data=json.dumps(body).encode(),headers={"content-type":"application/json","user-agent":"research/1.0"})
    r=json.load(urllib.request.urlopen(req,timeout=25))
    return r.get("result")
for name,url,f,rng in [("op","https://mainnet.optimism.io","evidence/extra_op_vaults.json",range(1,130)),
                        ("base","https://mainnet.base.org","evidence/extra_base_vaults.json",range(1,140))]:
    d={k:v for k,v in json.load(open(f))}
    live=[k for k,v in d.items() if v and v['totalLp']>0]
    nz=[]; tot=0
    for k in live:
        r=one(url,int(k))
        if not r or len(r)<2+64*34: continue
        w=[r[2+i*64:2+(i+1)*64] for i in range(34)]
        d0=int(w[29],16); d1=int(w[32],16)  # debtTotalShares0, debtTotalShares1
        if d0 or d1: nz.append((k,d0,d1))
    print(name,"live",len(live),"with-debt-shares",len(nz), nz[:5])
