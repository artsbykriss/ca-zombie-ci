import json,urllib.request,time
RPCS=["https://bsc-rpc.publicnode.com","https://binance.llamarpc.com","https://bsc-dataseed.bnbchain.org"]
def rpc(m,p):
    for url in RPCS:
        try:
            r=urllib.request.Request(url,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"Content-Type":"application/json"})
            with urllib.request.urlopen(r,timeout=25) as f: d=json.load(f)
            return d
        except Exception as e: last=str(e)
        time.sleep(0.3)
    return {"error":{"message":last}}
A="0x16ceff8d5a4c8648fcc7293f8bd3ac9ada454219"
S="0x7a3f000000000000000000000000000000009f01"
def w(x): return f"{x:064x}"
def tc(data,frm,value="0x0"):
    d=rpc("eth_call",[{"from":frm,"to":A,"data":data,"value":value},"latest"])
    if "result" in d: return "OK "+d["result"][:80]
    e=d.get("error",{})
    return "ERR "+(str(e.get("data") or e.get("message")))[:70]
tests={
 "unlockCallback(empty bytes)": "0x91dd7346"+w(0x20)+w(0),
 "pancakeV3SwapCallback(0,0,'')": "0x23a69e75"+w(0)+w(0)+w(0x60)+w(0),
 "uniswapV3SwapCallback(0,0,'')": "0xfa461e33"+w(0)+w(0)+w(0x60)+w(0),
 "receive 1wei (empty)": "0x",
 "fallback deadbeef": "0xdeadbeef",
 "f9125e2c(0)": "0xf9125e2c"+w(0),
 "authorize(stranger)": "0xb6a5d7de"+w(int(S,16)),
 "05e85860 9w zeros": "0x05e85860"+"".join(w(0) for _ in range(9)),
}
for nm,d in tests.items():
    v="0x1" if nm.startswith("receive") else "0x0"
    print(f"{nm:34s} stranger={tc(d,S,v)}")
