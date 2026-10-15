#!/usr/bin/env python3
"""TASK 1 fallback: enumerate YIELD token accounts via Token-program getProgramAccounts (dataSlice owner+amount).
Also: oldest sigs for stake8QtQ/reserve from the full histories."""
import json, time, urllib.request, base64, struct, sys

URL = "https://api.mainnet-beta.solana.com"
MINT = "phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG"

def post(url, method, params, timeout=60):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def call(method, params, tries=15, tag=""):
    for i in range(tries):
        try:
            d = post(URL, method, params)
            if "result" in d:
                return d["result"]
            print(tag, "try", i, str(d.get("error"))[:120], flush=True)
        except Exception as e:
            print(tag, "try", i, "exc", str(e)[:90], flush=True)
        time.sleep(min(45, 8 + i * 4))
    return None

# 1) Token program GPA filtered by mint
res = call("getProgramAccounts", ["TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA", {
    "encoding": "base64",
    "filters": [{"dataSize": 165}, {"memcmp": {"offset": 0, "bytes": MINT}}],
    "dataSlice": {"offset": 32, "length": 56},
}], tag="tokenGPA")
if res is not None:
    print("token GPA accounts:", len(res))
    holders = []
    for a in res:
        d = base64.b64decode(a["account"]["data"][0])
        owner = base64.b64encode(d[0:32]).decode()  # need b58 instead
        holders.append((a["pubkey"], owner, d))
    # proper b58 encode
    sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
    from sol_util import b58encode
    out = []
    total = 0
    for a in res:
        d = base64.b64decode(a["account"]["data"][0])
        owner = b58encode(d[0:32])
        amount = int.from_bytes(d[32:40], "little")
        state = d[40]
        # delegated amount if state==1 (delegate) -> delegate pubkey at 40..72; skip
        total += amount
        out.append({"token_account": a["pubkey"], "owner": owner, "amount": amount, "state": state,
                    "lamports": a["account"]["lamports"]})
    out.sort(key=lambda x: -x["amount"])
    json.dump({"endpoint": URL, "count": len(out), "sum_amount": total, "accounts": out},
              open("/home/heisenberg/CA/phase-stake/analysis/token_gpa_holders.json", "w"), indent=2)
    print("sum amount (raw):", total)
    print("top 25:")
    for h in out[:25]:
        print(f'{h["amount"]:>18d} {h["owner"]}  ({h["token_account"]}) state={h["state"]}')
else:
    print("token GPA FAILED")

# 2) oldest sigs from mb_sigs.json
db = json.load(open("/home/heisenberg/CA/phase-stake/analysis/mb_sigs.json"))
for name in ("stake8QtQ", "reserve"):
    sigs = db.get(name, {}).get("sigs", [])
    if sigs:
        print(f"\n{name}: n={len(sigs)} oldest slot {sigs[-1]['slot']} bt {sigs[-1]['blockTime']} sig {sigs[-1]['signature']}")
        print(f"   newest slot {sigs[0]['slot']} bt {sigs[0]['blockTime']}")
