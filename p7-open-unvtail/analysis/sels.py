#!/usr/bin/env python3
"""Extract PUSH4 selectors from EVM runtime bytecode and match a money-path dictionary."""
import re, glob, os, json
DICT = {
 "0xa9059cbb":"transfer(address,uint256)","0x23b872dd":"transferFrom(address,address,uint256)",
 "0x2e1a7d4d":"withdraw(uint256)","0x3ccfd60b":"withdraw()","0x00f714ce":"withdraw(uint256,address)",
 "0xf3fef3a3":"withdraw(address,uint256)","0xdb006a75":"redeem(uint256)",
 "0xba087652":"redeem(uint256,address,address)","0x2e7ba6ef":"redeem(uint256,address)",
 "0xd0e30db0":"deposit()","0xb6b55f25":"deposit(uint256)","0x6e553f65":"deposit(uint256,address)",
 "0xe2bbb158":"deposit(uint256,uint256)","0xa0712d68":"mint(uint256)","0x94bf804d":"mint(uint256,address)",
 "0x4e71d92d":"claim()","0x379607f5":"claim(uint256)","0x6ea056a9":"sweep(address)",
 "0x3014b6da":"sweepToken(address)","0x8f7d1a14":"sweepToken(address,address)",
 "0xb61d27f6":"execute(address,uint256,bytes)","0x1cff79cd":"execute(address,bytes)",
 "0x3659cfe6":"upgradeTo(address)","0x4f1ef286":"upgradeToAndCall(address,bytes)",
 "0x8f283970":"changeAdmin(address)","0xf851a440":"admin()","0x8da5cb5b":"owner()",
 "0xa0e67e2b":"getOwners()","0x2f54bf6e":"isOwner(address)","0xf2fde38b":"transferOwnership(address)",
 "0x8129fc1c":"initialize()","0xc4d66de8":"initialize(address)","0x3f4ba83a":"unpause()",
 "0x8456cb59":"pause()","0x5c975abb":"paused()","0x715018a6":"renounceOwnership()",
 "0x01e1d114":"totalAssets()","0x38d52e0f":"asset()","0x70a08231":"balanceOf(address)",
 "0x313ce567":"decimals()","0x95d89b41":"symbol()","0x06fdde03":"name()",
 "0x2f4f21e2":"rescueTokens(address)","0xb29a7b8f":"rescueETH(uint256)",
 "0xdb2e21bc":"emergencyWithdraw()","0x5312ea8e":"emergencyWithdraw(uint256)",
 "0x2f940c70":"rescueERC20(address,address,uint256)","0xd1660f99":"rescueTokens(address,uint256)",
 "0x51cff8d9":"withdraw(address)","0x69328dec":"withdraw(address,uint256,address)",
 "0x8d80ff0a":"multiSend(bytes)","0x8c9a4a2d":"setPrice(uint256)","0x4e69d560":"getPrice()",
}
rows=[]
for f in sorted(glob.glob("/tmp/opencode/unvtail/code/*.impl.hex")):
    name=os.path.basename(f).replace(".impl.hex","")
    hx=open(f).read().strip()
    if hx.startswith("0x"): hx=hx[2:]
    # PUSH4 = 63 followed by 4 bytes
    sels=set()
    for m in re.finditer("63([0-9a-fA-F]{8})", hx):
        sels.add("0x"+m.group(1).lower())
    found={s:DICT[s] for s in sels if s in DICT}
    rows.append((name,len(hx)//2,sorted(found.items())))
for name,sz,found in rows:
    print(f"\n== {name} ({sz} bytes)")
    for s,d in found: print(f"   {s} {d}")
