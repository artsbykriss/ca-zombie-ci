#!/usr/bin/env python3
"""Pala (Kaia) full live-state snapshot for CI. Read-only, keyless public RPCs.
Writes ci-out/state_probe.json. No secrets. All selectors hardcoded."""
import json, os, time, urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

RPCS = ["https://public-en.node.kaia.io", "https://rpc.ankr.com/kaia", "https://klaytn.drpc.org"]
FACTORY = "0xa25ba09d8837f6319cd65b2345c0bbea99c39cb1"
VIEWER = "0x2B16648ddD1559fc86e0c0617213Ab5dd2Ea01B9"
FARMS = ["0xcfc140e8e3b1b05f9acb4a42249b7abb8c27576c", "0x883726a307d420286086679f7851d8378bb16771"]
PALA = "0x7a1cdca99fe5995ab8e317ede8495c07cbf488ad"
ATTEN = "0x9160421ea3d1a24101d985b026a60cb0442322cc"
PKLAY = "0x1f2d6282d74ef26eb6c7e28b9e7048c1b42ebda5"
WKLAY = "0x2ff5f6de2287ca3075232127277e53519a77947c"
ATTACKER = "0x000000000000000000000000000000000000dEaD"
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ci-out")

SEL = {
    "token0": "0x0dfe1681", "token1": "0xd21220a7", "getReserves": "0x0902f1ac",
    "totalSupply": "0x18160ddd", "balanceOf": "0x70a08231", "factory": "0xc45a0155",
    "allPairs": "0x1e3dd18b", "allPairsLength": "0x574f2ba3",
    "owner": "0x8da5cb5b", "isMinter": "0xaa271e1a", "mint1": "0xa0712d68", "mint2": "0x40c10f19",
    "migrate": "0x454b0608", "dev": "0x8d88a90e", "setMigrator": "0x23cf3118",
    "migrator": "0x7cd07e47", "devaddr": "0xd49e77cd", "totalAllocPoint": "0x17caf6f1",
    "rewardPerBlock": "0x8ae39cac", "poolLength": "0x081e3eda", "poolInfo": "0x1526fe27",
    "feeTo": "0x017e7e58", "feeToSetter": "0x094b7415",
    "setFeeTo": "0xf46901ed", "setFeeToSetter": "0xa2e74af6",
    "tokenPrice": "0x84ba3f69", "kusdt": "0x7330c91c", "tokenList": "0x273cbaa0",
    "pendingReward2": "0x98969e82",
}

def rpc(method, params, tries=8):
    body = json.dumps({"jsonrpc": "2.0", "method": method, "params": params, "id": 1}).encode()
    last = None
    for i in range(tries):
        url = RPCS[i % len(RPCS)]
        try:
            req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=20) as r:
                d = json.loads(r.read().decode())
            if "result" in d and d["result"] not in (None, "0x"):
                return d["result"]
            last = d
        except Exception as e:
            last = e
        time.sleep(0.25 * (i + 1))
    raise RuntimeError(f"rpc fail {method} {str(params)[:70]}: {str(last)[:80]}")

def call(to, data, frm=None):
    p = {"to": to, "data": data}
    if frm:
        p["from"] = frm
    return rpc("eth_call", [p, "latest"])

def word(x):
    return hex(x)[2:].rjust(64, "0")

def addr_from(h):
    return "0x" + h[-40:]

def uint(h):
    return int(h, 16)

# DefiLlama prices captured 2026-10-14 (USD); WKLAY/pKLAY = KLAY market ~0.0452 (1:1 wrappers verified)
PRICES = {
    "0xcee8faf64bb97a73bb51e115aa89c17ffa8dd167": ("oUSDT", 6, 0.10387),
    "0x754288077d0ff82af7a5317c7cb8c444d421d103": ("oUSDC", 6, 0.29208),
    "0x2ff5f6de2287ca3075232127277e53519a77947c": ("WKLAY", 18, 0.0452),
    "0x34d21b1e550d73cee41151c77f3c73359527a396": ("oETH", 18, 168.29),
    "0x16d0e1fbd024c600ca0380a4c5d57ee7a2ecbf9c": ("oWBTC", 8, 19047.97),
    "0x9eaefb09fe4aabfbe6b1ca316a3c36afc83a393f": ("oXRP", 6, 1.3336),
    "0x5c74070fdea071359b86082bd9f9b3deaafbe32b": ("KDAI", 18, 0.09315),
    "0x7a1cdca99fe5995ab8e317ede8495c07cbf488ad": ("PALA", 18, 0.000756),
    "0x9160421ea3d1a24101d985b026a60cb0442322cc": ("ATTEN", 18, 0.0),
    "0x1f2d6282d74ef26eb6c7e28b9e7048c1b42ebda5": ("pKLAY", 18, 0.0452),
}

