#!/usr/bin/env python3
"""Main Project 0 group: vault balances + USD (batched). Read-only."""
import json, sys, os, base64, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sol import get_multiple, get_account_info, get_slot, b58enc, is_on_curve_b58

GROUP = "4qp6Fx6tnZkY5Wropq9wUYgtFxXKwE6viZxFHg3rdAG8"
HERE = os.path.dirname(os.path.abspath(__file__))

def llama(mints):
    url = "https://coins.llama.fi/prices/current/" + ",".join(f"solana:{m}" for m in mints)
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent":"audit/1.0"}), timeout=30) as r:
            return json.load(r).get("coins", {})
    except Exception as e:
        return {"_err": str(e)}

def main():
    st = json.load(open(os.path.join(HERE, "live_state.json")))
    banks = [b for b in st["banks"] if b["group"] == GROUP]
    print("main group banks:", len(banks))
    gv = get_account_info(GROUP)
    admin = b58enc(base64.b64decode(gv["data"][0])[8:40])
    print("group admin:", admin, "on_curve=", is_on_curve_b58(admin), "space=", gv.get("space"))
    keys = []
    for b in banks:
        keys.append(b["liquidity_vault"]); keys.append(b["insurance_vault"])
    amounts = {}
    for i in range(0, len(keys), 100):
        chunk = keys[i:i+100]
        vals = get_multiple(chunk)
        for k, v in zip(chunk, vals or []):
            if v:
                raw = base64.b64decode(v["data"][0])
                amounts[k] = int.from_bytes(raw[64:72], "little")
    mints = sorted({b["mint"] for b in banks})
    prices = llama(mints)
    tot_liq = 0.0; tot_ins = 0.0; rows = []
    for b in banks:
        lv = amounts.get(b["liquidity_vault"], 0)
        iv = amounts.get(b["insurance_vault"], 0)
        dec = b["decimals"]; px = (prices.get("solana:"+b["mint"]) or {}).get("price")
        lv_h = lv / 10**dec; iv_h = iv / 10**dec
        usd = lv_h * px if px else None
        if usd: tot_liq += usd
        if px: tot_ins += iv_h * px
        rows.append({"bank": b["pubkey"], "mint": b["mint"], "decimals": dec,
                     "liq_raw": lv, "liq_human": round(lv_h, 6), "ins_human": round(iv_h, 6),
                     "price": px, "liq_usd": round(usd, 2) if usd else None})
    rows.sort(key=lambda r: (r["liq_usd"] or 0), reverse=True)
    out = {"slot": get_slot(), "group": GROUP, "admin": admin, "bank_count": len(banks),
           "total_liquidity_usd": round(tot_liq, 2), "total_insurance_usd": round(tot_ins, 2),
           "priced": len([r for r in rows if r["liq_usd"] is not None]), "banks": rows}
    print(json.dumps({k: out[k] for k in ["slot","group","admin","bank_count","total_liquidity_usd","total_insurance_usd","priced"]}, indent=1))
    for r in rows[:25]:
        print(f"  {r['mint'][:10]} dec={r['decimals']:2d} liq={r['liq_human']:>16.4f} px={r['price']} usd={r['liq_usd']}")
    with open(os.path.join(HERE, "group_banks.json"), "w") as f:
        json.dump(out, f, indent=1)

if __name__ == "__main__":
    main()
