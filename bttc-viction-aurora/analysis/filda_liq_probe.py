#!/usr/bin/env python3
"""FilDA BTTC: liquidatability probe for ALL accounts with open borrows (eth_call, read-only)."""
import json, sys, subprocess
sys.path.insert(0, "/home/heisenberg/CA/bttc-viction-aurora/analysis")
from rpclib import rpc, batch, eth_call, block_number, pad32

MARKETS = {
 "fBTT":  "0x65019969b8308f062548d25b1483add15c582d5b",
 "fUSDT": "0x590052be9ad26e51f2f1382d29338fcc4c04bfbf",
 "fTRX":  "0x1b596e1fdd1d4895cf30f034ef1b7b6a8942136e",
 "fUSDC": "0xaee67519049092ab91efd033f7d350d62b9f166b",
 "fETH":  "0xa258bffd5f6814303a718d2b9d34b40e14c66289",
}
# CToken with repayAmount
SEL_LIQ3 = "0xf5e3c462"  # liquidateBorrow(address,uint256,address) - CErc20
SEL_LIQ2 = "0xaae40a2a"  # liquidateBorrow(address,address) payable - CWrappedNative

def probe(victim, bmkt, cmkt, repay):
    if bmkt == "fBTT":
        data = SEL_LIQ2 + pad32(victim) + pad32(MARKETS[cmkt])
        tx = {"to": MARKETS[bmkt], "data": data, "value": hex(repay)}
    else:
        data = SEL_LIQ3 + pad32(victim) + pad32(repay) + pad32(MARKETS[cmkt])
        tx = {"to": MARKETS[bmkt], "data": data}
    try:
        r = rpc("bttc", "eth_call", [tx, "latest"])
        if r in ("0x", None):
            return "SUCCESS_NO_RETURN"
        code = int(r, 16) if r != "0x" else None
        return f"RETURNED err={code}"
    except Exception as e:
        s = str(e)
        if "ERC20" in s or "TOKEN_TRANSFER" in s or "transfer" in s.lower() or "insufficient" in s.lower():
            return "GATES_PASS(token-level revert): " + s[:80]
        return "REVERT: " + s[:120]

def main():
    blk = block_number("bttc")
    acc = json.load(open("filda_accounts.json"))
    out = {"block": blk, "probes": []}
    open_bor = {a: e for a, e in acc["accounts"].items() if any(v.get("borrow",0)>0 for v in e["markets"].values())}
    for a, e in open_bor.items():
        for bmkt in MARKETS:
            bb = e["markets"].get(bmkt,{}).get("borrow",0)
            if bb <= 0: continue
            repay = max(bb//2, 1)
            # find a collateral market with balance
            for cmkt in MARKETS:
                cb = e["markets"].get(cmkt,{}).get("cBal",0)
                if cb <= 0: continue
                res = probe(a, bmkt, cmkt, repay)
                row = {"victim": a, "borrowed": bmkt, "collateral": cmkt, "repay": repay, "result": res,
                       "shortfall_stored": e.get("liquidity",{}).get("shortfall",0)}
                out["probes"].append(row)
                print(a, bmkt, "->", cmkt, "repay", repay, ":", res)
    json.dump(out, open("filda_liq_probe.json","w"), indent=1)
    print("total probes:", len(out["probes"]))

if __name__ == "__main__":
    main()
