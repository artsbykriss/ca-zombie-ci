#!/usr/bin/env python3
"""Probe PandaSwap farm (owner of PNDA), PNDA token params, BambooBar state."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc_batch, block_number, as_addr, as_int, encode_addr

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "farm.json")

PNDA = "0x47dcc83a14ad53ed1f13d3cae8aa4115f07557c0"
BAR = "0xef88e0d265ddc8f5e725a4fda1871f9fe21b11e2"
FARM = "0x9942cb4c6180820e6211183ab29831641f58577a"
FEE_TO = "0xe1a2cd535c4e7d9c2c187e529f9f491ccea41e07"
DEVS = {
    "dev1": "0x3bc3c8af8cfe3dfc9ba1a57c7c3b653e3f6d6951",
}
SEL = {
    "owner": "0x8da5cb5b", "totalSupply": "0x18160ddd", "cap": "0x355274ea",
    "manualMintLimit": None, "manualMinted": None, "circulatingSupply": None,
    "lockedSupply": None, "lockFromBlock": None, "lockToBlock": None,
    "authorized": "0xb9181611",
    "bambooPerBlock": "0xce7410bd", "startBlock": "0x48cd4cb1", "bonusEndBlock": "0x1aed6553",
    "totalAllocPoint": "0x17caf6f1", "poolLength": "0x081e3eda",
    "poolInfo": "0x1526fe27", "userInfo": "0x93f1a40b", "pendingBamboo": "0xde86b677",
    "devaddr1": "0x16c14382", "devaddr2": None, "devaddr3": None, "devaddr4": None,
    "devaddr5": None, "devaddr6": None,
    "balanceOf": "0x70a08231",
}
import subprocess
def sig(s):
    return subprocess.run(["cast", "sig", s], capture_output=True, text=True).stdout.strip()
for k, v in list(SEL.items()):
    if v is None:
        try:
            SEL[k] = sig(k + "()")
        except Exception:
            pass
print("selectors:", json.dumps(SEL), flush=True)


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

    # farm code + params
    o = rpc_batch([
        ("eth_getCode", [FARM, hex(bn)]),
        ("eth_call", [{"to": FARM, "data": SEL["owner"]}, hex(bn)]),
        ("eth_call", [{"to": FARM, "data": SEL["bambooPerBlock"]}, hex(bn)]),
        ("eth_call", [{"to": FARM, "data": SEL["startBlock"]}, hex(bn)]),
        ("eth_call", [{"to": FARM, "data": SEL["bonusEndBlock"]}, hex(bn)]),
        ("eth_call", [{"to": FARM, "data": SEL["totalAllocPoint"]}, hex(bn)]),
        ("eth_call", [{"to": FARM, "data": SEL["poolLength"]}, hex(bn)]),
        ("eth_call", [{"to": FARM, "data": SEL["devaddr1"]}, hex(bn)]),
    ])
    g["farm"] = {
        "addr": FARM, "code_size": (len(o[0]) - 2) // 2 if o[0] else 0,
        "owner": as_addr(o[1]), "bambooPerBlock": as_int(o[2]),
        "startBlock": as_int(o[3]), "bonusEndBlock": as_int(o[4]),
        "totalAllocPoint": as_int(o[5]), "poolLength": as_int(o[6]),
        "devaddr1": as_addr(o[7]),
    }
    print("farm:", json.dumps(g["farm"]), flush=True)

    # devs 2..6
    devs = {}
    for i in range(2, 7):
        r = rpc_batch([("eth_call", [{"to": FARM, "data": sig(f"devaddr{i}()")}, hex(bn)])])
        devs[f"devaddr{i}"] = as_addr(r[0])
    g["farm"]["devs"] = devs
    print("devs:", devs, flush=True)

    # pools
    n = g["farm"]["poolLength"] or 0
    pools = []
    for i in range(n):
        r = rpc_batch([("eth_call", [{"to": FARM, "data": SEL["poolInfo"] + hex(i)[2:].rjust(64, "0")}, hex(bn)])])
        h = r[0]
        if h and len(h) >= 2 + 64 * 4:
            lp = as_addr("0x" + h[2 + 24: 2 + 64])
            pools.append({"pid": i, "lpToken": lp,
                          "allocPoint": int(h[2 + 64: 2 + 128], 16),
                          "lastRewardBlock": int(h[2 + 128: 2 + 192], 16),
                          "accBambooPerShare": int(h[2 + 192: 2 + 256], 16)})
        else:
            pools.append({"pid": i, "lpToken": None})
    g["farm"]["pools"] = pools
    print("pools:", json.dumps(pools), flush=True)

    # farm balances: PNDA + each lp token
    calls = [("eth_call", [{"to": PNDA, "data": SEL["balanceOf"] + encode_addr(FARM)}, hex(bn)])]
    for p in pools:
        if p.get("lpToken"):
            calls.append(("eth_call", [{"to": p["lpToken"], "data": SEL["balanceOf"] + encode_addr(FARM)}, hex(bn)]))
    bals = rpc_batch(calls)
    g["farm"]["pndaBalance"] = as_int(bals[0])
    for j, p in enumerate(pools):
        if p.get("lpToken"):
            p["stakedLp"] = as_int(bals[j + 1])
    print("farm pndaBalance:", g["farm"]["pndaBalance"], flush=True)

    # PNDA token params
    o = rpc_batch([
        ("eth_call", [{"to": PNDA, "data": SEL["owner"]}, hex(bn)]),
        ("eth_call", [{"to": PNDA, "data": SEL["cap"]}, hex(bn)]),
        ("eth_call", [{"to": PNDA, "data": SEL["totalSupply"]}, hex(bn)]),
        ("eth_call", [{"to": PNDA, "data": SEL["manualMintLimit"]}, hex(bn)]),
        ("eth_call", [{"to": PNDA, "data": SEL["manualMinted"]}, hex(bn)]),
        ("eth_call", [{"to": PNDA, "data": SEL["circulatingSupply"]}, hex(bn)]),
        ("eth_call", [{"to": PNDA, "data": SEL["lockedSupply"]}, hex(bn)]),
        ("eth_call", [{"to": PNDA, "data": SEL["lockFromBlock"]}, hex(bn)]),
        ("eth_call", [{"to": PNDA, "data": SEL["lockToBlock"]}, hex(bn)]),
        ("eth_call", [{"to": PNDA, "data": SEL["balanceOf"] + encode_addr(BAR)}, hex(bn)]),
    ])
    g["pnda"] = {
        "addr": PNDA, "owner": as_addr(o[0]), "cap": as_int(o[1]), "totalSupply": as_int(o[2]),
        "manualMintLimit": as_int(o[3]), "manualMinted": as_int(o[4]),
        "circulatingSupply": as_int(o[5]), "lockedSupply": as_int(o[6]),
        "lockFromBlock": as_int(o[7]), "lockToBlock": as_int(o[8]),
        "barBalance": as_int(o[9]),
    }
    print("pnda:", json.dumps(g["pnda"]), flush=True)

    # authorized checks
    auth = {}
    for label, addr in [("farm", FARM), ("bar", BAR), ("feeToMaker", FEE_TO),
                        ("feeToSetter", "0x3bc3c8af8cfe3dfc9ba1a57c7c3b653e3f6d6951")]:
        r = rpc_batch([("eth_call", [{"to": PNDA, "data": SEL["authorized"] + encode_addr(addr)}, hex(bn)])])
        auth[label] = as_int(r[0])
    g["pnda"]["authorized"] = auth
    print("authorized:", auth, flush=True)

    # bar state
    o = rpc_batch([
        ("eth_call", [{"to": BAR, "data": SEL["totalSupply"]}, hex(bn)]),
        ("eth_call", [{"to": BAR, "data": SEL["owner"]}, hex(bn)]),
    ])
    g["bar"] = {"addr": BAR, "totalSupply": as_int(o[0]), "owner": as_addr(o[1])}
    print("bar:", json.dumps(g["bar"]), flush=True)

    json.dump(g, open(OUT, "w"), indent=1)
    print("wrote", OUT, flush=True)


if __name__ == "__main__":
    main()
