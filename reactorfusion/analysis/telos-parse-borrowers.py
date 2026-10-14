#!/usr/bin/env python3
"""Parse saved comptroller logs (Borrow/RepayBorrow/LiquidateBorrow) into
telos-borrowers.json (borrower set + decoded events). No network, no secrets."""
import json, os

OUT = os.path.dirname(os.path.abspath(__file__))

def addr(w):
    return "0x" + w[-40:]

def main():
    borrow = json.load(open(os.path.join(OUT, "telos-logs-comptroller-Borrow.json")))
    repay = json.load(open(os.path.join(OUT, "telos-logs-comptroller-RepayBorrow.json")))
    liq = json.load(open(os.path.join(OUT, "telos-logs-comptroller-LiquidateBorrow.json")))
    res = {"counts": {"Borrow": len(borrow), "RepayBorrow": len(repay), "LiquidateBorrow": len(liq)},
           "borrow_events": [], "repay_events": [], "liquidations": []}
    bset = set()
    for l in borrow:
        d = l["data"][2:]
        ev = {"block": int(l["blockNumber"], 16), "ctoken": addr(d[0:64]), "borrower": addr(d[64:128]),
              "amount": int(d[128:192], 16), "accountBorrows": int(d[192:256], 16),
              "totalBorrows": int(d[256:320], 16), "tx": l["transactionHash"]}
        res["borrow_events"].append(ev); bset.add(ev["borrower"])
    for l in repay:
        d = l["data"][2:]
        ev = {"block": int(l["blockNumber"], 16), "ctoken": addr(l["topics"][1]), "payer": addr(d[0:64]),
              "borrower": addr(d[64:128]), "repayAmount": int(d[128:192], 16),
              "accountBorrows": int(d[192:256], 16), "totalBorrows": int(d[256:320], 16), "tx": l["transactionHash"]}
        res["repay_events"].append(ev); bset.add(ev["borrower"])
    for l in liq:
        d = l["data"][2:]
        ev = {"block": int(l["blockNumber"], 16), "ctoken": addr(l["topics"][1]), "liquidator": addr(d[0:64]),
              "borrower": addr(d[64:128]), "repayAmount": int(d[128:192], 16),
              "ctokenCollateral": addr(d[192:256]), "seizeTokens": int(d[256:320], 16), "tx": l["transactionHash"]}
        res["liquidations"].append(ev); bset.add(ev["borrower"])
    res["borrowers"] = sorted(bset)
    print("borrowers:", len(bset))
    json.dump(res, open(os.path.join(OUT, "telos-borrowers.json"), "w"), indent=1)

    # cross-check vs prelim borrowers from Borrow-only
    old = set()
    for ev in res["borrow_events"]:
        old.add(ev["borrower"])
    extra = sorted(bset - old)
    print("borrowers not in Borrow events:", extra)

if __name__ == "__main__":
    main()
