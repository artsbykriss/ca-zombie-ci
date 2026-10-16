import json, urllib.request, subprocess
def topic(sig): return subprocess.run(["cast","keccak",sig],capture_output=True,text=True).stdout.strip()
def logs(addr, topic0, page=1):
    url=f"https://eth.blockscout.com/api?module=logs&action=getLogs&fromBlock=1&toBlock=latest&address={addr}&topic0={topic0}&page={page}&offset=1000"
    req=urllib.request.Request(url, headers={"User-Agent":"Mozilla/5.0 research"})
    return json.load(urllib.request.urlopen(req))["result"]

MCT="0x4eD90999f558Fdc28606b7F7f9AFc7044befb803"
for ev in ["Minted(address,address,uint256,uint256)","UnbackedMint(address,uint256)","Redeemed(address,address,uint256,uint256)","CollateralWithdrawn(address,uint256,address)"]:
    t=topic(ev); res=logs(MCT,t)
    print(f"== {ev} n={len(res)}")
    for r in res[:3]:
        print("  raw:", r["blockNumber"], r["topics"], r["data"][:200])
