#!/usr/bin/env python3
"""Read MinMax pool LP token supplies, admin balances, and holder counts (read-only)."""
import sys, json, time, urllib.request
from concurrent.futures import ThreadPoolExecutor

RPC = "https://babel-api.mainnet.iotex.io"

def rpc(method, params, retries=2):
    for i in range(retries + 1):
        try:
            req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                                         headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=20) as r:
                return json.loads(r.read())
        except Exception:
            time.sleep(0.4)
    return {}

def call_ok(to, data):
    d = rpc("eth_call", [{"to": to, "data": data}, "latest"])
    return d.get("result") if "result" in d else None

def words(h):
    if not h or h == "0x": return []
    h = h[2:]
    return [int(h[i:i+64], 16) for i in range(0, len(h), 64)]

def addr(w): return "0x" + f"{w:040x}"[-40:]

POOLS = {
 "P1_E4":  "0x89963FCD25Cd3b369A2e0642521BCA7Cf0B9d547",
 "P2":     "0x2c1B1DE747043f7C7c8e0896EB33b09eD9ED55c5",
 "P3_E3":  "0xC264ED05ed2aF451732EF05C480d9e51b92a07aC",
 "P4_META": "0x8360D306Be83f9A992b1657Ad68fe08Ca6f2757A",
 "P5_B3":  "0x09A1B7d922BcfECa097b06498Bc992A83b0BCc42",
 "P6":     "0xe409587F043f74e47eFB0C10aAf40808D4e037cE",
 "P7_USDT": "0x074ec23e80bd1fd26b822305614fb10b97847a35",
 "P8_META": "0x833d89FA7dD693035678AB53Be792F6F4B352C01",
 "P9_M3":  "0xdab7B4D2CA330dde50ce611E2177271fD3Eb3F5F",
 "P10_META": "0x7B24cAA6a497bc79FDfBAeb8A71a38F15eB3d7F7",
 "P11":    "0x73541e9ffb9F4B8d13C2E5621b1Cede1981aD0d9",
}

SEL = {"swapStorage()": "0x5fd65f0f", "totalSupply()": "0x18160ddd", "paused()": "0x5c975abb",
       "getAdminBalance(uint256)": "0xa3d6b4b1", "name()": "0x06fdde03", "symbol()": "0x95d89b41"}

if __name__ == "__main__":
    out = {}
    for name, pool in POOLS.items():
        ss = words(call_ok(pool, SEL["swapStorage()"]))
        lp = addr(ss[6]) if len(ss) >= 7 else None
        ts = words(call_ok(lp, SEL["totalSupply()"])) if lp else []
        paused = words(call_ok(pool, SEL["paused()"]))
        admin = [words(call_ok(pool, SEL["getAdminBalance(uint256)"] + f"{i:064x}")) for i in range(4)]
        adm = [w[0] if w else None for w in admin]
        sym = None
        try:
            from iotex import dec as decstr
            sym = decstr(call_ok(lp, SEL["symbol()"]))
        except Exception:
            pass
        out[name] = {"pool": pool, "lp": lp, "lpTotalSupply": ts[0] if ts else None,
                     "paused": paused, "adminBalances": adm, "lpSymbol": sym}
        print(f"{name:9s} {pool} lp={lp} ts={ts[0] if ts else None} paused={paused} admin={adm} sym={sym}", flush=True)
    json.dump(out, open("pool_lp_data.json", "w"), indent=1)
    print("saved")
