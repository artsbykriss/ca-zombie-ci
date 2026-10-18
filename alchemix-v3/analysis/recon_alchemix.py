import json, os, sys
from rpc import batch, block_number, uint, addr, sel

vaults = {
 "ethereum": ["0x9b44efca3e2a707b63dc00ce79d646e5e5d24ba5", "0x29bcfed246ce37319d94eba107db90c453d4c43d"],
}
fns = ["asset()","name()","symbol()","decimals()","totalAssets()","totalSupply()","owner()","curator()",
       "maxRate()","performanceFee()","managementFee()","performanceFeeRecipient()","managementFeeRecipient()",
       "liquidityAdapter()","adapterRegistry()","receiveSharesGate()","sendSharesGate()","receiveAssetsGate()",
       "sendAssetsGate()","adaptersLength()","virtualShares()","lastUpdate()"]
names=[f[:-2] for f in fns]
sels = {f: sel(f) for f in fns}

out = {}
for chain, addrs in vaults.items():
    bn = block_number(chain)
    calls = []
    for a in addrs:
        for f in fns: calls.append((a, sels[f]))
    res = batch(chain, calls, bn)
    i = 0
    for a in addrs:
        d = {"chain": chain, "block": bn}
        for f0 in fns:
            f = f0[:-2]
            r = res[i]; i += 1
            if f in ("name","symbol"):
                # ABI string decode
                try:
                    h = r[2:]; ln = int(h[64:128],16); d[f] = bytes.fromhex(h[128:128+ln*2]).decode()
                except Exception: d[f] = r
            elif f in ("asset","owner","curator","performanceFeeRecipient","managementFeeRecipient","liquidityAdapter","adapterRegistry","receiveSharesGate","sendSharesGate","receiveAssetsGate","sendAssetsGate"):
                d[f] = addr(r)
            else:
                v = uint(r)
                d[f] = v
        out[a] = d
print(json.dumps(out, indent=1))
json.dump(out, open("alchemix_vaults_eth.json","w"), indent=1)
