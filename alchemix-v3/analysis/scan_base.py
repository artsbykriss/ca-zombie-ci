from rpc import batch, block_number, uint, sel
import json
chain="base"; alch="0xEb380d86EeD275C9F2eD77745aB1B2ccf364BF7A"; n=75; myt="0xb8BeFE5a6941ca4022a52042075ff269C3C67467"
bn=block_number(chain); s=sel("getCDP(uint256)")
res=batch(chain,[(alch,s+hex(i)[2:].zfill(64)) for i in range(1,n+1)],bn,chunk=10)
px=uint(batch(chain,[(myt,sel("convertToAssets(uint256)")+hex(10**18)[2:].zfill(64))],bn,chunk=1)[0])
rows=[]
for i,r in enumerate(res,1):
    if not r or isinstance(r,dict) or len(r)<2: continue
    h=r[2:]; col=int(h[0:64],16); debt=int(h[64:128],16); ear=int(h[128:192],16)
    if col or debt: rows.append((i,col,debt,ear))
worst=[]
for i,col,debt,ear in rows:
    cv=col*px//10**18*10**12
    worst.append((cv/debt if debt else 99,i,col,debt,ear))
worst.sort()
print("base block",bn,"price per 1e18",px,"nonzero",len(rows))
for c,i,col,debt,ear in worst[:15]: print(round(c,5),i,col,debt,ear)
print("with debt",sum(1 for w in worst if w[3]>0),"<1.0526",sum(1 for w in worst if w[3]>0 and w[0]<1.0526),"<1.1111",sum(1 for w in worst if w[3]>0 and w[0]<1.1111))
json.dump([{"id":i,"cr":c,"collateral":col,"debt":debt,"ear":ear} for c,i,col,debt,ear in worst],open("health_base_alUSDb.json","w"),indent=1)
