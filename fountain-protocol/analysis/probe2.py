#!/usr/bin/env python3
"""Fountain Protocol probe #2 — impls, mining params, FTP token, oracle configs, storage."""
import json, sys, time, urllib.request

RPC = "https://emerald.oasis.dev"
_id = 0
def rpc(method, params):
    global _id
    _id += 1
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":_id,"method":method,"params":params}).encode(),
                                 headers={"Content-Type":"application/json","User-Agent":"fountain-probe/1.0"})
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=45) as r:
                out = json.loads(r.read())
            if "error" in out: return {"error": out["error"]}
            return out.get("result")
        except Exception as e:
            if attempt == 4: return {"error": str(e)}
            time.sleep(1.5*(attempt+1))

def call(to, sel, block, extra=""):
    return rpc("eth_call", [{"to": to, "data": "0x"+sel+extra}, hex(block)])

COMPTROLLERS = {
 "classic":"0xA7684aE7e07Dac91113900342b3ef25B9Fd1D841",
 "usd":"0x1C0C30795802Bf2B3232a824f41629BbBCF63127",
 "lpt":"0x7c4d0c834701C6E7F57b8c1424d30aDC46eA0840",
}
ORACLES = {
 "classic":"0x3789ae7132f2cad96553d378d13c58eb8508258f",
 "usd":"0x512efb22d9aa6024c332e0a2faf6895786cd95aa",
 "lpt":"0x13322c2911f73db4d4893cce068e2c6841207914",
}
MARKETS = {
 "classic":["0xd7d588babfb99e82cd6dd0ca7677a5599aa678b5","0x275b88547185d955f66e5dd1066e040af468fc66","0x352cc3320debffa3046cf66a4e0a80d528f00285","0x61d90f6ab2b2b1baffa39bebb5d8ad57028da258"],
 "usd":["0x2552707d66c102c12b0f8284824f80e1299cb6b7","0xbe5a2c8da347311c46b1f0868aa52b8eb59938b3","0x54cc15a99e40cc4a6d8a2ddc1b8ee65a2d7414e1","0x27d51cd65070d28463a42ee644a22353c2bbddf3"],
 "lpt":["0x63f1fe2e1da490611fc16e4a5d92b7ec7d0911a9","0xf377b8bcdd8e154ab8c846eebdf758f37be93381","0xb317c67b105f7e216f483618a91eaea3814b9b3c","0x3acaddeb99c714103683a1a061b793d53563f17c","0xb473e13cbb875c8f9598513cd4eb2c52b1b88173","0x6e298782e7bbc097442ed579d620d1b5a8e7dfd3","0x4be7e0ec31797d4d61fc07dbf0f843ae04a58f05"],
}
FTP = "0xd1dF9CE4b6159441D18BD6887dbd7320a8D52a05"
S = {
 "comptrollerImplementation()":"bb82aa5e","pendingComptrollerImplementation()":"dcfbc0c7","implementation()":"5c60da1b",
 "startSpeedTime()":"0cfbeb95","reductionPeriod()":"ba624f44","isMiningInit()":"f3808b4f",
 "seizeGuardianPaused()":"ac0b0bb7","transferGuardianPaused()":"87f76303","_mintGuardianPaused()":"3c94786f",
 "_borrowGuardianPaused()":"e6653f3d","borrowCaps(address)":"4a584432",
 "compSupplySpeeds(address)":"6aa875b5","compBorrowSpeeds(address)":"f4a433c0","compAccrued(address)":"cc7ebdc4",
 "symbol()":"95d89b41","decimals()":"313ce567","totalSupply()":"18160ddd","balanceOf(address)":"70a08231",
 "CTokenConfigs(string)":"79f4e7ea","cTokenSymbol(address)":"58b393b2",
 "totalBorrows()":"47bd3718","borrowIndex()":"aa5af0fd","interestRateModel()":"f3fdb15a",
 "exchangeRateStored()":"182df0f5","getCash()":"3b1d21a2","totalReserves()":"8f840ddd",
}
def pad(addr): return addr[2:].lower().rjust(64,"0")

def dec_str(h):
    if not isinstance(h,str) or h=="0x": return None
    b=bytes.fromhex(h[2:])
    try:
        if len(b)>=64:
            off=int.from_bytes(b[:32],"big"); ln=int.from_bytes(b[off:off+32],"big")
            return b[off+32:off+32+ln].decode("utf-8","replace")
        return b.decode("utf-8","replace")
    except Exception: return None

