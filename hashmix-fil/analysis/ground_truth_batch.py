#!/usr/bin/env python3
"""Batched JSON-RPC calls (ankr) for all remaining ground truth. Read-only."""
import json, urllib.request, time

EPS = ["https://rpc.ankr.com/filecoin", "https://api.chain.love/rpc/v1"]
HDRS = {"User-Agent": "Mozilla/5.0", "Content-Type": "application/json"}

def batch(calls, tries=5):
    """calls: list of (method, params) -> list of results"""
    payload = [{"jsonrpc": "2.0", "id": i, "method": m, "params": p} for i, (m, p) in enumerate(calls)]
    body = json.dumps(payload).encode()
    for i in range(tries):
        ep = EPS[i % len(EPS)]
        try:
            req = urllib.request.Request(ep, data=body, headers=HDRS)
            with urllib.request.urlopen(req, timeout=60) as r:
                out = json.loads(r.read().decode())
            if isinstance(out, dict):
                out = [out]
            res = {}
            for o in out:
                res[o.get("id")] = o.get("result", o.get("error"))
            return [res.get(i) for i in range(len(calls))]
        except Exception as e:
            time.sleep(3 + 3 * i)
    return None

def pad(a): return a.lower().replace("0x", "").rjust(64, "0")

POOL = "0x587A7eaE9b461ad724391Aa7195210e0547eD11d"
STFIL = "0x3C3501E6c353DbaEDDFA90376975Ce7aCe4Ac7a8"
VIEWS = {"totalSupply":"0x18160ddd","exchangeRateStored":"0x182df0f5","exchangeRateCurrent":"0xbd6d894d",
         "getCash":"0x3b1d21a2","totalBorrows":"0x47bd3718","totalReserves":"0x8f840ddd","borrowIndex":"0xaa5af0fd",
         "feeCollector":"0xc415b95c","controller":"0xf77c4791","interestRateModel":"0xf3fdb15a",
         "reserveFactor":"0x173b9904","protocolSeizeShare":"0x6752e702","accrualBlockNumber":"0x6c540baf",
         "admin":"0xf851a440","owner":"0x8da5cb5b","name":"0x06fdde03","symbol":"0x95d89b41","decimals":"0x313ce567",
         "initialExchangeRate":"0x675d972c","borrowBalanceCurrent_pool":"0x17bfdfbc"}
ADDRS = ["0x15723119e609331d5744258900D34F5C9B409ef4","0x256fA19F49661d166D58d9CF8D23c60711535413",
         "0x106a984153Ac6b5767B5A796C0BbEf9AB706022a","0x4c2231B68A630C789aEC9AF4107A8aEa3375382b",
         "0x7126063A90C3b1041c2D33C801459488da4A59B4","0x3D01FeB1ABEc6720fe2F2229C3c1f7A221D6df2D",
         "0x189eAd671C5C08000510b6B79e6e12F1413A320C","0xE2c0D842047781f2cF05A7973dc8124A37544976",
         "0xF487D7D6830c2580d78E703344f5FD271FD24F5A","0xA7a2646c0C76ffBDBDB1752D3878f84D7A5A561F",
         "0xb34c72BD27D8c585E706071586FEC1F67321eE09","0x55080E4Be333b46433bA3250670f72C03e6570B9",
         "0x22BFa0421CFc7607A8Ac4Eda7A8772CCe7e87b39","0x66A912d66d4f8D21c43a8488a185ADDa7586D6E5",
         "0xb80eC63a60Cee2B8952d3df208F4e3a14b67BE5b","0x037BC5D2998Fa68ea24b96D110dFe5eb2b2331C9",
         "0x92Fbb9Fc50074ACAb80554ccF4b19646bFDB8f00","0xDC465DB89Dc7ACc3DA000480c060afE934ccBf5E",
         "0xCD057a1c1c7A12Ebf5E5a48E4CEaA859322A6ed4","0x0440fad163462641F61787BAA018f2336871f761",
         "0xD59060790f28EcD10Be2d23cEc88a39461A8d0cd","0x06801E1eE94564198F720910dE61ec304a03F7c3",
         "0x6c9aCb3928c95F0DD6C057748e12750c2Fd4A5fa","0x1e8AbCb9FeBC3d3050f08DcE01D25e0d5E817241"]
