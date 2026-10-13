#!/usr/bin/env python3
"""Rose (Aurora) live-state dump for CI evidence. Read-only, keyless public RPC.

Writes ci-out/state.json. No secrets, no keyed endpoints.
"""
import json, urllib.request, time, os

RPC = "https://mainnet.aurora.dev"
OUT = "ci-out/state.json"

def rpc(method, params, retries=4):
    for _ in range(retries):
        try:
            req = urllib.request.Request(
                RPC,
                data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"},
            )
            r = json.load(urllib.request.urlopen(req, timeout=60))
            if "result" in r:
                return r["result"]
        except Exception:
            time.sleep(1)
    return None

def u(x):
    return int(x, 16) if x and x != "0x" else None

def call(to, data):
    return rpc("eth_call", [{"to": to, "data": data}, "latest"])

POOLS = {
    "3pool": ("0xc90dB0d8713414d78523436dC347419164544A3f",
              ["0xe3520349F477A5F6EB06107066048508498A291b", "0xB12BFcA5A55806AaF64E99521918A4bf0fC40802", "0x4988a896b1227218e4A686fdE5EabdcAbd91571f"]),
    "metaUST": ("0x8fe44f5cce02D5BE44e3446bBc2e8132958d22B8",
                ["0x5ce9F0B6AFb36135b5ddBF11705cEB65E634A9dC", "0xff79D5bff48e1C01b722560D6ffDfCe9FC883587"]),
    "metaFRAX": ("0xa34315F1ef49392387Dd143f4578083A9Bd33E94",
                 ["0xDA2585430fEf327aD8ee44Af8F1f989a2A91A3d2", "0xff79D5bff48e1C01b722560D6ffDfCe9FC883587"]),
    "metaMAI": ("0x65a761136815B45A9d78d9781d22d47247B49D23",
                ["0xdFA46478F9e5EA86d57387849598dbFB2e964b02", "0xff79D5bff48e1C01b722560D6ffDfCe9FC883587"]),
    "RUSDpool": ("0x79B0a67a4045A7a8DC04b17456F4fe15339cBA34",
                 ["0x19cc40283B057D6608C22F1D20F17e16C245642E", "0xff79D5bff48e1C01b722560D6ffDfCe9FC883587"]),
}
VASE = "0xee793001Ce9Fa988712B15a59CCf5dC7d54b22FF"
GARDENS = {
    "gardenNear": "0x64C922E3824ab40cbbEdd6C8092d148C283d3D3D",
    "gardenUsdc": "0xfbAF3eBF228eB712b1267285787e51aDd70086bB",
    "gardenUsdt": "0x0F44fCD177098Cb2B063B50f6C62e4F1E1f9d596",
    "gardenWeth": "0x084355FDd5fcfd55d60C5B8626756a6906576f13",
    "gardenAtust": "0xe8F7F08D50e12145Cb722cfF861e6A9b43EADBA1",
}
VASE_TOKENS = {
    "RUSD": "0x19cc40283B057D6608C22F1D20F17e16C245642E",
    "WBTC": "0xF4eB217Ba2454613b15dBdea6e5f22276410e89e",
    "UST": "0x5ce9F0B6AFb36135b5ddBF11705cEB65E634A9dC",
    "USDC": "0xB12BFcA5A55806AaF64E99521918A4bf0fC40802",
    "USDT": "0x4988a896b1227218e4A686fdE5EabdcAbd91571f",
    "WNEAR": "0xC42C30aC6Cc15faC9bD938618BcaA1a1FaE8501d",
    "WETH": "0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB",
}

out = {"rpc": "https://mainnet.aurora.dev", "block": None, "pools": {}, "gardens": {}, "vase": {}, "admin_fee_excess": {}}
blk = rpc("eth_blockNumber", [])
out["block"] = u(blk)

for name, (pool, coins) in POOLS.items():
    d = {"address": pool, "coins": coins, "balances": [], "actual": [], "excess": [], "A": u(call(pool, "0xf446c1d0")),
         "fee": u(call(pool, "0xddca3f43")), "owner": None, "vprice": u(call(pool, "0xbb7b8b80")),
         "lp": None}
    o = call(pool, "0x8da5cb5b")
    d["owner"] = "0x" + o[-40:] if o else None
    for i, t in enumerate(coins):
        b = u(call(pool, "0x4903b0d1" + f"{i:064x}"))
        a = u(call(t, "0x70a08231" + pool[2:].rjust(64, "0")))
        d["balances"].append(b)
        d["actual"].append(a)
        d["excess"].append((a - b) if (a is not None and b is not None) else None)
    lp = call(pool, "0x82c63066") or call(pool, "0xfc0c546a")
    d["lp"] = "0x" + lp[-40:] if lp else None
    out["pools"][name] = d

for name, g in GARDENS.items():
    ci = call(g, "0x1d1c9390")
    words = [ci[2 + 64 * i:2 + 64 * (i + 1)] for i in range(8)] if ci else []
    tb = call(g, "0x8285ef40")
    d = {
        "address": g,
        "collateral": "0x" + words[0][-40:] if words else None,
        "isBorrowWhitelisted": u("0x" + words[1]) if words else None,
        "oracle": "0x" + words[2][-40:] if words else None,
        "collateralizationRate": u("0x" + words[4]) if words else None,
        "liquidationMultiplier": u("0x" + words[5]) if words else None,
        "borrowOpeningFee": u("0x" + words[6]) if words else None,
        "interestPerSecond": u("0x" + words[7]) if words else None,
        "exchangeRate": u(call(g, "0x3ba0b9a9")),
        "totalCollateralShare": u(call(g, "0x473e3ce7")),
        "totalBorrow": [u(tb[2:66]), u(tb[66:130])] if tb else None,
        "feeTo": "0x" + (call(g, "0x017e7e58") or "")[-40:] if call(g, "0x017e7e58") else None,
    }
    out["gardens"][name] = d

for name, t in VASE_TOKENS.items():
    tot = call(VASE, "0x4ffe34db" + t[2:].rjust(64, "0"))
    d = {"token": t,
         "vase_balance": u(call(t, "0x70a08231" + VASE[2:].rjust(64, "0"))),
         "totals": [u(tot[2:66]), u(tot[66:130])] if tot else None}
    out["vase"][name] = d

# admin fee excess summary (USD at stated prices)
prices = {"3pool": [1.0, 1.0, 1.0], "metaUST": [0.0363, 1.0], "metaFRAX": [0.9904, 1.0], "metaMAI": [0.9962, 1.0], "RUSDpool": [0.31, 1.0]}
dec = {"3pool": [18, 6, 6], "metaUST": [18, 18], "metaFRAX": [18, 18], "metaMAI": [18, 18], "RUSDpool": [18, 18]}
total = 0.0
for name, d in out["pools"].items():
    s = 0.0
    for i, e in enumerate(d["excess"]):
        if e:
            s += e / (10 ** dec[name][i]) * prices[name][i]
    out["admin_fee_excess"][name] = round(s, 2)
    total += s
out["admin_fee_excess"]["TOTAL_USD"] = round(total, 2)

with open(OUT, "w") as f:
    json.dump(out, f, indent=1)
print(f"block={out['block']} pools={len(out['pools'])} gardens={len(out['gardens'])} admin_fee_excess_usd={out['admin_fee_excess']['TOTAL_USD']}")
print(json.dumps(out["admin_fee_excess"], indent=1))
