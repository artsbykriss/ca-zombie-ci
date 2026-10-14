#!/usr/bin/env python3
"""Probe #4: account liquidity for known borrowers/suppliers; compAccrued; usd borrower position."""
import json, urllib.request, sys, time

RPC = "https://emerald.oasis.dev"
_id=0
def rpc(method, params):
    global _id; _id+=1
    req=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":_id,"method":method,"params":params}).encode(),
                               headers={"Content-Type":"application/json","User-Agent":"fountain-probe/1.0"})
    for a in range(5):
        try:
            with urllib.request.urlopen(req,timeout=45) as r: out=json.loads(r.read())
            if "error" in out: return {"error":out["error"]}
            return out.get("result")
        except Exception as e:
            if a==4: return {"error":str(e)}
            time.sleep(1.5*(a+1))
def u(h): return None if not isinstance(h,str) or h=="0x" else int(h,16)
def pad(a): return a[2:].lower().rjust(64,"0")

COMPTROLLERS={"classic":"0xA7684aE7e07Dac91113900342b3ef25B9Fd1D841","usd":"0x1C0C30795802BfB3232a824f41629BbBCF63127","lpt":"0x7c4d0c834701C6E7F57b8c1424d30aDC46eA0840"}
MARKETS={
 "classic":["0xd7d588babfb99e82cd6dd0ca7677a5599aa678b5","0x275b88547185d955f66e5dd1066e040af468fc66","0x352cc3320debffa3046cf66a4e0a80d528f00285","0x61d90f6ab2b2b1baffa39bebb5d8ad57028da258"],
 "usd":["0x2552707d66c102c12b0f8284824f80e1299cb6b7","0xbe5a2c8da347311c46b1f0868aa52b8eb59938b3","0x54cc15a99e40cc4a6d8a2ddc1b8ee65a2d7414e1","0x27d51cd65070d28463a42ee644a22353c2bbddf3"],
 "lpt":["0x63f1fe2e1da490611fc16e4a5d92b7ec7d0911a9","0xf377b8bcdd8e154ab8c846eebdf758f37be93381","0xb317c67b105f7e216f483618a91eaea3814b9b3c","0x3acaddeb99c714103683a1a061b793d53563f17c","0xb473e13cbb875c8f9598513cd4eb2c52b1b88173","0x6e298782e7bbc097442ed579d620d1b5a8e7dfd3","0x4be7e0ec31797d4d61fc07dbf0f843ae04a58f05"],
}
ACCOUNTS=[
 # classic known borrowers / suppliers
 "0xf8aae8d5dd1d7697a4ec6f561737e68a2ab8539e","0x3c817fbf5d7425654fa7aaf63a93e951bbb93409",
 "0xbc4ea2bd8b03d7c5b87f6f5bcd6009037155d080","0x4ec0306f5d0e40bc6890031980691e832321b09a",
 "0xb4049a0d745c1ba5d679ed7898d42d19fb32872a","0x3d05bc525ad296c246901f38b23542692ab54a8d",
 "0x98c89980d1eae247ada3636ae27648f78e66e121","0x1f5e8942d652d9b1f639a3f1f797d767ba458668",
 "0xe0da368dbe7eef9d3575971f70409580ba90088d","0xe8a78a339d144b15cc9976c569d5f85d3fccf1fd",
 # usd borrower
 "0x9046fe485de18bb60a72172bc5ce99afa06cf616",
 # lpt borrowers (from cache)
 "0xf9d3c7a6faa853d8915562e32f90fba5704e468c","0x94aa22b1e578b34cd072501e70c058598ce80ad7",
 "0x62616bb4f919dd601445f63f6d1add393a683e0a","0x5ca83d32054d6b8b2c98bca7879e94eb57570d28",
 "0x4d6438f985612e6c8c3dccc3f3e90813ac2094c3","0x6c489eec64e0d1f6e16cee7b61efc7299ac4a01b",
]

def call(to, data, block):
    return rpc("eth_call",[{"to":to,"data":data},hex(block)])

def main():
    latest=int(rpc("eth_blockNumber",[]),16); block=latest-2
    out={"block":block,"accounts":{}}
    for acct in ACCOUNTS:
        row={"comptrollers":{}, "markets":{}}
        for label,c in COMPTROLLERS.items():
            r=call(c,"0x5ec88c79"+pad(acct),block)  # getAccountLiquidity(address)
            if isinstance(r,str) and len(r)>=194:
                err=u("0x"+r[2:66]); liq=u("0x"+r[66:130]); short=u("0x"+r[130:194])
                row["comptrollers"][label]={"err":err,"liquidity":liq,"shortfall":short}
            else:
                row["comptrollers"][label]=r
        for label,ms in MARKETS.items():
            for m in ms:
                r=call(m,"0xc37f68e2"+pad(acct),block)  # getAccountSnapshot
                if isinstance(r,str) and len(r)>=258:
                    err=u("0x"+r[2:66]); ctok=u("0x"+r[66:130]); debt=u("0x"+r[130:194]); exr=u("0x"+r[194:258])
                    if ctok or debt:
                        row["markets"][m]={"err":err,"cTokens":ctok,"borrowBalance":debt,"exchangeRate":exr}
        # compAccrued on each comptroller
        row["compAccrued"]={}
        for label,c in COMPTROLLERS.items():
            r=call(c,"0xcc7ebdc4"+pad(acct),block)
            row["compAccrued"][label]=u(r) if isinstance(r,str) else r
        out["accounts"][acct]=row
    print(json.dumps(out,indent=1))

if __name__=="__main__":
    main()
