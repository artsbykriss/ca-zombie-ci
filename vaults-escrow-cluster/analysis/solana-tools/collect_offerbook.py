#!/usr/bin/env python3
"""Collect Offerbook state (read-only) and value escrow with Jupiter prices.

Usage: python3 collect_offerbook.py
Outputs evidence/offerbook_state.json and prints aggregates.
"""
import base64, json, time, urllib.request
import rpc, pda, decode_offerbook as D

PROG = "offerbkFMvVfpQhL8ZQ5iromnjct5rz3r52B9ewu3ie"
PID = pda.b58decode(PROG)
ATA_PROG = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
USDC = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"

def load_raw(path):
    j = json.load(open(path))
    return j["slot"], {x["pubkey"]: base64.b64decode(x["account"]["data"][0]) for x in j["accounts"]}

def fetch_balances(keys):
    bal = {}
    keys = list(keys)
    for i in range(0, len(keys), 100):
        chunk = keys[i:i+100]
        r = rpc.rpc("getMultipleAccounts", [chunk, {"encoding": "jsonParsed", "commitment": "confirmed"}])
        for k, a in zip(chunk, r["value"]):
            if a is None:
                bal[k] = None; continue
            d = a["data"]
            if isinstance(d, dict) and d.get("parsed") and d["parsed"].get("type") == "account":
                info = d["parsed"]["info"]
                bal[k] = {"amount": int(info["tokenAmount"]["amount"]),
                          "decimals": info["tokenAmount"]["decimals"],
                          "owner": info["owner"], "mint": info["mint"]}
            else:
                bal[k] = {"other": str(d)[:80]}
    return bal

def prices(mints):
    out = {}
    mints = [m for m in mints if m]
    for i in range(0, len(mints), 50):
        chunk = mints[i:i+50]
        url = "https://lite-api.jup.ag/price/v3?ids=" + ",".join(chunk)
        try:
            with urllib.request.urlopen(url, timeout=30) as r:
                j = json.loads(r.read())
            for m, v in j.items():
                if isinstance(v, dict):
                    out[m] = v.get("usdPrice")
        except Exception as e:
            print("price err", e)
    return out

def main():
    import struct
    slot, offers_raw = load_raw("evidence/offerbook_offers_raw.json")
    _, loans_raw = load_raw("evidence/offerbook_loans_raw.json")
    _, users_raw = load_raw("evidence/offerbook_users_raw.json")
    offers = {k: D.decode_offer(d) for k, d in offers_raw.items()}
    loans = {k: D.decode_loan(d) for k, d in loans_raw.items()}
    users = {k: D.decode_user(d) for k, d in users_raw.items()}

    offer_esc = {}
    for k, o in offers.items():
        if o["status"] not in (0, 1): continue
        a = o["principal"] if o["side"] == 0 else o["collateral"]
        amt = o["remaining_principal"] if o["side"] == 0 else o["remaining_collateral"]
        if a["kind"] != "token": continue
        up, _ = pda.user_pda(o["creator"])
        ta, _ = pda.ata(up, a["token_program"], a["mint"])
        e = offer_esc.setdefault(ta, {"mint": a["mint"], "claimed": 0, "offers": []})
        e["claimed"] += amt; e["offers"].append(k)

    loan_esc = {}
    for k, l in loans.items():
        if l["status"] not in (0, 2): continue
        if l["collateral"]["kind"] != "token": continue
        up, _ = pda.user_pda(l["borrower"])
        ta, _ = pda.ata(up, l["collateral"]["token_program"], l["collateral"]["mint"])
        loan_esc[ta] = {"loan": k, "mint": l["collateral"]["mint"],
                        "collateral_amount": l["collateral_amount"], "status": l["status"]}

    loan_vaults = {}
    for k, l in loans.items():
        if l["status"] in (0, 2):
            p, _ = pda.find_program_address([b"loan_vault", pda.b58decode(k)], PID)
            loan_vaults[p] = {"loan": k,
                              "mint": l["principal"]["mint"] if l["principal"]["kind"] == "token" else None,
                              "status": l["status"]}

    all_keys = list(offer_esc) + list(loan_esc) + list(loan_vaults)
    bal = fetch_balances(all_keys)
    mints = {v["mint"] for v in bal.values() if v and v.get("mint")}
    px = prices(mints)

    def agg(keys, meta):
        rows = {}
        for k in keys:
            b = bal.get(k); m = meta[k].get("mint")
            if not b or "amount" not in b: continue
            r = rows.setdefault(m, {"raw": 0, "dec": b["decimals"], "usd": 0.0, "accounts": 0})
            r["raw"] += b["amount"]; r["accounts"] += 1
            p = px.get(m)
            if p: r["usd"] += b["amount"] / 10 ** b["decimals"] * p
        return rows

    offer_rows = agg(list(offer_esc), offer_esc)
    coll_rows = agg(list(loan_esc), {k: {"mint": v["mint"]} for k, v in loan_esc.items()})
    vault_rows = agg(list(loan_vaults), {k: {"mint": v["mint"]} for k, v in loan_vaults.items()})

    def show(name, rows):
        print(f"--- {name}")
        tot = 0
        for m, r in sorted(rows.items(), key=lambda x: -x[1]["usd"]):
            if r["raw"] == 0: continue
            print(f"  {m} ui={r['raw']/10**r['dec']:.6f} usd={r['usd']:.2f} accts={r['accounts']}")
            tot += r["usd"]
        print(f"  TOTAL USD {tot:.2f}")
        return tot

    t1 = show("open-offer escrow", offer_rows)
    t2 = show("loan collateral escrow (active+defaulted)", coll_rows)
    t3 = show("loan vaults", vault_rows)

    out = {
        "slot": slot,
        "program": PROG,
        "programdata": "ANwCXRSc7vwD1WpdFE7LmsWTzjq9Xbp7R7JmATgAFXzA",
        "upgrade_authority": "GpYnS3dPdR4Abj6pf3XbtU2kC8kgN6Lz5y6CuyFt4N79",
        "config": "5bjsMDacvtuRjtSD4j4ARsfP6Ras3dywyyuvsbbnXNQk",
        "yield_market": "GSYR6JQ9YmwP35SaDbzxQnWJJ6heCCkteaUAQtSKasYV",
        "prices": px,
        "offer_escrow": offer_rows, "loan_collateral": coll_rows, "loan_vaults": vault_rows,
        "totals_usd": {"open_offers": t1, "loan_collateral": t2, "loan_vaults": t3,
                       "total": t1 + t2 + t3},
        "counts": {"offers": len(offers), "loans": len(loans), "users": len(users),
                   "open_offers": sum(1 for o in offers.values() if o["status"] in (0,1)),
                   "active_loans": sum(1 for l in loans.values() if l["status"] == 0),
                   "defaulted_loans": sum(1 for l in loans.values() if l["status"] == 2)},
        "user_map": users, "offer_escrows": offer_esc,
        "loan_collateral_accounts": loan_esc, "loan_vault_accounts": loan_vaults,
        "balances": bal,
        "offers": offers, "loans": loans,
    }
    json.dump(out, open("evidence/offerbook_state.json", "w"))
    print("slot", slot, out["counts"])
    print("TOTAL USD", out["totals_usd"]["total"])

if __name__ == "__main__":
    main()
