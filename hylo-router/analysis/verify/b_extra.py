#!/usr/bin/env python3
"""Supplementary structural checks: mint authorities + router upgrade authority."""
import json
from solders.pubkey import Pubkey
from rpc import rpc

ROUTER = Pubkey.from_string("hyRouTRDAgn65xyyJ3L5c4k5SFmSdr3NxDV8Euzjy3f")
EXCH = Pubkey.from_string("HYEXCHtHkBagdStcJCp3xbbb9B7sdMdWXFNj6mdsG4hn")
A = {
 "user": "D5YqVMoSxnqeZAKAUUE1Dm3bmjtdxQ5DCF356ozqN9cM",
 "hylo": "9cd2sAfbBvKs4SX9YKo4dcjwP3TgTVQ8dT5koshGcDND",
 "stablecoin_auth": "CfuSViqf6wvUKEprLhtuCsSanvfAsMbDmkAW92FP95qe",
 "levercoin_auth": "BKdLWcUDE1Kmga2BfSNaMR2wbXSL4YouTbNQ8mTdcqTp",
 "stablecoin_mint": "5YMkXAYccHSGnHn9nob9xEvv6Pvka9DZWH7nTbotTu9E",
 "levercoin_mint": "7ga6rtE9qSb3wdEiDCpTu2kHqoGVfT52jD8ign1rYTvx",
 "collateral_mint": "98sMhvDwXj1RQi5c5Mndm3vPe9cBqPrbLaufMXFNMh5g",
}

def parsed(pk, enc="jsonParsed"):
    r = rpc("getAccountInfo", [str(pk), {"encoding": enc}])
    return r.get("value") if isinstance(r, dict) else None

out = {}
print("=== mint authorities (must be exchange PDAs, not router PDAs) ===")
for name in ["stablecoin_mint", "levercoin_mint", "collateral_mint"]:
    v = parsed(A[name])
    info = v["data"]["parsed"]["info"] if v and v.get("data", {}).get("parsed") else {}
    print(name, A[name], "-> mintAuthority:", info.get("mintAuthority"), "owner(program):", v.get("owner"))
    out[name] = {"mintAuthority": info.get("mintAuthority"), "programOwner": v.get("owner") if v else None}

print("\n=== hylo PDA authority fields ===")
v = parsed(A["hylo"])
if v and v.get("data", {}).get("parsed"):
    info = v["data"]["parsed"]["info"]
    print("hylo:", json.dumps(info)[:400])
out["hylo"] = v.get("data", {}).get("parsed", {}).get("info") if v else None

print("\n=== router upgrade authority ===")
pv = parsed(ROUTER)
print("router program:", json.dumps(pv.get("data")) if pv else None)
if pv and pv.get("data", {}).get("parsed"):
    pd = pv["data"]["parsed"]["info"]["programData"]
    print("programData:", pd)
    dv = parsed(Pubkey.from_string(pd))
    info = dv["data"]["parsed"]["info"]
    print("upgradeAuthority:", info.get("authority"), "slot:", info.get("slot"))
    out["router_programdata"] = {"programData": pd, "upgradeAuthority": info.get("authority")}

json.dump(out, open("hylo_structural_extra.json", "w"), indent=2)
print("wrote hylo_structural_extra.json")
