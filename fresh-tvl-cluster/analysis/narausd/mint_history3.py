import json, urllib.request, subprocess, time
def topic(sig): return subprocess.run(["cast","keccak",sig],capture_output=True,text=True).stdout.strip()
def logs(addr, topic0):
    url=f"https://eth.blockscout.com/api?module=logs&action=getLogs&fromBlock=1&toBlock=latest&address={addr}&topic0={topic0}&page=1&offset=1000"
    for attempt in range(5):
        try:
            req=urllib.request.Request(url, headers={"User-Agent":"Mozilla/5.0 research"})
            return json.load(urllib.request.urlopen(req))["result"]
        except Exception as e:
            time.sleep(4+attempt*4)
    raise RuntimeError("failed "+topic0)

MCT="0x4eD90999f558Fdc28606b7F7f9AFc7044befb803"
USDC="0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
USDT="0xdac17f958d2ee523a2206206994597c13d831ec7"
out={}
def hx(s): return int(s,16) if s and s!='0x' else 0

t=topic("Minted(address,address,uint256,uint256)"); res=logs(MCT,t)
tot={}; n=0
for r in res:
    asset="0x"+r["topics"][2][-40:]; d=r["data"][2:]
    amt=hx(d[0:64]); mct=hx(d[64:128]); n+=1
    tot[asset]=tot.get(asset,0)+amt
print(f"Minted n={n} per-asset-6dp:", {k:round(v/1e6,2) for k,v in tot.items()})
time.sleep(3)

t=topic("UnbackedMint(address,uint256)"); res=logs(MCT,t)
s=0; rows=[]
for r in res:
    d=r["data"][2:]; amt=hx(d[0:64]); s+=amt
    rows.append((int(r["blockNumber"],16), amt/1e18))
print(f"UnbackedMint n={len(res)} total={s/1e18:.6f} MCT")
for b,a in rows: print(f"  blk={b} {a:.4f}")
out["unbacked_total"]=s/1e18
time.sleep(3)

t=topic("Redeemed(address,address,uint256,uint256)"); res=logs(MCT,t)
tot={}
for r in res:
    asset="0x"+r["topics"][2][-40:]; d=r["data"][2:]
    amt=hx(d[0:64]); tot[asset]=tot.get(asset,0)+amt
print(f"Redeemed n={len(res)} per-asset-6dp:", {k:round(v/1e6,2) for k,v in tot.items()})
time.sleep(3)

t=topic("CollateralWithdrawn(address,uint256,address)"); res=logs(MCT,t)
tot={}
for r in res:
    asset="0x"+r["topics"][1][-40:]; d=r["data"][2:]
    amt=hx(d[0:64]); tot[asset]=tot.get(asset,0)+amt
print(f"CollateralWithdrawn n={len(res)} per-asset-6dp:", {k:round(v/1e6,2) for k,v in tot.items()})
time.sleep(3)

t=topic("UnbackedMint(address,uint256)")
# also NaraUSD Mint (mintWithCollateral emits Mint(address,address,uint256,uint256))
NUSD="0x5C6263904CCFD3Bcf1aAa6e7063dDd29743b3Bb7"
t2=topic("Mint(address,address,uint256,uint256)"); res=logs(NUSD,t2)
tot={}
for r in res[:400]:
    d=r["data"][2:]
    asset="0x"+r["topics"][2][-40:]
    amt=hx(d[0:64]); tot[asset]=tot.get(asset,0)+amt
print(f"NaraUSD Mint n={len(res)} per-asset-6dp:", {k:round(v/1e6,2) for k,v in tot.items()})
