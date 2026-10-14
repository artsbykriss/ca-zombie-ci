#!/usr/bin/env python3
"""Read Comptroller + market config for ReactorFusion Era at one block; save era-positions-config.json."""
import json, os, sys, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
C = "0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2"
MARKETS = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH":   "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC":  "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT":  "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK":    "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDC":  "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}
import os as _os
RPC_URLS = []
if _os.environ.get("ALCHEMY_API_KEY_2"):
    RPC_URLS.append("https://zksync-mainnet.g.alchemy.com/v2/" + _os.environ["ALCHEMY_API_KEY_2"])
if _os.environ.get("INFURA_API_KEY"):
    RPC_URLS.append("https://zksync-mainnet.infura.io/v3/" + _os.environ["INFURA_API_KEY"])
RPC_URLS.append("https://mainnet.era.zksync.io/")
SEL = {
    "oracle()": "0x7dc0d1d0", "closeFactorMantissa()": "0x6c540baf",
    "liquidationIncentiveMantissa()": "0x4ada90af", "markets(address)": "0x8e8f294b",
    "collateralFactorMantissa(address)": "0xe7c02777", "getUnderlyingPrice(address)": "0xfc57d4df",
    "decimals()": "0x313ce567", "totalSupply()": "0x18160ddd", "totalBorrows()": "0x47bd3718",
    "getCash()": "0x3b1d21a2", "exchangeRateStored()": "0x182df0f5", "symbol()": "0x95d89b41",
    "reserveFactorMantissa()": "0x173b9904", "borrowRatePerBlock()": "0xf8f9da28",
    "accrualBlockNumber()": "0x6c540baf_x", "interestRateModel()": "0xf2b3abbd_x",
}


def pad(a):
    return a.lower()[2:].rjust(64, "0")


def post(url, payload, timeout=25):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "research-read-only"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())


def batch(items, block_hex, size=50, tries=5):
    out = [None] * len(items); errs = [None] * len(items)
    pending = list(range(len(items)))
    while pending and tries > 0:
        tries -= 1
        still = []
        for i in range(0, len(pending), size):
            g = pending[i:i + size]
            payload = [{"jsonrpc": "2.0", "id": x, "method": "eth_call", "params": [{"to": items[x][0], "data": items[x][1]}, block_hex]} for x in g]
            ok = False
            for url in RPC_URLS:
                try:
                    resp = post(url, payload)
                    if isinstance(resp, list):
                        byid = {r.get("id"): r for r in resp}
                        for x in g:
                            r = byid.get(x, {})
                            if "result" in r:
                                out[x] = r["result"]
                            else:
                                errs[x] = str(r.get("error"))[:120]
                        ok = True
                        break
                except Exception as e:
                    errs[g[0]] = str(e)[:80]
            if not ok:
                still.extend(g)
        pending = still
        if pending:
            time.sleep(1.0)
    return out, errs


def main():
    block = None
    for url in RPC_URLS:
        try:
            j = post(url, {"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}, timeout=40)
            block = int(j["result"], 16); break
        except Exception:
            continue
    bh = hex(block)
    print("block", block, flush=True)
    items = [(C, SEL["oracle()"]), (C, SEL["closeFactorMantissa()"]), (C, SEL["liquidationIncentiveMantissa()"])]
    keys = ["oracle", "closeFactor", "liqIncentive"]
    for m, a in MARKETS.items():
        items += [(C, SEL["markets(address)"] + pad(a)), (C, SEL["collateralFactorMantissa(address)"] + pad(a)),
                  (a, SEL["decimals()"]), (a, SEL["totalSupply()"]), (a, SEL["totalBorrows()"]),
                  (a, SEL["getCash()"]), (a, SEL["exchangeRateStored()"]), (a, SEL["symbol()"]),
                  (a, SEL["reserveFactorMantissa()"])]
        keys += [f"{m}|markets", f"{m}|cf", f"{m}|decimals", f"{m}|totalSupply", f"{m}|totalBorrows",
                 f"{m}|cash", f"{m}|xrate", f"{m}|symbol", f"{m}|reserveFactor"]
    raws, errs = batch(items, bh)
    cfg = {}
    for k, raw, e in zip(keys, raws, errs):
        cfg[k] = {"raw": raw, "err": e}
    oracle = "0x" + cfg["oracle"]["raw"][-40:] if cfg["oracle"].get("raw") else None
    items2 = [(oracle, SEL["getUnderlyingPrice(address)"] + pad(a)) for a in MARKETS.values()]
    raws2, errs2 = batch(items2, bh, size=6)
    for m, raw, e in zip(MARKETS, raws2, errs2):
        cfg[f"{m}|price"] = {"raw": raw, "err": e}
    json.dump({"block": block, "comptroller": C, "oracle": oracle, "cfg": cfg},
              open(os.path.join(HERE, "era-positions-config.json"), "w"), indent=1)
    # human summary
    def u(x):
        return int(x, 16) if x else None
    print("closeFactor", u(cfg["closeFactor"]["raw"]), "liqIncentive", u(cfg["liqIncentive"]["raw"]))
    for m in MARKETS:
        mk = cfg[f"{m}|markets"]["raw"]
        listed = int(mk[2:66], 16) if mk else None
        cf = int(mk[66:130], 16) if mk else None
        print(f"{m}: listed={listed} cf={cf} dec={u(cfg[f'{m}|decimals']['raw'])} "
              f"supply={u(cfg[f'{m}|totalSupply']['raw'])} borrows={u(cfg[f'{m}|totalBorrows']['raw'])} "
              f"cash={u(cfg[f'{m}|cash']['raw'])} xrate={u(cfg[f'{m}|xrate']['raw'])} "
              f"price={u(cfg[f'{m}|price']['raw'])}", flush=True)


if __name__ == "__main__":
    main()
