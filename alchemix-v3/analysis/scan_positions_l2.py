from rpc import batch, block_number, uint, sel
import json,sys
M={
 "base_alUSDb":("base","0xEb380d86EeD275C9F2eD77745aB1B2ccf364BF7A",75,"0xb8BeFE5a6941ca4022a52042075ff269C3C67467"),
 "op_alUSD":("optimism","0x930750a3510E703535e943E826ABa3c364fFC1De",1950,"0xAf510a560744880410f0f65e3341A020FBC2cA41"),
 "arb_alUSD":("arbitrum","0x930750a3510E703535e943E826ABa3c364fFC1De",1454,"0xEba62B842081CeF5a8184318Dc5C4E4aACa9f651"),
}
s=sel("getCDP(uint256)")
for k,(chain,alch,n,myt) in M.items():
    bn=block_number(chain)
    res=batch(chain,[(alch,s+hex(i)[2:].zfill(64)) for i in range(1,n+1)],bn,chunk=(5 if chain=="optimism" else 20))
    rows=[]
    for i,r in enumerate(res,1):
        if not r or isinstance(r,dict) or len(r)<2: continue
        h=r[2:]; col=int(h[0:64],16); debt=int(h[64:128],16); ear=int(h[128:192],16)
        if col or debt: rows.append((i,col,debt,ear))
    pr=batch(chain,[(myt,sel("convertToAssets(uint256)")+hex(10**18)[2:].zfill(64))],bn,chunk=1)[0]
    px=uint(pr)
    worst=[]
    for i,col,debt,ear in rows:
        if debt==0: continue
        cv=col*px//10**18*10**12
        worst.append((cv/debt if debt else 99,i,col,debt,ear))
    worst.sort()
    print(k,"ids",n,"nonzero",len(rows),"withDebt",len(worst),"price",px/1e18)
    print("  worst",[(round(c,4),i) for c,i,*_ in worst[:5]])
    print("  <1.0526",sum(1 for c,*_ in worst if c<1.0526),"<1.1111",sum(1 for c,*_ in worst if c<1.1111))
    json.dump([{"id":i,"cr":c,"collateral":col,"debt":debt,"ear":e} for c,i,col,debt,e in worst],open(f"health_{k}.json","w"),indent=1)
