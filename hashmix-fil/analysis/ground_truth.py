#!/usr/bin/env python3
"""Ground-truth balance/rate calls via rotating public RPCs. Read-only."""
import json, urllib.request, time

EPS = ["https://api.node.glif.io/rpc/v1",
       "https://filecoin.chainup.net/rpc/v1",
       "https://rpc.ankr.com/filecoin",
       "https://filecoin.blockscout.com/api/eth-rpc"]
HDRS = {"User-Agent": "Mozilla/5.0", "Content-Type": "application/json"}

def rpc(method, params, tries=9, spacing=4.0):
    last = None
    for i in range(tries):
        ep = EPS[i % len(EPS)]
        try:
            body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
            req = urllib.request.Request(ep, data=body, headers=HDRS)
            with urllib.request.urlopen(req, timeout=45) as r:
                out = json.loads(r.read().decode())
            res = out.get("result")
            if res is None or res == "0x":
                last = "EMPTY/REVERT " + str(out.get("error", ""))[:80]
                time.sleep(spacing); continue
            return res
        except Exception as e:
            last = str(e)[:100]; time.sleep(spacing)
    return "RPCFAIL:" + str(last)

def pad(a): return a.lower().replace("0x","").rjust(64,"0")

POOL = "0x587A7eaE9b461ad724391Aa7195210e0547eD11d"
CAND = ["0x15723119e609331d5744258900D34F5C9B409ef4","0x256fA19F49661d166D58d9CF8D23c60711535413",
        "0x106a984153Ac6b5767B5A796C0BbEf9AB706022a","0x4c2231B68A630C789aEC9AF4107A8aEa3375382b",
        "0x7126063A90C3b1041c2D33C801459488da4A59B4","0x3D01FeB1ABEc6720fe2F2229C3c1f7A221D6df2D",
        "0x189eAd671C5C08000510b6B79e6e12F1413A320C","0xE2c0D842047781f2cF05A7973dc8124A37544976",
        "0xF487D7D6830c2580d78E703344f5FD271FD24F5A","0xA7a2646c0C76ffBDBDB1752D3878f84D7A5A561F",
        "0xb34c72BD27D8c585E706071586FEC1F67321eE09","0x55080E4Be333b46433bA3250670f72C03e6570B9",
        "0x22BFa0421CFc7607A8Ac4Eda7A8772CCe7e87b39","0x66A912d66d4f8D21c43a8488a185ADDa7586D6E5",
        "0xb80eC63a60Cee2B8952d3df208F4e3a14b67BE5b","0x037BC5D2998Fa68ea24b96D110dFe5eb2b2331C9",
        "0x92Fbb9Fc50074ACAb80554ccF4b19646bFDB8f00","0xDC465DB89Dc7ACc3DA000480c060afE934ccBf5E",
        "0xCD057a1c1c7A12Ebf5E5a48E4CEaA859322A6ed4","0x0440fad163462641F61787BAA018f2336871f761"]
VIEWS = {"totalSupply":"0x18160ddd","exchangeRateStored":"0x182df0f5","exchangeRateCurrent":"0xbd6d894d",
         "getCash":"0x3b1d21a2","totalBorrows":"0x47bd3718","totalReserves":"0x8f840ddd","borrowIndex":"0xaa5af0fd",
         "feeCollector":"0xc415b95c","controller":"0xf77c4791","interestRateModel":"0xf3fdb15a",
         "reserveFactor":"0x173b9904","protocolSeizeShare":"0x6752e702","accrualBlockNumber":"0x6c540baf",
         "initialExchangeRate":"0x675d972c","admin":"0xf851a440","owner":"0x8da5cb5b","pendingAdmin":"0x26782247"}

def main():
    out={"pool":{},"balances":{}}
    for k,s in VIEWS.items():
        out["pool"][k]=rpc("eth_call",[{"to":POOL,"data":s},"latest"])
        json.dump(out,open("ground_truth.json","w"),indent=1); time.sleep(2)
    for a in CAND:
        out["balances"][a]=rpc("eth_call",[{"to":POOL,"data":"0x70a08231"+pad(a)},"latest"])
        json.dump(out,open("ground_truth.json","w"),indent=1); time.sleep(2)
    print("DONE")

if __name__=="__main__":
    main()
