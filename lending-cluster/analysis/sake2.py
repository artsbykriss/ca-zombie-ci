from rpc import call,code
import json
POOL="0x3c3987a310ee13f7b8cbbe21d97d4436ba5e4b5f"
ORACLE="0x18530af497f558e23134e223244f353ea776af2a"
assets=["0x4200000000000000000000000000000000000006","0x2cae934a1e84f693fbb78ca5ed3b0a6893259441","0xba9986d2381edf1da03b0b9c1f8b00dc4aacc369","0xf24e57b1cb00d98c31f04f86328e22e8fca457fb","0x3a337a6ada9d885b6ad95ec48f9b75f197b5ae35","0x541fd749419ca806a8bc7da8ac23d346f2df8b77","0xcc0966d8418d412c599a6421b760a847eb169a8c","0x6c460b2c6d6719562d5da43e5152b375e79b9a8b","0x102d758f688a4c1c5a80b116bd945d4455460282","0xaffeb8576b927050f5a3b6fba43f360d2883a118","0x139450c2dcef827c9a2a0bb1cb5506260940c9fd","0x2a52b289ba68bbd02676640aa9f605700c9e5699"]
def sel(sig):
    import subprocess; return subprocess.check_output(["cast","sig",sig]).decode().strip()
def c(to,data):
    r=call("soneium",to,data); return r.get("result") or r
def dec(res,types):
    from eth_abi import decode
    data=bytes.fromhex(res[2:]) if res.startswith("0x") else None
    return decode(types,data)
try:
    from eth_abi import decode
except ImportError:
    import subprocess; subprocess.run(["pip","install","eth_abi","-q"])
    from eth_abi import decode
for a in assets:
    try:
        sym=dec(c(a,sel("symbol()")),["string"])[0]
    except Exception as e:
        try: sym=dec(c(a,sel("symbol()")),["bytes32"])[0].decode(errors='ignore').strip('\x00')
        except: sym="?"
    try: decm=dec(c(a,sel("decimals()")),["uint8"])[0]
    except: decm="?"
    conf=c(POOL, sel("getReserveConfigurationData(address)")+a[2:].rjust(64,'0'))
    try:
        vals=dec(conf,["uint256","uint256","uint256","uint256","uint256","bool","bool","bool","bool","bool"])
        ltv,liqth,liqbonus,rf,decp,uc,b,e,act,frz=vals
        cfg=f"ltv={ltv/1e4:.2f}% liqth={liqth/1e4:.2f}% bonus={liqbonus/1e4:.2f}x rf={rf/1e4:.2f} active={act} frozen={frz}"
    except Exception as e: cfg=f"ERR {e} {conf[:80]}"
    try:
        rd=c(POOL, sel("getReserveData(address)")+a[2:].rjust(64,'0'))
        vals=dec(rd,["uint256","uint128","uint128","uint128","uint128","uint128","uint40","uint16","address","address","address","address","uint128","uint128","uint128"])
        # v3 struct: configuration, liquidityIndex, currentLiquidityRate, variableBorrowIndex, currentVariableBorrowRate, currentStableBorrowRate, lastUpdateTimestamp, id, aToken, stableDebt, variableDebt, interestRateStrategy, liquidity, totalVariableDebt, totalStableDebt... let's print raw
        unavail=vals[12]
        tvd=vals[13]
        tsd=vals[14]
        rdstr=f"avail={unavail/10**decm if isinstance(decm,int) else unavail} vDebt={tvd/10**decm if isinstance(decm,int) else tvd} sDebt={tsd/10**decm if isinstance(decm,int) else tsd} aTok={vals[8]} vTok={vals[10]}"
    except Exception as e: rdstr=f"ERR {e} {rd[:80]}"
    try:
        price=dec(c(ORACLE, sel("getAssetPrice(address)")+a[2:].rjust(64,'0')),["uint256"])[0]
        src=c(ORACLE, sel("getSourceOfAsset(address)")+a[2:].rjust(64,'0'))
        srcaddr="0x"+src[-40:]
        pr=f"price={price/1e8:.6f} src={srcaddr}"
    except Exception as e: pr=f"priceERR {e}"
    print(a,sym,decm,"|",cfg,"|",rdstr,"|",pr)
print("oracle BASE", c(ORACLE,sel("BASE_CURRENCY()")), c(ORACLE,sel("BASE_CURRENCY_UNIT()")))
