#!/usr/bin/env python3
"""Follow the PandaSwap contract graph from factory feeTo -> maker/bar/token/farm."""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc_batch, block_number, as_addr, as_int, encode_addr

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "graph.json")

FACTORY = "0x9ad32bf5dafe152cbe027398219611db4e8753b3"
FEE_TO = "0xe1a2cd535c4e7d9c2c187e529f9f491ccea41e07"

SEL = {
    "factory": "0xc45a0155", "bar": "0xfebb0f7e", "bamboo": "0x4623eff0",
    "weth": "0x3fc8cef3", "owner": "0x8da5cb5b", "symbol": "0x95d89b41",
    "decimals": "0x313ce567", "name": "0x06fdde03", "totalSupply": "0x18160ddd",
    "bambooPerBlock": "0xce7410bd", "startBlock": "0x48cd4cb1", "bonusEndBlock": "0x1aed6553",
    "totalAllocPoint": "0x17caf6f1", "poolLength": "0x081e3eda", "devaddr1": "0x16c14382",
    "pendingBamboo": "0xde86b677", "lpToken": "0x5fcbd285",
}
# MasterChef poolInfo(uint256) selector
SEL_POOLINFO = "0x1526fe27"
# MasterChef userInfo(uint256,address)
SEL_USERINFO = "0x93f1a40b"


def dec(hexstr):
    if not hexstr or hexstr == "0x":
        return None
    raw = hexstr[2:]
    if len(raw) == 64:
        try:
            return bytes.fromhex(raw).rstrip(b"\x00").decode("utf-8", "replace") or None
        except Exception:
            return None
    try:
        off = int(raw[0:64], 16)
        if off == 32 and len(raw) >= 128:
            ln = int(raw[64:128], 16)
            if 0 < ln <= 200:
                return bytes.fromhex(raw[128:128 + ln * 2]).decode("utf-8", "replace")
    except Exception:
        pass
    return None


