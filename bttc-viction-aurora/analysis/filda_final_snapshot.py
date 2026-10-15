#!/usr/bin/env python3
"""FilDA BTTC: VALIDATED final snapshot (rpc.bt.io pads some returns to 96 bytes; take word0)."""
import json, sys, subprocess
sys.path.insert(0, "/home/heisenberg/CA/bttc-viction-aurora/analysis")
from rpclib import rpc, block_number, pad32

C = "0xe52792e024697a6be770e5d6f1c455550265b2cd"
ORACLE = "0xb2f0fef3631bc222df0e669e39582119804db72b"
MK = {
 "fBTT":  ("0x65019969b8308f062548d25b1483add15c582d5b", "0x23181f21dea5936e24163ffaba4ea3b316b57f3c", 18, "WBTT",   3.5388247212612327e-07),
 "fUSDT": ("0x590052be9ad26e51f2f1382d29338fcc4c04bfbf", "0xdb28719f7f938507dbfe4f0eae55668903d34a15", 6,  "USDT_t", 0.9990960317557076),
 "fTRX":  ("0x1b596e1fdd1d4895cf30f034ef1b7b6a8942136e", "0xedf53026aea60f8f75fca25f8830b7e2d6200662", 6,  "TRX",    0.33179191812598163),
 "fUSDC": ("0xaee67519049092ab91efd033f7d350d62b9f166b", "0x935faa2fcec6ab81265b301a30467bbc804b43d3", 6,  "USDC_t", 0.9996551067963053),
 "fETH":  ("0xa258bffd5f6814303a718d2b9d34b40e14c66289", "0x1249c65afb11d179ffb3ce7d4eedd1d9b98ad006", 18, "ETH",    2365.2675382778357),
}
SELS = {
 "getCash()": "0x3b1d21a2", "totalBorrows()": "0x47bd3718", "totalReserves()": "0x8f840ddd",
 "totalSupply()": "0x18160ddd", "exchangeRateStored()": "0x182df0f5", "accrualBlockNumber()": "0x6c540baf",
 "borrowIndex()": "0xaa5af0fd", "mintGuardianPaused(address)": "0x731f0c2b", "borrowGuardianPaused(address)": "0x6d154ea5",
}

def call1(to, data, blk, tries=3):
    """eth_call returning word0 only, with length validation & retry."""
    for _ in range(tries):
        r = rpc("bttc", "eth_call", [{"to": to, "data": data}, hex(blk)])
        if r and r != "0x" and len(r) >= 66:
            return int(r[2:66], 16), len(r)
    return None, None

def main():
    blk = block_number("bttc")
    out = {"block": blk, "markets": {}, "notes": "rpc.bt.io returns 96-byte padded returns for some views; word0 used"}
    for n, (a, und, dec, sym, rp) in MK.items():
        vals = {}
        for k, sel in SELS.items():
            data = sel + pad32(a) if "address)" in k else sel
            v, ln = call1(a if "address)" not in k else C, data, blk)
            vals[k] = v
        price, _ = call1(ORACLE, "0xfc57d4df" + pad32(a), blk)
        cash, bor, rsv, sup, er = vals["getCash()"], vals["totalBorrows()"], vals["totalReserves()"], vals["totalSupply()"], vals["exchangeRateStored()"]
        inv_lhs = er * sup // 10**18
        inv_rhs = cash + bor - rsv
        mult = 10.0**-dec
        out["markets"][n] = {
            "market": a, "underlying": und, "symbol": sym, "decimals": dec,
            "cash_units": cash, "borrows_units": bor, "reserves_units": rsv, "totalSupply_wei": sup,
            "exchangeRateStored": er, "accrualBlockNumber": vals["accrualBlockNumber()"],
            "borrowIndex": vals["borrowIndex()"], "mintPaused": vals["mintGuardianPaused(address)"],
            "borrowPaused": vals["borrowGuardianPaused(address)"],
            "oracle_price_raw": price,
            "cash_usd": cash*mult*rp, "borrows_usd": bor*mult*rp, "reserves_usd": rsv*mult*rp,
            "suppliers_claim_usd": (er*sup//10**18)*mult*rp,
            "collateralFactor": 0.8 if n in ("fUSDT","fUSDC","fETH") else 0.5,
            "liqIncentive": 1.2 if n in ("fBTT","fTRX") else 1.15,
            "invariant_ok": inv_rhs - inv_lhs < (10**18 // (sup//10**18+1)) + 1000,
        }
    out["tvl_usd"] = sum(m["cash_usd"]+m["borrows_usd"] for m in out["markets"].values())
    out["reserves_usd"] = sum(m["reserves_usd"] for m in out["markets"].values())
    out["supplier_claims_usd"] = sum(m["suppliers_claim_usd"] for m in out["markets"].values())
    json.dump(out, open("filda_final.json","w"), indent=1)
    for n,m in out["markets"].items():
        print(f"{n:6s} cash=${m['cash_usd']:9.2f} borrows=${m['borrows_usd']:8.2f} reserves=${m['reserves_usd']:8.2f} claims=${m['suppliers_claim_usd']:9.2f} er={m['exchangeRateStored']} inv_ok={m['invariant_ok']} paused={m['mintPaused']}/{m['borrowPaused']}")
    print(f"TVL=${out['tvl_usd']:.2f} reserves=${out['reserves_usd']:.2f} claims=${out['supplier_claims_usd']:.2f}")

if __name__ == "__main__":
    main()
