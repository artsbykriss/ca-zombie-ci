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
        except Exception as e:
            last=e
    raise RuntimeError(last)
def hx(s): return int(s,16) if s and s!='0x' else 0
def getlogs(addr, topic0, frm=24983700):
    return rpc("eth_getLogs",[{"address":addr,"topics":[topic0],"fromBlock":hex(frm),"toBlock":"latest"}])

MCT="0x4eD90999f558Fdc28606b7F7f9AFc7044befb803"
NUSD="0x5C6263904CCFD3Bcf1aAa6e7063dDd29743b3Bb7"

def asset_from_topic(t): return "0x"+t[-40:]
out={}

r=getlogs(MCT,topic("Minted(address,address,uint256,uint256)"))
tot={}; mct=0
for l in r:
    a=asset_from_topic(l["topics"][2]); d=l["data"][2:]
    amt=hx(d[0:64]); m=hx(d[64:128]); mct+=m; tot[a]=tot.get(a,0)+amt
print(f"[MCT.Minted] n={len(r)} collateral={ {k:round(v/1e6,2) for k,v in tot.items()} } mct={mct/1e18:.4f}")
out["minted_collateral"]={k:v/1e6 for k,v in tot.items()}; out["minted_mct"]=mct/1e18

r=getlogs(MCT,topic("UnbackedMint(address,uint256)"))
s=0
for l in r:
    s+=hx(l["data"][2:][0:64])
print(f"[MCT.UnbackedMint] n={len(r)} total={s/1e18:.4f}")
out["unbacked_mct"]=s/1e18

r=getlogs(MCT,topic("Redeemed(address,address,uint256,uint256)"))
tot={}; mct=0
for l in r:
    a=asset_from_topic(l["topics"][2]); d=l["data"][2:]
    amt=hx(d[0:64]); m=hx(d[64:128]); mct+=m; tot[a]=tot.get(a,0)+amt
print(f"[MCT.Redeemed] n={len(r)} collateral={ {k:round(v/1e6,2) for k,v in tot.items()} } mct={mct/1e18:.4f}")
out["redeemed_collateral"]={k:v/1e6 for k,v in tot.items()}; out["redeemed_mct"]=mct/1e18

r=getlogs(MCT,topic("CollateralWithdrawn(address,uint256,address)"))
tot={}; rows=[]
for l in r:
    a=asset_from_topic(l["topics"][1]); d=l["data"][2:]
    amt=hx(d[0:64]); to="0x"+d[24:64]; tot[a]=tot.get(a,0)+amt
    rows.append((hx(l["blockNumber"]),a,amt/1e6,to))
print(f"[MCT.CollateralWithdrawn] n={len(r)} totals={ {k:round(v/1e6,2) for k,v in tot.items()} }")
for b,a,amt,to in rows: print(f"   blk={b} {a[-6:]} amt={amt:.2f} to={to}")
out["withdrawn"]={k:v/1e6 for k,v in tot.items()}

r=getlogs(MCT,topic("AssetAdded(address)"))
print(f"[MCT.AssetAdded] n={len(r)}", [asset_from_topic(l["topics"][1]) for l in r])
r=getlogs(MCT,topic("AssetRemoved(address)"))
print(f"[MCT.AssetRemoved] n={len(r)}", [asset_from_topic(l["topics"][1]) for l in r])

# NaraUSD events
r=getlogs(NUSD,topic("Mint(address,address,uint256,uint256)"))
tot={}
for l in r:
    a=asset_from_topic(l["topics"][2]); d=l["data"][2:]
    tot[a]=tot.get(a,0)+hx(d[0:64])
print(f"[NaraUSD.mintWithCollateral] n={len(r)} deposits={ {k:round(v/1e6,2) for k,v in tot.items()} }")
out["narausd_mint_deposits"]={k:v/1e6 for k,v in tot.items()}

r=getlogs(NUSD,topic("Redeem(address,address,uint256,uint256)"))
tot={}
for l in r:
    a=asset_from_topic(l["topics"][2]); d=l["data"][2:]
    tot[a]=tot.get(a,0)+hx(d[0:64])
print(f"[NaraUSD.Redeem] n={len(r)} payouts={ {k:round(v/1e6,2) for k,v in tot.items()} }")

for ev in ["RedemptionRequested(address,uint256,address)","RedemptionCompleted(address,uint256,address,uint256)","RedemptionCancelled(address,uint256)"]:
    try:
        r=getlogs(NUSD,topic(ev))
        print(f"[NaraUSD.{ev.split('(')[0]}] n={len(r)}")
    except Exception as e:
        print(f"[NaraUSD.{ev}] ERR {e}")

json.dump(out, open("hist_summary.json","w"), indent=1)
print("saved hist_summary.json")
