#!/usr/bin/env python3
"""Role matrix probe: which caller passes each factory guard (read-only eth_call)."""
import json, urllib.request

RPC = "https://rpc.scroll.io"
FACTORY = "0xAAA16c016BF556fcD620328f0759252E29b1AB57"

CALLERS = {
    "owner_Safe": "0xC9d28676b7d470210a3C490B60729660eE5a7257",
    "proxyAdmin": "0x8e01fc0d89b93a6447d6c6eca6fbd30e6e4a1ce3",
    "feeManager": "0xAAA11500dddb2b67a90d1a154dfb7eabb518eae6",
    "voter": "0xAAAf3D9CDD3602d117c67D80eEC37a160C8d9869",
    "dead": "0x000000000000000000000000000000000000dEaD",
    "zero": "0x0000000000000000000000000000000000000000",
    "pair0": "0x1e7f72a9c63de22a88896e34d93645f5fc689b2c",
}

def enc_addr(a):
    return a.lower().replace("0x", "").rjust(64, "0")

def enc_uint(v):
    return hex(v)[2:].rjust(64, "0")

CALLS = {
    "setOwner(address)": "0x13af4035" + enc_addr("0x000000000000000000000000000000000000dEaD"),
    "setPauser(address)": "0x2d88af4a" + enc_addr("0x000000000000000000000000000000000000dEaD"),
    "acceptPauser()": "0x167a6f90",
    "setPause(bool)": "0xbedb86fb" + enc_uint(1),
    "setFeeManager(address)": "0x472d35b9" + enc_addr("0x000000000000000000000000000000000000dEaD"),
    "acceptFeeManager()": "0xf94c53c7",
    "setFee(bool,uint256)": "0xe1f76b44" + enc_uint(1) + enc_uint(5),
    "setTreasury(address)": "0xf0f44260" + enc_addr("0x000000000000000000000000000000000000dEaD"),
    "setImplementation(address)": "0xd784d426" + enc_addr("0xf5d139c3f51967505c532c42898ba47b15da4b9f"),
    "setFeeSplit(uint8,uint8)": "0x1cb8e3a7" + enc_uint(5) + enc_uint(5),
    "setPoolFeeSplit(address,uint8,uint8)": "0xd68f9af2" + enc_addr("0x1e7f72a9c63de22a88896e34d93645f5fc689b2c") + enc_uint(5) + enc_uint(5),
}

def call(data, frm):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                       "params": [{"to": FACTORY, "data": data, "from": frm}, "latest"]}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    r = json.load(urllib.request.urlopen(req, timeout=60))
    if "error" in r:
        msg = r["error"].get("message", "")
        return ("REVERT", msg[:80])
    return ("OK", r.get("result", "")[:20])

out = {}
for cname, data in CALLS.items():
    row = {}
    for rname, r in CALLERS.items():
        try:
            row[rname] = call(data, r)
        except Exception as e:
            row[rname] = ("ERR", str(e)[:60])
    out[cname] = row
    print(cname)
    for rn, v in row.items():
        print("   ", rn, "->", v)

json.dump(out, open("/home/heisenberg/CA/nuri-cl/analysis/childC-v2-role-matrix.json", "w"), indent=1)
