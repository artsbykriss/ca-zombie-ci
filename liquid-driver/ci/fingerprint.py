#!/usr/bin/env python3
"""
CI: resolve EIP-1967 impls of all Liquid Driver proxies, fingerprint unique impls,
and simulate standard farm/chef entry points from an unprivileged attacker address.
READ ONLY. Writes ci-out/fingerprints.json
"""
import json, os, hashlib, subprocess, urllib.request, time
from concurrent.futures import ThreadPoolExecutor

FANTOM = os.environ.get("FANTOM_RPC_URL") or "https://fantom.drpc.org"
BSC = os.environ.get("BSC_RPC_URL") or "https://bsc-rpc.publicnode.com"
OUTDIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ci-out")
os.makedirs(OUTDIR, exist_ok=True)
SLOT = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
ATK = "0x1111111111111111111111111111111111111111"

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
        time.sleep(0.5 * (a + 1))
    return None

def call(url, to, data, frm=None, blk="latest"):
    p = {"to": to, "data": data}
    if frm: p["from"] = frm
    return rpc(url, "eth_call", [p, blk])

def sel(sig):
    return subprocess.run(["cast", "sig", sig], capture_output=True, text=True).stdout.strip()

def enc_addr(a): return a[2:].lower().rjust(64, "0")
def enc_uint(n): return hex(n)[2:].rjust(64, "0")

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
 "0xf2c00E3ee1c67aAD4169bD041aFd3B7ff98b2775","0x57B57A9a34de8547EC4a26b4bded6e78c92C9A76",
 "0x948dbcf4595366297E5F2c1baD1593dBBDe875C6","0x1c9c9d2A73A07F2cbAaa7C086a2DA70f155667d6",
 "0x0f45B4A89AAb28f4C4dC2d08ebAD277983d4B67a","0x0BF91d2e547A07A41d48817bDD28cb331227d945",
 "0x762C8112207820d60FbB9894D429A60c570Ab574","0xD354908d297ce9a348b417d2e0F561EE7D11de5E"]
HUNDRED = ["0x79364E45648Db09eE9314E47b2fD31c199Eb03B9","0x9A07fB107b9d8eA8B82ECF453Efb7cFb85A66Ce9",
           "0xeD566B089Fc80Df0e8D3E0AD3aD06116433Bf4a7","0x669F5f289A5833744E830AD6AB767Ea47A3d6409"]
MINI = ["0x6e2ad6527901c9664f016466b8da1357a004db0f"]

def main():
    out = {"proxies": {}, "impls": {}}
    targets = [("fantom", FANTOM, a, "shadow") for a in SHADOW] + \
              [("fantom", FANTOM, a, "hundred") for a in HUNDRED] + \
              [("fantom", FANTOM, a, "minichef") for a in MINI] + \
              [("bsc", BSC, "0xd46db083de31c64af3f680f139a31ff37bac004f", "minichef_bsc")]

    def work(t):
        chain, url, a, kind = t
        v = rpc(url, "eth_getStorageAt", [a, SLOT, "latest"])
        impl = ("0x" + v[-40:]) if isinstance(v, str) and len(v) >= 42 else None
        h = sz = None
        if impl:
            c = rpc(url, "eth_getCode", [impl, "latest"])
            if isinstance(c, str) and len(c) > 4:
                h = hashlib.sha3_256(bytes.fromhex(c[2:])).hexdigest()[:16]
                sz = (len(c)-2)//2
        return {"addr": a, "chain": chain, "kind": kind, "impl": impl, "impl_hash": h, "impl_codesize": sz}

    with ThreadPoolExecutor(max_workers=6) as ex:
        rows = list(ex.map(work, targets))
    for r in rows:
        out["proxies"][r["addr"].lower()] = r
        if r["impl"]:
            key = r["impl"].lower()
            out["impls"].setdefault(key, {"hash": r["impl_hash"], "codesize": r["impl_codesize"], "users": []})
            out["impls"][key]["users"].append(r["addr"])
    print("proxies:", len(out["proxies"]), "impls:", len(out["impls"]), flush=True)

    # fingerprint each unique impl
    for impl, v in out["impls"].items():
        chain = "fantom"
        for r in rows:
            if (r["impl"] or "").lower() == impl:
                chain = r["chain"]; break
        url = FANTOM if chain == "fantom" else BSC
        c = rpc(url, "eth_getCode", [impl, "latest"])
        if isinstance(c, str) and len(c) > 4:
            v["selectors"] = selectors(c)
            v["strings"] = strings(c)
    print("fingerprinted", flush=True)

    # simulations from attacker on each proxy
    sigs = {}
    for s in ["withdraw(uint256)", "withdraw(uint256,address)", "withdraw(uint256,uint256)",
              "withdraw(uint256,uint256,address)", "harvest()", "harvest(uint256)",
              "harvest(uint256,address)", "emergencyWithdraw()", "emergencyWithdraw(uint256)",
              "emergencyWithdraw(uint256,address)", "deposit(uint256)", "deposit(uint256,uint256)",
              "getReward()", "getReward(uint256)", "claim()", "claim(uint256)", "massHarvestFromStrategies()",
              "withdrawAll()", "exit()", "leave()", "unstake(uint256)"]:
        sigs[s] = sel(s)
    sims = {}
    def sim_work(t):
        a, chain, sig, args = t
        url = FANTOM if chain == "fantom" else BSC
        data = sigs[sig] + args
        r = call(url, a, data, ATK)
        return (a, sig, r if isinstance(r, str) else json.dumps(r)[:120])
    sim_targets = []
    for a in SHADOW + HUNDRED + MINI:
        for sig, args in [("withdraw(uint256)", enc_uint(1)),
                          ("withdraw(uint256,address)", enc_uint(1) + enc_addr(ATK)),
                          ("harvest()", ""),
                          ("harvest(uint256)", enc_uint(0)),
                          ("emergencyWithdraw()", ""),
                          ("emergencyWithdraw(uint256)", enc_uint(0)),
                          ("getReward()", ""),
                          ("claim()", ""),
                          ("withdrawAll()", "")]:
            sim_targets.append((a, "fantom", sig, args))
    with ThreadPoolExecutor(max_workers=6) as ex:
        res = list(ex.map(sim_work, sim_targets))
    for a, sig, r in res:
        sims.setdefault(a.lower(), {})[sig] = r
    out["sims_from_attacker"] = sims
    print("sims done", flush=True)

    with open(os.path.join(OUTDIR, "fingerprints.json"), "w") as f:
        json.dump(out, f, indent=1)
    print("saved ci-out/fingerprints.json", flush=True)

if __name__ == "__main__":
    main()
