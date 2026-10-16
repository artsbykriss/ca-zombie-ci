#!/usr/bin/env python3
"""Probe factory view selectors with various args via local anvil (read-only eth_call)."""
import json
from web3 import Web3

w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8547", request_kwargs={"timeout": 60}))
F = Web3.to_checksum_address("0x9c3663FA9ab976E67B42939486EC4966Cb41a0BB")
PT = {
 "pTEST": "0x1193BcBfaFeB2F25C516817C46BD3143936d1d5C",
 "pBTC3x": "0x4472C69d299382F8847ebCE4FC6Ed8e295510E3e",
 "pHOOD3x": "0xe24CABDf76DD1c2576049167eB1755C84b985C36",
 "pTEST3": "0x122408C1399E51C41B096402fea46e20E762A950",
}
USDG = "0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168"

def call(sel, argbytes="", to=F, sender=None, block="latest"):
    tx={"to":to,"data":sel+argbytes}
    if sender: tx["from"]=sender
    try:
        r = w3.eth.call(tx, block)
        return r.hex()
    except Exception as e:
        return f"REVERT:{str(e)[:160]}"

def pad32(x):
    if isinstance(x,str): return x.lower().replace("0x","").rjust(64,"0")
    return f"{x:064x}"

def dec_words(h):
    b = bytes.fromhex(h)
    return [int.from_bytes(b[i:i+32],"big") for i in range(0,len(b)-31,32)]

def dec_addr(h):
    b = bytes.fromhex(h)
    return [Web3.to_checksum_address(b[i+12:i+32].hex()) for i in range(0,len(b)-31,32)]

print("=== simple getters ===")
for name, sel in [("0x48104be9()","0x48104be9"), ("0xcc040dc7()","0xcc040dc7"),
                  ("0x9dd6fe88()","0x9dd6fe88"), ("pTokenCount()","0x07f7e37c"),
                  ("version()","0x54fd4d50"), ("UPGRADE_INTERFACE_VERSION()","0xad3cb1cc"),
                  ("beacon()","0x59659e90"), ("bridgeVault()","0xac03e9f0"),
                  ("metadataBaseURI()","0x9f3d1a2a"), ("NAV_SIGNER_ROLE()","0xdba69b7c"),
                  ("DEFAULT_ADMIN_ROLE()","0xa217fddf")]:
    r = call(sel)
    print(f"{name}: {r[:200]}")
    if r.startswith("0x") and ":" not in r and len(r) == 66:
        print("    hexword:", r); print("    as addr:", Web3.to_checksum_address(r[2:]))

print("\n=== indexed getters 0x8380f472(uint256) ===")
for i in range(0,4):
    print(f"  i={i}:", call("0x8380f472", pad32(i))[:200])
print("=== indexed getters 0x4d9f30fc(uint256) ===")
for i in range(0,4):
    print(f"  i={i}:", call("0x4d9f30fc", pad32(i))[:200])

print("\n=== address getters ===")
for sel, nm in [("0x1f5f81f5","0x1f5f81f5(a)"),("0x57d41c64","0x57d41c64(a)"),
                ("0x22555cda","isPToken?"),("0x0e68ec95","config(a)"),("0x7f41826b","managerOf(a)")]:
    for label, a in list(PT.items()) + [("USDG",USDG),("random","0x000000000000000000000000000000000000dEaD")]:
        r = call(sel, pad32(a))
        print(f"  {nm} [{label}]: {r[:140]}")

print("\n=== 2-arg getters ===")
for label, a in PT.items():
    r = call("0x1c0d9bca", pad32(a)+pad32(USDG))
    print(f"  0x1c0d9bca({label}, USDG): {r[:140]}")
r = call("0x1c0d9bca", pad32(PT['pBTC3x'])+pad32(PT['pHOOD3x']))
print(f"  0x1c0d9bca(pBTC3x, pHOOD3x): {r[:140]}")

print("\n=== 0xd85777d0(uint256,address[],uint256[]) / variants ===")
# try (0, [pBTC3x], [1e11])
r = call("0xd85777d0", pad32(0)+pad32(0x60)+pad32(0x80+32)+pad32(1)+pad32(PT['pBTC3x'])+pad32(1e11))
print("  v1:", r[:300])
r = call("0xd85777d0", pad32(0)+pad32(0x60)+pad32(0x100)+pad32(1)+pad32(PT['pBTC3x'])+pad32(1e11))
print("  v2:", r[:300])

print("\n=== role members ===")
roles = {"DEFAULT_ADMIN(0x0)":"0x"+"00"*32, "NAV_SIGNER(0x2fc965e6)":"0x2fc965e6d3b4285cc1c2fdb81c559078c383a02a3e5c7d916842895edb7e4955",
         "b91dda2c":"0xb91dda2cc93a6f605881ec1c75364095dea47363eeac29e1c5af77baf0131a1",
         "fb488cd4":"0xfb488cd4db727b79"+"0"*40}
for nm, role in roles.items():
    rc = call("0xca15c873", role)  # getRoleMemberCount(bytes32)
    try:
        cnt = int(rc, 16)
    except: cnt = -1
    members = []
    for i in range(cnt if 0 <= cnt < 50 else 0):
        m = call("0x9010d07c", role + pad32(i))
        b = bytes.fromhex(m); members.append(Web3.to_checksum_address(b[12:32].hex()))
    print(f"  {nm}: count={cnt} members={members}")
