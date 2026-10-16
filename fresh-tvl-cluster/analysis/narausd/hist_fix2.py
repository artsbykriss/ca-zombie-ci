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
def getlogs(addr, topic0, frm=24983700):
    return rpc("eth_getLogs",[{"address":addr,"topics":[topic0],"fromBlock":hex(frm),"toBlock":"latest"}])

MCT="0x4eD90999f558Fdc28606b7F7f9AFc7044befb803"
SAFE="0xab05c0db9d26e96a9dcedcafca23341316f6fe6f"

r=getlogs(MCT,topic("CollateralWithdrawn(address,uint256,address)"))
agg={}
print("=== CollateralWithdrawn (correct to) ===")
for l in r:
    d=l["data"][2:]; asset="0x"+l["topics"][1][-40:]; amt=hx(d[0:64]); to="0x"+l["topics"][2][-40:]
    agg[to]=agg.get(to,0)+amt
    print(f"blk={hx(l['blockNumber'])} {asset[-6:]} {amt/1e6:>14.2f} -> {to} {'(SAFE)' if to==SAFE else ''}")
print("by recipient:", {k:round(v/1e6,2) for k,v in agg.items()})

r=getlogs(MCT,topic("Minted(address,address,uint256,uint256)"))
print("=== Minted (beneficiary, asset, amt) — big only ===")
for l in r:
    d=l["data"][2:]; amt=hx(d[0:64])
    if amt>100000e6:
        ben="0x"+l["topics"][1][-40:]; asset="0x"+l["topics"][2][-40:]
        print(f"blk={hx(l['blockNumber'])} {asset[-6:]} {amt/1e6:>14.2f} -> {ben}")