def main():
    bn = block_number()
    print("block", bn, flush=True)
    g = {"block": bn}

    # feeTo contract introspection: try maker getters + erc20 + owner
    o = rpc_batch([
        ("eth_getCode", [FEE_TO, hex(bn)]),
        ("eth_call", [{"to": FEE_TO, "data": SEL["factory"]}, hex(bn)]),
        ("eth_call", [{"to": FEE_TO, "data": SEL["bar"]}, hex(bn)]),
        ("eth_call", [{"to": FEE_TO, "data": SEL["bamboo"]}, hex(bn)]),
        ("eth_call", [{"to": FEE_TO, "data": SEL["weth"]}, hex(bn)]),
        ("eth_call", [{"to": FEE_TO, "data": SEL["owner"]}, hex(bn)]),
        ("eth_call", [{"to": FEE_TO, "data": SEL["symbol"]}, hex(bn)]),
        ("eth_call", [{"to": FEE_TO, "data": SEL["name"]}, hex(bn)]),
    ])
    g["feeTo"] = {
        "addr": FEE_TO,
        "code_size": (len(o[0]) - 2) // 2 if o[0] else 0,
        "factory": as_addr(o[1]), "bar": as_addr(o[2]), "bamboo": as_addr(o[3]),
        "weth": as_addr(o[4]), "owner": as_addr(o[5]),
        "symbol": dec(o[6]), "name": dec(o[7]),
    }
    print("feeTo:", json.dumps(g["feeTo"]), flush=True)

    # follow bar (BambooBar: bamboo getter) and bamboo token (owner)
    bar = g["feeTo"].get("bar"); bamboo = g["feeTo"].get("bamboo")
    for label, addr in [("bar", bar), ("bamboo", bamboo)]:
        if not addr:
            continue
        o = rpc_batch([
            ("eth_getCode", [addr, hex(bn)]),
            ("eth_call", [{"to": addr, "data": SEL["bamboo"]}, hex(bn)]),
            ("eth_call", [{"to": addr, "data": SEL["owner"]}, hex(bn)]),
            ("eth_call", [{"to": addr, "data": SEL["symbol"]}, hex(bn)]),
            ("eth_call", [{"to": addr, "data": SEL["name"]}, hex(bn)]),
            ("eth_call", [{"to": addr, "data": SEL["totalSupply"]}, hex(bn)]),
        ])
        g[label] = {"addr": addr, "code_size": (len(o[0]) - 2) // 2 if o[0] else 0,
                    "bamboo": as_addr(o[1]), "owner": as_addr(o[2]),
                    "symbol": dec(o[3]), "name": dec(o[4]), "totalSupply": as_int(o[5])}
        print(label + ":", json.dumps(g[label]), flush=True)

    # if bamboo token has owner -> likely MasterChefV2; introspect farm
    farm = None
    for cand in [g.get("bamboo", {}).get("owner"), g.get("bar", {}).get("owner")]:
        if cand and cand != "0x0000000000000000000000000000000000000000":
            farm = cand
            break
    if farm:
        o = rpc_batch([
            ("eth_getCode", [farm, hex(bn)]),
            ("eth_call", [{"to": farm, "data": SEL["owner"]}, hex(bn)]),
            ("eth_call", [{"to": farm, "data": SEL["bambooPerBlock"]}, hex(bn)]),
            ("eth_call", [{"to": farm, "data": SEL["startBlock"]}, hex(bn)]),
            ("eth_call", [{"to": farm, "data": SEL["bonusEndBlock"]}, hex(bn)]),
            ("eth_call", [{"to": farm, "data": SEL["totalAllocPoint"]}, hex(bn)]),
            ("eth_call", [{"to": farm, "data": SEL["poolLength"]}, hex(bn)]),
            ("eth_call", [{"to": farm, "data": SEL["devaddr1"]}, hex(bn)]),
        ])
        g["farm"] = {"addr": farm, "code_size": (len(o[0]) - 2) // 2 if o[0] else 0,
                     "owner": as_addr(o[1]), "bambooPerBlock": as_int(o[2]),
                     "startBlock": as_int(o[3]), "bonusEndBlock": as_int(o[4]),
                     "totalAllocPoint": as_int(o[5]), "poolLength": as_int(o[6]),
                     "devaddr1": as_addr(o[7])}
        print("farm:", json.dumps(g["farm"]), flush=True)

        # pool info
        n = g["farm"].get("poolLength") or 0
        pools = []
        for i in range(n):
            r = rpc_batch([("eth_call", [{"to": farm, "data": SEL_POOLINFO + hex(i)[2:].rjust(64, "0")}, hex(bn)])])
            h = r[0]
            if h and len(h) >= 2 + 64 * 4:
                lp = as_addr("0x" + h[2 + 24: 2 + 64])
                pools.append({"pid": i, "lpToken": lp,
                              "allocPoint": int(h[2 + 64: 2 + 128], 16),
                              "lastRewardBlock": int(h[2 + 128: 2 + 192], 16),
                              "accBambooPerShare": int(h[2 + 192: 2 + 256], 16)})
        g["farm"]["pools"] = pools
        print("pools:", json.dumps(pools), flush=True)

        # farm balances of bamboo + each lpToken
        bal_calls = [("eth_call", [{"to": g["bamboo"]["addr"], "data": "0x70a08231" + encode_addr(farm)}, hex(bn)])]
        for p in pools:
            bal_calls.append(("eth_call", [{"to": p["lpToken"], "data": "0x70a08231" + encode_addr(farm)}, hex(bn)]))
        bals = rpc_batch(bal_calls)
        g["farm"]["bambooBalance"] = as_int(bals[0])
        for j, p in enumerate(pools):
            p["stakedLp"] = as_int(bals[j + 1])
        print("farm bambooBalance:", g["farm"]["bambooBalance"], flush=True)

    json.dump(g, open(OUT, "w"), indent=1)
    print("wrote", OUT, flush=True)


if __name__ == "__main__":
    main()
