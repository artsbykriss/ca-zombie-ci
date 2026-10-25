#!/usr/bin/env python3
"""Light read-only BSC RPC helper (public endpoint). Usage as module or CLI."""
import json, urllib.request, os, sys, time

RPC = os.environ.get("BSC_RPC_URL", "https://bsc-rpc.publicnode.com")
FALLBACKS = ["https://bsc-rpc.publicnode.com","https://bsc.publicnode.com","https://rpc.48.club","https://bsc-dataseed1.defibit.io"]

def rpc(method, params, rpc_url=None):
    urls = [rpc_url] if rpc_url else [RPC]+[u for u in FALLBACKS if u!=RPC]
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for ui,url in enumerate(urls):
        req = urllib.request.Request(url, data=body, headers={"Content-Type":"application/json","User-Agent":"zh4-bsc/1.0"})
        for a in range(3):
            try:
                with urllib.request.urlopen(req, timeout=40) as r:
                    d = json.load(r)
                if "result" in d: return d["result"]
                if "error" in d: return {"__error__": d["error"]}
            except Exception as e:
                last=f"{url}: {e}"; time.sleep(0.8*(a+1))
    return {"__error__": last or "rpc-fail"}

def call(to, data, block="latest", frm=None):
    tx={"to":to,"data":data}
    if frm: tx["from"]=frm
    return rpc("eth_call",[tx, block])

def block_number():
    return int(rpc("eth_blockNumber",[]),16)

if __name__=="__main__":
    print(block_number())
