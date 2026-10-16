#!/usr/bin/env python3
"""Full fund scan: enumerate Collateral accounts per program, derive vault ATAs, sum balances.
Read-only. No keys written."""
import sys, json, base64, hashlib
import sol_rpc as S

COLL_DISC = "132d631dc432e475"  # account:Collateral
TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
ATA_PROG = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
MINTS = {
    "USDC": "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
    "USDT": "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB",
    "PYUSD": "2b1kV6DkPAnxd5ixfnxCpjxmKwqjjaYmCZfHsFu24GXo",
}

def collaterals_of(program_id):
    b58disc = S.b58encode(bytes.fromhex(COLL_DISC))
    res = S.rpc("getProgramAccounts", [program_id, {
        "encoding": "base64",
        "filters": [{"memcmp": {"offset": 0, "bytes": b58disc}}, {"dataSize": 177}],
        "commitment": "finalized"}])
    return [it["pubkey"] for it in res]

def vault_authority(collateral, program_id):
    pda, bump = S.find_pda([b"CollateralAuthority", S.b58decode(collateral)], program_id)
    return pda

def ata(owner, mint):
    pda, bump = S.find_pda([S.b58decode(owner), S.b58decode(TOKEN), S.b58decode(mint)], ATA_PROG)
    return pda

def parse_token_account(acc_val):
    if not acc_val:
        return None
    raw = base64.b64decode(acc_val["data"][0])
    if len(raw) < 72:
        return None
    return {
        "mint": S.b58encode(raw[0:32]),
        "authority": S.b58encode(raw[32:64]),
        "amount": int.from_bytes(raw[64:72], "little"),
    }

def get_many(addrs):
    out = {}
    for i in range(0, len(addrs), 100):
        chunk = addrs[i:i+100]
        res = S.rpc("getMultipleAccounts", [chunk, {"encoding": "base64", "commitment": "finalized"}])
        for a, v in zip(chunk, res["value"]):
            out[a] = parse_token_account(v)
    return out

def scan_program(program_id, mint_names=None):
    mint_names = mint_names or ["USDC", "USDT"]
    colls = collaterals_of(program_id)
    vaults = [vault_authority(c, program_id) for c in colls]
    atamap = {}
    for c, v in zip(colls, vaults):
        for mn in mint_names:
            atamap[ata(v, MINTS[mn])] = (c, v, mn)
    bal = get_many(list(atamap.keys()))
    rows = []
    for ata_addr, (c, v, mn) in atamap.items():
        info = bal.get(ata_addr)
        if info and info["amount"] > 0:
            rows.append({"collateral": c, "vault_authority": v, "mint": mn, "vault_ata": ata_addr,
                         "amount_raw": info["amount"], "authority": info["authority"]})
    return {"program": program_id, "n_collaterals": len(colls), "collaterals": colls,
            "n_nonzero_vaults": len(rows), "nonzero_vaults": rows}

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "scan":
        out = []
        for pid in sys.argv[2:]:
            r = scan_program(pid)
            out.append(r)
            print(json.dumps({k: v for k, v in r.items() if k != "collaterals"}))
        json.dump(out, open("fund_scan.json", "w"), indent=1)
    elif cmd == "colls":
        for pid in sys.argv[2:]:
            c = collaterals_of(pid)
            print(pid, "collaterals:", len(c), c[:10])
    elif cmd == "vault":
        # verify derivation on known pair
        c, pid = sys.argv[2], sys.argv[3]
        v = vault_authority(c, pid)
        print("vault authority:", v)
        for mn, m in MINTS.items():
            print(f"  ATA {mn}:", ata(v, m))
