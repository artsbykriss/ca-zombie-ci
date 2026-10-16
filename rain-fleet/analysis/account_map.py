#!/usr/bin/env python3
"""Account role mapping + per-program account enumeration + token balance scan."""
import sys, json, base64, hashlib
import sol_rpc as S

TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
TOKEN2022 = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"

def acc_disc(name):
    return hashlib.sha256(("account:" + name).encode()).digest()[:8]

ACC_NAMES = ["Collateral", "Signatures", "CollateralAdminSignatures", "Coordinator",
             "Statement", "WithdrawalRequest", "CollateralInfo", "UserAccount",
             "CollateralAdminSignaturesAccount", "CollateralSignatures"]

def describe(addr):
    a = S.get_account(addr)
    if not a or not a.get("value"):
        return {"addr": addr, "exists": False}
    v = a["value"]
    raw = base64.b64decode(v["data"][0]) if isinstance(v["data"], list) else b""
    out = {"addr": addr, "exists": True, "owner": v["owner"], "size": len(raw), "lamports": v["lamports"]}
    if v["owner"] in (TOKEN, TOKEN2022) and len(raw) == 165:
        mint = S.b58encode(raw[0:32]); owner = S.b58encode(raw[32:64])
        amount = int.from_bytes(raw[64:72], "little")
        out.update({"token": True, "mint": mint, "authority": owner, "amount": amount})
    else:
        d = raw[:8]
        out["disc"] = d.hex()
        for n in ACC_NAMES:
            if acc_disc(n) == d:
                out["disc_name"] = n
    return out

def program_accounts(program_id, dataSlice=None):
    cfg = {"encoding": "base64", "commitment": "finalized"}
    if dataSlice:
        cfg["dataSlice"] = dataSlice
    return S.rpc("getProgramAccounts", [program_id, cfg])

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "desc":
        for a in sys.argv[2:]:
            print(json.dumps(describe(a)))
    elif cmd == "enum":
        pid = sys.argv[2]
        rows = program_accounts(pid, dataSlice={"offset": 0, "length": 8})
        groups = {}
        for it in rows:
            raw = base64.b64decode(it["account"]["data"][0])
            d = raw[:8].hex()
            key = d
            g = groups.setdefault(key, {"count": 0, "size": it["account"]["data"][1] if False else None, "disc": d, "examples": []})
            g["count"] += 1
            if len(g["examples"]) < 3:
                g["examples"].append(it["pubkey"])
        # sizes need full fetch; approximate with account space field if present
        print(json.dumps({"program": pid, "total_accounts": len(rows), "groups": groups}, indent=1))
    elif cmd == "accts":
        pid = sys.argv[2]
        rows = program_accounts(pid)
        out = []
        for it in rows:
            raw = base64.b64decode(it["account"]["data"][0])
            out.append({"pubkey": it["pubkey"], "size": len(raw), "disc": raw[:8].hex(), "lamports": it["account"]["lamports"]})
        json.dump(out, open(f"accts_{pid[:8]}.json", "w"), indent=1)
        print(f"{pid}: {len(out)} accounts -> accts_{pid[:8]}.json")