def usd(token, amount):
    t = token.lower()
    if t in PRICES:
        _, dec, price = PRICES[t]
        return amount / (10 ** dec) * price
    return None

def probe_pool(p):
    t0 = addr_from(call(p, SEL["token0"])).lower()
    t1 = addr_from(call(p, SEL["token1"])).lower()
    res = call(p, SEL["getReserves"])[2:]
    r0, r1 = int(res[0:64], 16), int(res[64:128], 16)
    ts = uint(call(p, SEL["totalSupply"]))
    b0 = uint(call(t0, SEL["balanceOf"] + word(int(p, 16))))
    b1 = uint(call(t1, SEL["balanceOf"] + word(int(p, 16))))
    res2 = call(p, SEL["getReserves"])[2:]
    r0b, r1b = int(res2[0:64], 16), int(res2[64:128], 16)
    ex0, ex1 = b0 - r0b, b1 - r1b
    row = {"pair": p, "token0": t0, "token1": t1, "reserve0": r0b, "reserve1": r1b,
           "tsLast": int(res[128:192], 16), "totalSupply": ts, "bal0": b0, "bal1": b1,
           "excess0": ex0, "excess1": ex1}
    u0, u1 = usd(t0, ex0 if ex0 > 0 else 0), usd(t1, ex1 if ex1 > 0 else 0)
    row["excess_usd"] = round((u0 or 0) + (u1 or 0), 2)
    return row

