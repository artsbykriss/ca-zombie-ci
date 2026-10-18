from rpc import batch, block_number, uint, addr, sel
import json
V={"USDC":"0x9b44efca3e2a707b63dc00ce79d646e5e5d24ba5","WETH":"0x29bcfed246ce37319d94eba107db90c453d4c43d"}
bn=block_number("ethereum")
out={}
for k,v in V.items():
    n=uint(batch("ethereum",[(v,sel("adaptersLength()"))],bn)[0])
    calls=[(v,sel("adapters(uint256)")+hex(i)[2:].zfill(64)) for i in range(n)]
    res=batch("ethereum",calls,bn)
    ads=[addr(r) for r in res]
    out[k]={"vault":v,"adapters":ads,"block":bn}
    print(k,n,ads)
json.dump(out,open("alchemix_adapters.json","w"),indent=1)
