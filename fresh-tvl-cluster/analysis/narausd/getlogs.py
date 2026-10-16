import json, urllib.request, subprocess, time, sys
RPC="https://eth.drpc.org"
def topic(sig): return subprocess.run(["cast","keccak",sig],capture_output=True,text=True).stdout.strip()
def rpc(method, params, rpc=RPC):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req=urllib.request.Request(rpc, data=body, headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0 research"})
    return json.load(urllib.request.urlopen(req))

MCT="0x4eD90999f558Fdc28606b7F7f9AFc7044befb803"
def getlogs(addr, topic0, frm=0x1700000, to="latest"):
    res=rpc("eth_getLogs",[{"address":addr,"topics":[topic0],"fromBlock":hex(frm),"toBlock":to}])
    if "error" in res: 
        print("ERR",res["error"]); sys.exit(1)
    return res["result"]

def hx(s): return int(s,16) if s and s!='0x' else 0

t=topic("Minted(address,address,uint256,uint256)")
res=getlogs(MCT,t)
tot={}
for r in res:
    asset="0x"+r["topics"][2][-40:]; d=r["data"][2:]
    tot[asset]=tot.get(asset,0)+hx(d[0:64])
print(f"Minted n={len(res)}:", {k:round(v/1e6,2) for k,v in tot.items()}, "total_usd~", round(sum(tot.values())/1e6,2))

t=topic("UnbackedMint(address,uint256)")
res=getlogs(MCT,t)
s=0; rows=[]
for r in res:
    d=r["data"][2:]; amt=hx(d[0:64]); s+=amt
    rows.append((hx(r["blockNumber"]), amt/1e18))
print(f"UnbackedMint n={len(res)} total={s/1e18:.4f} MCT")
for b,a in rows: print(f"   blk={b} {a:.4f}")

t=topic("Redeemed(address,address,uint256,uint256)")
res=getlogs(MCT,t)
tot={}
for r in res:
    asset="0x"+r["topics"][2][-40:]; d=r["data"][2:]
    tot[asset]=tot.get(asset,0)+hx(d[0:64])
print(f"Redeemed n={len(res)}:", {k:round(v/1e6,2) for k,v in tot.items()})

t=topic("CollateralWithdrawn(address,uint256,address)")
res=getlogs(MCT,t)
tot={}
for r in res:
    asset="0x"+r["topics"][1][-40:]; d=r["data"][2:]
    tot[asset]=tot.get(asset,0)+hx(d[0:64])
print(f"CollateralWithdrawn n={len(res)}:", {k:round(v/1e6,2) for k,v in tot.items()})

NUSD="0x5C6263904CCFD3Bcf1aAa6e7063dDd29743b3Bb7"
t=topic("Mint(address,address,uint256,uint256)")
res=getlogs(NUSD,t)
tot={}
for r in res:
    asset="0x"+r["topics"][2][-40:]; d=r["data"][2:]
    tot[asset]=tot.get(asset,0)+hx(d[0:64])
print(f"NaraUSD.mintWithCollateral Mint n={len(res)}:", {k:round(v/1e6,2) for k,v in tot.items()})
