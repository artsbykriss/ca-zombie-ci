#!/usr/bin/env python3
"""Full detail of the SetManager tx + Squads multisig members decode."""
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
SETMGR_SIG = None
# find the SetManager sig from the fee account sig list
db = json.load(open("/home/heisenberg/CA/phase-stake/analysis/mb_sigs.json"))
fs = db["fee"]["sigs"]
# fee[-2] (2nd oldest) was the SetManager tx
SETMGR_SIG = fs[-2]["signature"]
print("SetManager sig:", SETMGR_SIG)
tx = call("getTransaction", [SETMGR_SIG, {"maxSupportedTransactionVersion": 0, "encoding": "jsonParsed"}], tag="setmgr")
if tx:
    m = tx["meta"]; msg = tx["transaction"]["message"]
    keys = [k["pubkey"] for k in msg["accountKeys"]]
    print("slot", tx["slot"], "bt", tx["blockTime"], "err", m["err"])
    print("accounts:")
    for i, k in enumerate(msg["accountKeys"]):
        print(f'   [{i:2d}] {k["pubkey"]} signer={k.get("signer")} writable={k.get("writable")} d={(m["postBalances"][i]-m["preBalances"][i])/1e9:+.9f}')
    la = msg.get("loadedAddresses") or {}
    n = len(keys)
    for j, k in enumerate(la.get("writable", [])):
        i = n + j
        print(f'   [{i:2d}L] {k} writable d={(m["postBalances"][i]-m["preBalances"][i])/1e9:+.9f}')
    for j, k in enumerate(la.get("readOnly", [])):
        i = n + len(la.get("writable", [])) + j
        print(f'   [{i:2d}L] {k} readonly d={(m["postBalances"][i]-m["preBalances"][i])/1e9:+.9f}')
    for ix in msg["instructions"]:
        print("TOP:", ix.get("programId"), "data:", str(ix.get("data"))[:40])
        if ix.get("accounts"): print("    accounts:", ix["accounts"])
        if "parsed" in ix: print("    parsed:", json.dumps(ix["parsed"])[:400])
    print("LOGS:")
    for l in (m.get("logMessages") or []):
        print("   ", l)
    out["setmanager_tx"] = {"slot": tx["slot"], "blockTime": tx["blockTime"],
                            "accounts": [(k["pubkey"], k.get("signer")) for k in msg["accountKeys"]],
                            "logs": m.get("logMessages")}
    json.dump(tx, open("/home/heisenberg/CA/phase-stake/analysis/setmanager_tx.json", "w"), indent=1)

# multisig decode with members
time.sleep(2)
r = call("getAccountInfo", ["GRe1iCBEeAMdEeFmEMavgXJE8Uk8tU82pyxZ4iXXAD1v", {"encoding": "base64"}], tag="msig")
if r:
    v = r["value"]; d = base64.b64decode(v["data"][0])
    o = 8
    create_key = b58encode(d[o:o+32]); o += 32
    config_authority = b58encode(d[o:o+32]); o += 32
    threshold = struct.unpack_from("<H", d, o)[0]; o += 2
    time_lock = struct.unpack_from("<I", d, o)[0]; o += 4
    tx_index = struct.unpack_from("<Q", d, o)[0]; o += 8
    stale = struct.unpack_from("<Q", d, o)[0]; o += 8
    rent_collector_tag = d[o]; o += 1
    if rent_collector_tag == 1:
        o += 8 + 8 + 32
    mem_n = struct.unpack_from("<I", d, o)[0]; o += 4
    members = []
    for i in range(mem_n):
        k = b58encode(d[o:o+32]); perm = d[o+32]; o += 33
        members.append({"key": k, "permissions_mask": perm})
    out["msig_decoded"] = {"lamports": v["lamports"], "len": len(d), "create_key": create_key,
                           "config_authority": config_authority, "threshold": threshold,
                           "time_lock_s": time_lock, "transaction_index": tx_index,
                           "stale_transaction_index": stale, "members_count": mem_n, "members": members,
                           "consumed": o}
    print("\nMSIG:", json.dumps(out["msig_decoded"], indent=1))
json.dump(out, open("/home/heisenberg/CA/phase-stake/analysis/msig_setmgr.json", "w"), indent=2)
print("saved msig_setmgr.json")
