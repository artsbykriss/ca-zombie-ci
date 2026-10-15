#!/usr/bin/env python3
"""
EtherVista extra live-state checks — Z3-C5 deep-dive (read-only).
Records every role/binding/balance that the report cites, at one pinned block.
Output: ci-out/extra_checks.json (+ analysis/extra_checks.json copy)
No secrets; public RPCs only.
"""
import json
import os
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
OUTDIR = os.path.abspath(os.environ.get("OUTDIR", os.path.join(HERE, "..", "ci-out")))

FACTORY = "0x9a27cb5ae0B2cEe0bb71f9A85C0D60f3920757B4"
PAIR = "0xfdd05552F1377aA488AFed744c8024358AF02041"
ROUTER = "0x9bD63C5D44fF28390df1EaaFD4eB4BD73E94A72a"
SETTER = "0xCA90D843288E35beeADfCe14E5F906e3F1AFc7cB"
WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
VISTA = "0xC9bCa88B04581699fAb5aa276CCafF7Df957cbbf"
ATTACKER_CONTRACT = "0x469424b628a9d2036e41496e814db500d683b120"
DEAD = "0x000000000000000000000000000000000000dEaD"
ZERO = "0x0000000000000000000000000000000000000000"

HISTORICAL_ROUTERS = [
    "0xeaaa41cb2a64b11fe761d41e747c032cdd60cace",
    "0xead811d798020c635cf8dd4ddf31bdc5595b09f3",
    "0xcedd366065a146a039b92db35756ecd7688fcc77",
    "0x25b929e4dc4248858f4a874d076961070d88de04",
    "0x13f2632393ad736c8aab9eeccbbd8bcfe5bb5371",
    "0xa03626f924f550f615ebbbb6f024c250f9f0f3d4",
    "0x2a27e4e1d2b97c5b8a2460df5342e0e9293d4fdf",
    "0xb7c6c50d6dfc478e7b40906f582e14575e7d895a",
    "0xdbf723f9ee663fb643fb08f86829727f8140b2d6",
    "0x9bd63c5d44ff28390df1eaafd4eb4bd73e94a72a",
    "0xbc3902178a02939ba53a18c8dd374a3fc17f9c5c",
    "0x469424b628a9d2036e41496e814db500d683b120",
]

RPC_CANDIDATES = [os.environ.get("FORK_RPC_URL", ""), os.environ.get("RPC_URL", ""),
                  "https://ethereum-rpc.publicnode.com", "https://eth.drpc.org"]
RPC_CANDIDATES = [u for u in RPC_CANDIDATES if u]
UA = {"User-Agent": "zombie-research/1.0"}

SEL = {
    "router": "0xf887ea40", "routerSetter": "0x461142c3", "feeTo": "0x017e7e58",
    "feeToSetter": "0x094b7415", "initCodeHash": "0x257671f5",
    "totalSupply": "0x18160ddd", "balanceOf": "0x70a08231", "poolBalance": "0x96365d44",
    "totalCollected": "0xe29eb836", "euler": "0x5cb1ccec", "kLast": "0x7464fc3d",
    "getReserves": "0x0902f1ac", "creator": "0x02d05d3f", "creation_time": "0x65008cd6",
    "treasury": "0x61d027b3", "treasurySetter": "0x3792fdb0", "treasuryFeeUsd": "0x0b4ec5ff",
    "Providers": "0x018d0f8d", "decimals": "0x313ce567", "symbol": "0x95d89b41",
    "name": "0x06fdde03", "owner": "0x8da5cb5b",
}


def http_json(url, payload, timeout=60):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={**UA, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())


