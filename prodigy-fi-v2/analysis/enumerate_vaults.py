#!/usr/bin/env python3
"""Enumerate Prodigy.Fi V2 PositionManager vaults on Base (read-only, KEYLESS).

Reads getDeployedVaultCount/getDeployedVaults and per-vault state + balances.
Writes analysis/vaults.json
"""
import json, os, sys, time
from concurrent.futures import ThreadPoolExecutor
import urllib.request

RPC = os.environ.get("BASE_RPC", "https://base-rpc.publicnode.com")
PM = "0x50aB3FE7d089c4F0dD8096aAeA9578f8E7B18AF7"
TOKENS = {
    "WETH": "0x4200000000000000000000000000000000000006",
    "USDC": "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
    "cbBTC": "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf",
    "AERO": "0x940181a94A35A4569E4529A3CDfB74e38FD98631",
    "t1": "0x0b3e328455c4059EEb9e3f84b5543F74E24e7E1b",
    "t2": "0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196",
    "t3": "0x63706e401c06ac8513145b7687A14804d17f814b",
    "t4": "0x8Ee73c484A26e0A5df2Ee2a4960B789967dd0415",
    "t5": "0x4F9Fd6Be4a90f2620860d680c0d4d5Fb53d1A825",
    "t6": "0x98d0baa52b2D063E780DE12F615f963Fe8537553",
    "t7": "0xA99F6e6785Da0F5d6fB42495Fe424BCE029Eeb3E",
}
S_COLLPOOL="0xff0eccf6"; S_INVTOKEN="0x002703a2"; S_LINKED="0xea12489f"
S_STATE="0xc19d93fb"; S_INIT="0x392e53cd"; S_DEPOSITTOTAL="0x4adae0da"
S_EXPIRY="0xe184c9be"; S_VAULTCREATOR="0xfe3a6d88"; S_BAL="0x70a08231"

def rpc(method, params):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    for _ in range(4):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json"})
            r = json.load(urllib.request.urlopen(req, timeout=30))
            return r.get("result")
        except Exception:
            time.sleep(0.3)
    return None

def call(to, data):
    r = rpc("eth_call", [{"to": to, "data": data}, "latest"])
    return r

def a(h):
    return "0x"+h[-40:] if h and len(h) >= 42 else None
def u(h):
    try: return int(h, 16)
    except: return None

def main():
    total = u(call(PM, "0xa7220cc9"))
    print("count", total, file=sys.stderr)
    vaults = []
    i = 0
    while i < total:
        n = min(100, total-i)
        data = "0xba0bdff0" + format(i,'064x') + format(n,'064x')
        r = call(PM, data)
        if not r: print("page fail", i, file=sys.stderr); break
        raw = r[2:]
        off = int(raw[0:64],16)
        ln = int(raw[off*2:off*2+64],16)
        for k in range(ln):
            w = raw[(off+32+k*32)*2:(off+32+k*32)*2+64]
            vaults.append("0x"+w[-40:])
        i += n
    print("vaults", len(vaults), file=sys.stderr)
    def probe(v):
        rec = {"vault": v}
        rec["collateralPool"] = a(call(v, S_COLLPOOL))
        rec["investmentToken"] = a(call(v, S_INVTOKEN))
        rec["linkedToken"] = a(call(v, S_LINKED))
        rec["state"] = u(call(v, S_STATE))
        rec["initialized"] = u(call(v, S_INIT))
        rec["depositTotal"] = u(call(v, S_DEPOSITTOTAL))
        rec["expiry"] = u(call(v, S_EXPIRY))
        rec["vaultCreator"] = a(call(v, S_VAULTCREATOR))
        rec["native"] = u(rpc("eth_getBalance",[v,"latest"]))
        tb = {}
        for name, addr in TOKENS.items():
            b = u(call(addr, S_BAL + v[2:].rjust(64,"0")))
            if b: tb[name] = b
        rec["tokenBalances"] = tb
        return rec
    out = []
    with ThreadPoolExecutor(max_workers=16) as ex:
        for r in ex.map(probe, vaults):
            out.append(r)
    json.dump(out, open("vaults.json","w"), indent=1)
    funded = [r for r in out if r["native"] or r["tokenBalances"]]
    print("funded", len(funded), file=sys.stderr)
    selfc = [r for r in out if r["collateralPool"] and int(r["collateralPool"],16)==0]
    print("self-collateralised", len(selfc), file=sys.stderr)
    for r in funded:
        print(r["vault"], "pool=",r["collateralPool"], "inv=",r["investmentToken"], r["tokenBalances"], "native=",r["native"], file=sys.stderr)

if __name__=="__main__":
    main()
