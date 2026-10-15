#!/usr/bin/env python3
"""Resolve EIP-1967 impls for all Liquid Driver proxies; fingerprint unique impls."""
import json, urllib.request, hashlib, sys
from concurrent.futures import ThreadPoolExecutor

def post(url, payload, timeout=30):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def rpc(url, method, params, retries=3):
    for a in range(retries):
        try:
            d = post(url, {"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
            if "result" in d: return d["result"]
        except Exception:
            pass
    return None

F = "https://fantom.drpc.org"
B = "https://bsc-rpc.publicnode.com"
SLOT = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"

SHADOW = ["0x59ab3c33e75C91B2B632d51144e57293EF64E556","0xDC5bDd3966884a2b1cfFd4213DaE925778786f97",
 "0xFfa8B88160Bd847a3bF032B78c8967DCa877981C","0x767e4Dc3EA4FF70D97BDEEF086e4B021923E4BdD",
 "0xA7cB4E3Ea2d6B44F4109970d7E9E7B7aBa372Eb5","0x9CD5ab5b2c00560E93Bb89174078a05b03Eb469e",
 "0x477A71A9154050DFbC497B9F782CC5169f7BDDf5","0xc43a1555554FF87f957c0DD5B80ab54951265c2E",
 "0xf4987eE98881ded997D1F3389B82ADF99e6592ed","0x3F576a5a3eb52e658bc88c23d8478Ac67eC90aeE",
 "0x3Ce75C35AF2DD29D76C7C8521c218c5A0f2826A8","0x71943a80a81c64235fC45DE4BD06638556fC773E",
 "0x3beFeA69e89931b70B80231389F97A9bF6827B2E","0x62A8bB540e52eDfFa5F71B9Ad6BEF52600A1e247",
 "0xDcBd61032cF40C16f6d7B124676C89a0e2e874c4","0xBb07eBA448e404B56Ba1273B762d690A57F7f84f",
 "0x5bC0F62BfBAc6C5f977BaC73EdC8FbCED89Ba8EC","0x4423Ca3dB49914c13068C484F9D341D636A515dd",
 "0x22214b00318300e0D046feD2D9CB166cBb48Ba60","0xA8E6F303092F0c345eEc9f780d72A8Bf56C54DF0",
 "0x04C4244F6b497343e2CcD6f3fE992910c8557dCE","0x46F8546E33900CcdB5D5FBE80af2449ecAe42128",
 "0xD75d45215a5E8E484F1f094f15b2f626A953456e","0x9757fd7d3B6281218E11Bab3b550eab8C4eF5eA9",
 "0xa0AC54644dfCE40F83F3B1BC941c234532B4B8e1","0x763caa35565d457AD4231E089C3E8fb3d0fa3d56",
 "0xf2c00E3ee1c67aAD4169bD041aFd3B7fd3B7ff98b2775".lower() if False else "0xf2c00E3ee1c67aAD4169bD041aFd3B7ff98b2775",
 "0x57B57A9a34de8547EC4a26b4bded6e78c92C9A76","0x948dbcf4595366297E5F2c1baD1593dBBDe875C6",
 "0x1c9c9d2A73A07F2cbAaa7C086a2DA70f155667d6","0x0f45B4A89AAb28f4C4dC2d08ebAD277983d4B67a",
 "0x0BF91d2e547A07A41d48817bDD28cb331227d945","0x762C8112207820d60FbB9894D429A60c570Ab574",
 "0xD354908d297ce9a348b417d2e0F561EE7D11de5E"]
HUNDRED = ["0x79364E45648Db09eE9314E47b2fD31c199Eb03B9","0x9A07fB107b9d8eA8B82ECF453Efb7cFb85A66Ce9",
           "0xeD566B089Fc80Df0e8D3E0AD3aD06116433Bf4a7","0x669F5f289A5833744E830AD6AB767Ea47A3d6409"]
OTHERS = ["0x6e2ad6527901c9664f016466b8da1357a004db0f",  # minichef ftm
          "0xd46db083de31c64af3f680f139a31ff37bac004f"]  # minichef bsc

def impl_of(url, addr):
    v = rpc(url, "eth_getStorageAt", [addr, SLOT, "latest"])
    if isinstance(v, str) and len(v) >= 42:
        return "0x" + v[-40:]
    return None

def code_hash(url, addr):
    c = rpc(url, "eth_getCode", [addr, "latest"])
    if isinstance(c, str) and len(c) > 4:
        return hashlib.sha3_256(bytes.fromhex(c[2:])).hexdigest()[:16], (len(c)-2)//2, c
    return None, 0, None

out = {"proxies": {}, "impls": {}}
targets = [("fantom", F, a, "shadow") for a in SHADOW] + \
          [("fantom", F, a, "hundred") for a in HUNDRED] + \
          [("fantom", F, OTHERS[0], "minichef"), ("bsc", B, OTHERS[1], "minichef")]

def work(t):
    chain, url, a, kind = t
    impl = impl_of(url, a)
    h, sz, _ = code_hash(url, impl) if impl else (None, 0, None)
    return {"addr": a, "chain": chain, "kind": kind, "impl": impl, "impl_hash": h, "impl_codesize": sz}

with ThreadPoolExecutor(max_workers=6) as ex:
    rows = list(ex.map(work, targets))

for r in rows:
    out["proxies"][r["addr"].lower()] = r
    if r["impl"]:
        out["impls"].setdefault(r["impl"].lower(), {"hash": r["impl_hash"], "codesize": r["impl_codesize"], "users": []})
        out["impls"][r["impl"].lower()]["users"].append(r["addr"])

print("proxies resolved:", len(out["proxies"]))
for k, v in out["impls"].items():
    print(f"impl {k} size={v['codesize']} hash={v['hash']} users={len(v['users'])}")

# fingerprint each unique impl
def selectors(code):
    b = bytes.fromhex(code[2:]); sels, i = [], 0
    while i < len(b):
        if b[i] == 0x63 and i + 5 <= len(b):
            s = "0x" + b[i+1:i+5].hex()
            if s not in sels: sels.append(s)
            i += 5
        else: i += 1
    return sels

def strings(code, minlen=6):
    b = bytes.fromhex(code[2:]); out=[]; cur=b""
    for byte in b:
        if 32 <= byte < 127: cur += bytes([byte])
        else:
            if len(cur) >= minlen: out.append(cur.decode())
            cur = b""
    if len(cur) >= minlen: out.append(cur.decode())
    return out

for impl in out["impls"]:
    chain = "fantom"
    url = F
    for r in rows:
        if (r["impl"] or "").lower() == impl:
            chain, url = r["chain"], (F if r["chain"]=="fantom" else B)
            break
    _, _, code = code_hash(url, impl)
    if code:
        out["impls"][impl]["selectors"] = selectors(code)
        out["impls"][impl]["strings"] = strings(code)

with open("/home/heisenberg/CA/liquid-driver/analysis/impl-map.json", "w") as f:
    json.dump(out, f, indent=1)
print("saved impl-map.json")
for impl, v in out["impls"].items():
    print("\n==", impl, "size", v["codesize"], "users", len(v["users"]))
    print("selectors:", v.get("selectors", [])[:50])
