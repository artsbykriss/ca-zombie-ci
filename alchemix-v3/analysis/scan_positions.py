from rpc import batch, block_number, uint, addr, sel
import json
M={
 "alUSD":{"alchemist":"0xeB83112d925268BeDe86654C13D423a987587e3E","nft":"0x872a03FabC86b59c883CD9c439E969321b719bEB","n":1244},
 "alETH":{"alchemist":"0xfa995B6ABc387376C3e7De5f6d394Ab5B6beE26B","nft":"0x15da4c7db6404b92894d5214FAc92057Fb8a263d","n":860},
}
bn=block_number("ethereum")
s=sel("getCDP(uint256)")
out={}
for k,v in M.items():
    ids=list(range(1,v["n"]+1))
    res=batch("ethereum",[(v["alchemist"],s+hex(i)[2:].zfill(64)) for i in ids],bn,chunk=20)
    rows=[]
    for i,r in zip(ids,res):
        if not r or isinstance(r,dict) or len(r)<2: continue
        h=r[2:]
        col=int(h[0:64],16); debt=int(h[64:128],16); ear=int(h[128:192],16)
        if col or debt: rows.append({"id":i,"collateral":col,"debt":debt,"earmarked":ear})
    out[k]={"block":bn,"total_ids":v["n"],"nonzero":len(rows),"rows":rows}
    print(k,"nonzero",len(rows))
json.dump(out,open("positions_eth.json","w"),indent=1)
