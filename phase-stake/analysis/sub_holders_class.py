#!/usr/bin/env python3
"""Holder classification + Squads vault PDA check + reserve/stake-history sampling for donations."""
import json, sys, time, base64, hashlib
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import rpc, b58decode, b58encode, on_curve, pda

OUT = {}
# --- 1) concentration
tg = json.load(open("/home/heisenberg/CA/phase-stake/analysis/token_gpa_holders.json"))
accs = tg["accounts"]
supply = 25123581135630
def share(n):
    a = sum(x["amount"] for x in accs[:n])
    return a, a / supply
OUT["concentration"] = {f"top{n}": {"amount": share(n)[0], "share": share(n)[1]} for n in (1, 2, 3, 4, 5, 10, 15, 25, 50)}
print("concentration:", json.dumps(OUT["concentration"], indent=1))
print("n_accounts:", tg["count"])

# --- 2) classify top 15 holders
cls = {}
for h in accs[:15]:
    o = h["owner"]
    time.sleep(1.2)
    try:
        r = rpc("getAccountInfo", [o, {"encoding": "base64"}])
        v = r.get("value")
        if v is None:
            cls[o] = {"exists": False, "on_curve": on_curve(b58decode(o))}
        else:
            dl = len(base64.b64decode(v["data"][0])) if v["data"] else 0
            cls[o] = {"exists": True, "owner_program": v["owner"], "executable": v["executable"],
                      "lamports": v["lamports"], "datalen": dl, "on_curve": on_curve(b58decode(o))}
    except Exception as e:
        cls[o] = {"error": str(e)[:120]}
    print(f'{h["amount"]:>18d} {o}  token_acct={h["token_account"]}  {json.dumps(cls[o])[:160]}')
OUT["top15_classification"] = cls

# --- 3) Squads vault PDA check
msig = "GRe1iCBEeAMdEeFmEMavgXJE8Uk8tU82pyxZ4iXXAD1v"
SQDS = "SQDS4ep65T869zMMBKyuUq6aD6EgTu8psMjkvj52pCf"
for idx in range(3):
    a, b = pda([b"multisig", b58decode(msig), b"vault", bytes([idx])], SQDS)
    print(f"Squads multisig {msig} vault[{idx}] ->", a, "bump", b)
    OUT.setdefault("squads_vaults", {})[f"vault{idx}"] = a
OUT["manager_is_squads_vault"] = OUT["squads_vaults"].get("vault0") == "7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1"
print("manager == multisig vault[0]?", OUT["manager_is_squads_vault"])

# --- 4) reserve + stake sampling (from complete histories)
db = json.load(open("/home/heisenberg/CA/phase-stake/analysis/mb_sigs.json"))
WATCH = {"pool": "phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG",
         "reserve": "phaseECAeXantYWXvRGkmeh7ddQsUJTf7DcywquY9Z2",
         "stake8QtQ": "8QtQ1U34DPs2UKQiwUoRPMHnjJedsmdASZdbQHa7VHKh",
         "mint": "phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG",
         "fee": "GAGMZfQU5ArnaciyQBnDLDsEpbbhpyqPR24t98WYL4n6U"}
WATCH["fee"] = "GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U"
rev = {v: k for k, v in WATCH.items()}

def pick(sigs, n_head, fracs):
    idxs = list(range(min(n_head, len(sigs))))
    for f in fracs:
        i = int(f * (len(sigs) - 1))
        if i not in idxs:
            idxs.append(i)
    return idxs

samples = {}
for name, head in (("reserve", 8), ("stake8QtQ", 6)):
    sigs = db[name]["sigs"]
    idxs = pick(sigs, head, [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.97])
    print(f"\n{name}: n={len(sigs)} sampling {len(idxs)} txs, oldest bt {sigs[-1]['blockTime']}")
    for i in idxs:
        s = sigs[i]
        time.sleep(1.2)
        try:
            tx = rpc("getTransaction", [s["signature"], {"maxSupportedTransactionVersion": 0, "encoding": "jsonParsed"}])
        except Exception as e:
            print("  fail", s["signature"][:16], str(e)[:80]); continue
        if not tx:
            continue
        m = tx["meta"]; msg = tx["transaction"]["message"]
        keys = [k["pubkey"] for k in msg["accountKeys"]]
        la = msg.get("loadedAddresses") or {}
        keys += la.get("writable", []) + la.get("readOnly", [])
        deltas = {}
        for j, k in enumerate(keys):
            d = m["postBalances"][j] - m["preBalances"][j]
            if d and (k in WATCH.values() or abs(d) >= 5_000_000_000):
                deltas[rev.get(k, k[:8])] = d
        progs = []
        for ix in msg["instructions"]:
            progs.append(ix.get("programId", "?")[:12])
        for b in m.get("innerInstructions") or []:
            for ix in b["instructions"]:
                progs.append("in:" + (ix.get("programId") or "?")[:12])
        logged = [l for l in (m.get("logMessages") or []) if "Instruction:" in l][:8]
        yd = {}
        for bal in m.get("preTokenBalances", []):
            if bal["mint"] == WATCH["mint"]:
                yd[bal["owner"]] = yd.get(bal["owner"], 0) - int(bal["uiTokenAmount"]["amount"])
        for bal in m.get("postTokenBalances", []):
            if bal["mint"] == WATCH["mint"]:
                yd[bal["owner"]] = yd.get(bal["owner"], 0) + int(bal["uiTokenAmount"]["amount"])
        yd = {k: v for k, v in yd.items() if v}
        rec = {"idx": i, "slot": s["slot"], "blockTime": s["blockTime"], "err": s["err"],
               "fee": m["fee"], "payer": keys[0], "programs": progs, "sol_deltas": deltas,
               "yield_deltas": yd, "ix_logs": logged}
        samples[f"{name}:{i}"] = rec
        print(f'  {name}[{i}] slot {s["slot"]} bt {s["blockTime"]} payer {keys[0][:8]} progs={sorted(set(progs))[:6]} sol={json.dumps(deltas)}')
OUT["samples"] = samples
json.dump(OUT, open("/home/heisenberg/CA/phase-stake/analysis/holder_class_and_samples.json", "w"), indent=2)
print("\nsaved holder_class_and_samples.json")
