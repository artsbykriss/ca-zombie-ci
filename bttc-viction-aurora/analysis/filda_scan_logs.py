#!/usr/bin/env python3
"""Scan FilDA BTTC logs (Borrow/Mint/Redeem/LiquidateBorrow/RepayBorrow). Read-only. Chunked."""
import json, sys, subprocess, time
sys.path.insert(0, "/home/heisenberg/CA/bttc-viction-aurora/analysis")
from rpclib import rpc, block_number

MARKETS = {
 "fBTT":  "0x65019969b8308f062548d25b1483add15c582d5b",
 "fUSDT": "0x590052be9ad26e51f2f1382d29338fcc4c04bfbf",
 "fTRX":  "0x1b596e1fdd1d4895cf30f034ef1b7b6a8942136e",
 "fUSDC": "0xaee67519049092ab91efd033f7d350d62b9f166b",
 "fETH":  "0xa258bffd5f6814303a718d2b9d34b40e14c66289",
}

def topic(sig):
    return subprocess.run(["cast","keccak",sig], capture_output=True, text=True).stdout.strip()

TOPICS = {
 "Borrow": topic("Borrow(address,uint256,uint256,uint256)"),
 "RepayBorrow": topic("RepayBorrow(address,address,uint256,uint256,uint256)"),
 "LiquidateBorrow": topic("LiquidateBorrow(address,address,uint256,address,uint256)"),
 "Mint": topic("Mint(address,uint256,uint256)"),
 "Redeem": topic("Redeem(address,uint256,uint256)"),
 "AccrueInterest": topic("AccrueInterest(uint256,uint256,uint256,uint256)"),
}

def get_logs(chain, addr, t0, fromb, tob, tries=4):
    params = {"fromBlock": hex(fromb), "toBlock": hex(tob), "address": addr, "topics": [t0]}
    for t in range(tries):
        try:
            return rpc(chain, "eth_getLogs", [params])
        except Exception as e:
            msg = str(e)
            if t == tries-1:
                raise
            time.sleep(1.0)
    return []

def scan_range(addr, t0, lo, hi, chunk, out):
    b = lo
    while b <= hi:
        e = min(b+chunk-1, hi)
        try:
            logs = get_logs("bttc", addr, t0, b, e)
        except Exception as ex:
            if chunk > 2000:
                chunk //= 2
                continue
            else:
                raise
        out.extend(logs)
        b = e+1
    return out

if __name__ == "__main__":
    blk = block_number("bttc")
    res = {"block": blk, "topics": TOPICS, "events": {}}
    lo = int(sys.argv[1]) if len(sys.argv)>1 else 0
    hi = int(sys.argv[2]) if len(sys.argv)>2 else blk
    chunk = int(sys.argv[3]) if len(sys.argv)>3 else 100000
    only = sys.argv[4] if len(sys.argv)>4 else None
    for name, addr in MARKETS.items():
        res["events"][name] = {}
        for ev, t0 in TOPICS.items():
            if only and ev != only: continue
            if ev == "AccrueInterest" and only is None: continue
            try:
                logs = scan_range(addr, t0, lo, hi, chunk, [])
                res["events"][name][ev] = {"count": len(logs), "logs": logs}
                print(name, ev, len(logs), file=sys.stderr)
            except Exception as ex:
                res["events"][name][ev] = {"error": str(ex)[:200]}
                print(name, ev, "ERROR", str(ex)[:120], file=sys.stderr)
    print(json.dumps(res))
