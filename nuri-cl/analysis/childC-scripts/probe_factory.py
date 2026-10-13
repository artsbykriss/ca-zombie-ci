#!/usr/bin/env python3
"""Probe live admin state + guards of the Nuri V2 factory (read-only eth_call)."""
import json, subprocess, urllib.request

RPC = "https://rpc.scroll.io"
FACTORY = "0xAAA16c016BF556fcD620328f0759252E29b1AB57"
UNPRIV = "0x000000000000000000000000000000000000dEaD"

SIGS = {
    "owner()": "0x8da5cb5b", "pauser()": "0x9fd0506d", "pendingPauser()": "0x9a7165e4",
    "feeManager()": "0xd0fb0203", "pendingFeeManager()": "0x8a4fa0d2",
    "treasury()": "0x61d027b3", "stableFee()": "0x40bbd775", "volatileFee()": "0x5084ed03",
    "MAX_FEE()": "0xbc063e1a", "isPaused()": "0xb187bd26", "implementation()": "0x5c60da1b",
    "voter()": "0x46c96aac", "feeSplit()": "0x6373ea69", "allPairsLength()": "0x574f2ba3",
    "getFee(true)": "0x512b45ea" + "1".rjust(64, "0"),
    "getFee(false)": "0x512b45ea" + "0".rjust(64, "0"),
}

def call(to, data, frm=None, block="latest"):
    p = [{"to": to, "data": data}, block]
    if frm:
        p[0]["from"] = frm
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_call", "params": p}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    try:
        r = json.load(urllib.request.urlopen(req, timeout=60))
        return r.get("result", {"error": r.get("error")})
    except Exception as e:
        return {"http_error": str(e)}

def dec_addr(h):
    if isinstance(h, str) and len(h) >= 42:
        return "0x" + h[-40:]
    return h

def dec_uint(h):
    try:
        return int(h, 16)
    except Exception:
        return h

def main():
    out = {"factory": FACTORY, "block": None, "views": {}, "guards": {}, "raw": {}}
    # block
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    out["block"] = int(json.load(urllib.request.urlopen(req, timeout=60))["result"], 16)
    for name, sel in SIGS.items():
        r = call(FACTORY, sel)
        out["raw"][name] = r
        if name.endswith("(bool)") or name in ("MAX_FEE()",):
            out["views"][name] = dec_uint(r)
        elif name in ("allPairsLength()", "stableFee()", "volatileFee()", "feeSplit()", "isPaused()"):
            out["views"][name] = dec_uint(r)
        else:
            out["views"][name] = dec_addr(r)
    # guard probe: call each state-changing fn from unprivileged address
    zero32 = "00" * 32
    dead = UNPRIV.lower().replace("0x", "")
    guards = {
        "setOwner(address)": "0x13af4035" + dead.rjust(64, "0"),
        "setPauser(address)": "0x2d88af4a" + dead.rjust(64, "0"),
        "acceptPauser()": "0x167a6f90",
        "setPause(bool)": "0xbedb86fb" + "1".rjust(64, "0"),
        "setFeeManager(address)": "0x472d35b9" + dead.rjust(64, "0"),
        "acceptFeeManager()": "0xf94c53c7",
        "setFee(bool,uint256)": "0xe1f76b44" + "1".rjust(64, "0") + "a".rjust(64, "0"),
        "setPairFee(address,uint256)": "0xa93a897d" + dead.rjust(64, "0") + "a".rjust(64, "0"),
        "setTreasury(address)": "0xf0f44260" + dead.rjust(64, "0"),
        "setImplementation(address)": "0xd784d426" + dead.rjust(64, "0"),
        "setFeeSplit(uint8,uint8)": "0x1cb8e3a7" + "5".rjust(64, "0") + "5".rjust(64, "0"),
        "setPoolFeeSplit(address,uint8,uint8)": "0xd68f9af2" + dead.rjust(64, "0") + "5".rjust(64, "0") + "5".rjust(64, "0"),
        "createPair(address,address,bool)": "0x82dfdce4" + dead.rjust(64, "0") + dead.rjust(64, "0") + "0".rjust(64, "0"),
        "initialize(...)": "0x1459457a" + dead.rjust(64, "0") * 5,
    }
    for name, data in guards.items():
        r = call(FACTORY, data, frm=UNPRIV)
        out["guards"][name] = r
    with open("/home/heisenberg/CA/nuri-cl/analysis/childC-v2-factory-probe.json", "w") as f:
        json.dump(out, f, indent=1)
    print(json.dumps({"block": out["block"], "views": out["views"]}, indent=1))
    print("--- guards (from unprivileged) ---")
    for k, v in out["guards"].items():
        if isinstance(v, dict) and v.get("error"):
            print(k, "REVERT:", str(v["error"])[:100])
        else:
            print(k, "SUCCESS (!!):", str(v)[:80])

if __name__ == "__main__":
    main()
