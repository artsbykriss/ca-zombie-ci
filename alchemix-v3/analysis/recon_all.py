from rpc import batch, block_number, uint, addr, sel
import json
V={
 "ethereum": {"WETH":"0x29bcfeD246ce37319d94eBa107db90C453D4c43D","USDC":"0x9B44efCa3e2a707B63Dc00CE79d646E5E5D24bA5"},
 "optimism": {"WETH":"0x91b8657aea26Caa8A0E9D6DD4E24727Ccf32F822","USDC":"0xAf510a560744880410f0f65e3341A020FBC2cA41"},
 "arbitrum": {"WETH":"0xfe8F223F3d81462F55bf8609897B8cEcfA4B195C","USDC":"0xEba62B842081CeF5a8184318Dc5C4E4aACa9f651"},
 "base": {"USDC":"0xb8BeFE5a6941ca4022a52042075ff269C3C67467"},
}
fns=["asset","name","symbol","decimals","totalAssets","totalSupply","owner","curator","maxRate","performanceFee","managementFee","performanceFeeRecipient","liquidityAdapter","adapterRegistry","receiveSharesGate","sendSharesGate","receiveAssetsGate","sendAssetsGate","adaptersLength","virtualShares","lastUpdate"]
sels={f:sel(f+"()") for f in fns}
out={}
for chain,vs in V.items():
    try: bn=block_number(chain)
    except Exception as e: print(chain,"blocknum err",e); continue
    calls=[]
    for a in vs.values():
        calls += [(a,sels[f]) for f in fns]
    res=batch(chain,calls,bn)
    i=0
    for k,a in vs.items():
        d={"chain":chain,"block":bn}
        for f in fns:
            r=res[i]; i+=1
            if f in ("name","symbol"):
                try:
                    h=r[2:]; ln=int(h[64:128],16); d[f]=bytes.fromhex(h[128:128+ln*2]).decode()
                except Exception: d[f]=r
            elif f in ("asset","owner","curator","performanceFeeRecipient","liquidityAdapter","adapterRegistry","receiveSharesGate","sendSharesGate","receiveAssetsGate","sendAssetsGate"):
                d[f]=addr(r)
            else: d[f]=uint(r)
        out[chain+":"+k]=d
        print(chain,k,d["name"],d["totalAssets"],d["totalSupply"],"adapters",d["adaptersLength"],"maxRate",d["maxRate"])
json.dump(out,open("myt_vaults_all.json","w"),indent=1)
