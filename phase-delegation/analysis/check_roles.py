#!/usr/bin/env python3
"""Check every authority / role account of the Phase Delegation pool + scan for
orphaned stake accounts whose withdraw authority is the pool PDA."""
import base64, json, sys
sys.path.insert(0, '.')
from rpc import rpc, b58enc, b58dec

ROLES = {
    "manager": "7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1",
    "staker": "QocTiqKmq654c5hxBitSUD7UKZH7JMzjkcNHeh917wk",
    "stake_deposit_authority": "4Y6XeEZ2Dg2zXU9NJgdmAG9xpwAsNusLReSTLzJxtZJ8",
    "manager_fee_account": "HC77HUgE6XpEVnS6RtNwe1yf7a1BoBdQzdxyWrAsxVac",
    "pool_mint": "aeroXvCT6tjGVNyTvZy86tFDwE4sYsKCh7FbNDcrcxF",
    "reserve_stake": "aeroivis36SwDvAJpzQCDX9Y7cCLXBdv9vTn1DtDnVC",
    "withdraw_auth_PDA": "AKJt3m2xJ6ANda9adBGqb5BMrheKJSwxyCfYkLuZNmjn",
    "program_upgrade_authority": "dPpFfahSWhm5M2RB3nVaHsXfnh9ooz5bWtR3WeUguDH",
    "programdata": "EmiU8AQkB2sswTxVB6aCmsAJftoowZGGDXuytm6X65R3",
}
out = {}
for name, addr in ROLES.items():
    res = rpc("getAccountInfo", [addr, {"encoding": "base64"}])
    v = res["value"]
    if v is None:
        out[name] = {"address": addr, "exists": False}
        print(f"{name:28s} {addr} MISSING")
        continue
    info = {"address": addr, "exists": True, "owner": v["owner"], "lamports": v["lamports"],
            "space": v["space"], "executable": v["executable"]}
    raw = base64.b64decode(v["data"][0]) if v["data"] else b""
    if v["owner"] == "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA" and len(raw) == 82:
        tag = int.from_bytes(raw[:4], "little")
        auth = b58enc(raw[4:36]) if tag == 1 else None
        ftag = int.from_bytes(raw[46:50], "little")
        fauth = b58enc(raw[50:82]) if ftag == 1 else None
        info["mint"] = {"mint_authority": auth, "supply": int.from_bytes(raw[36:44], "little"),
                        "decimals": raw[44], "is_init": raw[45], "freeze_authority": fauth}
    if v["owner"] == "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA" and len(raw) == 165:
        info["token_account"] = {"mint": b58enc(raw[:32]), "owner": b58enc(raw[32:64]),
                                 "amount": int.from_bytes(raw[64:72], "little")}
    if v["owner"] == "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA" and len(raw) == 355:
        info["token_multisig"] = {"m": raw[0], "n": raw[1], "is_initialized": raw[2]}
    if v["owner"] == "Stake11111111111111111111111111111111111111" and len(raw) >= 200:
        tag = int.from_bytes(raw[:4], "little")
        info["stake_state_tag"] = tag
        if tag in (1, 2):
            info["staker"] = b58enc(raw[12:44]); info["withdrawer"] = b58enc(raw[44:76])
    out[name] = info
    print(f"{name:28s} {addr}")
    print("   ", json.dumps({k: val for k, val in info.items() if k != 'address'})[:240])

# program accounts of the pool (stake pool + validator list) for cross-ref
json.dump(out, open('role_accounts.json', 'w'), indent=1)

print("\n=== orphan scan: all Stake-program accounts whose withdrawer == pool PDA ===")
try:
    res = rpc("getProgramAccounts", ["Stake11111111111111111111111111111111111111", {
        "encoding": "base64",
        "filters": [{"memcmp": {"offset": 44, "bytes": "AKJt3m2xJ6ANda9adBGqb5BMrheKJSwxyCfYkLuZNmjn"}}]}],
        tries=2, timeout=120)
    print("accounts with withdrawer == pool PDA:", len(res))
    rows = []
    for a in res:
        raw = base64.b64decode(a["account"]["data"][0])
        tag = int.from_bytes(raw[:4], "little")
        rows.append({"address": a["pubkey"], "lamports": a["account"]["lamports"], "tag": tag,
                     "staker": b58enc(raw[12:44]), "withdrawer": b58enc(raw[44:76])})
    json.dump(rows, open('withdrawer_scan.json', 'w'), indent=1)
    for r in rows[:5]:
        print(r)
except Exception as e:
    print("scan failed:", str(e)[:300])
