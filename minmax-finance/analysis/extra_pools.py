#!/usr/bin/env python3
"""Check candidate addresses for MinMax pool identity (read-only, single RPC, threaded)."""
import json, sys, time, urllib.request
from concurrent.futures import ThreadPoolExecutor

RPC = "https://babel-api.mainnet.iotex.io"

def rpc(method, params, retries=1):
    for _ in range(retries + 1):
        try:
            req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                                         headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=12) as r:
                return json.loads(r.read())
        except Exception:
            time.sleep(0.2)
    return {}

def call_ok(to, data):
    d = rpc("eth_call", [{"to": to, "data": data}, "latest"])
    return d.get("result") if "result" in d else None

def words(h):
    if not h or h == "0x": return []
    h = h[2:]
    return [int(h[i:i+64], 16) for i in range(0, len(h), 64)]

def addr(w): return "0x" + f"{w:040x}"[-40:]

SEL = {"swapStorage()": "0x5fd65f0f", "getToken(uint8)": "0x82b86600", "getTokenBalance(uint8)": "0x91ceb3eb",
       "paused()": "0x5c975abb", "owner()": "0x8da5cb5b", "totalSupply()": "0x18160ddd"}

TOKSYM = {"0xacee9b11cd4b3f57e58880277ac72c8c41abe4e4":"ioBUSD","0x3b2bf2b523f54c4e454f08aa286d03115aff326c":"ioUSDC",
"0x6fbcdc1169b5130c59e72e51ed68a84841c98cd1":"ioUSDT","0x1cbad85aa66ff3c12dc84c5881886eeb29c1bb9b":"ioDAI",
"0x84abcb2832be606341a50128aeb1db43aa017449":"BUSD-bsc","0x037346e5a5722957ac2cab6ceb8c74fc18cea91d":"USDC_b",
"0x42c9255d5e522e83b16ea11a3ba04c2d3afca079":"USDT_b","0x3cdb7c48e70b854ed2fa392e21687501d84b3afc":"USDT-matic",
"0x62a9d987cbf4c45a550deed5b57b200d7a319632":"DAI-matic","0xc04da3a99d17135857bb937d2fbb321d3b6c6a81":"USDC-matic",
"0xec690cdd448e3cbb51ed135df72301c3265a8f80":"XIM"}
LPNAMES = {"0xa546b5769f3f97f93fc90f63fbe7423250216b98":"P3-LP","0xc35257624b01932e521bc5d9dc07e4f9ed21ed28":"P5-LP",
"0xdff5dc9d8dac189324452d54e2df19d2bdba78ce":"P9-LP","0x14d66e676b978255c719b2771c657acc418bb9fa":"P1-LP",
"0xb581afb9c7aa567edbe6274bddc975b7926edaaf":"P2-LP","0xd33f8a41e2ec9ff64fdc008e00f69f0e142948ad":"P6-LP",
"0x425c2c686f12d61ecd4dfd1170214e3befebbe33":"P7-LP","0xf79fd0a6d1d8ce877fc70acd321fdf1626168398":"P11-LP",
"0x89a7663c4ca176acd8e6a054da67b0d301fc218a":"P4-LP","0x834d27a61c7fe4f52ad5435e59e85d64aa1375a7":"P8-LP",
"0x69d9eabd5b3f967bbae9ff9b73e4da3ba0c46d08":"P10-LP"}

CANDS = ["0x38B872cA72135D9658441C8662eedaAB5f5F8119","0x5F0273ABD7754EF42a4eC320c97d5Eb1e270e54c",
"0x78A00Db770E8fb8F19bDaF2B7117107bb8E38E9A","0x886fA6ca90750ddd53E74217Be01eDF9049dAc2f",
"0xA63B7e43F4cb7C4E366e5524849a8eAc1086D33e","0xEd01d84879D56Eb4e0969007ab8aF0e1996353A2",
"0x8360D306Be83f9A992b1657Ad68fe08Ca6f2757A","0x833d89FA7dD693035678AB53Be792F6F4B352C01",
"0x7B24cAA6a497bc79FDfBAeb8A71a38F15eB3d7F7","0xC264ED05ed2aF451732EF05C480d9e51b92a07aC"]

def probe(c):
    ss = words(call_ok(c, SEL["swapStorage()"]))
    if len(ss) < 7:
        return {"addr": c, "is_pool": False}
    lp = addr(ss[6])
    out = {"addr": c, "is_pool": True, "lp": lp, "lpname": LPNAMES.get(lp.lower(), ""),
           "swapFee": ss[4], "adminFee": ss[5],
           "paused": words(call_ok(c, SEL["paused()"])), "owner": None, "tokens": [], "bals": [], "lpSupply": None}
    o = words(call_ok(c, SEL["owner()"]))
    out["owner"] = addr(o[0]) if o else None
    for i in range(4):
        v = call_ok(c, SEL["getToken(uint8)"] + f"{i:064x}")
        out["tokens"].append(addr(words(v)[0]) if v else None)
        v2 = call_ok(c, SEL["getTokenBalance(uint8)"] + f"{i:064x}")
        out["bals"].append(words(v2)[0] if v2 else None)
    ts = words(call_ok(lp, SEL["totalSupply()"]))
    out["lpSupply"] = ts[0] if ts else None
    return out

if __name__ == "__main__":
    with ThreadPoolExecutor(max_workers=10) as ex:
        res = list(ex.map(probe, CANDS))
    for r in res:
        if not r["is_pool"]:
            print(r["addr"], "NOT a pool")
            continue
        print(f"POOL {r['addr']} lp={r['lp']} ({r['lpname']}) paused={r['paused']} owner={r['owner']} lpSupply={r['lpSupply']} swapFee={r['swapFee']} adminFee={r['adminFee']}")
        print("   tokens:", [(t, TOKSYM.get((t or '').lower(), '')) for t in r["tokens"]])
        print("   bals:", r["bals"])
    json.dump(res, open("extra_pools_probe.json", "w"), indent=1)
