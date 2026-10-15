#!/usr/bin/env python3
"""Re-verify flagged skim-excess pairs with careful sequential reads."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, sel, enc_addr

CHAIN = "aurora"
GR = sel("getReserves()"); T0 = sel("token0()"); T1 = sel("token1()"); BAL = sel("balanceOf(address)")

FLAGGED_TRI = ["0xf70e54745923440209cb59dd9f24750439f4af62","0x336c4886580c7cfe908b9ead1f0d80d95b295d3c","0x682c0204156674611c27e0cff6dc9e4862749320","0xbeae058769d38d4cee19ab5653fb2fcb62b8cce5","0xdd794fc2c6e3c17f77290be0d47c1cc153781c76","0xb067a42b8ce4653a0cb1fab8ce662459842b2f2d","0xa897e4307923b80bdf44a2f7264010d3ef5f5a61","0x5a829708ca6cbd188a5659275689255bd7afdd0b","0x1304e3458b1b1419dbca02352570f332c78fda24","0x677bb3aa35deeccc8520b58c52501d3f7cdb3583","0x5e3e907928c7f4b43fe166e7b8dec3b5f98f24c3","0x962bc3510152f869e06147c7da9fae8d0e27a2b9","0xa356a32f1d2b2e70e0f5c0f7a03bb73ddb9c793c","0x2da9be0dc5fdd883109d1327f8369e9b04a4702b","0x845122b4ed42cf63d618586f1617f1dc21fdc305","0x045733366f6ab6140f4fddd053911284929c013c","0xde1a98bbf2eaf2678e5db8758cc5ba0600e743b8","0x16a6821f1cf25688347bb30c63d8d4f4d83d33c4","0x1cf01ac98f86a72a376d8ea2653bf84569b66e94","0x82377a6416eca9846c8f676b478514638c77e263"]
FLAGGED_WAN = ["0x467a5ba2bb30ee0e5bc6733282d8f570f061ea06"]

def check(pair):
    t0 = rpc(CHAIN,"eth_call",[{"to":pair,"data":T0},"latest"])
    t1 = rpc(CHAIN,"eth_call",[{"to":pair,"data":T1},"latest"])
    if not (isinstance(t0,str) and len(t0)>=42): return {"pair":pair,"err":"no token0"}
    t0="0x"+t0[2:][24:64]; t1="0x"+t1[2:][24:64]
    g = rpc(CHAIN,"eth_call",[{"to":pair,"data":GR},"latest"])
    b0 = rpc(CHAIN,"eth_call",[{"to":t0,"data":BAL+enc_addr(pair)},"latest"])
    b1 = rpc(CHAIN,"eth_call",[{"to":t1,"data":BAL+enc_addr(pair)},"latest"])
    try:
        raw=g[2:]; r0=int(raw[:64],16); r1=int(raw[64:128],16)
        b0i=int(b0,16); b1i=int(b1,16)
    except Exception as e:
        return {"pair":pair,"err":str(e)[:60],"t0":t0,"t1":t1}
    return {"pair":pair,"t0":t0,"t1":t1,"r0":r0,"r1":r1,"b0":b0i,"b1":b1i,"e0":b0i-r0,"e1":b1i-r1}

if __name__ == "__main__":
    out=[]
    for p in FLAGGED_TRI + FLAGGED_WAN:
        r = check(p)
        out.append(r)
        if "err" in r:
            print(p, "ERR", r["err"])
        else:
            flag = " <-- EXCESS" if (r["e0"]>0 or r["e1"]>0) else ""
            print(f"{p} t0={r['t0'][:10]} t1={r['t1'][:10]} e0={r['e0']} e1={r['e1']}{flag}")
    json.dump(out, open("/home/heisenberg/CA/aurora-dust/analysis/skim-verify.json","w"), indent=1)
