#!/usr/bin/env python3
"""Read-only batched enumeration of MultiLockMoat contracts. Public RPCs only, no keys."""
import json, urllib.request, sys, time

CHAINS = {
    "avax":      ("https://avalanche-c-chain-rpc.publicnode.com", "0xD0b5249EA2f93E54B90ff0737B4d78AA13a222BC", 43114),
    "robinhood": ("https://robinhood.drpc.org",                    "0x5CffC369e14BFcD730031B137FbCEccd0a49560", 4663),
    "base":      ("https://base-rpc.publicnode.com",               "0xcd1901A5AB6CaA8D706D44009609f3c0E04760C4", 8453),
    "bsc":       ("https://bsc-rpc.publicnode.com",                "0xcd1901A5AB6CaA8D706D44009609f3c0E04760C4", 56),
    "monad":     ("https://rpc.monad.xyz",                         "0xcd1901A5AB6CaA8D706D44009609f3c0E04760C4", 143),
}

S = {
 "owner":"0x8da5cb5b","moatManager":"0xf5b8488f","stakingToken":"0x72f702f3",
 "tokenDecimals":"0x3b97e856","POINTS_SCALING_FACTOR":"0x5b2cee4b","MIN_STAKE_AMOUNT":"0x27ed7188",
 "totalPoints":"0x567142be","totalStaked":"0x817b1cd2","totalLocked":"0x56891412",
 "totalBurned":"0xd89135cd","paused":"0x5c975abb","stakingEnabled":"0x1cfff51b",
 "lockingEnabled":"0x937c9130","burningEnabled":"0x4d754715","earlyExitEnabled":"0x4ae1815e",
 "emergencyUnlockEnabled":"0x0b5dce33","unstakeFee":"0x8ea97d26","feeCollector":"0xc415b95c",
 "getActiveUserCount":"0x3fa2fe7a","getRewardTokens":"0xc4f59f9b","getTotalAmounts":"0xc4a7761e",
 "getLogoURL":"0x2543408f","BURN_MULTIPLIER":"0x80771ca2","MAX_LOCK_DURATION":"0x4f1bfc9e",
 "getDeployedContractsCount":"0x5fc7f334","getAllDeployedContracts":"0x6c9364b2",
 "adminWallet":"0x36b19cd7","deploymentFee":"0xf2cff57f","usdcToken":"0x11eac855","feeReceiver":"0xb3f00674",
 "decimals":"0x313ce567","name":"0x06fdde03","symbol":"0x95d89b41","totalSupply":"0x18160ddd",
}

UA={"Content-Type":"application/json","User-Agent":"Mozilla/5.0 (X11; Linux x86_64) research"}

def rpc(url, method, params):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req = urllib.request.Request(url, data=body, headers=UA)
    with urllib.request.urlopen(req, timeout=60) as r:
        j = json.loads(r.read())
    if "error" in j: raise RuntimeError(j["error"])
    return j["result"]

def batch(url, calls):
    """calls: list of (id, to, data, block)"""
    payload=[]
    for i,(to,data,block) in enumerate(calls):
        payload.append({"jsonrpc":"2.0","id":i,"method":"eth_call","params":[{"to":to,"data":data},block]})
    body = json.dumps(payload).encode()
    req = urllib.request.Request(url, data=body, headers=UA)
    with urllib.request.urlopen(req, timeout=90) as r:
        j = json.loads(r.read())
    res={}
    for item in j:
        res[item["id"]] = item.get("result") if "error" not in item else None
    return res

def w(hexs):
    if not hexs or hexs=="0x": return None
    return int(hexs,16)

def addr(hexs):
    if not hexs or len(hexs)<42: return None
    return "0x"+hexs[-40:]

def dec_addr_array(hexs):
    if not hexs or hexs=="0x": return []
    h=hexs[2:]
    off=int(h[0:64],16)*2
    ln=int(h[off:off+64],16)
    out=[]
    for i in range(ln):
        p=off+64+i*64
        out.append("0x"+h[p+24:p+64])
    return out

