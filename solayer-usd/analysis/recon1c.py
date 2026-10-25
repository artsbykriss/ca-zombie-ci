#!/usr/bin/env python3
"""Step 1c: find token accounts owned by the pool PDA via getProgramAccounts memcmp(owner=32)."""
import json, base64, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solrpc as s

POOL = "FhVcYNEe58SMtxpZGnTu2kpYJrTu2vwCZDGpPLqbd2yG"
TOK22 = "BnANu5CtUogLqcvBNByJuwaRvRxNtVuDcAytwjsUUtqs"
USDC  = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
out = {}
out["slot"] = s.get_slot()["result"]

for pid, label in [("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA", "spl"),
                   ("TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb", "t22")]:
    try:
        r = s.get_program_accounts(pid, filters=[{"memcmp": {"offset": 32, "bytes": POOL}}],
                                   encoding="base64")
        accts = r.get("result") or []
        print("==", label, "n=", len(accts))
        rows = []
        for a in accts:
            d = base64.b64decode(a["account"]["data"][0])
            mint = None
            if len(d) >= 64:
                n = int.from_bytes(d[0:32], "big"); A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
                o = ""
                while n > 0:
                    n, rr = divmod(n, 58); o = A[rr] + o
                pad = 0
                for c in d[0:32]:
                    if c == 0: pad += 1
                    else: break
                mint = "1"*pad + (o or "")
                amt = int.from_bytes(d[64:72], "little")
            rows.append({"pubkey": a["pubkey"], "space": a["account"]["space"],
                         "lamports": a["account"]["lamports"], "mint": mint, "amount_raw": amt})
            print("   ", a["pubkey"], "mint", mint, "amt", amt, "space", a["account"]["space"])
        out["owned_" + label] = rows
    except Exception as e:
        print("err", label, e)
        out["owned_" + label] = {"error": str(e)}

# also: all accounts owned by the sUSD program
PROG = "s1aysqpEyZyijPybUV89oBGeooXrR22wMNLjnG2SWJA"
try:
    r = s.get_program_accounts(PROG, encoding="base64")
    accts = r.get("result") or []
    print("== program-owned accounts n=", len(accts))
    for a in accts:
        print("   ", a["pubkey"], "space", a["account"]["space"], "lamports", a["account"]["lamports"])
    out["program_accounts"] = [{"pubkey": a["pubkey"], "space": a["account"]["space"],
                                "lamports": a["account"]["lamports"],
                                "data_b64": a["account"]["data"][0]} for a in accts]
except Exception as e:
    print("prog err", e)

json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "recon1c.json"), "w"), indent=1)
print("slot", out["slot"])
