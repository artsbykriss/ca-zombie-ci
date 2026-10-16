import json, urllib.request, subprocess, time
RPC="https://rpc.flashbots.net"
def topic(sig): return subprocess.run(["cast","keccak",sig],capture_output=True,text=True).stdout.strip()
def rpc(method, params):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req=urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0 research"})
    res=json.load(urllib.request.urlopen(req, timeout=60))
    if "error" in res: raise RuntimeError(res["error"])
    return res["result"]
def hx(s): return int(s,16) if s and s!='0x' else 0

head=hx(rpc("eth_blockNumber",[]))
print("head",head)
MCT="0x4eD90999f558Fdc28606b7F7f9AFc7044befb803"
def getlogs(addr, topic0, frm, chunk=90000):
    out=[]; b=frm
    while b<=head:
        e=min(b+chunk-1,head)
        out+=rpc("eth_getLogs",[{"address":addr,"topics":[topic0],"fromBlock":hex(b),"toBlock":hex(e)}])
        b=e+1
    return out

res=getlogs(MCT,topic("Minted(address,address,uint256,uint256)"),24900000)
tot={}; per=[]
for r in res:
    a="0x"+r["topics"][2][-40:]; d=r["data"][2:]
    amt=hx(d[0:64]); mctamt=hx(d[64:128])
    tot[a]=tot.get(a,0)+amt
    per.append((hx(r["blockNumber"]),a,amt,mctamt,r["topics"][1]))
print(f"[Minted] n={len(res)}", {k:round(v/1e6,2) for k,v in tot.items()})
for b,a,amt,m,bn in per: print(f"   blk={b} {a[-6:]} amt={amt/1e6:.2f}")

res=getlogs(MCT,topic("UnbackedMint(address,uint256)"),24900000)
s=0; rows=[]
for r in res:
    d=r["data"][2:]; amt=hx(d[0:64]); s+=amt; rows.append((hx(r["blockNumber"]), amt/1e18))
print(f"[UnbackedMint] n={len(res)} total={s/1e18:.4f}")
for b,a in rows: print(f"   blk={b} {a:.4f}")

res=getlogs(MCT,topic("Redeemed(address,address,uint256,uint256)"),24900000)
tot={}
for r in res:
    a="0x"+r["topics"][2][-40:]; d=r["data"][2:]
    tot[a]=tot.get(a,0)+hx(d[0:64])
print(f"[Redeemed] n={len(res)}", {k:round(v/1e6,2) for k,v in tot.items()})

res=getlogs(MCT,topic("CollateralWithdrawn(address,uint256,address)"),24900000)
tot={}; rows=[]
for r in res:
    a="0x"+r["topics"][1][-40:]; d=r["data"][2:]
    amt=hx(d[0:64]); tot[a]=tot.get(a,0)+amt
    rows.append((hx(r["blockNumber"]),a,amt,"0x"+d[24:64]))
print(f"[CollateralWithdrawn] n={len(res)}", {k:round(v/1e6,2) for k,v in tot.items()})
for b,a,amt,to in rows: print(f"   blk={b} {a[-6:]} amt={amt/1e6:.2f} to={to}")
