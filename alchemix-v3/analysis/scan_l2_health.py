from rpc import batch, block_number, uint, sel
import json
M={
 "op_alUSD":("optimism","0x930750a3510E703535e943E826ABa3c364fFC1De",1950,"0xAf510a560744880410f0f65e3341A020FBC2cA41",1e12),
 "op_alETH":("optimism","0xDeD3A04612FF12b57317abE38e68026Fc9D28114",914,"0x91b8657aea26Caa8A0E9D6DD4E24727Ccf32F822",1),
 "arb_alUSD":("arbitrum","0x930750a3510E703535e943E826ABa3c364fFC1De",1454,"0xEba62B842081CeF5a8184318Dc5C4E4aACa9f651",1e12),
 "arb_alETH":("arbitrum","0xDeD3A04612FF12b57317abE38e68026Fc9D28114",411,"0xfe8F223F3d81462F55bf8609897B8cEcfA4B195C",1),
}
s=sel("getCDP(uint256)")
for k,(chain,alch,n,myt,fac) in M.items():
    bn=block_number(chain)
    res=batch(chain,[(alch,s+hex(i)[2:].zfill(64)) for i in range(1,n+1)],bn,chunk=30)
    px=uint(batch(chain,[(myt,sel("convertToAssets(uint256)")+hex(10**18)[2:].zfill(64))],bn,chunk=1)[0])
    rows=[]
    for i,r in enumerate(res,1):
        if not r or isinstance(r,dict) or len(r)<2: continue
        h=r[2:]; col=int(h[0:64],16); debt=int(h[64:128],16); ear=int(h[128:192],16)
        if col or debt: rows.append((i,col,debt,ear))
    worst=[]
    for i,col,debt,ear in rows:
        cv=col*px//10**18*fac
        worst.append((cv/debt if debt else 99,i,col,debt,ear))
    worst.sort()
    print(k,"block",bn,"price",px,"nonzero",len(rows),"withDebt",sum(1 for w in worst if w[3]>0),"<1.0526",sum(1 for w in worst if w[3]>0 and w[0]<1.0526),"<1.1111",sum(1 for w in worst if w[3]>0 and w[0]<1.1111),flush=True)
    print(" worst",[(round(c,4),i) for c,i,*_ in worst[:5]],flush=True)
    json.dump([{"id":i,"cr":c,"collateral":col,"debt":debt,"ear":ear} for c,i,col,debt,ear in worst],open(f"health_{k}.json","w"),indent=1)