def dec_uint_array_at(h, off_words):
    off=off_words*64
    ln=int(h[off:off+64],16)
    out=[]
    for i in range(ln):
        p=off+64+i*64
        out.append(int(h[p:p+64],16))
    return out

def getRewardTokens(hexs):
    if not hexs or hexs=="0x": return None
    h=hexs[2:]
    # returns (address[] addresses, uint256[] totalDeposited, uint256[] totalClaimed, uint256[] unallocated)
    addrs=dec_addr_array(hexs)
    # offsets for arrays 2,3,4
    o1=int(h[0:64],16)//32
    o2=int(h[64:128],16)//32
    o3=int(h[128:192],16)//32
    o4=int(h[192:256],16)//32
    dep=dec_uint_array_at(h,o2)
    clm=dec_uint_array_at(h,o3)
    un=dec_uint_array_at(h,o4)
    return {"addresses":addrs,"totalDeposited":dep,"totalClaimed":clm,"unallocated":un}

def main():
    result={"chains":{}}
    for chain,(url,factory,cid) in CHAINS.items():
        try:
            blk=int(rpc(url,"eth_blockNumber",[]),16)
        except Exception as e:
            result["chains"][chain]={"error":str(e)}; continue
        blkhex=hex(blk)
        try:
            cnt=w(rpc(url,"eth_call",[{"to":factory,"data":S["getDeployedContractsCount"]},blkhex]))
            allmoats=dec_addr_array(rpc(url,"eth_call",[{"to":factory,"data":S["getAllDeployedContracts"]},blkhex]))
            fdata={}
            # factory fields
            fbatch=[(factory,S["adminWallet"],blkhex),(factory,S["deploymentFee"],blkhex),(factory,S["usdcToken"],blkhex),(factory,S["feeReceiver"],blkhex)]
            fr=batch(url,fbatch)
            fdata["adminWallet"]=addr(fr.get(0)); fdata["deploymentFee"]=w(fr.get(1)); fdata["usdcToken"]=addr(fr.get(2)); fdata["feeReceiver"]=addr(fr.get(3))
        except Exception as e:
            result["chains"][chain]={"error":str(e)}; continue
        entry={"block":blk,"factory":factory,"chainId":cid,"count":cnt,"factoryData":fdata,"moats":[]}
        for m in allmoats:
            keys=["owner","moatManager","stakingToken","tokenDecimals","POINTS_SCALING_FACTOR","MIN_STAKE_AMOUNT",
                  "totalPoints","totalStaked","totalLocked","totalBurned","paused","stakingEnabled","lockingEnabled",
                  "burningEnabled","earlyExitEnabled","emergencyUnlockEnabled","unstakeFee","feeCollector",
                  "getActiveUserCount","getRewardTokens","getTotalAmounts","BURN_MULTIPLIER","MAX_LOCK_DURATION"]
            calls=[(m,S[k],blkhex) for k in keys]
            r=batch(url,calls)
            mo={"address":m}
            for i,k in enumerate(keys):
                v=r.get(i)
                if k in ("owner","moatManager","stakingToken","feeCollector"):
                    mo[k]=addr(v)
                elif k=="getRewardTokens":
                    mo[k]=getRewardTokens(v)
                elif k=="getTotalAmounts":
                    h=(v or "0x")[2:]
                    mo[k]=[int(h[j*64:(j+1)*64],16) for j in range(4)] if len(h)>=256 else None
                else:
                    mo[k]=w(v)
            # staking token metadata + balance
            st=mo["stakingToken"]
            balsel="0x70a08231"+ "0"*24 + st[2:]
            tb=[(st,S["decimals"],blkhex),(st,S["totalSupply"],blkhex),(m,balsel,blkhex)]
            tr=batch(url,tb)
            mo["stDecimals"]=w(tr.get(0)); mo["stTotalSupply"]=w(tr.get(1)); mo["moatStBalance"]=w(tr.get(2))
            entry["moats"].append(mo)
        result["chains"][chain]=entry
        print(f"{chain}: block {blk}, {len(allmoats)} moats", file=sys.stderr)
    print(json.dumps(result, indent=1))

if __name__=="__main__":
    main()
