#!/usr/bin/env python3
"""Final targeted fetches via mainnet-beta: mint creation, first CiTY stake op, fee-account switch txs,
top1-holder controller, Squads multisig decode."""
import json, sys, time, urllib.request, base64, struct
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import b58decode, b58encode

URL = "https://api.mainnet-beta.solana.com"
MINT = "phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG"

def post(method, params, timeout=50):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(URL, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def call(method, params, tries=15, tag=""):
    for i in range(tries):
        try:
            d = post(method, params)
            if "result" in d:
                return d["result"]
            print(" ", tag, "try", i, str(d.get("error"))[:90], flush=True)
        except Exception as e:
            print(" ", tag, "try", i, "exc", str(e)[:70], flush=True)
        time.sleep(min(40, 8 + i * 4))
    return None

def get_tx(sig, label, tries=6):
    for i in range(tries):
        time.sleep(3)
        tx = call("getTransaction", [sig, {"maxSupportedTransactionVersion": 0, "encoding": "jsonParsed"}], tries=2, tag=label)
        if tx:
            return tx
    print(f"  {label}: NOT FOUND")
    return None

def summarize(tx, label, verbose=True):
    if not tx:
        return None
    m = tx["meta"]; msg = tx["transaction"]["message"]
    keys = [k["pubkey"] for k in msg["accountKeys"]]
    la = msg.get("loadedAddresses") or {}
    keys += la.get("writable", []) + la.get("readOnly", [])
    ops = []
    for ix in msg["instructions"]:
        e = {"p": ix.get("programId", "?")[:18]}
        if "parsed" in ix and isinstance(ix["parsed"], dict):
            e["t"] = ix["parsed"].get("type")
            info = ix["parsed"].get("info", {})
            if isinstance(info, dict):
                e["i"] = {k2: str(v2)[:30] for k2, v2 in list(info.items())[:7] if not isinstance(v2, dict)}
        else:
            e["data"] = str(ix.get("data"))[:20]
        ops.append(e)
    for b in m.get("innerInstructions") or []:
        for ix in b["instructions"]:
            e = {"p": "in:" + (ix.get("programId") or "?")[:15]}
            if "parsed" in ix and isinstance(ix["parsed"], dict):
                e["t"] = ix["parsed"].get("type")
                info = ix["parsed"].get("info", {})
                if isinstance(info, dict):
                    e["i"] = {k2: str(v2)[:30] for k2, v2 in list(info.items())[:7] if not isinstance(v2, dict)}
            else:
                e["data"] = str(ix.get("data"))[:20]
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
    logs = [l for l in (m.get("logMessages") or []) if "Program log: Instruction" in l][:8]
    print(f'  {label}: slot {tx["slot"]} bt {tx["blockTime"]} err={m["err"]} payer={keys[0][:14]} ixlogs={logs}')
    if verbose:
        print(f'    ops: {json.dumps(ops)[:600]}')
        print(f'    YIELD deltas: {json.dumps(yd)}')
    return {"label": label, "slot": tx["slot"], "blockTime": tx["blockTime"], "err": m["err"],
            "payer": keys[0], "ops": ops, "yield_deltas": yd, "ix_logs": logs, "keys": keys}

out = {}
db = json.load(open("/home/heisenberg/CA/phase-stake/analysis/mb_sigs.json"))

print("== mint creation tx (oldest mint sig, bt 1713204023)")
out["mint_creation"] = summarize(get_tx(db["mint"]["sigs"][-1]["signature"], "mint[-1]"), "mint creation")

print("\n== stake8QtQ oldest 3")
ss = db["stake8QtQ"]["sigs"]
for i in (1, 2, 3):
    out[f"stake_old_{i}"] = summarize(get_tx(ss[-i]["signature"], f"8QtQ[-{i}]"), f"8QtQ[-{i}]")

print("\n== fee account GAGMZfQ oldest 3 (first use of current fee acct)")
fs = db["fee"]["sigs"]
for i in (1, 2, 3):
    out[f"fee_new_{i}"] = summarize(get_tx(fs[-i]["signature"], f"feeG[-{i}]"), f"fee_new[-{i}]")

print("\n== top1 holder token account BvN7jJrLSzv txs")
ta = call("getSignaturesForAddress", ["BvN7jJrLSzvJUd3FcR2kjvfzX6zPRkxBdMoK4Whz4cvD", {"limit": 3}], tag="top1")
if ta is not None:
    out["top1_ta_sigs"] = ta
    for s in ta[:3]:
        print("  ", s["slot"], s["blockTime"], s["signature"][:24])
    for j, s in enumerate(ta[:2]):
        out[f"top1_tx_{j}"] = summarize(get_tx(s["signature"], f"top1tx{j}"), f"top1tx{j}", verbose=True)

print("\n== Squads multisig decode + oldest tx")
r = call("getAccountInfo", ["GRe1iCBEeAMdEeFmEMavgXJE8Uk8tU82pyxZ4iXXAD1v", {"encoding": "base64"}], tag="msig")
if r:
    v = r["value"]; d = base64.b64decode(v["data"][0])
    o = 8
    create_key = b58encode(d[o:o+32]); o += 32
    config_authority = b58encode(d[o:o+32]); o += 32
    threshold = struct.unpack_from("<H", d, o)[0]; o += 2
    time_lock = struct.unpack_from("<I", d, o)[0]; o += 4
    tx_index = struct.unpack_from("<Q", d, o)[0]; o += 8
    out["msig"] = {"lamports": v["lamports"], "len": len(d), "create_key": create_key,
                   "config_authority": config_authority, "threshold": threshold,
                   "time_lock": time_lock, "tx_index": tx_index, "next48hex": d[o:o+48].hex()}
    print(" ", json.dumps(out["msig"]))
ms = call("getSignaturesForAddress", ["GRe1iCBEeAMdEeFmEMavgXJE8Uk8tU82pyxZ4iXXAD1v", {"limit": 1000}], tag="msig_sigs")
if ms is not None:
    out["msig_sigs_count"] = len(ms)
    oldest = ms[-1]
    out["msig_oldest_sig"] = oldest
    out["msig_oldest_tx"] = summarize(get_tx(oldest["signature"], "msig_oldest"), "msig oldest")
json.dump(out, open("/home/heisenberg/CA/phase-stake/analysis/final_targeted.json", "w"), indent=2)
print("\nsaved final_targeted.json")
