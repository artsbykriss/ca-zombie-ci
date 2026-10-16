import json, urllib.request, subprocess
RPCS=["https://gateway.tenderly.co/public/mainnet","https://rpc.mevblocker.io"]
def topic(sig): return subprocess.run(["cast","keccak",sig],capture_output=True,text=True).stdout.strip()
def rpc(method, params):
    last=None
    for u in RPCS:
        try:
            body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
            req=urllib.request.Request(u, data=body, headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0 research"})
            res=json.load(urllib.request.urlopen(req, timeout=90))
            if "error" in res: last=res["error"]; continue
            return res["result"]
        except Exception as e: last=e
    raise RuntimeError(last)
def hx(s): return int(s,16) if s and s!='0x' else 0

SAFE="0xaB05c0DB9D26e96A9dcEDCAFCA23341316F6fe6F"
TRANSFER=topic("Transfer(address,address,uint256)")
tokens={
 "USDC":"0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
 "USDT":"0xdAC17F958D2ee523a2206206994597C13D831ec7",
 "sUSDS":"0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD",
 "mGLOBAL":"0x7433806912Eae67919e66aea853d46Fa0aef98A8",
 "mGLO":"0x1dd91a111606382b77a917633ed90feaf25e0f76",
}
for name,t in tokens.items():
    # outgoing: topic1 = safe padded
    topic1="0x000000000000000000000000"+SAFE[2:].lower()
    res=rpc("eth_getLogs",[{"address":t,"topics":[TRANSFER,topic1],"fromBlock":"0x17a0000","toBlock":"latest"}])
    agg={}
    for l in res:
        d=l["data"][2:]; amt=hx(d[0:64]); to="0x"+l["topics"][2][-40:]
        agg[to]=agg.get(to,0)+amt
    print(f"OUT {name} n={len(res)}")
    for to,v in sorted(agg.items(), key=lambda x:-x[1])[:8]:
        print(f"   -> {to} {v/10**6 if name in ('USDC','USDT','mGLO') else v/1e18:.4f}")
