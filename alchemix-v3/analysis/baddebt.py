from rpc import batch, block_number, uint, sel
import json
M={
 "eth_alUSD":("ethereum","0xeB83112d925268BeDe86654C13D423a987587e3E","0x2584E8b0616b3E750492c9629a3b27679C410cb9","0x9B44efCa3e2a707B63Dc00CE79d646E5E5D24bA5",6),
 "eth_alETH":("ethereum","0xfa995B6ABc387376C3e7De5f6d394Ab5B6beE26B","0x073598132f37756a7E665FB52f1757463120bd3C","0x29bcfeD246ce37319d94eBa107db90C453D4c43D",18),
 "op_alUSD":("optimism","0x930750a3510E703535e943E826ABa3c364fFC1De","0x693b7594Ae0633d9c5574D0da46a040f92F5b281","0xAf510a560744880410f0f65e3341A020FBC2cA41",6),
 "op_alETH":("optimism","0xDeD3A04612FF12b57317abE38e68026Fc9D28114","0x2584E8b0616b3E750492c9629a3b27679C410cb9","0x91b8657aea26Caa8A0E9D6DD4E24727Ccf32F822",18),
 "arb_alUSD":("arbitrum","0x930750a3510E703535e943E826ABa3c364fFC1De","0x693b7594Ae0633d9c5574D0da46a040f92F5b281","0xEba62B842081CeF5a8184318Dc5C4E4aACa9f651",6),
 "arb_alETH":("arbitrum","0xDeD3A04612FF12b57317abE38e68026Fc9D28114","0x2584E8b0616b3E750492c9629a3b27679C410cb9","0xfe8F223F3d81462F55bf8609897B8cEcfA4B195C",18),
 "base_alUSDb":("base","0xEb380d86EeD275C9F2eD77745aB1B2ccf364BF7A","0x5B1c7180C630d3B2b6782Df70f43aE5Ea80425ba","0xb8BeFE5a6941ca4022a52042075ff269C3C67467",6),
}
out={}
for k,(chain,alch,tr,myt,dec) in M.items():
    try:
        bn=block_number(chain)
        fns=["totalSyntheticsIssued()","getTotalLockedUnderlyingValue()","convertYieldTokensToUnderlying(uint256)"]
        calls=[(alch,sel(fns[0])),(alch,sel(fns[1])),(alch,sel(fns[2])+hex(10**18)[2:].zfill(64)),(myt,"0x70a08231"+tr[2:].rjust(64,"0"))]
        r=batch(chain,calls,bn,chunk=4)
        syn=uint(r[0]); locked=uint(r[1]); oneShare=uint(r[2]); trShares=uint(r[3])
        # transmuter MYT value in underlying
        trval=trShares*oneShare//10**18
        backing=locked+trval
        ratio=syn*10**dec*10**18//(backing*10**18) if False else (syn*10**dec)/backing  # scaled 1e18 after /? syn(18)*10^dec/backing(dec) = 18-dec? normalize:
        ratio18=(syn*10**dec*10**18//backing)//10**18
        # simpler explicit
        ratio18=(syn*(10**dec)*10**18)//(backing*10**18)
        out[k]={"block":bn,"synthetics":syn,"lockedUnderlying":locked,"transmuterShares":trShares,"oneShareUnderlying":oneShare,"transmuterValue":trval,"backing":backing,"ratio":ratio18/1e18}
        print(k,"syn",syn/1e18,"locked",locked/10**dec,"trShares",trShares/1e18,"trVal",trval/10**dec,"backing",backing/10**dec,"badDebtRatio",ratio18/1e18)
    except Exception as e: print(k,"ERR",e)
json.dump(out,open("baddebt.json","w"),indent=1,default=str)
