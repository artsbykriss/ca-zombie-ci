#!/usr/bin/env python3
"""Quantify live Loopscale-curated Exponent vault exposure (read-only).
AUM is denominated in each vault's underlying base units.
"""
import json, base64, struct, urllib.request, time, sys
sys.path.insert(0, "/home/heisenberg/CA/loopscale/analysis")
from decode_vaults import rpc, b58e, decode, CURATOR  # reuse

SOL = "So11111111111111111111111111111111111111112"
USDC = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
USDE = "DEkqHyPN7GMRJ5cArtQFAWefqbZb33Hyf6s5iCwjEonT"
SYNTH = {"USD1111111111111111111111111111111111111111": USDC,
         "USD1111111111111111111111111111111111111119": USDE}
DEC = {SOL: 9, USDC: 6, USDE: 6}

def llama_prices(mints):
    q = ",".join(f"solana:{m}" for m in mints)
    d = json.load(urllib.request.urlopen("https://coins.llama.fi/prices/current/" + q, timeout=60))
    return {k.split(":")[1]: v["price"] for k, v in d["coins"].items()}

if __name__ == "__main__":
    slot = rpc("getSlot", [])["result"]
    accs = rpc("getProgramAccounts", ["sVau1tXvayVWfotzm9Ahcv2qfnnfRWttt78BCnNC6dD", {
        "encoding": "base64",
        "filters": [{"memcmp": {"offset": 0, "bytes": b58e(bytes([98,228,39,201,116,210,39,11]))}}]}])["result"]
    rows = []
    for a in accs:
        raw = base64.b64decode(a["account"]["data"][0])
        try:
            d = decode(raw)
        except Exception:
            continue
        if CURATOR not in d["curators"]:
            continue
        d["pubkey"] = a["pubkey"]; rows.append(d)
    mints = sorted({SYNTH.get(r["underlying"], r["underlying"]) for r in rows})
    prices = llama_prices(mints)
    total = 0.0
    print(f"slot {slot}  vaults {len(rows)}")
    out = []
    for r in rows:
        mint = SYNTH.get(r["underlying"], r["underlying"])
        dec = DEC.get(mint, 6)
        amt = r["aum"] / 10**dec
        usd = amt * prices.get(mint, 0)
        if r["status"] == 8:
            usd = 0.0
        total += usd
        out.append(dict(pubkey=r["pubkey"], underlying=r["underlying"], mapped_mint=mint,
                        status=r["status"], aum_base=r["aum"], amount=round(amt, 4),
                        price=prices.get(mint), usd=round(usd, 2), positions=r["positions"]))
        print(f"  {r['pubkey']}  {mint[:8]}  aum={r['aum']:>16}  = {amt:>14.4f}  ${usd:>12,.2f}")
    print(f"TOTAL live (Loopscale-curated Exponent vaults) = ${total:,.2f}")
    json.dump(dict(slot=slot, curator=CURATOR, prices=prices, total_usd=round(total, 2), vaults=out),
              open("/home/heisenberg/CA/loopscale/analysis/loopscale_exposure.json", "w"), indent=1)
