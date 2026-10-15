#!/usr/bin/env python3
"""Reconstruct early history: reserve/stake/fee samples, ATA derivation checks, initial deposits."""
import json, sys, time, base64, hashlib
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import rpc, b58encode, b58decode, pda

ATA_PROG = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
MINT = "phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG"
POOL = "phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG"
WATCH = {"pool": POOL, "reserve": "phaseECAeXantYWXvRGkmeh7ddQsUJTf7DcywquY9Z2",
         "stake8QtQ": "8QtQ1U34DPs2UKQiwUoRPMHnjJedsmdASZdbQHa7VHKh",
         "mint": MINT, "fee": "GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U",
         "vlist": "phaseeExd43yGjjad2FZSigdG9UTRpMdxS4aMerx821",
         "withdraw_auth": "9HYjrCF5evTobLmay372kpUWSNTrtmDU2NkQtqjdnHKa"}
rev = {v: k for k, v in WATCH.items()}
OUT = {}

def ata(owner, mint):
    a, b = pda([b58decode(owner), b58decode(TOKEN), b58decode(mint)], ATA_PROG)
    return a

# ATA checks
for label, owner in [("7LqS(squads vault)", "7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1"),
                     ("phaseGat2(creator)", "phaseGat2zkWtpMPbjPJWWj2EVN4tFR1HN4EqtwUzit"),
                     ("phaseUTHS(sol withdraw auth)", "phaseUTHSD78uiD8rnRQWuvbEakvY1chNSeftkpvz6d")]:
    a = ata(owner, MINT)
    print(f"ATA(YIELD, {label}) = {a}")
    OUT.setdefault("ata_derivations", {})[label] = a
print("state says fee account = GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U")
print("creation tx mintTo went to 3Y3bNqaRLFiG8w3wUUE82oEsbMwc8NjnJ5QLyn39APPU")

# 3Y3b account
time.sleep(1.2)
r = rpc("getAccountInfo", ["3Y3bNqaRLFiG8w3wUUE82oEsbMwc8NjnJ5QLyn39APPU", {"encoding": "jsonParsed"}])
OUT["3Y3bNqaR"] = r.get("value")
print("3Y3b:", json.dumps(r.get("value"), indent=1)[:400])

# find old manager: check some old deposit txs
db = json.load(open("/home/heisenberg/CA/phase-stake/analysis/mb_sigs.json"))
reserve_sigs = db["reserve"]["sigs"]
stake_sigs = db["stake8QtQ"]["sigs"]
fee_sigs = db["fee"]["sigs"]

def analyze_tx(sig, idx_label):
    time.sleep(1.2)
    try:
        tx = rpc("getTransaction", [sig, {"maxSupportedTransactionVersion": 0, "encoding": "jsonParsed"}])
    except Exception as e:
        print("  fail", sig[:20], str(e)[:100]); return None
    if not tx:
        return None
    m = tx["meta"]; msg = tx["transaction"]["message"]
    keys = [k["pubkey"] for k in msg["accountKeys"]]
    la = msg.get("loadedAddresses") or {}
    keys += la.get("writable", []) + la.get("readOnly", [])
    deltas = {}
    for j, k in enumerate(keys):
        d = m["postBalances"][j] - m["preBalances"][j]
        if d and (k in WATCH.values() or abs(d) >= 10_000_000_000):
            deltas[rev.get(k, k[:8])] = d
    ops = []
    for ix in msg["instructions"]:
        pid = ix.get("programId", "?")
        if pid == "SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn":
            ops.append({"program": "SPMBzs", "data": str(ix.get("data"))[:20], "accounts": ix.get("accounts")})
        else:
            ops.append({"program": pid[:14], "data": str(ix.get("data"))[:20]})
    for b in m.get("innerInstructions") or []:
        for ix in b["instructions"]:
            pid = ix.get("programId")
            if pid == "SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn":
                ops.append({"program": "SPMBzs(inner)", "data": str(ix.get("data"))[:20], "accounts": ix.get("accounts")})
    yd = {}
    for bal in m.get("preTokenBalances", []):
        if bal["mint"] == MINT:
            yd[bal["owner"]] = yd.get(bal["owner"], 0) - int(bal["uiTokenAmount"]["amount"])
    for bal in m.get("postTokenBalances", []):
        if bal["mint"] == MINT:
            yd[bal["owner"]] = yd.get(bal["owner"], 0) + int(bal["uiTokenAmount"]["amount"])
    yd = {k: v for k, v in yd.items() if v}
    rec = {"label": idx_label, "slot": tx["slot"], "blockTime": tx["blockTime"], "err": m["err"],
           "fee": m["fee"], "payer": keys[0], "all_keys": keys, "ops": ops,
           "sol_deltas": deltas, "yield_deltas": yd}
    print(f'  {idx_label}: slot {tx["slot"]} bt {tx["blockTime"]} payer {keys[0][:12]} fee {m["fee"]}')
    print(f'     ops: {json.dumps(ops)[:400]}')
    print(f'     SOL: {json.dumps(deltas)}')
    print(f'     YIELD: {json.dumps(yd)}')
    return rec

samples = []
print("\n=== reserve oldest 8 txs (April 2024 era) ===")
for i in range(0, 8):
    r2 = analyze_tx(reserve_sigs[i]["signature"], f"reserve[{i}] bt={reserve_sigs[i]['blockTime']}")
    if r2: samples.append(r2)
print("\n=== reserve spread samples ===")
for f in (0.05, 0.2, 0.45, 0.7, 0.9):
    i = int(f * (len(reserve_sigs) - 1))
    r2 = analyze_tx(reserve_sigs[i]["signature"], f"reserve[{i}] bt={reserve_sigs[i]['blockTime']}")
    if r2: samples.append(r2)
print("\n=== stake8QtQ oldest 4 txs ===")
for i in range(0, 4):
    r2 = analyze_tx(stake_sigs[i]["signature"], f"stake8QtQ[{i}] bt={stake_sigs[i]['blockTime']}")
    if r2: samples.append(r2)
print("\n=== fee account: all oldest 5 ===")
for i in range(0, min(5, len(fee_sigs))):
    r2 = analyze_tx(fee_sigs[i]["signature"], f"fee[{i}] bt={fee_sigs[i]['blockTime']}")
    if r2: samples.append(r2)

JSONOUT = "/home/heisenberg/CA/phase-stake/analysis/history_samples.json"
json.dump({"samples": samples, "ata_derivations": OUT.get("ata_derivations"), "3Y3b": OUT.get("3Y3bNqaR")},
          open(JSONOUT, "w"), indent=2)
print("\nsaved", JSONOUT)
