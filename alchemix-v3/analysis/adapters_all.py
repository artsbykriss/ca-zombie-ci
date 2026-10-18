from rpc import batch, block_number, uint, addr, sel
import json
V=json.load(open("myt_vaults_all.json"))
out={}
for key,d in V.items():
    chain=d["chain"]; v=d.get("_addr") or {
     "ethereum:WETH":"0x29bcfeD246ce37319d94eBa107db90C453D4c43D","ethereum:USDC":"0x9B44efCa3e2a707B63Dc00CE79d646E5E5D24bA5",
     "optimism:WETH":"0x91b8657aea26Caa8A0E9D6DD4E24727Ccf32F822","optimism:USDC":"0xAf510a560744880410f0f65e3341A020FBC2cA41",
     "arbitrum:WETH":"0xfe8F223F3d81462F55bf8609897B8cEcfA4B195C","arbitrum:USDC":"0xEba62B842081CeF5a8184318Dc5C4E4aACa9f651",
     "base:USDC":"0xb8BeFE5a6941ca4022a52042075ff269C3C67467"}[key]
    n=d["adaptersLength"]; bn=d["block"]
    res=batch(chain,[(v,sel("adapters(uint256)")+hex(i)[2:].zfill(64)) for i in range(n)],bn)
    ads=[addr(r) for r in res]
    # read owner + MYT + killSwitch + realAssets for each adapter
    fns=["owner()","MYT()","killSwitch()","realAssets()"]
    calls=[]
    for a in ads:
        for f in fns: calls.append((a,sel(f)))
    r2=batch(chain,calls,bn)
    i=0; rows=[]
    for a in ads:
        row={"adapter":a}
        for f in fns:
            r=r2[i]; i+=1
            if f in ("owner()","MYT()"): row[f[:-2]]=addr(r)
            else: row[f[:-2]]=uint(r)
        rows.append(row)
    out[key]={"vault":v,"chain":chain,"block":bn,"adapters":rows}
    print(key,"vault",v)
    for r in rows: print("  ",r["adapter"],"owner",r["owner"],"kill",r["killSwitch"],"realAssets",r["realAssets"])
json.dump(out,open("myt_adapters_all.json","w"),indent=1)
