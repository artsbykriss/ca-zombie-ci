#!/usr/bin/env python3
"""Batch: role gating of setters, role members, beacon impl history hashes, 4d9f30fc anomaly."""
import json, urllib.request

RPC = "http://127.0.0.1:8547"
def rpc(m, p):
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),
        headers={"Content-Type":"application/json"})
    with urllib.request.urlopen(req, timeout=300) as r: d = json.load(r)
    if "error" in d: raise RuntimeError(json.dumps(d["error"])[:350])
    return d["result"]

def pad(a): return "0"*24 + a.lower().replace("0x","")
def u(x): return f"{x:064x}"
F = "0x9c3663FA9ab976E67B42939486EC4966Cb41a0BB"
SENDERS = {
 "deployer": "0x38d0eabaedbcd65c2c2ff8e075f58f29f83cc101",
 "safe": "0x81B80499C396a9931b9e44953425a82C1b2541bd",
 "manager": "0xB7410dc44e2715161E9914272e2D55D7c5061FAa",
 "NAVsig": "0xC70352b9a07be0e6aFDce63AC05c540E7d8Fe45A",
 "dead": "0x000000000000000000000000000000000000dEaD",
 "trad57d": "0x57D32496efA0ebe68C1AEd77c9d46EC99c4f5b78",
}
def call(data, sender, to=F):
    try:
        r = rpc("eth_call", [{"to": to, "data": data, "from": sender}, "latest"])
        return "OK " + r[:74]
    except Exception as e:
        s = str(e)
        # extract custom error selector + role
        import re
        m = re.search(r"custom error 0x([0-9a-f]+): ([0-9a-f]*)", s)
        if m:
            sel = m.group(1); data_hex = m.group(2)
            role = data_hex[-64:] if len(data_hex) >= 128 else "?"
            return f"REVERT 0x{sel} role={role}"
        return "REVERT " + s[:120]

print("=== setter gating ===")
tests = [
 ("setBeacon(0x978ad5bf)", "0xd42afb56" + pad("0x978ad5bfc6cfe45cd57885d8b9c6ee0cbaca5fc8")),
 ("setBridgeVault(0xd42c46c7)", "0xebcb0b7a" + pad("0xD42c46c7BaD6A54b38395F846b09981CE75fb8e2")),
 ("setMetadataBaseURI('x')", "0xfb94bd8a" + u(0x20) + u(1) + ("78" + "00"*31)),
 ("setManager(pBTC3x,manager)", "0x5df8122f" + pad("0x4472C69d299382F8847ebCE4FC6Ed8e295510E3e") + pad("0xB7410dc44e2715161E9914272e2D55D7c5061FAa")),
 ("0x4e666f20(pBTC3x,1)", "0x4e666f20" + pad("0x4472C69d299382F8847ebCE4FC6Ed8e295510E3e") + u(1)),
 ("0xc2eabaf3(pBTC3x,true)", "0xc2eabaf3" + pad("0x4472C69d299382F8847ebCE4FC6Ed8e295510E3e") + u(1)),
 ("0xd3c5ee0e(pTEST,[dead],true)", "0xd3c5ee0e" + pad("0x1193BcBfaFeB2F25C516817C46BD3143936d1d5C") + u(0x60) + u(1) + u(1) + pad("0x000000000000000000000000000000000000dEaD")),
 ("0x8da87eb1(1)", "0x8da87eb1" + u(1)),
 ("0x8da87eb1(604800)", "0x8da87eb1" + u(604800)),
 ("0x8da87eb1(2592000)", "0x8da87eb1" + u(2592000)),
 ("0xed6d7b26(salt,tuple)", "0xed6d7b26" + "ab"*32 + u(0x40) + pad("0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168") + u(0xe0) + u(0x120) + u(0x12) + u(10**6) + pad("0x38d0eabaedbcd65c2c2ff8e075f58f29f83cc101") + u(0) + u(1) + ("41"+"00"*31) + u(1) + ("42"+"00"*31)),
]
for name, data in tests:
    print(f"\n-- {name}")
    for sn, sa in SENDERS.items():
        print(f"   [{sn}] {call(data, sa)[:150]}")

