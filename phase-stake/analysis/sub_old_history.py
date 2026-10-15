#!/usr/bin/env python3
"""Timeline: 3Y3b (old fee acct) newest sig, multisig creation, old deposit txs via mainnet-beta."""
import json, sys, time, urllib.request, base64
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import b58decode, b58encode, pda

URL = "https://api.mainnet-beta.solana.com"

def post(method, params, timeout=50):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(URL, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def call(method, params, tries=20, tag=""):
    for i in range(tries):
        try:
            d = post(method, params)
            if "result" in d:
                return d["result"]
            print(tag, "try", i, str(d.get("error"))[:100], flush=True)
        except Exception as e:
            print(tag, "try", i, "exc", str(e)[:80], flush=True)
        time.sleep(min(40, 8 + i * 4))
    return None

MINT = "phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG"
ATA_PROG = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"

def ata(owner):
    a, b = pda([b58decode(owner), b58decode(TOKEN), b58decode(MINT)], ATA_PROG)
    return a

res = {}
for lbl, ow in [("Gutj91DY", "Gutj91DY4ZS7TCJzCUVMRdDhT9U2ccsDy4fgn74WawgL"),
                ("phaseGat2", "phaseGat2zkWtpMPbjPJWWj2EVN4tFR1HN4EqtwUzit"),
                ("7LqS(squads vault)", "7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1"),
                ("GRe1iCBE(multisig)", "GRe1iCBEeAMdEeFmEMavgXJE8Uk8tU82pyxZ4iXXAD1v")]:
    res.setdefault("atas", {})[lbl] = ata(ow)
    print(f"ATA(YIELD, {lbl}) = {ata(ow)}")
print("current fee acct state: GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U")
print("old fee acct (creation): 3Y3bNqaRLFiG8w3wUUE82oEsbMwc8NjnJ5QLyn39APPU")

# 3Y3b newest sig
r = call("getSignaturesForAddress", ["3Y3bNqaRLFiG8w3wUUE82oEsbMwc8NjnJ5QLyn39APPU", {"limit": 3}], tag="3Y3b")
if r is not None:
    res["3Y3b_sigs"] = r
    print("\n3Y3b newest sigs:")
    for s in r:
        print("  slot", s["slot"], "bt", s["blockTime"], "err", s["err"])

# multisig history (creation date?)
time.sleep(2)
r = call("getSignaturesForAddress", ["GRe1iCBEeAMdEeFmEMavgXJE8Uk8tU82pyxZ4iXXAD1v", {"limit": 1000}], tag="msig")
if r is not None:
    res["msig_sigs_n"] = len(r)
    res["msig_oldest"] = r[-1]
    res["msig_newest"] = r[0]
    print(f"\nmultisig sigs: {len(r)} newest slot {r[0]['slot']} bt {r[0]['blockTime']}; oldest slot {r[-1]['slot']} bt {r[-1]['blockTime']}")

# old reserve txs via mainnet-beta: indices from the end
db = json.load(open("/home/heisenberg/CA/phase-stake/analysis/mb_sigs.json"))
rs = db["reserve"]["sigs"]
print(f"\nreserve sigs n={len(rs)}; oldest bt={rs[-1]['blockTime']}")

def get_tx(sig, label):
    for i in range(8):
        time.sleep(4)
        tx = call("getTransaction", [sig, {"maxSupportedTransactionVersion": 0, "encoding": "jsonParsed"}], tries=1, tag=label)
        if tx:
            return tx
    return None

def summarize(tx, label):
    if not tx:
        print(label, "NOT FOUND"); return None
    m = tx["meta"]; msg = tx["transaction"]["message"]
    keys = [k["pubkey"] for k in msg["accountKeys"]]
    la = msg.get("loadedAddresses") or {}
    keys += la.get("writable", []) + la.get("readOnly", [])
    ops = []
    for ix in msg["instructions"]:
        e = {"p": ix.get("programId", "?")[:16]}
        if "parsed" in ix and isinstance(ix["parsed"], dict):
            e["t"] = ix["parsed"].get("type")
            info = ix["parsed"].get("info", {})
            if isinstance(info, dict):
                e["i"] = {k2: str(v2)[:26] for k2, v2 in list(info.items())[:6] if not isinstance(v2, dict)}
        else:
            e["data"] = str(ix.get("data"))[:18]
        ops.append(e)
    for b in m.get("innerInstructions") or []:
        for ix in b["instructions"]:
            e = {"p": "in:" + (ix.get("programId") or "?")[:14]}
            if "parsed" in ix and isinstance(ix["parsed"], dict):
                e["t"] = ix["parsed"].get("type")
                info = ix["parsed"].get("info", {})
                if isinstance(info, dict):
                    e["i"] = {k2: str(v2)[:26] for k2, v2 in list(info.items())[:6] if not isinstance(v2, dict)}
            else:
                e["data"] = str(ix.get("data"))[:18]
            if ix.get("programId") == "SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn":
                e["accounts"] = ix.get("accounts")
            ops.append(e)
    yd = {}
    for bal in m.get("preTokenBalances", []):
        if bal["mint"] == MINT:
            yd[bal["owner"]] = yd.get(bal["owner"], 0) - int(bal["uiTokenAmount"]["amount"])
    for bal in m.get("postTokenBalances", []):
        if bal["mint"] == MINT:
            yd[bal["owner"]] = yd.get(bal["owner"], 0) + int(bal["uiTokenAmount"]["amount"])
    yd = {k: v for k, v in yd.items() if v}
    print(f'\n  {label}: slot {tx["slot"]} bt {tx["blockTime"]} err={m["err"]} payer={keys[0][:14]}')
    print(f'    ops: {json.dumps(ops)[:800]}')
    print(f'    YIELD deltas: {json.dumps(yd)}')
    return {"label": label, "slot": tx["slot"], "blockTime": tx["blockTime"], "err": m["err"],
            "payer": keys[0], "ops": ops, "yield_deltas": yd, "keys": keys}

out = []
for i in (1, 2, 3, 4, 5, 6, 8, 12, 30, 100):
    idx = len(rs) - i
    s = rs[idx]
    r2 = summarize(get_tx(s["signature"], f"reserve[-{i}]"), f"reserve[-{i}] slot~{s['slot']}")
    if r2:
        out.append(r2)
        json.dump({"res": res, "old_txs": out}, open("/home/heisenberg/CA/phase-stake/analysis/old_history.json", "w"), indent=2)
