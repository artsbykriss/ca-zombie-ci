"""Final liquidation-profitability analysis from the CI scan (positions2.json).

Profit rule (Compound): a liquidator repays R of debt and seizes 1.05*R nominal of
collateral. The collateral is only worth cash at the market's true cash ratio
rho = cash / (cash + borrows - reserves). Profit = R * (1.05*rho - 1), so only
markets with rho > 0.9524 are profitable. Seizable collateral is capped by the
borrower's balance.

Reads ci-artifacts/result-orbit-protocol/ci-out/positions2.json.
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "..", "ci-artifacts", "result-orbit-protocol", "ci-out", "positions2.json")

# market -> (cash, borrows, reserves) raw underlying units (verified reads 2026-10-14)
M = {
    "0xf92996ddc677a8dcb032ac5fe62bbf00f92ae2ec": (43988628869122, 1061353907120762, 1005120837472023),
    "0x9aecedcd6a82d26f2f86d331b17a1c1676442a87": (63723584275331133032497, 52170693068977873633326, 898673053067176775449),
    "0xf9b3b455f5d900f62bc1792a6ca6e1d47b989389": (53825135219381941563, 5135614187733804587, 13537863000000000),
    "0x0872b71efc37cb8dde22b2118de3d800427fdba0": (143471291963961746088, 34977179567143257669, 124641350000000000),
    "0x8c415331761063e5d6b1c8e700f996b13603fc2e": (489430, 611728, 373900),
    "0x795dcd51eac6eb3123b7a4a1f906992eaa54cb0e": (9174863762532532945, 95706371161513175, 43769687000000000),
    "0x4991b902f397dc16b0bbd21b0057a20b4b357ae2": (8220120131778910544, 0, 0),
    "0xb51b76c73fb24f472e0dd63bb8195bd2170bc65d": (341061647564991163, 172730312152299541, 19113255000000000),
    "0xafabd582e82042f4a8574f75c36409abea916ac5": (0, 0, 5699333200000000000000),
    "0x9bbba6322fe5f3968c1f27c8b860727d683194c8": (1265548077755198259, 0, 0),
    "0xd55634a79e571dc4c7cdd2f2c0a5857bf7a8a782": (500955589781465776, 1176911134391554953, 19113255000000000),
    "0xfb661cdcfcb62b4ed7bbef6f70068863e213cb6b": (24812034129007478, 0, 0),
    "0xa3135b76c28b3971b703a5e6cd451531b187eb5a": (285041392884344883, 181183307182505486956828, 36114353301573580000000),
    "0x4adf85e2e760c9211894482df74ba535bcae50a4": (15845955806501657, 7327273572191783155387559, 1308703573516171500000000),
    "0x3a61f4bf054cdfac3a3436a21c4463c6d85c2408": (1892217752813832621371, 5745413077546427229068992, 1144067214044684300000000),
    "0x7732e29e35e8a8b26e7f026c0865c7c2d88cf853": (1234636237480297414715, 0, 140000000000000000),
    "0x586abb06179535de9eb6c6d968a355128dd74511": (9985211600000000000000, 93625178476493867047, 0),
    "0x530a8d3fdf61112f8a879d753fe02e9e37ec36aa": (538497764765334795, 27018039602395315, 61902088000000000),
    "0xe9391d8e1d5c970f7648852ffeda1a9f42833857": (206703000000000004, 0, 0),
    "0x7878c119f08052789f84cf4fdd3c3642fa291257": (100000000000000000, 0, 0),
}


def main():
    d = json.load(open(ART))
    rows = d["all"]
    rhos = {}
    for m, (cash, borr, res) in M.items():
        claims = cash + borr - res
        rhos[m] = (cash / claims) if claims > 0 else None
    print("true cash ratios rho (cash/claims):")
    for m, r in sorted(rhos.items(), key=lambda x: -(x[1] or 0)):
        print(f"  {m} rho={r if r is None else round(r,6)}")

    total_realizable = 0.0
    total_profit = 0.0
    hits = []
    for r in rows:
        if r["shortfall_usd"] <= 1:
            continue
        real = 0.0
        det = []
        for m, p in r["positions"].items():
            if not isinstance(p, dict) or p.get("cTokens", 0) == 0:
                continue
            rho = rhos.get(m)
            if rho and rho > 0.9524:
                real += p.get("realizable_usd", 0)
                det.append((p["label"], p.get("realizable_usd"), rho))
        if real > 0.5:
            total_realizable += real
            total_profit += 0.05 * real
            hits.append({"borrower": r["borrower"], "shortfall_usd": r["shortfall_usd"],
                         "realizable_usd": round(real, 2), "positions": det})
    print(f"\nunderwater accounts (shortfall>$1): {sum(1 for r in rows if r['shortfall_usd']>1)}")
    print(f"underwater accounts with profitable-collateral (rho>0.9524): {len(hits)}")
    print(f"total realizable collateral in profitable markets: ${total_realizable:,.2f}")
    print(f"=> max liquidation profit (5% of that): ${total_profit:,.2f}")
    for h in sorted(hits, key=lambda x: -x["realizable_usd"])[:15]:
        print(f"  {h['borrower']} shortfall=${h['shortfall_usd']:,.0f} realizable=${h['realizable_usd']:,.2f} {h['positions']}")
    out = {"rhos": rhos, "hits": hits, "total_realizable_usd": round(total_realizable, 2),
           "max_liquidation_profit_usd": round(total_profit, 2)}
    with open(os.path.join(HERE, "liquidation_profit.json"), "w") as f:
        json.dump(out, f, indent=1)
    print("\nwrote liquidation_profit.json")


if __name__ == "__main__":
    main()