print("\n\n=== role members (getRoleMembers(bytes32) 0xa3246ad3; getRoleMemberCount 0xca15c873) ===")
roles = {
 "DEFAULT_ADMIN_ROLE": "0x"+"00"*32,
 "NAV_SIGNER_ROLE": "0x2fc965e6d3b4285cc1c2fdb81c559078c383a02a3e5c7d916842895edb7e4955",
 "role_b91dda2c(0xcc040dc7)": "0xb91dda2cc93a6f605881ec1c75364095dea47363eeac29e1c5af77baf0131a16",
 "role_fb488cd4(0x9dd6fe88)": "0xfb488cd4db727b7998f22f1294cea9002efdf4cebb4161d79996d3226406b044",
}
for nm, r in roles.items():
    try:
        ret = rpc("eth_call", [{"to": F, "data": "0xa3246ad3" + r[2:]}, "latest"])
        b = bytes.fromhex(ret[2:])
        n = int.from_bytes(b[32:64], "big")
        members = ["0x" + b[64+i*32+12:64+i*32+32].hex() for i in range(n)]
        print(f"  {nm}: {members}")
    except Exception as e:
        print(f"  {nm}: ERR {str(e)[:100]}")

print("\n\n=== beacon impl history: code hashes ===")
impls = ["0x5c4e2a240e32470f08bd65c0575f7730ae6c714f","0x931f2a7fe19ffc064b66b711a3e64539e29957a9",
 "0xa01ec722248c36e805e84ce09d629cacb868f18a","0xaa4b74024149f2f1e4f76551515421b65bbdf90f",
 "0x9c65f71ee067dc08906a25ec200d70ba1f76fbd6","0x29b9e468037fe1a56bb49062c960cf8267d9ad86",
 "0xe4e7ea7dbf58c2d5cbd5462d470223a460c978d7","0xc56fcd809de4f79748b4d7c29e5d788f7f61a617",
 "0x4b7fbbd8d5ff1073f897662306b79724261172e0","0x1815a37b6027ae8066720d873a508f25fc151ac5"]
for impl in impls:
    code = rpc("eth_getCode", [impl, "latest"])
    from eth_utils import keccak
    h = keccak(bytes.fromhex(code[2:])).hex() if len(code) > 4 else "NO-CODE"
    print(f"  {impl} size={(len(code)-2)//2} keccak=0x{h}")
# factory impls
print(" factory impls:")
for impl in ["0xd42f03be1b183e5bf5dc3907232a2e4e3e1ec15a","0xa592a0f081218399ff622ad9457fa23ecd288897",
             "0x8ed2b831a12a734b92d03b88db89a65d9d886731","0x4fa0ca643d4cc038077042005e358098b81d565f",
             "0xfff94bfe44e1a645322b1f593d6a54dc27e4006a","0x58bdc1d3068a0a79d7a662dee033d62cbd4f589f"]:
    code = rpc("eth_getCode", [impl, "latest"])
    from eth_utils import keccak
    h = keccak(bytes.fromhex(code[2:])).hex() if len(code) > 4 else "NO-CODE"
    print(f"  {impl} size={(len(code)-2)//2} keccak=0x{h}")

print("\n\n=== 0x4d9f30fc(i) vs pTokenAt(j) comparison ===")
for i in range(0, 20):
    try:
        r = rpc("eth_call", [{"to": F, "data": "0x4d9f30fc" + u(i)}, "latest"])
        a = "0x" + r[-40:]
    except Exception as e:
        a = "REVERT"
    print(f"  idx {i:2d} -> {a}")
print(" pTokenAt:")
for j in range(0, 18):
    try:
        r = rpc("eth_call", [{"to": F, "data": "0xb806d460" + u(j)}, "latest"])
        a = "0x" + r[-40:]
    except Exception as e:
        a = "REVERT"
    print(f"  idx {j:2d} -> {a}")

print("\n=== examine 0xc95b311c346559b65f1565f3d7c8169075d97d12 (index0 of 4d9f30fc) ===")
X = "0xc95b311c346559b65f1565f3d7c8169075d97d12"
code = rpc("eth_getCode", [X, "latest"])
print("  code size:", (len(code)-2)//2)
impl_slot = rpc("eth_getStorageAt", [X, "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc", "latest"])
print("  ERC1967 impl slot:", impl_slot)
for nm, sel in [("name", "0x06fdde03"), ("symbol", "0x95d89b41"), ("decimals", "0x313ce567"), ("totalAssets", "0x01e1d114"), ("totalSupply", "0x18160ddd"), ("asset", "0x38d52e0f")]:
    try:
        r = rpc("eth_call", [{"to": X, "data": sel}, "latest"])
        if sel == "0x06fdde03":
            b = bytes.fromhex(r[2:]); ln = int.from_bytes(b[32:64], "big"); val = b[64:64+ln].decode()
        elif sel == "0x95d89b41":
            b = bytes.fromhex(r[2:]); ln = int.from_bytes(b[32:64], "big"); val = b[64:64+ln].decode()
        else:
            val = int(r, 16)
        print(f"  {nm}: {val}")
    except Exception as e:
        print(f"  {nm}: ERR {str(e)[:80]}")