def main():
    os.makedirs(OUT, exist_ok=True)
    blk = uint(rpc("eth_blockNumber", []))
    n = uint(call(FACTORY, SEL["allPairsLength"]))
    pairs = [addr_from(call(FACTORY, SEL["allPairs"] + word(i))).lower() for i in range(n)]
    res = {"block": blk, "factory": FACTORY, "viewer": VIEWER, "attacker": ATTACKER,
           "pairs_count": len(pairs), "pairs": [], "farms": [], "roles": {}, "viewer_state": {}, "wrappers": {}}
    print(f"block={blk} pairs={len(pairs)}", flush=True)

    with ThreadPoolExecutor(max_workers=4) as ex:
        futs = {ex.submit(probe_pool, p): p for p in pairs}
        for f in as_completed(futs):
            try:
                res["pairs"].append(f.result())
            except Exception as e:
                res["pairs"].append({"pair": futs[f], "error": str(e)})
    res["pairs"].sort(key=lambda x: x.get("pair", ""))
    ok = [r for r in res["pairs"] if "error" not in r]
    pos = [r for r in ok if r["excess0"] > 0 or r["excess1"] > 0]
    neg = [r for r in ok if r["excess0"] < 0 or r["excess1"] < 0]
    res["summary"] = {
        "pools_ok": len(ok), "pools_total": len(res["pairs"]),
        "pools_with_positive_excess": len(pos),
        "pools_with_negative_excess": len(neg),
        "total_excess_usd": round(sum(r.get("excess_usd", 0) for r in pos), 2),
        "reserves_usd_total": round(sum(
            (usd(r["token0"], r["reserve0"]) or 0) + (usd(r["token1"], r["reserve1"]) or 0) for r in ok), 2),
        "balances_usd_total": round(sum(
            (usd(r["token0"], r["bal0"]) or 0) + (usd(r["token1"], r["bal1"]) or 0) for r in ok), 2),
    }
    print("summary:", json.dumps(res["summary"]), flush=True)

    # farms
    for f in FARMS:
        fd = {"farm": f, "owner": call(f, SEL["owner"]),
              "pala_balance": uint(call(PALA, SEL["balanceOf"] + word(int(f, 16)))),
              "poolLength": uint(call(f, SEL["poolLength"]))}
        for key, sel in [("migrator", SEL["migrator"]), ("devaddr", SEL["devaddr"]),
                         ("totalAllocPoint", SEL["totalAllocPoint"]), ("rewardPerBlock", SEL["rewardPerBlock"])]:
            try:
                fd[key] = call(f, sel)
            except Exception as e:
                fd[key] = f"ERR {str(e)[:80]}"
        sims = {}
        for name, data in [("migrate(0)", SEL["migrate"] + word(0)),
                           ("dev(attacker)", SEL["dev"] + word(int(ATTACKER, 16))),
                           ("setMigrator(attacker)", SEL["setMigrator"] + word(int(ATTACKER, 16))),
                           ("pendingReward(0,attacker)", SEL["pendingReward2"] + word(0) + word(int(ATTACKER, 16)))]:
            try:
                sims[name] = {"result": call(f, data, frm=ATTACKER)}
            except Exception as e:
                sims[name] = {"revert": str(e)[:140]}
        fd["attacker_simulations"] = sims
        res["farms"].append(fd)

    # token roles
    roles = {}
    for nm, tok in [("PALA", PALA), ("ATTEN", ATTEN)]:
        roles[nm] = {"owner": call(tok, SEL["owner"]),
                     "isMinter_attacker": call(tok, SEL["isMinter"] + word(int(ATTACKER, 16))),
                     "isMinter_palaFarm": call(tok, SEL["isMinter"] + word(int(FARMS[0], 16))),
                     "isMinter_attenFarm": call(tok, SEL["isMinter"] + word(int(FARMS[1], 16))),
                     "totalSupply": uint(call(tok, SEL["totalSupply"]))}
        sims = {}
        for s, data in [("mint(uint256)", SEL["mint1"] + word(10**18)),
                        ("mint(attacker,uint256)", SEL["mint2"] + word(int(ATTACKER, 16)) + word(10**18))]:
            try:
                sims[s] = {"result": call(tok, data, frm=ATTACKER)}
            except Exception as e:
                sims[s] = {"revert": str(e)[:140]}
        roles[nm]["attacker_mint_sim"] = sims
    roles["factory"] = {"feeTo": call(FACTORY, SEL["feeTo"]), "feeToSetter": call(FACTORY, SEL["feeToSetter"])}
    sims = {}
    for s, data in [("setFeeTo(attacker)", SEL["setFeeTo"] + word(int(ATTACKER, 16))),
                    ("setFeeToSetter(attacker)", SEL["setFeeToSetter"] + word(int(ATTACKER, 16)))]:
        try:
            sims[s] = {"result": call(FACTORY, data, frm=ATTACKER)}
        except Exception as e:
            sims[s] = {"revert": str(e)[:140]}
    roles["factory"]["attacker_setter_sim"] = sims
    roles["pKLAY"] = {"native_balance": uint(rpc("eth_getBalance", [PKLAY, "latest"])),
                      "totalSupply": uint(call(PKLAY, SEL["totalSupply"]))}
    roles["pKLAY"]["delta"] = roles["pKLAY"]["native_balance"] - roles["pKLAY"]["totalSupply"]
    roles["WKLAY"] = {"native_balance": uint(rpc("eth_getBalance", [WKLAY, "latest"])),
                      "totalSupply": uint(call(WKLAY, SEL["totalSupply"]))}
    roles["WKLAY"]["delta"] = roles["WKLAY"]["native_balance"] - roles["WKLAY"]["totalSupply"]
    res["roles"] = roles

    # viewer lens
    vs = {}
    try:
        vs["kusdt"] = call(VIEWER, SEL["kusdt"])
        h = call(VIEWER, SEL["tokenList"])[2:]
        off = int(h[0:64], 16) * 2
        cnt = int(h[off:off+64], 16)
        toks = ["0x" + h[off+64+i*64+24: off+64+i*64+64] for i in range(cnt)]
        vs["token_count"] = cnt
        prices = {}
        for t in toks:
            try:
                prices[t] = uint(call(VIEWER, SEL["tokenPrice"] + word(int(t, 16))))
            except Exception:
                prices[t] = None
        vs["tokenPrice_1e18"] = prices
    except Exception as e:
        vs["error"] = str(e)[:200]
    res["viewer_state"] = vs

    with open(os.path.join(OUT, "state_probe.json"), "w") as fh:
        json.dump(res, fh, indent=1)
    print("wrote ci-out/state_probe.json", flush=True)

if __name__ == "__main__":
    main()
