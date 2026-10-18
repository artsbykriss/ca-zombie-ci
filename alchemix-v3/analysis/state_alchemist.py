from rpc import batch, block_number, uint, addr, sel
import json
A={
 "alUSD":{"alchemist":"0xeB83112d925268BeDe86654C13D423a987587e3E","nft":"0x872a03FabC86b59c883CD9c439E969321b719bEB","feevault":"0x5B1c7180C630d3B2b6782Df70f43aE5Ea80425ba","transmuter":"0x2584E8b0616b3E750492c9629a3b27679C410cb9"},
 "alETH":{"alchemist":"0xfa995B6ABc387376C3e7De5f6d394Ab5B6beE26B","nft":"0x15da4c7db6404b92894d5214FAc92057Fb8a263d","feevault":"0x5FE3963cb35AB635bD3A11E4F9730fC07293f9c1","transmuter":"0x073598132f37756a7E665FB52f1757463120bd3C"},
}
fns=["totalSyntheticsIssued()","getTotalUnderlyingValue()","getTotalLockedUnderlyingValue()","getTotalDeposited()","depositCap()","totalDebt()","cumulativeEarmarked()","minimumCollateralization()","collateralizationLowerBound()","liquidationTargetCollateralization()","globalMinimumCollateralization()","liquidatorFee()","protocolFee()","repaymentFee()","myt()","underlyingToken()","debtToken()","depositsPaused()","loansPaused()","admin()","transmuter()"]
bn=block_number("ethereum")
out={}
for k,v in A.items():
    calls=[(v["alchemist"],sel(f)) for f in fns]
    calls+=[(v["nft"],sel("totalSupply()")),(v["feevault"],sel("totalDeposits()"))]
    res=batch("ethereum",calls,bn)
    d={"block":bn}
    for i,f in enumerate(fns):
        r=res[i]
        d[f[:-2]]=addr(r) if f in ("myt()","underlyingToken()","debtToken()","admin()","transmuter()") else uint(r)
    d["nftTotalSupply"]=uint(res[len(fns)])
    d["feeVaultTotalDeposits"]=uint(res[len(fns)+1])
    out[k]=d
    print(k,json.dumps(d,default=str))
json.dump(out,open("alchemist_state_eth.json","w"),indent=1)
