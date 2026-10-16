import json, urllib.request, subprocess
def topic(sig): return subprocess.run(["cast","keccak",sig],capture_output=True,text=True).stdout.strip()
def logs(addr, topic0, page=1):
    url=f"https://eth.blockscout.com/api?module=logs&action=getLogs&fromBlock=1&toBlock=latest&address={addr}&topic0={topic0}&page={page}&offset=1000"
    req=urllib.request.Request(url, headers={"User-Agent":"Mozilla/5.0 research"})
    return json.load(urllib.request.urlopen(req))["result"]

MCT="0x4eD90999f558Fdc28606b7F7f9AFc7044befb803"
USDC="0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48".lower()
USDT="0xdAC17F958D2ee523a2206206994597C13D831ec7".lower()

for ev in ["Minted(address,address,uint256,uint256)","UnbackedMint(address,uint256)","Redeemed(address,address,uint256,uint256)","CollateralWithdrawn(address,uint256,address)"]:
    t=topic(ev)
    res=logs(MCT,t)
    print(f"== {ev} n={len(res)}")
    tot={}
    for r in res:
        d=r["data"][2:]
        blk=int(r["blockNumber"],16)
        if ev.startswith("Minted") or ev.startswith("Redeemed"):
            # data: beneficiary, asset, amount, mctAmount (all 32 bytes each)
            ben="0x"+d[24:64]; asset="0x"+d[88:128].replace("000000000000000000000000","")[-40:]
            amount=int(d[64:128],16); mctAmt=int(d[128:192],16)
            asset=("0x"+d[24+64+24:24+64+64])
            tot.setdefault(asset,0)
            tot[asset]+= amount if ev.startswith("Minted") else -amount
            print(f"  blk={blk} asset={asset} amount={amount/1e6:.6f} mct={mctAmt/1e18:.6f}")
        elif ev.startswith("UnbackedMint"):
            ben="0x"+d[24:64]; amt=int(d[64:128],16)
            tot.setdefault("UNBACKED",0); tot["UNBACKED"]+=amt
            print(f"  blk={blk} beneficiary={ben} mct={amt/1e18:.6f}")
        else:
            asset="0x"+d[24+64+64+24:24+64+64+64]; amt=int(d[64:128],16); to="0x"+d[24:64]
            tot.setdefault("WITHDRAWN:"+asset,0); tot["WITHDRAWN:"+asset]+=amt
            print(f"  blk={blk} asset={asset} amount={amt/1e6:.6f} to={to}")
    print("  totals:", {k:(v/1e6 if not k=='UNBACKED' else v/1e18) for k,v in tot.items()})