def main():
    latest = int(rpc("eth_blockNumber",[]),16); block = latest-2
    out={"pinned_block":block,"latest":latest}
    # comptrollers
    out["comptrollers"]={}
    for label,c in COMPTROLLERS.items():
        o={"address":c}
        for k,sel in [("comptrollerImplementation",S["comptrollerImplementation()"]),
                      ("pendingComptrollerImplementation",S["pendingComptrollerImplementation()"]),
                      ("startSpeedTime",S["startSpeedTime()"]),("reductionPeriod",S["reductionPeriod()"]),
                      ("isMiningInit",S["isMiningInit()"]),("seizeGuardianPaused",S["seizeGuardianPaused()"]),
                      ("transferGuardianPaused",S["transferGuardianPaused()"]),("_mintGuardianPaused",S["_mintGuardianPaused()"]),
                      ("_borrowGuardianPaused",S["_borrowGuardianPaused()"])]:
            o[k]=call(c,sel,block)
        o["markets"]={}
        for m in MARKETS[label]:
            mm=pad(m)
            d={}
            d["borrowCaps"]=call(c,S["borrowCaps(address)"],block,mm)
            d["compSupplySpeeds"]=call(c,S["compSupplySpeeds(address)"],block,mm)
            d["compBorrowSpeeds"]=call(c,S["compBorrowSpeeds(address)"],block,mm)
            o["markets"][m]=d
        out["comptrollers"][label]=o
    # FTP token
    ftp={}
    for k,sel in [("symbol",S["symbol()"]),("decimals",S["decimals()"]),("totalSupply",S["totalSupply()"])]:
        ftp[k]=call(FTP,sel,block)
    ftp["balances"]={}
    for name,addr in list(COMPTROLLERS.items()):
        ftp["balances"][f"comptroller_{name}"]=call(FTP,S["balanceOf(address)"],block,pad(COMPTROLLERS[name]))
    for name,addr in [("deployer_guess_5d4ae9","0x5d4ae9ecbeea7038324582d8b4b745a715ddfb72"),
                      ("admin2_4ce415","0x4ce41518591272a42406b4829f6c4f66907891e9"),
                      ("guardian_c8c8ae","0xc8c8ae893611a617d128742abe5aed7952c71b7c"),
                      ("fountain_token_holder_probe","0x0000000000000000000000000000000000000000")]:
        ftp["balances"][name]=call(FTP,S["balanceOf(address)"],block,pad(addr))
    out["ftp_token"]=ftp
    # cToken impl + extras
    out["cmarkets"]={}
    for label,ms in MARKETS.items():
        for m in ms:
            d={}
            d["implementation"]=call(m,S["implementation()"],block)
            d["interestRateModel"]=call(m,S["interestRateModel()"],block)
            d["borrowIndex"]=call(m,S["borrowIndex()"],block)
            out["cmarkets"][m]=d
    # oracle storage slot 0 (ref) + configs
    out["oracles"]={}
    for label,o in ORACLES.items():
        d={}
        d["slot0_ref"]=rpc("eth_getStorageAt",[o,"0x0",hex(block)])
        d["code_size"]=len(rpc("eth_getCode",[o,hex(block)]) or "0x")//2-1
        out["oracles"][label]=d
    # LPT oracle configs for each lpt market symbol
    lpt_symbols={}
    for m in MARKETS["lpt"]:
        sy=call(m,S["symbol()"],block)
        lpt_symbols[m]=dec_str(sy)
    out["lpt_symbols"]=lpt_symbols
    out["lpt_oracle_configs"]={}
    for m,sym in lpt_symbols.items():
        if sym:
            # encode string arg
            b=sym.encode(); off=32; ln=len(b)
            data=(off).to_bytes(32,"big").hex()+ (ln).to_bytes(32,"big").hex() + b.hex().ljust(64,"0")
            out["lpt_oracle_configs"][sym]=call(ORACLES["lpt"],S["CTokenConfigs(string)"],block,data)
    # classic/usd oracle configs: cTokenSymbol(market)
    out["oracle_symbols"]={}
    for label,ms in MARKETS.items():
        for m in ms:
            out["oracle_symbols"][m]=call(ORACLES[label],S["cTokenSymbol(address)"],block,pad(m))
    print(json.dumps(out,indent=1))

if __name__=="__main__":
    main()
