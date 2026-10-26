#!/usr/bin/env python3
"""Check owner/admin addresses: contract vs EOA, and their owner()/admin() if contract."""
import json, urllib.request, time
RPCS={"op":"https://mainnet.optimism.io","polygon":"https://polygon-bor-rpc.publicnode.com",
 "zksync":"https://mainnet.era.zksync.io","scroll":"https://rpc.scroll.io",
 "eth":"https://ethereum-rpc.publicnode.com"}
def rpc(chain,method,params):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req=urllib.request.Request(RPCS[chain],data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    for _ in range(3):
        try:
            with urllib.request.urlopen(req,timeout=15) as r: return json.loads(r.read())["result"]
        except Exception: time.sleep(1)
    return None
ADDRS=[
 ("row14/13 owner (WOOFi)","op","0x682f676389bde27db6c8a3d8bc6af0b021e9fff2"),
 ("row17 owner (Wanchain)","op","0x329f162550e3d5d9898a0aae05e21bfcd5f1cf83"),
 ("row17 admin","op","0xa35b3c55626188015ac79f396d0b593947231976"),
 ("row19 owner","op","0x2869b95d0cd5a5a673270505bb6fb7a129ce968e"),
 ("row21 owner","polygon","0x58c5927b3c603c5a59fd1ed7d22dff5655e43e79"),
 ("row18 owner (Upshift vault)","eth","0xc428439fb7b1efe56360eb837ca98f551fdd9b26"),
 ("row22 eip1967 admin","op","0xfba759bcd1a99a7724c5068feddb4f5b844b941a"),
 ("scr4 owner","scroll","0xe0474827e6ec1953300f4efab36bcfd535fb7e44"),
 ("row14/13 eip1967 admin","op","0x4f0416bbc406bb725bd185cf69bc4b8b2e22357e"),
]
for label,chain,a in ADDRS:
    c=rpc(chain,"eth_getCode",[a,"latest"])
    sz=(len(c)-2)//2 if c and c!="0x" else 0
    out={"label":label,"chain":chain,"addr":a,"code_size":sz}
    if sz>0:
        for n,sel in [("owner","0x8da5cb5b"),("admin","0xf851a440"),("getOwners","0xa0e67e2b"),
                      ("totalAssets","0x01e1d114"),("asset","0x38d52e0f"),("symbol","0x95d89b41")]:
            r=rpc(chain,"eth_call",[{"to":a,"data":sel},"latest"])
            if r and r!="0x": out[n]=r[:130]
    print(json.dumps(out))
