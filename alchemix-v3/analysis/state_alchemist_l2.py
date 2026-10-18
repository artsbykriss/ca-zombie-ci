from rpc import batch, block_number, uint, addr, sel
import json
M={
 "op_alUSD":("optimism","0x930750a3510E703535e943E826ABa3c364fFC1De","0xF700c7e40efCA6f7a810e172AFCee3592ff4aD33"),
 "op_alETH":("optimism","0xDeD3A04612FF12b57317abE38e68026Fc9D28114","0x763F5d567403add750e13234DB896CFe6b423059"),
 "arb_alUSD":("arbitrum","0x930750a3510E703535e943E826ABa3c364fFC1De","0xF700c7e40efCA6f7a810e172AFCee3592ff4aD33"),
 "arb_alETH":("arbitrum","0xDeD3A04612FF12b57317abE38e68026Fc9D28114","0x763F5d567403add750e13234DB896CFe6b423059"),
 "base_alUSDb":("base","0xEb380d86EeD275C9F2eD77745aB1B2ccf364BF7A","0xDeD3A04612FF12b57317abE38e68026Fc9D28114"),
}
fns=["totalSyntheticsIssued()","getTotalUnderlyingValue()","getTotalDeposited()","minimumCollateralization()","collateralizationLowerBound()","liquidatorFee()","myt()"]
out={}
for k,(chain,alch,nft) in M.items():
    try:
        bn=block_number(chain)
        calls=[(alch,sel(f)) for f in fns]+[(nft,sel("totalSupply()"))]
        res=batch(chain,calls,bn,chunk=5)
        d={"chain":chain,"block":bn}
        for i,f in enumerate(fns): d[f[:-2]]=addr(res[i]) if f=="myt()" else uint(res[i])
        d["nftTotalSupply"]=uint(res[len(fns)])
        out[k]=d; print(k,d)
    except Exception as e:
        print(k,"ERR",e)
json.dump(out,open("alchemist_state_l2.json","w"),indent=1)
