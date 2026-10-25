#!/usr/bin/env python3
import json, urllib.request, time
RPCS=["https://bsc-rpc.publicnode.com","https://binance.llamarpc.com"]
def rpc(m,p):
    for url in RPCS:
        for a in range(3):
            try:
                r=urllib.request.Request(url,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"Content-Type":"application/json"})
                with urllib.request.urlopen(r,timeout=25) as f: d=json.load(f)
                if "result" in d: return d["result"]
                if "error" in d: return {"__err__":d["error"]}
            except Exception: time.sleep(0.4)
    return {"__err__":"fail"}
A="0x16ceff8d5a4c8648fcc7293f8bd3ac9ada454219"
S="0x7a3f000000000000000000000000000000009f01"
def w(x): return f"{x:064x}"
def tc(data,frm=S,value="0x0"):
    d=rpc("eth_call",[{"from":frm,"to":A,"data":data,"value":value},"latest"])
    if isinstance(d,dict):
        e=d.get("__err__"); return "REVERT:"+str((e.get("data") if isinstance(e,dict) else e))[:70]
    return "OK:"+d[:90]
# unlockCallback(bytes) = 91dd7346 : abi = offset(0x20) len data
empty_bytes = "0x"+w(0x20)+w(0)
tests = {
 "unlockCallback(empty)": "0x91dd7346"+empty_bytes[2:],
 "unlockCallback(32 zero bytes)": "0x91dd7346"+w(0x20)+w(0x20)+w(0),
 "pancakeV3SwapCallback(0,0,empty)": "0x23a69e75"+w(0)+w(0)+w(0x60)+w(0),
 "uniswapV3SwapCallback(0,0,empty)": "0xfa461e33"+w(0)+w(0)+w(0x60)+w(0),
 "receive (empty calldata, 1 wei)": "0x",
 "fallback 0xdeadbeef": "0xdeadbeef",
 "f9125e2c(0)": "0xf9125e2c"+w(0),
 "authorize(stranger)": "0xb6a5d7de"+w(int(S,16)),
}
for nm,d in tests.items():
    v="0x1" if nm.startswith("receive") else "0x0"
    print(f"{nm:40s} stranger={tc(d,S,v)}")
    print(f"{'':40s} from_self ={tc(d,A,v)}")
