import json,subprocess
RPC="https://4663.rpc.thirdweb.com"
def call(to,data):
    p=subprocess.run(["cast","call",to,data,"--rpc-url",RPC],capture_output=True,text=True)
    o=p.stdout.strip()
    return o if o.startswith("0x") else (p.stderr.strip())
POOL="0x433e21dc2bf027910b1635653c2eb630bc7dad43"
ORACLE="0x0e1289335e72a9e1799d691fc618656fa69f2ca1"
reserves=["0xd0601CE157Db5bdC3162BbaC2a2C8aF5320D9EEC","0x117cc2133c37B721F49dE2A7a74833232B3B4C0C","0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168","0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73","0xCEC185eB182c47d1bA1EFc84e6959e18cd620Be4","0xD5f3879160bc7c32ebb4dC785F8a4F505888de68","0x92FD66527192E3e61d4DDd13322Aa222DE86F9B5","0xC9a981FEE1F9DEc688bb123ccDeCc63D0deBFC4e"]
syms={"0xd0601CE157Db5bdC3162BbaC2a2C8aF5320D9EEC":"NVDA","0x117cc2133c37B721F49dE2A7a74833232B3B4C0C":"SPY","0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168":"USDG","0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73":"WETH","0xCEC185eB182c47d1bA1EFc84e6959e18cd620Be4":"cbBTC","0xD5f3879160bc7c32ebb4dC785F8a4F505888de68":"QQQ","0x92FD66527192E3e61d4DDd13322Aa222DE86F9B5":"SGOV","0xC9a981FEE1F9DEc688bb123ccDeCc63D0deBFC4e":"GLD"}
out={}
for a in reserves:
    raw=call(POOL,"0x35ea6a75"+a[2:].rjust(64,'0'))
    raw=raw[2:] if raw.startswith("0x") else raw
    words=[raw[i:i+64] for i in range(0,len(raw),64)]
    def w(i): return int(words[i],16) if i<len(words) and words[i] else 0
    cfg=w(0)
    ltv=cfg&0xFFFF; lt=(cfg>>16)&0xFFFF; bonus=(cfg>>32)&0xFFFF; dec=(cfg>>48)&0xFF; flags=(cfg>>56)&0xFF
    src=call(ORACLE,"0x92bf2be0"+a[2:].rjust(64,'0')); src="0x"+src[-40:]
    price=call(ORACLE,"0xb3596f07"+a[2:].rjust(64,'0'))
    price=int(price,16) if price.startswith("0x") else None
    out[syms[a]]={"asset":a,"ltv_bps":ltv,"liq_threshold_bps":lt,"liq_bonus_bps":bonus,"decimals":dec,
      "isActive":bool(flags&1),"isFrozen":bool(flags&2),"borrowingEnabled":bool(flags&4),"stableRateEnabled":bool(flags&8),"isPaused":bool(flags&16),
      "oracle_source":src,"price_1e8":price,"_words":len(words)}
    # aToken / debt tokens: locate 20-byte addresses in words
    addrs=[]
    for i,ww in enumerate(words):
        if len(ww)==64 and ww[:24]=="0"*24 and ww[24:]!="0"*40:
            addrs.append((i,"0x"+ww[24:]))
    out[syms[a]]["addr_words"]=addrs
print(json.dumps(out,indent=1))
open("reserves.json","w").write(json.dumps(out,indent=1))
