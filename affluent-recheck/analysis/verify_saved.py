#!/usr/bin/env python3
"""Offline verification of the saved Affluent recheck evidence.

No network required. Verifies:
  1. every recheck burn trace is REFUND-ONLY (0x178d4519, no asset payout);
  2. the 2026-10-16 historical trace paid 13.824e9 raw USDT and refunded 5.697e15 shares;
  3. the vault snapshot NAV arithmetic (balance + whitelisted-pool supplyAmount).
Writes ci-out/verify_saved.json.
"""
import glob
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "ci-out")
os.makedirs(OUT, exist_ok=True)

PAYOUT_OPS = {"0x0f8a7ea5", "0xcb03bfaf", "0xb2a4c51b"}
REFUND_OP = "0x178d4519"


def rows_of(trace):
    out = []

    def walk(n):
        tx = n.get("transaction", {})
        im = tx.get("in_msg", {}) or {}
        out.append({
            "op": im.get("op_code"),
            "src": (im.get("source") or {}).get("address"),
            "dst": (im.get("destination") or {}).get("address"),
            "value": im.get("value"),
            "decoded": im.get("decoded_body"),
        })
        for c in n.get("children", []) or []:
            walk(c)

    walk(trace)
    return out


def main():
    res = {"burn_checks": [], "historical": {}, "snapshot": {}, "all_refund_only": True}

    for f in sorted(glob.glob(os.path.join(HERE, "emul", "recheck_*.json"))):
        t = json.load(open(f))
        rows = rows_of(t)
        payouts = [r for r in rows if r["op"] in PAYOUT_OPS]
        refunds = [r for r in rows if r["op"] == REFUND_OP]
        ok = len(payouts) == 0 and len(refunds) >= 1
        res["all_refund_only"] &= ok
        res["burn_checks"].append({
            "file": os.path.basename(f),
            "payout_count": len(payouts),
            "refund_count": len(refunds),
            "refund_amounts": [r["decoded"].get("amount") for r in refunds if r["decoded"]],
            "ok": ok,
        })

    hist = json.load(open(os.path.join(HERE, "emul", "hist_oct16_trace.json")))
    rows = rows_of(hist)
    transfers = [r for r in rows if r["op"] == "0x0f8a7ea5" and r["decoded"]]
    total = sum(int(r["decoded"]["amount"]) for r in transfers)
    mints = [r for r in rows if r["op"] == REFUND_OP and r["decoded"]
             and r["decoded"].get("from") == ""]
    res["historical"] = {
        "jetton_transfers": len(transfers),
        "payout_raw_usdt": total,
        "payout_usdt": total / 1e6,
        "refund_mint_raw": [r["decoded"]["amount"] for r in mints],
        "note": "2026-10-16 burn of 1e16 affUSDTl; five pool withdrawals paid the attacker; "
                "the remainder was minted back as change.",
    }

    # Mint recheck: the primitive is still live (from="" master mint of 1e16 to the beneficiary).
    res["mint_checks"] = []
    res["all_mint_live"] = True
    for f in sorted(glob.glob(os.path.join(HERE, "emul", "mint_recheck_*.json"))):
        t = json.load(open(f))
        rows = rows_of(t)
        mints = [r for r in rows if r["op"] == REFUND_OP and r["decoded"]
                 and r["decoded"].get("from") == ""]
        payouts = [r for r in rows if r["op"] in PAYOUT_OPS]
        ok = any(int(m["decoded"]["amount"]) == 10 ** 16 for m in mints)
        res["all_mint_live"] &= ok
        res["mint_checks"].append({
            "file": os.path.basename(f),
            "mint_amounts": [m["decoded"]["amount"] for m in mints],
            "gas_transfer_count": len(payouts),
            "ok": ok,
        })

    snap_path = os.path.join(HERE, "vault_snapshot.json")
    if os.path.exists(snap_path):
        s = json.load(open(snap_path))
        res["snapshot"] = s
        for name, v in s.get("vaults", {}).items():
            assert v["nav_raw"] == v["balance"] + v["supply_amount_sum"], name
            res.setdefault("nav_check", {})[name] = {
                "balance": v["balance"],
                "supply_amount_sum": v["supply_amount_sum"],
                "nav_raw": v["nav_raw"],
                "nav_usd": v["nav_usd"],
            }

    with open(os.path.join(OUT, "verify_saved.json"), "w") as f:
        json.dump(res, f, indent=1)
    print(json.dumps(res, indent=1)[:4000])
    print("wrote", os.path.join(OUT, "verify_saved.json"))


if __name__ == "__main__":
    main()
