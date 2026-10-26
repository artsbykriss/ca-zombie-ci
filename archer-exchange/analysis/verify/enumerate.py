#!/usr/bin/env python3
"""Enumerate Archer maker books & markets independently."""
import json, sys, base64
from rpc import rpc, disc_b58, b58decode, b58encode

ARCHER = "Archer8kgiavM61GyusMzaaS2ft5sALtNsD1HxkUPMhy"
TOKENKEG = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"

def get_program_accounts(filters, size=None):
    cfg = {"encoding": "base64", "filters": filters}
    if size is not None:
        cfg["dataSlice"] = {"offset": 0, "length": size}
    res = rpc("getProgramAccounts", [ARCHER, cfg])
    if not isinstance(res, list):
        print("ERROR getProgramAccounts:", json.dumps(res)[:500])
        return None
    return res

def main():
    print("=== maker books (disc ACHRMKR1) ===")
    books = get_program_accounts([
        {"memcmp": {"offset": 0, "encoding": "base58", "bytes": disc_b58("ACHRMKR1")}}
    ])
    if books is None:
        print("getProgramAccounts failed/restricted")
        return
    print("count:", len(books))
    rows = []
    for acc in books:
        pk = acc["pubkey"]
        data = base64.b64decode(acc["account"]["data"][0]) if isinstance(acc["account"]["data"], list) else None
        if data is None:
            continue
        # maker=8:40, market=40:72, quote_free u64 @136, base_free u64 @152
        maker = data[8:40]
        market = data[40:72]
        qf = int.from_bytes(data[136:144], "little")
        bf = int.from_bytes(data[152:160], "little")
        rows.append((pk, b58encode(maker), b58encode(market), qf, bf, len(data)))
    for r in rows:
        print(r)
    with open("maker_books.json", "w") as f:
        json.dump([{"book": r[0], "maker": r[1], "market": r[2], "quote_free": r[3], "base_free": r[4], "len": r[5]} for r in rows], f, indent=2)

    print("\n=== markets (disc ACHRMKT1) ===")
    mkts = get_program_accounts([
        {"memcmp": {"offset": 0, "encoding": "base58", "bytes": disc_b58("ACHRMKT1")}}
    ])
    if mkts is None:
        print("getProgramAccounts failed/restricted")
        return
    print("count:", len(mkts))
    mrows = []
    for acc in mkts:
        pk = acc["pubkey"]
        data = base64.b64decode(acc["account"]["data"][0])
        base_mint = b58encode(data[40:72])
        quote_mint = b58encode(data[72:104])
        base_vault = b58encode(data[104:136])
        quote_vault = b58encode(data[136:168])
        bapbl = int.from_bytes(data[200:208], "little")
        qapql = int.from_bytes(data[208:216], "little")
        status = data[258] if len(data) > 258 else None
        mrows.append((pk, base_mint, quote_mint, base_vault, quote_vault, bapbl, qapql, status, len(data)))
    for r in mrows:
        print(r)
    with open("markets.json", "w") as f:
        json.dump([{"market": r[0], "base_mint": r[1], "quote_mint": r[2], "base_vault": r[3], "quote_vault": r[4], "base_atoms_per_base_lot": r[5], "quote_atoms_per_quote_lot": r[6], "status": r[7], "len": r[8]} for r in mrows], f, indent=2)

if __name__ == "__main__":
    main()
