#!/usr/bin/env python3
"""TASK 2c: deep analysis of all fetched txs: full ix tree, YIELD token deltas, lamport deltas."""
import json, sys
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import b58encode, b58decode

MINT = "phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG"
WATCH = {
    "pool": "phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG",
    "reserve": "phaseECAeXantYWXvRGkmeh7ddQsUJTf7DcywquY9Z2",
    "stake8QtQ": "8QtQ1U34DPs2UKQiwUoRPMHnjJedsmdASZdbQHa7VHKh",
    "mint": MINT,
    "fee": "GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U",
    "vlist": "phaseeExd43yGjjad2FZSigdG9UTRpMdxS4aMerx821",
    "withdraw_auth": "9HYjrCF5evTobLmay372kpUWSNTrtmDU2NkQtqjdnHKa",
    "manager_pda": "7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1",
    "sol_withdraw_auth": "phaseUTHSD78uiD8rnRQWuvbEakvY1chNSeftkpvz6d",
}
rev = {v: k for k, v in WATCH.items()}
txs = json.load(open("/home/heisenberg/CA/phase-stake/analysis/history_txs.json"))

programs = {}

def key_list(tx):
    msg = tx["transaction"]["message"]
    keys = [k["pubkey"] for k in msg["accountKeys"]]
    la = msg.get("loadedAddresses")
    if la:
        keys += la.get("writable", []) + la.get("readOnly", [])
    return keys

def ix_summary(ix, keys):
    pid = ix.get("programId", "?")
    pname = programs.get(pid, pid[:10])
    if "parsed" in ix and isinstance(ix["parsed"], dict):
        t = ix["parsed"].get("type")
        info = ix["parsed"].get("info", {})
        short = {k: (str(v)[:24] if not isinstance(v, dict) else v) for k, v in list(info.items())[:6]}
        return f"{pname}:{t} {json.dumps(short)[:220]}"
    else:
        d = ix.get("data", "")
        return f"{pname}:raw(data={d[:20]}) accounts={len(ix.get('accounts', []))}"

out = []
for sig, obj in sorted(txs.items(), key=lambda kv: (kv[1]["tx"]["slot"] if kv[1]["tx"] else 0)):
    tx = obj["tx"]
    if not tx:
        continue
    m = tx["meta"]
    keys = key_list(tx)
    msg = tx["transaction"]["message"]
    signers = [k["pubkey"] for k in msg["accountKeys"] if k.get("signer")]
    deltas = {}
    for i, k in enumerate(keys):
        d = m["postBalances"][i] - m["preBalances"][i]
        if d and (k in WATCH.values() or abs(d) >= 1_000_000_000):
            deltas[rev.get(k, k[:6])] = d
    # YIELD token deltas
    tok = {}
    for bal in m.get("preTokenBalances", []):
        if bal["mint"] == MINT:
            tok.setdefault(bal["owner"], 0)
            tok[bal["owner"]] -= int(bal["uiTokenAmount"]["amount"])
    for bal in m.get("postTokenBalances", []):
        if bal["mint"] == MINT:
            tok.setdefault(bal["owner"], 0)
            tok[bal["owner"]] += int(bal["uiTokenAmount"]["amount"])
    tok = {k: v for k, v in tok.items() if v}
    tops = [ix_summary(ix, keys) for ix in msg["instructions"]]
    inners = []
    for inner in m.get("innerInstructions", []) or []:
        for ix in inner["instructions"]:
            inners.append(ix_summary(ix, keys))
    rec = {
        "sig": sig, "slot": tx["slot"], "blockTime": tx["blockTime"], "fee": m["fee"],
        "payer": keys[0], "signers": signers, "err": m["err"],
        "lamport_deltas": deltas, "yield_deltas": tok,
        "top": tops, "inner": inners,
        "log_head": (m.get("logMessages") or [])[:14],
    }
    out.append(rec)
    for ix in msg["instructions"]:
        pid = ix.get("programId")
        if pid:
            programs.setdefault(pid, pid)

json.dump(out, open("/home/heisenberg/CA/phase-stake/analysis/history_analysis.json", "w"), indent=1)
print("=== distinct programs ===")
for p in sorted(programs):
    print(p)
print()
for rec in out:
    print(f'--- slot {rec["slot"]} {rec["blockTime"]} fee={rec["fee"]} payer={rec["payer"][:6]}..{rec["payer"][-4:]}')
    print("   top:", " | ".join(rec["top"])[:400])
    if rec["inner"]:
        print("   inner:", " | ".join(rec["inner"])[:600])
    if rec["lamport_deltas"]:
        print("   SOL:", json.dumps(rec["lamport_deltas"]))
    if rec["yield_deltas"]:
        print("   YIELD:", json.dumps(rec["yield_deltas"]))
