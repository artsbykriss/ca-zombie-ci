#!/usr/bin/env python3
"""child2_fetch_vase.py - complete VASE (BentoBox V2) share-holder enumeration.
Includes LogDeposit/LogWithdraw/LogTransfer (deposits don't emit LogTransfer in this fork).
"""
import json, time
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
import requests

RPC = "https://mainnet.aurora.dev"
S = requests.Session()

LOGTRANSFER = "0x6eabe333476233fd382224f233210cb808a7bc4c4de64f9d76628bf63c677b1a"
LOGDEPOSIT = "0xb2346165"  # keccak LogDeposit(address,address,address,uint256,uint256)
LOGWITHDRAW = "0xad9ab9ee" # keccak LogWithdraw(address,address,address,uint256,uint256)

VASE = "0xee793001ce9fa988712b15a59ccf5dc7d54b22ff"
VASE_TOKENS = {
    "RUSD":  "0x19cc40283b057d6608c22f1d20f17e16c245642e",
    "WBTC":  "0xf4eb217ba2454613b15dbdea6e5f22276410e89e",
    "UST":   "0x5ce9f0b6afb36135b5ddbf11705ceb65e634a9dc",
    "USDC":  "0xb12bfca5a55806aaf64e99521918a4bf0fc40802",
    "USDT":  "0x4988a896b1227218e4a686fde5eabdcabd91571f",
    "WNEAR": "0xc42c30ac6cc15fac9bd938618bcaa1a1fae8501d",
    "WETH":  "0xc9bdeed33cd01541e1eed10f90519d2c06fe3feb",
}
DAO_EOA = "0x3820feddeaba00564166e68a73babdae5740394f"

class TooBig(Exception): pass

def rpc(method, params, tries=7, timeout=180):
    last = None
    for i in range(tries):
        try:
            r = S.post(RPC, json={"jsonrpc":"2.0","id":1,"method":method,"params":params}, timeout=timeout)
            if r.status_code == 429:
                last="429"; time.sleep(2+2*i); continue
            j = r.json()
            if "error" in j:
                e=j["error"]; msg=json.dumps(e)
                if e.get("code")==-32005 or "exceeds" in msg.lower() or "size" in msg.lower():
                    raise TooBig(msg)
                last=msg
            else:
                return j.get("result")
        except TooBig: raise
        except Exception as ex: last=repr(ex)
        time.sleep(1.0+1.5*i)
    raise RuntimeError(f"{method} failed: {last}")

def rpc_batch(calls, chunk=40):
    out=[]
    for i in range(0,len(calls),chunk):
        part=calls[i:i+chunk]
        payload=[{"jsonrpc":"2.0","id":k,"method":m,"params":p} for k,(m,p) in enumerate(part)]
        for attempt in range(6):
            try:
                r=S.post(RPC,json=payload,timeout=180)
                if r.status_code==429: time.sleep(2+attempt*2); continue
                by={x["id"]:x for x in r.json()}
                for k in range(len(part)):
                    x=by.get(k,{}); out.append(x.get("result",{"error":x.get("error")}))
                break
            except Exception:
                if attempt==5: raise
                time.sleep(1+attempt)
    return out

def get_logs(addr, topics, lo, hi):
    try:
        return rpc("eth_getLogs",[{"fromBlock":hex(lo),"toBlock":hex(hi),"address":addr,"topics":topics}])
    except TooBig:
        if hi-lo<1: raise
        mid=(lo+hi)//2
        return get_logs(addr,topics,lo,mid)+get_logs(addr,topics,mid+1,hi)

def call(addr,data):
    return rpc("eth_call",[{"to":addr,"data":data},"latest"])

def pad(a): return a[2:].lower().rjust(64,"0")

def main():
    blk=int(rpc("eth_blockNumber",[]),16)
    print("block",blk)
    out={"block":blk,"vase":VASE,"tokens":{}}
    def job(item):
        sym,tok=item
        ntr = get_logs(VASE,[LOGTRANSFER,"0x"+pad(tok)],0,blk)
        nde = get_logs(VASE,[LOGDEPOSIT,"0x"+pad(tok)],0,blk)
        nwd = get_logs(VASE,[LOGWITHDRAW,"0x"+pad(tok)],0,blk)
        shares=defaultdict(int)
        for lg in ntr:
            t=lg["topics"]; frm="0x"+t[2][-40:]; to="0x"+t[3][-40:]; amt=int(lg["data"],16)
            shares[frm]-=amt; shares[to]+=amt
        for lg in nde:
            t=lg["topics"]; to="0x"+t[3][-40:]; share=int(lg["data"][66:130],16)
            shares[to]+=share
        for lg in nwd:
            t=lg["topics"]; frm="0x"+t[2][-40:]; share=int(lg["data"][66:130],16)
            shares[frm]-=share
        return sym,tok,ntr,nde,nwd,shares
    with ThreadPoolExecutor(max_workers=3) as ex:
        results=list(ex.map(job,VASE_TOKENS.items()))
    for sym,tok,ntr,nde,nwd,shares in results:
        pos={k:v for k,v in shares.items() if v>0}
        raw=call(VASE,"0x4ffe34db"+pad(tok))
        w1,w2=raw[2:66],raw[66:130]
        elastic,base=int(w1,16),int(w2,16)
        tot=sum(shares.values())
        dec=int(call(tok,"0x313ce567"),16) if sym!="WNEAR" else 24
        # verify top 15 with balanceOf -> shares
        top=sorted(pos.items(),key=lambda kv:-kv[1])[:15]
        calls=[("eth_call",[{"to":VASE,"data":"0xf7888aec"+pad(tok)+a[2:].rjust(64,"0")},"latest"]) for a,_ in top]
        res=rpc_batch(calls)
        ver=[]
        for (a,net),r in zip(top,res):
            oc=int(r,16) if isinstance(r,str) else None
            amount_est = net*elastic//base if base else net
            ver.append({"addr":a,"shares_netted":str(net),"balanceOf":str(oc) if oc is not None else None,
                        "match": oc==net if oc is not None else None,
                        "amount_prop": str(amount_est)})
        tok_bal=int(call(tok,"0x70a08231"+pad(VASE)),16)
        out["tokens"][sym]={"token":tok,"decimals":dec,"elastic":str(elastic),"base":str(base),
                            "sumSharesNetted":str(tot),"sumMatchBase":tot==base,
                            "logCounts":{"transfer":len(ntr),"deposit":len(nde),"withdraw":len(nwd)},
                            "vaseTokenBalance":str(tok_bal),
                            "excess":str(tok_bal-elastic),
                            "top":ver,
                            "allShares":{k:str(v) for k,v in sorted(pos.items(),key=lambda kv:-kv[1])}}
        print(sym,"elastic",elastic,"base",base,"sum",tot,"matchBase",tot==base,
              "logs t/d/w",len(ntr),len(nde),len(nwd),"vaseBal",tok_bal,"excess",tok_bal-elastic)
    json.dump(out,open("/home/heisenberg/CA/rose/analysis/child2_vase_full.json","w"),indent=1)
    print("saved child2_vase_full.json")

if __name__=="__main__":
    main()
