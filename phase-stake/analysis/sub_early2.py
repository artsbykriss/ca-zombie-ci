#!/usr/bin/env python3
"""Corrected early-history sampling (oldest txs) + fee account authority."""
import json, sys, time
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import rpc, b58decode

MINT = "phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG"
WATCH = {"pool": "phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG",
         "reserve": "phaseECAeXantYWXvRGkmeh7ddQsUJTf7DcywquY9Z2",
         "stake8QtQ": "8QtQ1U34DPs2UKQiwUoRPMHnjJedsmdASZdbQHa7VHKh",
         "mint": MINT, "fee": "GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U",
         "vlist": "phaseeExd43yGjjad2FZSigdG9UTRpMdxS4aMerx821",
         "withdraw_auth": "9HYjrCF5evTobLmay372kpUWSNTrtmDU2NkQtqjdnHKa"}
rev = {v: k for k, v in WATCH.items()}

print("== fee account authority")
time.sleep(1.2)
r = rpc("getAccountInfo", ["GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U", {"encoding": "jsonParsed"}])
print(json.dumps(r["value"]["data"]["parsed"], indent=1))
fee_auth = r["value"]["data"]["parsed"]["info"]["owner"]
print("FEE AUTHORITY:", fee_auth)

db = json.load(open("/home/heisenberg/CA/phase-stake/analysis/mb_sigs.json"))

def analyze_tx(sig, label, keep_keys=False):
    time.sleep(1.2)
    try:
        tx = rpc("getTransaction", [sig, {"maxSupportedTransactionVersion": 0, "encoding": "jsonParsed"}])
    except Exception as e:
        print("  fail", sig[:20], str(e)[:90]); return None
    if not tx:
        print("  no tx", sig[:20]); return None
    m = tx["meta"]; msg = tx["transaction"]["message"]
    keys = [k["pubkey"] for k in msg["accountKeys"]]
    la = msg.get("loadedAddresses") or {}
    keys += la.get("writable", []) + la.get("readOnly", [])
    deltas = {}
    for j, k in enumerate(keys):
        d = m["postBalances"][j] - m["preBalances"][j]
        if d and (k in WATCH.values() or abs(d) >= 100_000_000):
            deltas[rev.get(k, k[:8])] = d
    ops = []
    for ix in msg["instructions"]:
        pid = ix.get("programId", "?")
        entry = {"p": (rev.get(pid, pid[:16]))}
        if "parsed" in ix and isinstance(ix["parsed"], dict):
            entry["t"] = ix["parsed"].get("type")
            info = ix["parsed"].get("info", {})
            if isinstance(info, dict):
                entry["i"] = {k2: (str(v2)[:28]) for k2, v2 in list(info.items())[:8] if not isinstance(v2, dict)}
        else:
            entry["data"] = str(ix.get("data"))[:20]
        ops.append(entry)
    for b in m.get("innerInstructions") or []:
        for ix in b["instructions"]:
            if ix.get("programId") == "SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn" or "parsed" in ix:
                entry = {"p": "in:" + (ix.get("programId") or "?")[:12]}
                if "parsed" in ix and isinstance(ix["parsed"], dict):
                    entry["t"] = ix["parsed"].get("type")
                    info = ix["parsed"].get("info", {})
                    if isinstance(info, dict):
                        entry["i"] = {k2: (str(v2)[:30]) for k2, v2 in list(info.items())[:8] if not isinstance(v2, dict)}
                else:
                    entry["data"] = str(ix.get("data"))[:20]
                if ix.get("programId") == "SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn":
                    entry["accounts"] = ix.get("accounts")
                ops.append(entry)
    yd = {}
    for bal in m.get("preTokenBalances", []):
        if bal["mint"] == MINT:
            yd[bal["owner"]] = yd.get(bal["owner"], 0) - int(bal["uiTokenAmount"]["amount"])
    for bal in m.get("postTokenBalances", []):
        if bal["mint"] == MINT:
            yd[bal["owner"]] = yd.get(bal["owner"], 0) + int(bal["uiTokenAmount"]["amount"])
    yd = {k: v for k, v in yd.items() if v}
    rec = {"label": label, "sig": sig, "slot": tx["slot"], "blockTime": tx["blockTime"], "err": m["err"],
           "fee": m["fee"], "payer": keys[0], "ops": ops, "sol_deltas": deltas, "yield_deltas": yd}
    if keep_keys:
        rec["all_keys"] = keys
    print(f'\n  {label}: slot {tx["slot"]} bt {tx["blockTime"]} err={m["err"]} fee={m["fee"]} payer={keys[0][:14]}')
    print(f'    ops: {json.dumps(ops)[:700]}')
    print(f'    SOL: {json.dumps(deltas)}')
    print(f'    YIELD: {json.dumps(yd)}')
    return rec

samples = []
print("\n=== reserve: 10 OLDEST txs (list is newest-first) ===")
rs = db["reserve"]["sigs"]
for i in range(1, 11):
    idx = len(rs) - i
    r2 = analyze_tx(rs[idx]["signature"], f"reserve[-{i}] slot~{rs[idx]['slot']}")
    if r2: samples.append(r2)

print("\n=== reserve: mid-history samples ===")
for f in (0.1, 0.35, 0.6, 0.85):
    idx = int(f * (len(rs) - 1))
    r2 = analyze_tx(rs[idx]["signature"], f"reserve[mid{int(f*100)}] slot~{rs[idx]['slot']}")
    if r2: samples.append(r2)

print("\n=== stake8QtQ: 4 OLDEST txs ===")
ss = db["stake8QtQ"]["sigs"]
for i in range(1, 5):
    idx = len(ss) - i
    r2 = analyze_tx(ss[idx]["signature"], f"stake8QtQ[-{i}] slot~{ss[idx]['slot']}")
    if r2: samples.append(r2)

print("\n=== fee account: 8 OLDEST of 15 ===")
fs = db["fee"]["sigs"]
for i in range(1, 9):
    idx = len(fs) - i
    r2 = analyze_tx(fs[idx]["signature"], f"fee[-{i}] slot~{fs[idx]['slot']}", keep_keys=True)
    if r2: samples.append(r2)

print("\n=== mint creation tx (oldest mint sig) ===")
ms = db["mint"]["sigs"]
r2 = analyze_tx(ms[-1]["signature"], f"mint[-1] slot~{ms[-1]['slot']}")
if r2: samples.append(r2)

json.dump({"fee_authority": fee_auth, "samples": samples},
          open("/home/heisenberg/CA/phase-stake/analysis/history_early2.json", "w"), indent=2)
print("\nsaved history_early2.json")
