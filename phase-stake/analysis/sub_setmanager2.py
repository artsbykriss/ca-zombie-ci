#!/usr/bin/env python3
"""Find SetManager #2 (manager->Squads vault?); re-verify pool manager field; decode msig raw."""
import json, sys, time, urllib.request, base64, struct
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import b58decode, b58encode

URL = "https://api.mainnet-beta.solana.com"

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

out = {}
# 1) fresh pool state: verify manager field
r = call("getAccountInfo", ["phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG", {"encoding": "base64"}], tag="pool")
d = base64.b64decode(r["value"]["data"][0])
print("manager[1:33] =", b58encode(d[1:33]))
print("staker[33:65] =", b58encode(d[33:65]))
print("deposit_auth[65:97] =", b58encode(d[65:97]))
print("fee_acct[194:226] =", b58encode(d[194:226]))
out["pool_fields"] = {"manager": b58encode(d[1:33]), "staker": b58encode(d[33:65]),
                      "stake_deposit_authority": b58encode(d[65:97]),
                      "manager_fee_account": b58encode(d[194:226])}

# 2) scan remaining fee-account sigs for SetManager
db = json.load(open("/home/heisenberg/CA/phase-stake/analysis/mb_sigs.json"))
fs = db["fee"]["sigs"]
print("\nfee account sigs:", [(i, s["slot"], s["blockTime"]) for i, s in enumerate(fs)])
setmgrs = []
for i in [3, 4, 5, 6, 7, 8, 9, 10, 11]:
    s = fs[i]
    time.sleep(2)
    tx = call("getTransaction", [s["signature"], {"maxSupportedTransactionVersion": 0, "encoding": "jsonParsed"}], tries=3, tag=f"fee{i}")
    if not tx:
        print(f"  fee[{i}] not found"); continue
    logs = [l for l in (tx["meta"].get("logMessages") or []) if "Instruction" in l]
    print(f'  fee[{i}] slot {tx["slot"]} bt {tx["blockTime"]} logs={logs[:4]}')
    if any("SetManager" in l for l in logs):
        setmgrs.append({"idx": i, "sig": s["signature"], "slot": tx["slot"], "blockTime": tx["blockTime"]})
        msg = tx["transaction"]["message"]
        print("   >>> SETMANAGER accounts:")
        for k in msg["accountKeys"]:
            print("      ", k["pubkey"], "signer=", k.get("signer"))
        for ix in msg["instructions"]:
            if "accounts" in ix and ix.get("data"):
                print("      ix accounts:", ix.get("accounts"))
out["setmanager_found"] = setmgrs
json.dump(out, open("/home/heisenberg/CA/phase-stake/analysis/setmanager2.json", "w"), indent=2)

# 3) msig raw hex
time.sleep(2)
r = call("getAccountInfo", ["GRe1iCBEeAMdEeFmEMavgXJE8Uk8tU82pyxZ4iXXAD1v", {"encoding": "base64"}], tag="msig")
if r:
    raw = base64.b64decode(r["value"]["data"][0])
    print("\nmsig len:", len(raw))
    print("hex:", raw.hex())
    # try structured decode: walk and print offsets
    print("bytes 94..105:", raw[94:105].hex())
