#!/usr/bin/env python3
"""Probe pToken maxDeposit/maxMint/maxRedeem vs allowlist; dump factory TokenInfo struct fields."""
import json, urllib.request
from eth_utils import keccak

RPC = "https://rpc.mainnet.chain.robinhood.com"
def rpc(m, p):
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),
        headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0 arcus/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r: d = json.load(r)
    if "error" in d: raise RuntimeError(d["error"])
    return d["result"]

def call(to, data, sender=None):
    tx = {"to": to, "data": data}
    if sender: tx["from"] = sender
    try:
        return rpc("eth_call", [tx, "latest"])
    except Exception as e:
        return f"REVERT:{str(e)[:140]}"

def pad_addr(a): return "0"*24 + a.lower().replace("0x","")
def pad_u(x): return f"{x:064x}"

F = "0x9c3663FA9ab976E67B42939486EC4966Cb41a0BB"
inv = json.load(open('/home/heisenberg/CA/arcus/analysis/child-ptoken-inventory.json'))

ACCOUNTS = {
 "deployer": "0x38d0eabaedbcd65c2c2ff8e075f58f29f83cc101",
 "manager": "0xB7410dc44e2715161E9914272e2D55D7c5061FAa",
 "safe": "0x81B80499C396a9931b9e44953425a82C1b2541bd",
 "team001232": "0x001232c60a01d7b54cb011b0075bab75791aa03b",
 "NAVsig": "0xC70352b9a07be0e6aFDce63AC05c540E7d8Fe45A",
 "dead": "0x000000000000000000000000000000000000dEaD",
}

print("=== maxDeposit / maxMint / maxRedeem(account) on key tokens ===")
for sym in ["pBTC3x","pTEST","pTEST3","pSPCX5x"]:
    t = next(x for x in inv["pTokens"] if x["symbol"]==sym)
    addr = t["address"]
    print(f"\n--- {sym} {addr} TA={t['totalAssets']} TS={t['totalSupply']} paused={t['depositsPaused']}")
    print(f"    {'account':<12} {'maxDeposit':>22} {'maxMint':>22} {'maxRedeem':>22}")
    for nm, a in ACCOUNTS.items():
        md = call(addr, "0x402d267d"+pad_addr(a), sender=a)
        mm = call(addr, "0xc63d75b6"+pad_addr(a), sender=a)
        mr = call(addr, "0xd905777e"+pad_addr(a), sender=a)
        def fmt(x):
            if x.startswith("REVERT"): return "REVERT"
            return str(int(x,16))
        print(f"    {nm:<12} {fmt(md):>22} {fmt(mm):>22} {fmt(mr):>22}")

print("\n=== factory TokenInfo struct fields +0..+8 for all tokens ===")
BASE = 0xa769f8c9143baba25af081fc9be8c430818f488859fcf079e05437b69a641000
def struct_base(key):
    return int.from_bytes(keccak(bytes.fromhex("00"*12+key.lower().replace("0x","")) + (BASE+0x04).to_bytes(32,"big")), "big")
print(f"{'token':<10} {'+0 manager':<12} {'+1':>16} {'+2':>4} {'+3':>4} {'+4':>4} {'+5':>4} {'+6':>4} {'+7':>8} {'+8':>8}")
for t in inv["pTokens"]:
    s = struct_base(t["address"])
    vals = []
    for k in range(0,9):
        v = rpc("eth_getStorageAt",[F,hex(s+k),"latest"])
        vals.append(int(v,16))
    last = lambda x: x  # full ints
    print(f"{t['symbol']:<10} {hex(vals[0])[-4:]:<12} {vals[1]:>16} {vals[2]:>4} {vals[3]:>4} {vals[4]:>4} {vals[5]:>4} {vals[6]:>4} {vals[7]:>8} {vals[8]:>8}")

print("\n=== global flag map (BASE+0x06) + per-token map (BASE+0x05) sample checks ===")
def gslot(key): return int.from_bytes(keccak(bytes.fromhex("00"*12+key.lower().replace("0x","")) + (BASE+0x06).to_bytes(32,"big")), "big")
def pslot(tok, key):
    inner = keccak(bytes.fromhex("00"*12+key.lower().replace("0x","")) + (BASE+0x05).to_bytes(32,"big"))
    return int.from_bytes(keccak(bytes.fromhex("00"*12+tok.lower().replace("0x","")) + inner), "big")
teams = ["0x001232c60a01d7b54cb011b0075bab75791aa03b","0x075cb6d2818c11080df6fc7d396921076c003c08",
        "0x46dd8d1e5a580233b5421a7032c604ab3c6bb9e8","0x90020d503799aa9dfe0f13ad08ae7fa8431d1c22",
        "0xa9877c8a990ca2eeba4dd3ee9ab4d2395c9f8b23","0xf6c1dca6220983e07930a1a6298f4d00692e3089",
        "0x57d32496efa0ebe68c1aed77c9d46ec99c4f5b78"]
for a in teams:
    print("  global", a, int(rpc("eth_getStorageAt",[F,hex(gslot(a)),"latest"]),16))
pBTC3x = next(x["address"] for x in inv["pTokens"] if x["symbol"]=="pBTC3x")
pTEST = next(x["address"] for x in inv["pTokens"] if x["symbol"]=="pTEST")
for tok in [pBTC3x, pTEST]:
    print("  per-token map on", tok)
    for a in teams + ["0x38d0eabaedbcd65c2c2ff8e075f58f29f83cc101"]:
        print("    ", a, int(rpc("eth_getStorageAt",[F,hex(pslot(tok,a)),"latest"]),16))
