#!/usr/bin/env python3
"""Focused read-only calls (glif primary). No keys/signing."""
import json, urllib.request, time

ENDPOINTS = ["https://api.node.glif.io/rpc/v1", "https://filecoin.chainup.net/rpc/v1",
             "https://filecoin.blockscout.com/api/eth-rpc"]
HDRS = {"User-Agent": "Mozilla/5.0", "Content-Type": "application/json"}

def rpc(method, params, tries=5):
    last = None
    for i in range(tries):
        ep = ENDPOINTS[min(i, len(ENDPOINTS) - 1)]
        try:
            body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
            req = urllib.request.Request(ep, data=body, headers=HDRS)
            with urllib.request.urlopen(req, timeout=45) as r:
                out = json.loads(r.read().decode())
            if "error" in out or out.get("result") is None:
                last = str(out)[:120]; time.sleep(1.5); continue
            return out.get("result")
        except Exception as e:
            last = str(e); time.sleep(2 + 2 * i)
    return "RPCFAIL:" + str(last)

def pad(a): return a.lower().replace("0x", "").rjust(64, "0")

POOL = "0x587A7eaE9b461ad724391Aa7195210e0547eD11d"
STFIL = "0x3C3501E6c353DbaEDDFA90376975Ce7aCe4Ac7a8"
FA33 = "0xFA33F3866e7eF32F79734BCC5e011d767F8E574b"
HOLDERS = ["0x037BC5D2998Fa68ea24b96D110dFe5eb2b2331C9","0x92Fbb9Fc50074ACAb80554ccF4b19646bFDB8f00",
           "0xDC465DB89Dc7ACc3DA000480c060afE934ccBf5E","0xCD057a1c1c7A12Ebf5E5a48E4CEaA859322A6ed4",
           "0xA7a2646c0C76ffBDBDB1752D3878f84D7A5A561F","0xb34c72BD27D8c585E706071586FEC1F67321eE09",
           "0x0440fad163462641F61787BAA018f2336871f761"]
VIEWS = {"computeTotalSupply":"0x18160ddd","exchangeRateStored":"0x182df0f5","getCash":"0x3b1d21a2",
         "totalBorrows":"0x47bd3718","totalReserves":"0x8f840ddd","feeCollector":"0xc415b95c",
         "controller":"0xf77c4791","interestRateModel":"0xf3fdb15a","admin":"0xf851a440","owner":"0x8da5cb5b",
         "pendingAdmin":"0x26782247","borrowIndex":"0xaa5af0fd","reserveFactor":"0x173b9904",
         "exchangeRateCurrent":"0xbd6d894d","protocolSeizeShare":"0xff5a20bf","initialExchangeRate":"0x675d972c",
         "totalBorrowsCurrent":"0x17bfdfbc","accrualBlockNumber":"0x6c540baf"}

def main():
    out = {"block": rpc("eth_blockNumber", []), "pool": {}, "holders": {}, "storage": {}, "code": {}}
    def save(): json.dump(out, open("focused_calls.json", "w"), indent=1)
    for k, s in VIEWS.items():
        out["pool"][k] = rpc("eth_call", [{"to": POOL, "data": s}, "latest"]); save()
    for h in HOLDERS:
        out["holders"][h] = rpc("eth_call", [{"to": POOL, "data": "0x70a08231" + pad(h)}, "latest"]); save()
    for name, addr in [("pool", POOL), ("stfil", STFIL), ("controllerFA33", FA33)]:
        out["storage"][name + "_impl"] = rpc("eth_getStorageAt", [addr, "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc", "latest"])
        out["storage"][name + "_admin"] = rpc("eth_getStorageAt", [addr, "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103", "latest"]); save()
    for a in ["0xD59060790f28EcD10Be2d23cEc88a39461A8d0cd", "0xFA33F3866e7eF32F79734BCC5e011d767F8E574b",
              "0xE1DACa5a43DADd1b4db972d5d3a66eCF9960Eb81", "0x10D81c7a15da6218F475b82eBFD638CFC3Cf36a5",
              "0x45D000319ac5BcBbf4C76799FbFd3045EBBE9b09", "0x8f468C3e8A124376272F4042858a302c1634D5bc",
              "0x06A4c6527fD462c4fD55664861437bC6D417FFA3"]:
        c = rpc("eth_getCode", [a, "latest"])
        out["code"][a] = (len(c) - 2) // 2 if isinstance(c, str) and c.startswith("0x") else c
        out["code"]["bal_" + a] = rpc("eth_getBalance", [a, "latest"]); save()
    print("DONE block", out["block"])

if __name__ == "__main__":
    main()
