#!/usr/bin/env python3
"""FilDA BTTC: deep-dive underwater accounts + liquidation profit math. Read-only."""
import json, sys
sys.path.insert(0, "/home/heisenberg/CA/bttc-viction-aurora/analysis")
from rpclib import rpc, batch, eth_call, block_number, pad32, dec_uint, dec_addr

C = "0xe52792e024697a6be770e5d6f1c455550265b2cd"
MARKETS = {
 "fBTT":  ("0x65019969b8308f062548d25b1483add15c582d5b", 18, "WBTT"),
 "fUSDT": ("0x590052be9ad26e51f2f1382d29338fcc4c04bfbf", 6,  "USDT_t"),
 "fTRX":  ("0x1b596e1fdd1d4895cf30f034ef1b7b6a8942136e", 6,  "TRX"),
 "fUSDC": ("0xaee67519049092ab91efd033f7d350d62b9f166b", 6,  "USDC_t"),
 "fETH":  ("0xa258bffd5f6814303a718d2b9d34b40e14c66289", 18, "ETH"),
}
SEIZE = "0x81bc6ea9"  # liquidateCalculateSeizeTokens(address,address,uint256)
ASSETS = "0xabfceffc"  # getAssetsIn(address)
BALS = "0x4a8a5c1d"  # getBalances(address) from flash loan? skip
BALOF = "0x70a08231"  # balanceOf(address)

# prices (real USD, DefiLlama 2026-10-15 fetch)
REAL = {"WBTT": 3.5388247212612327e-07, "USDT_t": 0.9990960317557076, "TRX": 0.33179191812598163,
        "USDC_t": 0.9996551067963053, "ETH": 2365.2675382778357}

def main():
    blk = block_number("bttc")
    acc = json.load(open("filda_accounts.json"))
    out = {"block": blk, "accounts": {}}
    targets = [a for a,e in acc["accounts"].items() if e.get("liquidity",{}).get("shortfall",0) > 0]
    # oracle prices
    prices = {}
    ORACLE = "0xb2f0fef3631bc222df0e669e39582119804db72b"
    for mkt,(maddr,dec,sym) in MARKETS.items():
        r = eth_call("bttc", ORACLE, "0xfc57d4df"+pad32(maddr), block=hex(blk))
        prices[mkt] = int(r,16) if r and r!="0x" else None
    out["oracle_prices_raw"] = prices
    out["implied_btt_usd"] = {mkt: (REAL[sym]*(10**(36-dec))/prices[mkt]) for mkt,(a,dec,sym) in MARKETS.items() if prices.get(mkt)}
    for a in targets:
        e = acc["accounts"][a]
        d = {"snapshot": e}
        d["code_len"] = len(eth_call("bttc", a, "") or "0x") if False else None
        d["is_contract"] = False
        try:
            code = rpc("bttc","eth_getCode",[a, hex(blk)])
            d["is_contract"] = code not in ("0x","0x0")
            d["code_len"] = (len(code)-2)//2
        except Exception: pass
        # assets in
        try:
            r = eth_call("bttc", C, ASSETS+pad32(a), block=hex(blk))
            h = r[2:] if r else ""
            n = int(h[64:128],16) if len(h)>=128 else 0
            d["assets_in"] = ["0x"+h[128+i*64+24:128+(i+1)*64] for i in range(n)]
        except Exception as ex:
            d["assets_in"] = "REVERT"
        # liquidation quotes: for each borrowed market, each collateral market
        quotes = {}
        for bmkt,(baddr,bdec,bsym) in MARKETS.items():
            bb = e["markets"].get(bmkt,{}).get("borrow",0)
            if bb <= 0: continue
            maxclose = bb//2
            for cmkt,(caddr,cdec,csym) in MARKETS.items():
                cb = e["markets"].get(cmkt,{}).get("cBal",0)
                if cb <= 0: continue
                try:
                    r = eth_call("bttc", C, SEIZE+pad32(baddr)+pad32(caddr)+pad32(maxclose), block=hex(blk))
                    h = r[2:]
                    err = int(h[0:64],16); st = int(h[64:128],16)
                    quotes[f"{bmkt}->{cmkt}"] = {"repay": maxclose, "seizeTokens": st, "err": err,
                                                 "collateral_cBal": cb, "seize_le_cBal": st<=cb}
                except Exception as ex:
                    quotes[f"{bmkt}->{cmkt}"] = {"error": str(ex)[:80]}
        d["liquidation_quotes"] = quotes
        out["accounts"][a] = d
    json.dump(out, open("filda_liquidations.json","w"), indent=1)
    # print readable
    for a,d in out["accounts"].items():
        e = d["snapshot"]
        print("="*100)
        print(a, "is_contract:", d["is_contract"], "code", d.get("code_len"))
        print(" assets_in:", d.get("assets_in"))
        for mkt,(maddr,dec,sym) in MARKETS.items():
            m = e["markets"].get(mkt,{})
            if m and (m.get("cBal",0)>0 or m.get("borrow",0)>0):
                cb = m.get("cBal",0)/1e18; bb = m.get("borrow",0)/10**dec
                er = m.get("er",0)/1e18
                coll_und = cb*er
                print(f"  {mkt:6s} cBal={cb:.6f} er={er:.6e} collateral_underlying={coll_und:.6f} {sym}  borrow={bb:.6f} {sym}")
        print(" liquidity:", e.get("liquidity"))
        print(" quotes:")
        for k,q in d["liquidation_quotes"].items():
            print("   ", k, q)
        print(" shortfall in BTT:", e["liquidity"]["shortfall"] if e.get("liquidity") else None,
              "→ USD ≈", (e["liquidity"]["shortfall"]/1e18*3.5388247e-07) if e.get("liquidity") else None)
    print("implied BTT usd from feeds:", out["implied_btt_usd"])

if __name__ == "__main__":
    main()
