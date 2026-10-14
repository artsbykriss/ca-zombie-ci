#!/usr/bin/env python3
"""Live value table for EddyFinance AMM pools at block 19473564 (2026-10-14).
Prices: ZetaScan exchange_rate (Blockscout oracle) where available; DefiLlama fallback.
Note: ZRC-20 stablecoins are deeply discounted on ZetaChain (gateway impairment);
      .BSC oracle rates ($0.97/$0.999) disagree with every DEX on the chain (~$0.37/$0.46)."""
import json

pairs = json.load(open("pairs_live.json"))
meta = json.load(open("tokens_live.json"))

# price sources: zetascan rate (USD) ; None = unpriced
P = {
 "0x5f0b1a82749cb4e2278ec87f8bf6b618dc71a8bf": ("WZETA", 0.0449556, "zetascan"),
 "0xd97b1de3619ed2c6beb3860147e30ca8a7dc9891": ("ETH.ETH", 1654.93, "llama"),
 "0x48f80608b672dc30dc7e3dbbd0343c5f02c738eb": ("BNB.BSC", 572.89, "llama"),
 "0x0cbe0df132a6c6b4a2974fa1b7fb953cf0cc798a": ("USDC.ETH", 0.364253, "llama/zetascan"),
 "0x7c8dda80bbbe1254a7aacf3219ebe1481c6e01d7": ("USDT.ETH", 0.458671, "llama/zetascan"),
 "0x05ba149a7bd6dc1f937fa9046a9e05c05f3b18b0": ("USDC.BSC", 0.970245, "zetascan (suspect)"),
 "0x91d4f0d54090df2d81e834c3c8ce71c6c865e79f": ("USDT.BSC", 0.999223, "zetascan (suspect)"),
 "0x13a0c5930c028511dc02665e7285134b6d11a5f4": ("BTC.BTC", 32196.0, "zetascan"),
 "0x45334a5b0a01ce6c260f2b570ec941c680ea62c0": ("stZETA(ZE)", 1.159644709*0.0449556, "vault rate x ZETA"),
 "0xadf73eba3ebaa7254e859549a44c74ef7cff7501": ("POL.POL", 0.087041, "zetascan"),
 "0xcc683a782f4b30c138787cb5576a86af66fdc31d": ("DAI.ETH", None, "n/a"),
 "0x45334a5b": ("stZETA", None, "n/a"),
}

total = 0.0
rows = []
for e in pairs["pairs"]:
    vals = []
    for tok, res in ((e["token0"], e["reserve0"]), (e["token1"], e["reserve1"])):
        dec = meta[tok]["decimals"]
        sym = meta[tok]["symbol"]
        amt = res / 10**dec
        pr = P.get(tok, (sym, None, "n/a"))[1]
        usd = amt * pr if pr else 0.0
        vals.append((sym, amt, pr, usd))
    pair_usd = vals[0][3] + vals[1][3]
    total += pair_usd
    if pair_usd > 1:
        rows.append((e["pair"], vals[0], vals[1], pair_usd))

rows.sort(key=lambda r: -r[3])
print(f"live pair reserves at block {pairs['block']} (priced portion)")
print(f"{'pair':44} {'token0':>26} {'token1':>26} {'USD':>12}")
for p, v0, v1, u in rows:
    f = lambda v: f"{v[0]} {v[1]:,.4f} @ {v[2]}"
    print(f"{p:44} {f(v0):>40} {f(v1):>40} {u:>12,.2f}")
print(f"{'TOTAL (priced)':44} {'':>40} {'':>40} {total:>12,.2f}")

# unpriced tokens with material balances
print("\nunpriced tokens with reserves (value not counted):")
for e in pairs["pairs"]:
    for tok, res in ((e["token0"], e["reserve0"]), (e["token1"], e["reserve1"])):
        if tok not in P and res > 0:
            dec = meta[tok]["decimals"]; sym = meta[tok]["symbol"]
            amt = res/10**dec
            if amt > 0.01:
                print(f"  {sym:12} {amt:>22,.4f} in {e['pair']}")

# farm-staked LP share
print("\nfarm-staked LP (H-O: stakers withdraw their own LP):")
farms = [("0x14a4Ab67b637c366AC58C4F416C297Cd3037bDb3", "0x16Ef1b018026E389FDA93c1e993E987CF6E852E7"),
         ("0xB681eC7C35534bd9131e02A31fe0eb698a81843F", "0x4E77A430a1b8E9055540b2A4aB8364E4E31089ae"),
         ("0xFd9048fC1f26765f60272f4E8B8D1C8faC62EB89", "0x0C0B35C5eF00d9caD8D2ce65b147ea2A27d526Bc")]
staked = {"0x14a4Ab67b637c366AC58C4F416C297Cd3037bDb3": 517192171200346336102,
          "0xB681eC7C35534bd9131e02A31fe0eb698a81843F": 1509633833553791323778,
          "0xFd9048fC1f26765f60272f4E8B8D1C8faC62EB89": 364545382891792}
for f, lp in farms:
    pair = next(x for x in pairs["pairs"] if x["pair"].lower() == lp.lower())
    share = staked[f]/pair["totalSupply"] if pair["totalSupply"] else 0
    # pair USD
    pu = 0.0
    for tok, res in ((pair["token0"], pair["reserve0"]), (pair["token1"], pair["reserve1"])):
        dec = meta[tok]["decimals"]; pr = P.get(tok, (None,None,None))[1]
        if pr: pu += res/10**dec*pr
    print(f"  farm {f}: {share*100:.1f}% of pair {lp} (~${pu*share:,.2f} of ${pu:,.2f})")