def pick():
    for u in RPC_CANDIDATES:
        try:
            j = http_json(u, {"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []})
            if "result" in j:
                return u, int(j["result"], 16)
        except Exception:
            pass
    raise RuntimeError("no rpc")


def main():
    os.makedirs(OUTDIR, exist_ok=True)
    url, block = pick()
    print(f"[extra] block={block}", flush=True)

    def call(to, data):
        j = http_json(url, {"jsonrpc": "2.0", "id": 1, "method": "eth_call", "params": [{"to": to, "data": data}, "latest"]})
        return j.get("result")

    def code(a):
        j = http_json(url, {"jsonrpc": "2.0", "id": 1, "method": "eth_getCode", "params": [a, "latest"]})
        return j.get("result") or "0x"

    def num(h):
        return int(h, 16) if h and h != "0x" else 0

    def address(h):
        return "0x" + h[-40:].lower() if h and h != "0x" else None

    def bal(a):
        j = http_json(url, {"jsonrpc": "2.0", "id": 1, "method": "eth_getBalance", "params": [a, "latest"]})
        return int(j["result"], 16)

    def nonce(a):
        j = http_json(url, {"jsonrpc": "2.0", "id": 1, "method": "eth_getTransactionCount", "params": [a, "latest"]})
        return int(j["result"], 16)

    pad = lambda a: a.lower().replace("0x", "").rjust(64, "0")

    out = {"block": block, "factory": FACTORY, "pair": PAIR, "router": ROUTER, "routerSetter": SETTER}

    out["factory_state"] = {
        "router": address(call(FACTORY, SEL["router"])),
        "routerSetter": address(call(FACTORY, SEL["routerSetter"])),
        "feeTo": address(call(FACTORY, SEL["feeTo"])),
        "feeToSetter": address(call(FACTORY, SEL["feeToSetter"])),
        "INIT_CODE_HASH": call(FACTORY, SEL["initCodeHash"]),
        "code_len": (len(code(FACTORY)) - 2) // 2,
    }

    out["routerSetter_eoa"] = {
        "code_len": (len(code(SETTER)) - 2) // 2,   # 0 => no EIP-7702 delegation
        "nonce": nonce(SETTER),
        "eth_balance_wei": bal(SETTER),
    }

    r = call(PAIR, SEL["getReserves"]) or "0x" + "0" * 192
    out["pair_state"] = {
        "reserve0_wei": num(r[2:66]), "reserve1_wei": num(r[66:130]),
        "totalSupply_lp": num(call(PAIR, SEL["totalSupply"])),
        "lp_balance_zero": num(call(PAIR, SEL["balanceOf"] + pad(ZERO))),
        "lp_balance_dead": num(call(PAIR, SEL["balanceOf"] + pad(DEAD))),
        "lp_balance_setter": num(call(PAIR, SEL["balanceOf"] + pad(SETTER))),
        "lp_balance_router": num(call(PAIR, SEL["balanceOf"] + pad(ROUTER))),
        "lp_balance_pair_self": num(call(PAIR, SEL["balanceOf"] + pad(PAIR))),
        "poolBalance_wei": num(call(PAIR, SEL["poolBalance"])),
        "totalCollected_wei": num(call(PAIR, SEL["totalCollected"])),
        "euler0": num(call(PAIR, SEL["euler"] + pad(hex(0)[2:]))),
        "creator": address(call(PAIR, SEL["creator"])),
        "creation_time": num(call(PAIR, SEL["creation_time"])),
        "weth_balance": num(call(WETH, SEL["balanceOf"] + pad(PAIR))),
        "vista_balance": num(call(VISTA, SEL["balanceOf"] + pad(PAIR))),
        "eth_balance_wei": bal(PAIR),
        "providers_setter": [num(call(PAIR, SEL["Providers"] + pad(SETTER))[2:66]) if call(PAIR, SEL["Providers"] + pad(SETTER)) else None],
    }

    out["router_state"] = {
        "code_len": (len(code(ROUTER)) - 2) // 2,
        "treasury": address(call(ROUTER, SEL["treasury"])),
        "treasurySetter": address(call(ROUTER, SEL["treasurySetter"])),
        "treasuryFeeUsd": num(call(ROUTER, SEL["treasuryFeeUsd"])),
        "weth_balance": num(call(WETH, SEL["balanceOf"] + pad(ROUTER))),
        "vista_balance": num(call(VISTA, SEL["balanceOf"] + pad(ROUTER))),
        "eth_balance_wei": bal(ROUTER),
    }

    out["attacker_contract_oct9"] = {
        "code_len": (len(code(ATTACKER_CONTRACT)) - 2) // 2,
        "eth_balance_wei": bal(ATTACKER_CONTRACT),
        "weth_balance": num(call(WETH, SEL["balanceOf"] + pad(ATTACKER_CONTRACT))),
        "vista_balance": num(call(VISTA, SEL["balanceOf"] + pad(ATTACKER_CONTRACT))),
    }

    out["historical_routers_code_len"] = {a: (len(code(a)) - 2) // 2 for a in HISTORICAL_ROUTERS}

    out["vista_token"] = {
        "totalSupply": num(call(VISTA, SEL["totalSupply"])),
        "owner_best_effort": address(call(VISTA, SEL["owner"])) if call(VISTA, SEL["owner"]) else None,
        "code_len": (len(code(VISTA)) - 2) // 2,
    }

    # H-O / dead-LP arithmetic
    ps = out["pair_state"]
    ts = ps["totalSupply_lp"]
    live_lp = ts - ps["lp_balance_dead"] - ps["lp_balance_zero"]
    out["lp_split"] = {
        "total_lp": ts,
        "dead_lp": ps["lp_balance_dead"],
        "zero_lp": ps["lp_balance_zero"],
        "live_lp": live_lp,
        "dead_share_pct": round(100 * ps["lp_balance_dead"] / ts, 4) if ts else None,
        "live_share_pct": round(100 * live_lp / ts, 4) if ts else None,
    }

    with open(os.path.join(OUTDIR, "extra_checks.json"), "w") as f:
        json.dump(out, f, indent=2)
    with open(os.path.join(HERE, "extra_checks.json"), "w") as f:
        json.dump(out, f, indent=2)
    print(json.dumps(out["lp_split"], indent=2), flush=True)
    print("[extra] wrote extra_checks.json", flush=True)


if __name__ == "__main__":
    main()
