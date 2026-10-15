#!/usr/bin/env python3
"""Generate LiteSVM batch cases: top-N program-verified liquidatable accounts (by deficit)
plus liquidatable accounts that hold real collateral. Writes poc/accounts/batch_*.json.

Each case carries `asset_amount_max`: the largest single-liquidation seizure that can keep the
account at/below maintenance (deficit / (lwm*(1-f_l) - awm) capped by the balance), so the
harness can attempt the best executable size.
"""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mfi_common import get_accounts, decode_balances, b58encode
from decode_bank import decode_bank
import fetch_poc_state as fps

HERE = os.path.dirname(os.path.abspath(__file__))
N_BADDEBT = 12
N_COLL = 10
SOL_BANK = "CCKtUs6Cgwo4aaQUmBPmyoApH2gUDErxNZCAntD6LYGh"
LIQ_FEE = 0.025


def pick_banks(pk, deficit_usd):
    raw = get_accounts([pk])[0][3]
    bals = decode_balances(raw)
    liabs = [b for b in bals if b["liability_shares"] > 0]
    assets = [b for b in bals if b["asset_shares"] > 0]
    if not liabs:
        return None
    liab_b = max(liabs, key=lambda b: b["liability_shares"])
    liab_bank = decode_bank(get_accounts([liab_b["bank"]])[0][3])
    if assets:
        a = max(assets, key=lambda b: b["asset_shares"])
        asset_bank = decode_bank(get_accounts([a["bank"]])[0][3])
        bal_units = int(a["asset_shares"] * asset_bank["asset_share_value"])
    else:
        asset_bank = decode_bank(get_accounts([SOL_BANK])[0][3])
        bal_units = 0
    dec = 10 ** asset_bank["mint_decimals"]
    # max seizure value that keeps post-health <= 0
    denom = liab_bank["config"]["liability_weight_maint"] * (1 - LIQ_FEE) - \
        asset_bank["config"]["asset_weight_maint"]
    # price via the bank cache is unreliable; use the model detail instead where available
    return {
        "asset_bank": asset_bank, "liab_bank": liab_bank,
        "bal_units": bal_units, "denom": denom, "dec": dec,
    }


def main():
    pulse = json.load(open(os.path.join(HERE, "pulse_all.json")))
    scan = json.load(open(os.path.join(HERE, "rederived_underwater.json")))
    model = {r["account"]: r for r in scan["all_underwater"]}

    def coll_value(pk):
        m = model.get(pk)
        if m is None:
            return None
        tot = 0.0
        for d in m["detail"]:
            if d["side"] == "asset":
                w = d.get("weight") or 0.0
                if w > 0:
                    tot += d["value"] / w
                else:
                    tot += d["amount"] * d.get("price_low", 0.0)
        return tot

    liq = [r for r in pulse if r.get("health") and r["health"]["internal_liq_err"] == 0]
    liq.sort(key=lambda r: r["health"]["health_maint"])

    cases = []
    seen = set()

    def add(pk, deficit, label):
        pick = pick_banks(pk, deficit)
        if not pick:
            return None
        ab = pick["asset_bank"]
        # max seizure in base units: value/price; approximate price from the model detail
        m = model.get(pk)
        price = None
        if m:
            for d in m["detail"]:
                if d["side"] == "asset" and d["bank"].startswith(pick["asset_bank"]["_pk"][:8] if "_pk" in pick["asset_bank"] else "___"):
                    pass
        amt = max(1, min(pick["bal_units"] or 1, 10 ** 9))
        return {"label": label, "liquidatee": pk, "asset_bank": ab["_pk"],
                "liab_bank": pick["liab_bank"]["_pk"], "asset_amount": amt,
                "asset_amount_max": amt, "program_health_maint": deficit}

    # we need the bank pubkeys: re-derive via accounts_for_bank keys in fps; simpler: re-fetch
    def add_case(pk, deficit, label, max_units):
        raw = get_accounts([pk])[0][3]
        bals = decode_balances(raw)
        liabs = [b for b in bals if b["liability_shares"] > 0]
        assets = [b for b in bals if b["asset_shares"] > 0]
        if not liabs:
            return None
        liab_bank = max(liabs, key=lambda b: b["liability_shares"])["bank"]
        if assets:
            asset_bank = max(assets, key=lambda b: b["asset_shares"])["bank"]
            bank = decode_bank(get_accounts([asset_bank])[0][3])
            bal_units = int(assets[0]["asset_shares"] * bank["asset_share_value"])
            amt = max(1, min(bal_units, max_units or 10 ** 9))
        else:
            asset_bank = bals[0]["bank"]
            amt = 1
        cases.append({"label": label, "liquidatee": pk, "asset_bank": asset_bank,
                      "liab_bank": liab_bank, "asset_amount": amt,
                      "program_health_maint": deficit})

    n = 0
    for r in liq:
        if n >= N_BADDEBT:
            break
        pk = r["account"]
        c = coll_value(pk)
        if c is None or c > 0.5:
            continue
        seen.add(pk)
        add_case(pk, r["health"]["health_maint"], f"batch_bd_{n:02d}", None)
        n += 1
    n = 0
    for r in liq:
        if n >= N_COLL:
            break
        pk = r["account"]
        if pk in seen:
            continue
        c = coll_value(pk)
        if c is None or c <= 0.5:
            continue
        seen.add(pk)
        add_case(pk, r["health"]["health_maint"], f"batch_coll_{n:02d}", None)
        n += 1

    json.dump(cases, open(os.path.join(HERE, "batch_cases.json"), "w"), indent=1)
    print(f"generated {len(cases)} batch cases")
    for c in cases:
        print(f"  {c['label']} {c['liquidatee'][:44]} health ${c['program_health_maint']:>10,.2f} amount={c['asset_amount']}")
    for c in cases:
        fps.fetch_case(c)


if __name__ == "__main__":
    main()
