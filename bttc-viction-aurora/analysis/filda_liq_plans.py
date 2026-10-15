#!/usr/bin/env python3
"""FilDA BTTC: exact max-liquidation math per underwater account (on-chain seize quotes). Read-only."""
import json, sys
sys.path.insert(0, "/home/heisenberg/CA/bttc-viction-aurora/analysis")
from rpclib import rpc, batch, eth_call, block_number, pad32, dec_addr

C = "0xe52792e024697a6be770e5d6f1c455550265b2cd"
SEIZE = "0xc488847b"  # liquidateCalculateSeizeTokens(address,address,uint256)
LIQ = "0x5ec88c79"
MARKETS = {
 "fBTT":  ("0x65019969b8308f062548d25b1483add15c582d5b", 18, "WBTT",  1e-18),
 "fUSDT": ("0x590052be9ad26e51f2f1382d29338fcc4c04bfbf", 6,  "USDT_t", 1e-6),
 "fTRX":  ("0x1b596e1fdd1d4895cf30f034ef1b7b6a8942136e", 6,  "TRX",    1e-6),
 "fUSDC": ("0xaee67519049092ab91efd033f7d350d62b9f166b", 6,  "USDC_t", 1e-6),
 "fETH":  ("0xa258bffd5f6814303a718d2b9d34b40e14c66289", 18, "ETH",    1e-18),
}
REAL = {"WBTT": 3.5388247212612327e-07, "USDT_t": 0.9990960317557076, "TRX": 0.33179191812598163,
        "USDC_t": 0.9996551067963053, "ETH": 2365.2675382778357}
ORACLE_P = {  # raw oracle prices read earlier (BTT-denominated)
 "fBTT": 10**18, "fUSDT": 2837785963068181818181818181818181818, "fTRX": 942027599431818181818181818181818181,
 "fUSDC": 2840056985795454545454545454545454545, "fETH": 6719275930528409090909090909,
}

def seize_quote(blk, bmkt, cmkt, repay):
    r = eth_call("bttc", C, SEIZE+pad32(MARKETS[bmkt][0])+pad32(MARKETS[cmkt][0])+pad32(repay), block=hex(blk))
    h = r[2:]
    return int(h[0:64],16), int(h[64:128],16)

def main():
    blk = block_number("bttc")
    acc = json.load(open("filda_accounts.json"))
    out = {"block": blk, "analysis": {}}
    for a,e in acc["accounts"].items():
        sf = e.get("liquidity",{}).get("shortfall",0)
        if sf <= 0: continue
        d = {"shortfall_denom": sf, "positions": {}, "plans": []}
        for mkt,(maddr,dec,sym,mult) in MARKETS.items():
            m = e["markets"].get(mkt,{})
            cb_wei = m.get("cBal",0); bb_wei = m.get("borrow",0); er = m.get("er",0)
            coll_und = cb_wei*er//10**18  # underlying smallest units
            d["positions"][mkt] = {"cBal_wei": cb_wei, "coll_und_units": coll_und, "coll_usd_real": coll_und*mult*REAL[sym],
                                   "borrow_wei": bb_wei, "borrow_usd_real": bb_wei*mult*REAL[sym], "er": er}
        # plan per (borrowed, collateral) pair
        for bmkt,(baddr,bdec,bsym,bmult) in MARKETS.items():
            bb = e["markets"].get(bmkt,{}).get("borrow",0)
            if bb <= 0: continue
            maxclose = bb//2
            for cmkt,(caddr,cdec,csym,cmult) in MARKETS.items():
                cb = e["markets"].get(cmkt,{}).get("cBal",0)
                if cb <= 0: continue
                err, st = seize_quote(blk, bmkt, cmkt, maxclose)
                if err != 0:
                    # try 0 repay? skip
                    continue
                if st <= cb:
                    best = maxclose
                    err, st = seize_quote(blk, bmkt, cmkt, best)
                else:
                    # binary search largest repay with seize <= cb
                    lo, hi = 1, maxclose
                    while lo < hi:
                        mid = (lo+hi+1)//2
                        e2, s2 = seize_quote(blk, bmkt, cmkt, mid)
                        if e2 == 0 and s2 <= cb:
                            lo = mid
                        else:
                            hi = mid-1
                    best = lo
                    err, st = seize_quote(blk, bmkt, cmkt, best)
                if best <= 0: continue
                repaid_usd = best*bmult*REAL[bsym]
                seized_und = st*e["markets"][cmkt]["er"]//10**18
                seized_usd = seized_und*cmult*REAL[csym]
                d["plans"].append({"borrowed": bmkt, "collateral": cmkt, "repay_units": best,
                                   "repay_usd": repaid_usd, "seizeTokens": st, "seize_cBal": cb,
                                   "seized_und_units": seized_und, "seized_usd": seized_usd,
                                   "gross_profit_usd": seized_usd - repaid_usd})
        d["plans"].sort(key=lambda p: -p["gross_profit_usd"])
        out["analysis"][a] = d
    json.dump(out, open("filda_liq_plans.json","w"), indent=1)
    for a,d in out["analysis"].items():
        print("="*100)
        print(a, "shortfall_denom", d["shortfall_denom"])
        for mkt,p in d["positions"].items():
            if p["cBal_wei"] or p["borrow_wei"]:
                print(f"   {mkt:6s} coll_usd={p['coll_usd_real']:.6f} borrow_usd={p['borrow_usd_real']:.6f}")
        for p in d["plans"][:6]:
            print(f"   PLAN repay {p['borrowed']} ${p['repay_usd']:.4f} -> seize {p['collateral']} ${p['seized_usd']:.4f}  profit ${p['gross_profit_usd']:.4f}  (seizeTokens {p['seizeTokens']} / cBal {p['seize_cBal']})")

if __name__ == "__main__":
    main()
