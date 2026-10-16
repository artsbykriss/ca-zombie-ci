import json, urllib.request, subprocess, time
def topic(sig): return subprocess.run(["cast","keccak",sig],capture_output=True,text=True).stdout.strip()
def logs(addr, topic0, tries=6):
    url=f"https://eth.blockscout.com/api?module=logs&action=getLogs&fromBlock=1&toBlock=latest&address={addr}&topic0={topic0}&page=1&offset=1000"
    for i in range(tries):
        try:
            req=urllib.request.Request(url, headers={"User-Agent":"Mozilla/5.0 research"})
            d=json.load(urllib.request.urlopen(req, timeout=60))
            if d.get("result") is not None: return d["result"]
        except Exception as e:
            pass
        time.sleep(15+i*10)
    raise RuntimeError("failed "+topic0)
def hx(s): return int(s,16) if s and s!='0x' else 0

MCT="0x4eD90999f558Fdc28606b7F7f9AFc7044befb803"
NUSD="0x5C6263904CCFD3Bcf1aAa6e7063dDd29743b3Bb7"

t=topic("Minted(address,address,uint256,uint256)")
res=logs(MCT,t); tot={}
for r in res:
    a="0x"+r["topics"][2][-40:]; d=r["data"][2:]
    tot[a]=tot.get(a,0)+hx(d[0:64])
print(f"[MCT.Minted] n={len(res)}", {k:round(v/1e6,2) for k,v in tot.items()}, "total~$", round(sum(tot.values())/1e6,2)); time.sleep(12)

t=topic("UnbackedMint(address,uint256)")
res=logs(MCT,t); s=0; rows=[]
for r in res:
    d=r["data"][2:]; amt=hx(d[0:64]); s+=amt; rows.append((hx(r["blockNumber"]), amt/1e18))
print(f"[MCT.UnbackedMint] n={len(res)} total={s/1e18:.4f} MCT")
for b,a in rows: print(f"   blk={b} {a:.4f}"); time.sleep(12)

t=topic("Redeemed(address,address,uint256,uint256)")
res=logs(MCT,t); tot={}
for r in res:
    a="0x"+r["topics"][2][-40:]; d=r["data"][2:]
    tot[a]=tot.get(a,0)+hx(d[0:64])
print(f"[MCT.Redeemed] n={len(res)}", {k:round(v/1e6,2) for k,v in tot.items()}); time.sleep(12)

t=topic("CollateralWithdrawn(address,uint256,address)")
res=logs(MCT,t); tot={}
for r in res:
    a="0x"+r["topics"][1][-40:]; d=r["data"][2:]
    tot[a]=tot.get(a,0)+hx(d[0:64])
print(f"[MCT.CollateralWithdrawn] n={len(res)}", {k:round(v/1e6,2) for k,v in tot.items()}); time.sleep(12)

t=topic("Mint(address,address,uint256,uint256)")
res=logs(NUSD,t); tot={}
for r in res:
    a="0x"+r["topics"][2][-40:]; d=r["data"][2:]
    tot[a]=tot.get(a,0)+hx(d[0:64])
print(f"[NaraUSD.Mint] n={len(res)}", {k:round(v/1e6,2) for k,v in tot.items()})
