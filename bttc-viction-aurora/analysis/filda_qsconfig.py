#!/usr/bin/env python3
"""FilDA BTTC: verify deployed Qstroller + QsConfig params. Read-only."""
import json, sys, subprocess
sys.path.insert(0, "/home/heisenberg/CA/bttc-viction-aurora/analysis")
from rpclib import rpc, batch, eth_call, block_number, get_code, pad32, dec_uint, dec_addr

C = "0xe52792e024697a6be770e5d6f1c455550265b2cd"

def k4(sig):
    return subprocess.run(["cast","keccak",sig], capture_output=True, text=True).stdout.strip()[:10]

SIGS = ["qsConfig()","safetyGuardian()","comptrollerImplementation()","pendingComptrollerImplementation()",
        "compToken()","safetyVaultRatio()","safetyVault()","compRatio()","flashLoanFeeRatio()","owner()",
        "isBlocked(address)","getCreditLimit(address)","getBorrowCap(address)","getSupplyCap(address)",
        "getFlashLoanCap(address)","maxAssets()","transferGuardianPaused()","seizeGuardianPaused()",
        "_mintGuardianPaused()","_borrowGuardianPaused()","compRate()","getCompAddress()"]
S = {n: k4(n) for n in SIGS}

def main():
    blk = block_number("bttc")
    out = {"block": blk}
    # 1) impl verification on comptroller proxy
    for n in ["qsConfig()","safetyGuardian()","comptrollerImplementation()","pendingComptrollerImplementation()"]:
        try:
            r = eth_call("bttc", C, S[n], block=hex(blk))
            out[n] = dec_addr(r) if r and r!="0x" else r
        except Exception as e:
            out[n] = "REVERT:"+str(e)[:100]
    qs = out.get("qsConfig()")
    out["qsConfig"] = qs
    # 2) qsconfig params
    if qs and qs.startswith("0x"):
        q = {"code_len": len(get_code("bttc", qs))//2-1}
        for n in ["compToken()","safetyVaultRatio()","safetyVault()","compRatio()","flashLoanFeeRatio()","owner()","safetyGuardian()"]:
            try:
                r = eth_call("bttc", qs, S[n], block=hex(blk))
                q[n] = dec_addr(r) if n in ("compToken()","safetyVault()","owner()","safetyGuardian()") else (dec_uint(r) if r and r!="0x" else None)
            except Exception as e:
                q[n] = "REVERT:"+str(e)[:80]
        out["qsconfig"] = q
    # 3) comptroller misc
    for n in ["transferGuardianPaused()","seizeGuardianPaused()","_mintGuardianPaused()","_borrowGuardianPaused()","maxAssets()","compRate()"]:
        try:
            r = eth_call("bttc", C, S[n], block=hex(blk))
            out[n] = dec_uint(r) if r and r!="0x" else None
        except Exception as e:
            out[n] = "REVERT:"+str(e)[:80]
    try:
        r = eth_call("bttc", C, S["getCompAddress()"], block=hex(blk))
        out["getCompAddress()"] = dec_addr(r)
    except Exception as e:
        out["getCompAddress()"] = "REVERT:"+str(e)[:80]
    # 4) per-market caps
    d = json.load(open("/home/heisenberg/CA/bttc-viction-aurora/analysis/filda_markets.json"))
    mk = []
    for m in d["markets"]:
        e = {"market": m["address"], "symbol": m["symbol"]}
        if qs and qs.startswith("0x"):
            res = batch("bttc", [("eth_call",[{"to":qs,"data":S["getBorrowCap(address)"]+pad32(m["address"])},hex(blk)]),
                                 ("eth_call",[{"to":qs,"data":S["getSupplyCap(address)"]+pad32(m["address"])},hex(blk)]),
                                 ("eth_call",[{"to":qs,"data":S["getFlashLoanCap(address)"]+pad32(m["address"])},hex(blk)]),
                                 ("eth_call",[{"to":qs,"data":S["isBlocked(address)"]+pad32(m["address"])},hex(blk)])])
            e["borrowCap"],e["supplyCap"],e["flashLoanCap"],e["isBlocked"] = [dec_uint(x) if x and x!="0x" else None for x in res]
        mk.append(e)
    out["market_caps"] = mk
    # 5) admin/pauseGuardian code
    for name, a in [("admin","0x8bcb316f2d9313c8a9dbe9fdf1210f5243a81479"),("pauseGuardian","0x05ddc595fd33d7b2ab302143c420d0e7f21b622a")]:
        try:
            out[name+"_code_len"] = len(get_code("bttc", a))//2-1
        except Exception as ex:
            out[name+"_code_len"] = "ERR:"+str(ex)[:60]
    print(json.dumps(out, indent=1))

if __name__ == "__main__":
    main()
