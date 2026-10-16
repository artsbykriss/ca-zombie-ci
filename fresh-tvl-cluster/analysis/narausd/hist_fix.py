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
def w(d,i): return hx(d[i*64:(i+1)*64])
def getlogs(addr, topic0, frm=24983700):
    return rpc("eth_getLogs",[{"address":addr,"topics":[topic0],"fromBlock":hex(frm),"toBlock":"latest"}])

MCT="0x4eD90999f558Fdc28606b7F7f9AFc7044befb803"

# Redeemed(address beneficiary, address asset, uint256 ?) -- inspect one raw log
r=getlogs(MCT,topic("Redeemed(address,address,uint256,uint256)"))
print("Redeemed raw sample:", json.dumps(r[0],indent=1)[:400])
for l in r:
    d=l["data"][2:]
    print("  blk",hx(l["blockNumber"]),"beneficiary=0x"+l["topics"][1][-40:],"asset=0x"+l["topics"][2][-40:],
          "w0",w(d,0)/1e18,"w1",w(d,1)/1e6)
print()
r=getlogs(MCT,topic("CollateralWithdrawn(address,uint256,address)"))
print("total to==Safe:", flush=True)
tot_safe={}; tot_other={}
for l in r:
    d=l["data"][2:]
    asset="0x"+l["topics"][1][-40:]; amt=w(d,0); to="0x"+d[64+24:128]
    if to.lower()=="0xab05c0db9d26e96a9dcedcafca23341316f6fe6f":
        tot_safe[asset]=tot_safe.get(asset,0)+amt
    else:
        tot_other[asset]=tot_other.get(asset,0)+amt
    print(f"  blk={hx(l['blockNumber'])} asset={asset[-6:]} amt={amt/1e6:.2f} to={to}")
print("to==Safe totals:", {k:round(v/1e6,2) for k,v in tot_safe.items()})
print("to!=Safe totals:", {k:round(v/1e6,2) for k,v in tot_other.items()})