EXTRA = {
  "FA33": "0xFA33F3866e7eF32F79734BCC5e011d767F8E574b",
  "E1DA": "0xE1DACa5a43DADd1b4db972d5d3a66eCF9960Eb81",
  "proxyAdmin13ce": "0x13ce9eB145a40b14B721570F0A91fc97656807DC",
  "D590": "0xD59060790f28EcD10Be2d23cEc88a39461A8d0cd",
  "CF89": "0xcF89b3A29499229E35d4fe71dFE54BEC2C1EbA48",
  "deployer": "0x06A4c6527fD462c4fD55664861437bC6D417FFA3",
  "10D81c": "0x10D81c7a15da6218F475b82eBFD638CFC3Cf36a5",
  "45D000": "0x45D000319ac5BcBbf4C76799FbFd3045EBBE9b09",
  "8f468C": "0x8f468C3e8A124376272F4042858a302c1634D5bc",
  "WFIL": "0x60E1773636CF5E4A227d9AC24F20fEca034ee25A",
  "controllerImplD3A8": "0xD3A8DCbada627FBE5E21eF224486Af4412c80aDF",
}

calls = []
idx = {}
for k, s in VIEWS.items():
    idx[("call", k)] = len(calls); calls.append(("eth_call", [{"to": POOL, "data": s}, "latest"]))
for a in ADDRS:
    idx[("bal", a)] = len(calls); calls.append(("eth_call", [{"to": POOL, "data": "0x70a08231" + pad(a)}, "latest"]))
for k, a in EXTRA.items():
    idx[("code", k)] = len(calls); calls.append(("eth_getCode", [a, "latest"]))
    idx[("native", k)] = len(calls); calls.append(("eth_getBalance", [a, "latest"]))
for k, a in [("pool","0x587A7eaE9b461ad724391Aa7195210e0547eD11d"), ("stfil", STFIL), ("FA33", "0xFA33F3866e7eF32F79734BCC5e011d767F8E574b")]:
    idx[("impl_slot", k)] = len(calls); calls.append(("eth_getStorageAt", [a, "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc", "latest"]))
    idx[("admin_slot", k)] = len(calls); calls.append(("eth_getStorageAt", [a, "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103", "latest"]))
# stFIL views
for k, s in [("stfil_name","0x06fdde03"),("stfil_symbol","0x95d89b41"),("stfil_totalSupply","0x18160ddd"),("stfil_bal_pool","0x70a08231" + pad(POOL))]:
    idx[("call2", k)] = len(calls); calls.append(("eth_call", [{"to": STFIL, "data": s}, "latest"]))
idx[("blocknum",)] = len(calls); calls.append(("eth_blockNumber", []))

res = batch(calls)
out = {"block": None, "views": {}, "cwfil_balance": {}, "code_bytes": {}, "native": {}, "slots": {}, "stfil": {}}
if res is None:
    print("BATCH FAILED")
else:
    for (kind, k), i in idx.items():
        v = res[i]
        if kind == "call": out["views"][k] = v
        elif kind == "bal": out["cwfil_balance"][k] = v
        elif kind == "code": out["code_bytes"][k] = (len(v) - 2) // 2 if isinstance(v, str) and v.startswith("0x") else v
        elif kind == "native": out["native"][k] = v
        elif kind == "impl_slot" or kind == "admin_slot": out["slots"][kind + "_" + k] = v
        elif kind == "call2": out["stfil"][k] = v
        elif kind == "blocknum": out["block"] = v
    json.dump(out, open("ground_truth_batch.json", "w"), indent=1)
    print(json.dumps(out, indent=1)[:4000])
