#!/usr/bin/env python3
"""TASK 2b: fetch EVERY unique transaction touching Phase YIELD pool accounts (read-only).
Uses getTransaction with maxSupportedTransactionVersion=0, jsonParsed."""
import json, sys, time
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import rpc

SIGS = "/home/heisenberg/CA/phase-stake/analysis/history_sigs.json"
OUT = "/home/heisenberg/CA/phase-stake/analysis/history_txs.json"
WATCH = {
    "pool": "phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG",
    "reserve": "phaseECAeXantYWXvRGkmeh7ddQsUJTf7DcywquY9Z2",
    "stake8QtQ": "8QtQ1U34DPs2UKQiwUoRPMHnjJedsmdASZdbQHa7VHKh",
    "mint": "phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG",
    "fee": "GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U",
    "manager_pda": "7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1",
    "vlist": "phaseeExd43yGjjad2FZSigdG9UTRpMdxS4aMerx821",
    "withdraw_auth": "9HYjrCF5evTobLmay372kpUWSNTrtmDU2NkQtqjdnHKa",
    "sol_withdraw_auth": "phaseUTHSD78uiD8rnRQWuvbEakvY1chNSeftkpvz6d",
}

data = json.load(open(SIGS))
uniq = {}
for name, d in data.items():
    for s in d["sigs"]:
        uniq.setdefault(s["signature"], {"slot": s["slot"], "blockTime": s.get("blockTime"), "err": s.get("err")})
print("unique sigs:", len(uniq))

try:
    txdb = json.load(open(OUT))
except Exception:
    txdb = {}

done = 0
for sig, meta in uniq.items():
    if sig in txdb:
        continue
    time.sleep(1.25)
    try:
        tx = rpc("getTransaction", [sig, {"maxSupportedTransactionVersion": 0, "encoding": "jsonParsed"}])
    except Exception as e:
        print("FAIL", sig, str(e)[:120])
        continue
    txdb[sig] = {"sigMeta": meta, "tx": tx}
    done += 1
    if done % 5 == 0:
        json.dump(txdb, open(OUT, "w"), indent=1)
        print("...", done, flush=True)

json.dump(txdb, open(OUT, "w"), indent=1)
print("saved", OUT, "with", len(txdb), "txs (new:", done, ")")

# --- summary ---
def w(x):
    for k, v in WATCH.items():
        if v == x:
            return k
    return x[:8]

rows = []
for sig, obj in txdb.items():
    tx = obj["tx"]
    if not tx:
        rows.append((sig, None, "NOT FOUND"))
        continue
    m = tx["meta"]
    keys = [k["pubkey"] for k in tx["transaction"]["message"]["accountKeys"]]
    pre, post = m["preBalances"], m["postBalances"]
    deltas = {}
    for i, k in enumerate(keys):
        d = post[i] - pre[i]
        if d and (k in WATCH.values() or abs(d) >= 1_000_000_000):
            deltas[w(k) + f"({k[:4]})"] = d
    tops = []
    for ix in tx["transaction"]["message"]["instructions"]:
        if "parsed" in ix:
            t = ix["parsed"].get("type") if isinstance(ix["parsed"], dict) else None
            tops.append(f'{ix["program"]}:{t}')
        else:
            tops.append(f'{ix.get("programId","?")[:12]}:{ix.get("program","")[:28]}')
    rows.append((sig, tx["slot"], tx["blockTime"], m["err"], m["fee"], tops, deltas))

rows.sort(key=lambda r: r[1] if r[1] else 0)
print(f"\n{'slot':>12} {'time':>10} {'fee':>8} ops")
for r in rows:
    if len(r) == 3:
        print(r[2], r[0][:20]); continue
    sig, slot, tb, err, fee, tops, deltas = r
    print(f"{slot:>12} {tb:>10} {fee:>8} err={bool(err)} {sig[:20]}")
    print("    ops:", "; ".join(tops))
    if deltas:
        print("    dlamports:", json.dumps(deltas))
