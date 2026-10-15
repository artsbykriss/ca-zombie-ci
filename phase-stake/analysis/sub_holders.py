#!/usr/bin/env python3
"""TASK 1: YIELD holder distribution (read-only, keyless public RPC)."""
import json, sys, time, base64
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import rpc, b58decode, on_curve

MINT = "phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG"
OUT = "/home/heisenberg/CA/phase-stake/analysis/holders.json"

res = {"mint": MINT, "note": "read-only public RPC"}
res["epoch"] = rpc("getEpochInfo", [])
time.sleep(1.5)
res["supply"] = rpc("getTokenSupply", [MINT])
time.sleep(1.5)
res["largest"] = rpc("getTokenLargestAccounts", [MINT])

supply = int(res["supply"]["value"]["amount"])
res["supply_raw"] = supply

holders = []
for i, h in enumerate(res["largest"]["value"]):
    addr = h["address"]
    time.sleep(1.2)
    v = rpc("getAccountInfo", [addr, {"encoding": "jsonParsed"}])
    val = v.get("value")
    e = {"rank": i + 1, "token_account": addr,
         "raw_amount": h.get("amount"), "ui_amount_string": h.get("uiAmountString")}
    if val is None:
        e["exists"] = False
    else:
        e["exists"] = True
        e["acct_lamports"] = val["lamports"]
        p = val["data"]["parsed"]["info"]
        e["owner"] = p["owner"]
        e["token_program"] = val["owner"]
        e["amount"] = p["tokenAmount"]["amount"]
        e["decimals"] = p["tokenAmount"]["decimals"]
        e["delegate"] = p.get("delegate")
        e["state"] = p.get("state")
        e["on_curve_owner"] = on_curve(b58decode(p["owner"]))
    holders.append(e)
res["holders"] = holders

# fetch each distinct owner's account info to classify (program/multisig/EOA)
owners = []
for h in holders:
    if h.get("owner") and h["owner"] not in owners:
        owners.append(h["owner"])
owner_info = {}
for o in owners:
    time.sleep(1.2)
    try:
        ai = rpc("getAccountInfo", [o, {"encoding": "base64"}])
        v = ai.get("value")
        if v is None:
            owner_info[o] = {"exists": False, "on_curve": on_curve(b58decode(o))}
        else:
            dl = len(base64.b64decode(v["data"][0])) if v["data"] else 0
            owner_info[o] = {"exists": True, "executable": v["executable"],
                             "owner_program": v["owner"], "lamports": v["lamports"],
                             "datalen": dl, "on_curve": on_curve(b58decode(o))}
    except Exception as ex:
        owner_info[o] = {"error": str(ex)}
res["owner_info"] = owner_info

# concentration
def share(n):
    amt = sum(int(h.get("amount", h.get("raw_amount", "0"))) for h in holders[:n])
    return amt, (amt / supply if supply else 0)

a1, s1 = share(1)
a5, s5 = share(5)
a10, s10 = share(10)
a15, s15 = share(len(holders))
res["concentration"] = {
    "supply_raw": supply,
    "top1_amount": a1, "top1_share": s1,
    "top5_amount": a5, "top5_share": s5,
    "top10_amount": a10, "top10_share": s10,
    "topN_amount": a15, "topN_share": s15, "n": len(holders),
    "pool_account_itself_holds": None,
}
# sanity: does the pool-adjacent fee account appear?
res["fee_account_in_top"] = [h for h in holders if h.get("owner") == "GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U"]

json.dump(res, open(OUT, "w"), indent=2)
print("supply:", supply, res["supply"]["value"]["uiAmountString"], "decimals", res["supply"]["value"]["decimals"])
for h in holders:
    print(f'{h["rank"]:2d} {h["token_account"]} amt={h.get("amount","?")} owner={h.get("owner","?"):44s} oncurve={h.get("on_curve_owner")}')
print("top1 share %.6f  top5 %.6f  topN %.6f" % (s1, s5, s15))
for o, i in owner_info.items():
    print(o, i)
