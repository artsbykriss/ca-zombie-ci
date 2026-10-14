#!/usr/bin/env python3
"""CI RPC helper — reads RPC from env (FORK_RPC_URL / RPC_URL), never from files.
Used by the MiniSwap Phase-2 heavy enumeration job."""
import json, os, sys, time, urllib.request

def rpc_url():
    for k in ("FORK_RPC_URL", "RPC_URL", "NODEREAL_ETH_RPC_URL", "BLOCKPI_RPC_URL"):
        v = os.environ.get(k)
        if v: return v
    return "https://ethereum-rpc.publicnode.com"

URL = rpc_url()

def rpc_batch(calls, timeout=40, retries=3):
    out = [None]*len(calls)
    for attempt in range(retries):
        missing = [i for i,x in enumerate(out) if x is None]
        if not missing: break
        payload = [{"jsonrpc":"2.0","id":i,"method":calls[i][0],"params":calls[i][1]} for i in missing]
        try:
            req = urllib.request.Request(URL, data=json.dumps(payload).encode(),
                                         headers={"Content-Type":"application/json","User-Agent":"miniswap-ci/1.0"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                resp = json.load(r)
            for item in resp:
                if isinstance(item, dict) and "result" in item and item["result"] is not None:
                    idx = item.get("id")
                    if idx is not None: out[missing[idx]] = item["result"]
        except Exception as e:
            sys.stderr.write(f"[rpc] attempt {attempt+1} err: {str(e)[:100]}\n")
        for i in [i for i,x in enumerate(out) if x is None]:
            if len(calls) > 1:
                one = rpc_batch([calls[i]], timeout=timeout, retries=1)
                if one[0] is not None: out[i] = one[0]
        time.sleep(0.5)
    return out

def eth_call(to, data, block="latest"):
    return rpc_batch([("eth_call", [{"to":to,"data":data}, block])])[0]

def calls_batched(items, chunk=10, block="latest"):
    res=[]
    for i in range(0,len(items),chunk):
        part=items[i:i+chunk]
        rs=rpc_batch([("eth_call",[{"to":t,"data":d},block]) for t,d in part])
        res.extend(rs)
    return res

def pad(addr): return "0"*24 + addr.lower().replace("0x","")

SEL = {
 "allPairsLength":"0x574f2ba3","allPairs":"0x1e3dd18b","token0":"0x0dfe1681","token1":"0xd21220a7",
 "getReserves":"0x0902f1ac","totalSupply":"0x18160ddd","balanceOf":"0x70a08231",
 "symbol":"0x95d89b41","decimals":"0x313ce567","feeTo":"0x017e7e58","miner":"0x349dc329",
 "feeTemp":"0xbd821f34","mineInfo":"0x5487aae2","whitelistMap":"0x32531c3c","minFee":"0x24ec7590",
}
