#!/usr/bin/env python3
"""Creation tx of the pool (oldest vlist sig) + fee account balance + current-state snapshot."""
import json, time, urllib.request, base64, sys

URL = "https://api.mainnet-beta.solana.com"

def post(method, params, timeout=50):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(URL, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def call(method, params, tries=25, tag=""):
    for i in range(tries):
        try:
            d = post(method, params)
            if "result" in d:
                return d["result"]
            print(tag, "try", i, str(d.get("error"))[:90], flush=True)
        except Exception as e:
            print(tag, "try", i, "exc", str(e)[:80], flush=True)
        time.sleep(min(40, 8 + i * 3))
    return None

CREATION = "4YRfsPUw43kDXcPFsWpffVdg8FKrcQ6YzRyYnjGjLZynqBvJxnZiDgmZMEMeFZyjXVA65RUtYcu1kbxrYyR36Y2G"
tx = call("getTransaction", [CREATION, {"maxSupportedTransactionVersion": 0, "encoding": "jsonParsed"}], tag="creation")
if tx:
    json.dump(tx, open("/home/heisenberg/CA/phase-stake/analysis/creation_tx.json", "w"), indent=1)
    m = tx["meta"]; msg = tx["transaction"]["message"]
    keys = [k["pubkey"] for k in msg["accountKeys"]]
    la = msg.get("loadedAddresses") or {}
    keys += la.get("writable", []) + la.get("readOnly", [])
    print("=== CREATION TX", CREATION, "slot", tx["slot"], "bt", tx["blockTime"], "fee", m["fee"])
    for i, k in enumerate(keys):
        d = (m["postBalances"][i] - m["preBalances"][i]) / 1e9
        print(f'  [{i:2d}] {k} {d:+.9f}')
    for ix in msg["instructions"]:
        print("TOP:", ix.get("programId"), "data:", str(ix.get("data"))[:40])
        if "parsed" in ix:
            print("    ", json.dumps(ix["parsed"])[:300])
    for b in m.get("innerInstructions") or []:
        for ix in b["instructions"]:
            print("INNER:", ix.get("programId"), str(ix.get("data"))[:30], "acct#", len(ix.get("accounts", [])))
            if "parsed" in ix:
                print("    ", json.dumps(ix["parsed"])[:260])
    print("LOGS:")
    for l in (m.get("logMessages") or [])[:40]:
        print("   ", l)

time.sleep(3)
fee = call("getAccountInfo", ["GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U", {"encoding": "jsonParsed"}], tag="fee")
if fee:
    print("\n=== FEE ACCOUNT:", json.dumps(fee["value"]["data"]["parsed"], indent=1))
    json.dump(fee, open("/home/heisenberg/CA/phase-stake/analysis/fee_account.json", "w"), indent=2)

time.sleep(3)
pool = call("getAccountInfo", ["phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG", {"encoding": "base64"}], tag="pool")
if pool:
    d = base64.b64decode(pool["value"]["data"][0])
    json.dump({"lamports": pool["value"]["lamports"], "data_b64": pool["value"]["data"][0]},
              open("/home/heisenberg/CA/phase-stake/analysis/pool_state_full.json", "w"), indent=2)
    print("\n=== POOL lamports:", pool["value"]["lamports"])

time.sleep(3)
res = call("getAccountInfo", ["phaseECAeXantYWXvRGkmeh7ddQsUJTf7DcywquY9Z2", {"encoding": "jsonParsed"}], tag="reserve")
if res:
    print("=== RESERVE lamports:", res["value"]["lamports"])
    json.dump(res, open("/home/heisenberg/CA/phase-stake/analysis/reserve_stake.json", "w"), indent=2)
