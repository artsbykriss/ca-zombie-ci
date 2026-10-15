#!/usr/bin/env python3
"""FilDA BTTC: eth_call simulation of the liquidation path (read-only, no tx)."""
import json, sys, subprocess
sys.path.insert(0, "/home/heisenberg/CA/bttc-viction-aurora/analysis")
from rpclib import rpc, batch, eth_call, block_number, pad32, dec_addr

FUSDC = "0xaee67519049092ab91efd033f7d350d62b9f166b"
FBTT  = "0x65019969b8308f062548d25b1483add15c582d5b"
FETH  = "0xa258bffd5f6814303a718d2b9d34b40e14c66289"
FUSDT = "0x590052be9ad26e51f2f1382d29338fcc4c04bfbf"
USDC  = "0x935faa2fcec6ab81265b301a30467bbc804b43d3"
VICTIM = "0x0dfd9fc5a3abefc047168830c10111bca895305f"
VICTIM2 = "0x4e92b67c1a0dc26f346e822ddf0d7395427285b6"

SEL_LIQ = "0xf5e3c462"      # liquidateBorrow(address,uint256,address)
SEL_BAL = "0x70a08231"
SEL_ALW = "0xdd62ed3e"

def word_of(lg, i):
    d = lg.get("data","0x")[2:]
    return "0x"+d[i*64+24:(i+1)*64] if len(d) >= (i+1)*64 else None

def main():
    blk = block_number("bttc")
    ev = json.load(open("filda_events.json"))
    out = {"block": blk}
    # 1) dummy-from simulation: expect token-level revert only (gates pass)
    tests = []
    dummy = "0x000000000000000000000000000000000000dEaD"
    for (bmkt, baddr, repay_units, cmkt, caddr, label) in [
        ("fUSDC", FUSDC, 17370200, "fUSDT", FUSDT, "repay 17.37 USDC seize fUSDT"),
        ("fUSDC", FUSDC, 16234400, "fETH",  FETH,  "repay 16.23 USDC seize fETH"),
        ("fUSDC", FUSDC, 7373400,  "fUSDT", FUSDT, "victim2: repay 7.37 USDC seize fUSDT"),
        ("fUSDC", FUSDC, 9999999999,"fUSDT",FUSDT, "over-close-factor control (>50%)"),
    ]:
        victim = VICTIM if "victim2" not in label else VICTIM2
        data = SEL_LIQ + pad32(victim) + pad32(repay_units) + pad32(caddr)
        try:
            r = eth_call("bttc", baddr, data, block=hex(blk))
            tests.append({"case": label, "from": dummy, "result": r, "status": "RETURNED", "err_code": int(r,16) if r and r!="0x" else None})
        except Exception as e:
            tests.append({"case": label, "from": dummy, "status": "REVERT", "error": str(e)[:220]})
    out["dummy_from_tests"] = tests
    # 2) find real USDC holders with allowance to fUSDC from RepayBorrow payers
    payers = []
    for lg in ev.get("fUSDC",{}).get("RepayBorrow", []):
        p = word_of(lg, 0)
        if p: payers.append((p, lg.get("blockNumber")))
    cands = sorted(set(p for p,_ in payers))
    out["n_usdc_repayers"] = len(cands)
    res = batch("bttc", [("eth_call",[{"to":USDC,"data":SEL_BAL+pad32(a)},hex(blk)]) for a in cands] +
                          [("eth_call",[{"to":USDC,"data":SEL_ALW+pad32(a)+pad32(FUSDC)},hex(blk)]) for a in cands])
    n = len(cands)
    funded = []
    for i,a in enumerate(cands):
        bal = int(res[i],16) if res[i] and res[i]!="0x" else 0
        alw = int(res[n+i],16) if res[n+i] and res[n+i]!="0x" else 0
        if bal > 0 or alw > 0:
            funded.append({"addr": a, "usdc_bal": bal, "allowance_fusdc": alw})
    out["funded_repayers"] = sorted(funded, key=lambda x:-x["usdc_bal"])[:20]
    # 3) full simulation from the best funded address
    sim = []
    best = [f for f in funded if f["usdc_bal"] >= 16234400 and f["allowance_fusdc"] >= 16234400]
    for f in best[:3]:
        for (baddr, repay, caddr, label) in [(FUSDC, 16234400, FETH, "repay 16.23 USDC -> seize fETH"),
                                              (FUSDC, 17370200, FUSDT, "repay 17.37 USDC -> seize fUSDT")]:
            data = SEL_LIQ + pad32(VICTIM) + pad32(repay) + pad32(caddr)
            try:
                r = eth_call("bttc", baddr, data, block=hex(blk), url=None)
                sim.append({"from": f["addr"], "case": label, "result": r, "err_code": int(r,16) if r and r!="0x" else None})
            except Exception as e:
                sim.append({"from": f["addr"], "case": label, "REVERT": str(e)[:220]})
    out["funded_simulations"] = sim
    json.dump(out, open("filda_sim.json","w"), indent=1)
    print(json.dumps(out, indent=1)[:4000])

if __name__ == "__main__":
    main()
