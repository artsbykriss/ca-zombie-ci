#!/usr/bin/env python3
import json,os,sys,urllib.request
URL=os.environ["D"]
PV="0xf9cfb8a62f50e10adde5aa888b44cf01c5957055"
SEL="0x9403b634"
def one(k):
    body=[{"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":PV,"data":SEL+hex(k)[2:].rjust(64,'0')},"latest"]}]
    for _ in range(3):
        try:
            req=urllib.request.Request(URL,data=json.dumps(body).encode(),headers={"content-type":"application/json","user-agent":"research/1.0"})
            r=json.load(urllib.request.urlopen(req,timeout=30))
            return [(k,r[0].get('result'),r[0].get('error'))]
        except Exception as ex:
            err=ex
    return [(k,None,str(err))]
res=[]
for k,r,e in [x for kk in range(1,130) for x in one(kk)]:
    if e or not r or len(r)<2+64*34: res.append((k,None)); continue
    w=[r[2+i*64:2+(i+1)*64] for i in range(34)]
    d=dict(gauge="0x"+w[0][24:],pair="0x"+w[1][24:],token0="0x"+w[2][24:],token1="0x"+w[3][24:],
      stable=bool(int(w[4],16)),paused=bool(int(w[5],16)),frozen=bool(int(w[6],16)),
      borrowEnabled=bool(int(w[7],16)),liqTWAP=bool(int(w[8],16)),
      maxLev=int(w[9],16),premLev=int(w[10],16),maxPriceDiff=int(w[11],16),
      liqDebtRatio=int(w[12],16),wfee=int(w[13],16),cfee=int(w[14],16),lfee=int(w[15],16),
      totalLp=int(w[24],16),totalLpShares=int(w[25],16),minSwap0=int(w[22],16),minSwap1=int(w[23],16))
    res.append((k,d))
json.dump(res,open("evidence/extra_op_vaults.json","w"),indent=1)
live=[(k,d) for k,d in res if d and d['totalLp']>0]
print("total",len(res),"live",len(live))
for k,d in live: print(k,d['pair'],d['token0'],d['token1'],"stable",d['stable'],"liq",d['liqTWAP'],"lev",d['maxLev'],"liqRatio",d['liqDebtRatio'],"lfee",d['lfee'],"lp",d['totalLp'])
