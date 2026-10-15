#!/usr/bin/env python3
"""Re-derive the genuinely-liquidatable set with the PROGRAM's own oracle prices and the
program-exact emode rule (see program_health.py). Scans every MarginfiAccount balance dump.

Inputs:
  analysis/state/banks_decoded.json, oracles_raw.json
  /tmp/opencode/mfi-data/balances_all.json (getProgramAccounts dataSlice: balances region)

Outputs (analysis/):
  rederived_underwater.json  - accounts failing the program maintenance health check
  rederived_stats.json       - counts, totals, unsupported-bank census
"""
import base64, json, os, re, struct, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mfi_common import b58encode, rpc
from program_health import (BankState, PriceEngine, account_health, ORACLE_SETUP)

HERE = os.path.dirname(os.path.abspath(__file__))
STATE = os.path.join(HERE, "state")
BALANCES = os.environ.get("BALANCES_FILE", "/tmp/opencode/mfi-data/balances_all.json")
ENTRY_RE = re.compile(rb'"pubkey":"([1-9A-HJ-NP-Za-km-z]{32,44})","account":\{[^}]*?"data":\["([A-Za-z0-9+/=]+)"')
I80F48 = 1 << 48


def decode_balances(raw, base=0):
    out = []
    for i in range(16):
        o = base + i * 104
        if o + 104 > len(raw):
            break
        if not raw[o]:
            continue
        bank = b58encode(raw[o + 1:o + 33])
        a = int.from_bytes(raw[o + 40:o + 56], "little", signed=True) / I80F48
        l = int.from_bytes(raw[o + 56:o + 72], "little", signed=True) / I80F48
        prem = int.from_bytes(raw[o + 72:o + 88], "little", signed=True) / I80F48
        out.append({"bank": bank, "asset_shares": a, "liability_shares": l,
                    "premium_outstanding": prem})
    return out


def main():
    banks_raw = json.load(open(os.path.join(STATE, "banks_decoded.json")))
    oracles = json.load(open(os.path.join(STATE, "oracles_raw.json")))
    meta = json.load(open(os.path.join(STATE, "meta.json")))
    epoch = rpc("getEpochInfo", [])["epoch"]
    now = meta["fetched_at"]   # staleness is judged at the oracle fetch snapshot
    banks = {pk: BankState(pk, b) for pk, b in banks_raw.items()}
    prices = PriceEngine(banks, oracles, epoch, now)
    print(f"banks={len(banks)} epoch={epoch} snapshot_now={now}")

    # price status census
    from collections import Counter
    st = Counter()
    for pk in banks:
        st[prices.price(pk)["status"]] += 1
    print("price status census:", dict(st))

    data = open(BALANCES, "rb").read()
    print(f"balances dump {len(data)/1e6:.0f} MB")
    t0 = time.time()
    n = 0
    underwater = []
    unsupported_census = Counter()
    acct_unsupported = 0
    total_dep = total_bor = 0.0
    for m in ENTRY_RE.finditer(data):
        n += 1
        pk = m.group(1).decode()
        raw = base64.b64decode(m.group(2))
        bals = decode_balances(raw)
        if not bals:
            continue
        r = account_health(bals, banks, prices)
        if r["unsupported"]:
            acct_unsupported += 1
            for u in r["unsupported"]:
                unsupported_census[u["reason"]] += 1
            continue
        dep = sum(d["value"] for d in r["detail"] if d["side"] == "asset")
        bor = sum(d["value"] for d in r["detail"] if d["side"] == "liab")
        total_dep += dep
        total_bor += bor
        if r["health"] < 0:
            underwater.append({
                "account": pk,
                "health_usd": round(r["health"], 2),
                "deficit_usd": round(-r["health"], 2),
                "asset_value_maint_usd": round(r["asset_value_maint"], 2),
                "liability_value_maint_usd": round(r["liability_value_maint"], 2),
                "detail": r["detail"],
                "reconciled_emode": {str(k): round(v, 4) for k, v in r["reconciled_emode"].items()},
            })
    print(f"scanned {n} accounts in {time.time()-t0:.0f}s; underwater {len(underwater)}; "
          f"accounts w/ unsupported banks {acct_unsupported}")
    underwater.sort(key=lambda r: -r["deficit_usd"])
    out = {
        "slot_meta": json.load(open(os.path.join(STATE, "meta.json"))),
        "epoch": epoch, "now": now,
        "accounts_scanned": n,
        "accounts_with_unsupported_banks": acct_unsupported,
        "unsupported_census": dict(unsupported_census),
        "n_underwater_maint": len(underwater),
        "underwater_total_deficit_usd": round(sum(r["deficit_usd"] for r in underwater), 2),
        "top_underwater": underwater[:200],
        "all_underwater": underwater,
    }
    json.dump(out, open(os.path.join(HERE, "rederived_underwater.json"), "w"), indent=1)
    print(json.dumps({k: v for k, v in out.items() if k != "top_underwater"}, indent=1))
    for r in underwater[:20]:
        print(f"  {r['account']} deficit ${r['deficit_usd']:,.2f} "
              f"(av ${r['asset_value_maint_usd']:,.0f} lv ${r['liability_value_maint_usd']:,.0f})")


if __name__ == "__main__":
    main()
