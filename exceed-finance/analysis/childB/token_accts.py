#!/usr/bin/env python3
import json, sys
sys.path.insert(0, "/home/heisenberg/CA/exceed-finance/analysis/childB")
from rpc import call

TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
TOKEN22 = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
MINT_NAMES = {
    "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v": "USDC",
    "So11111111111111111111111111111111111111112": "SOL",
    "cbbtcf3aa214zXHbiAZQwf4122FBYbraNdFqgw4iMij": "cbBTC",
    "8B9vL4c9w5HiyFXdPT8Z8hgFvSeZ14Y5DxjCZyRSTf4z": "pikUSDC",
    "4J93x2zCNMrL4Qq8Nuvjk9yNLNkf1Vmqz14UxtcM4uny": "exSOL-LST",
    "HabWg55SK5Jam5WUpbk8Wfq7JbuAaFVPu8KVFMJj9yVg": "exBTC-LST",
    "9ir8o6rj7dJsXXFQPbDZcWCiPx4UDcdTKrYZfnct6GDm": "pUSD",
}
OWNERS = {
    "exUSDC_pair": "EwqMpnBHKEd537E37kcsNU9Qi82uukjVAXsC8K5Kswt7",
    "exSOL_pair": "HwsGQqoXwQjGg5CDojLTipmeYFSmovoHtk7ZFtgrxSop",
    "exBTC_pair": "GpV9U2yY3L5u4DkWC6Unejsz42iNME4Usk5RzTaA23to",
    "vault_authority": "WYSyHasQGFCtfHb1W5pFf64YCzvMSahJgBoZei5RrwJ",
    "pair_authority(same)": "WYSyHasQGFCtfHb1W5pFf64YCzvMSahJgBoZei5RrwJ",
    "window_authority": "F2x6FM19gx68ubHWxNBsJKQksM5N38QhmgYhEG7yLnHv",
    "deposit_authority": "CpdVRBHtnDd3RbYzvESXdrAD5bhWdQNvbfLUfjJpQnTE",
    "unseal/access_authority": "DY9GqHNXBRxyS2cM4x8DasUwpRXzU2GDo2LFAefAjDkK",
}

for label, owner in OWNERS.items():
    for tp, tpname in [(TOKEN, "spl"), (TOKEN22, "t22")]:
        r = call("getTokenAccountsByOwner", [owner, {"programId": tp}, {"encoding": "jsonParsed"}])
        vals = r.get("result", {}).get("value", [])
        if vals:
            print(f"--- {label} {owner} [{tpname}] : {len(vals)} accounts")
            for v in vals:
                info = v["account"]["data"]["parsed"]["info"]
                mint = info["mint"]
                amt = info["tokenAmount"]
                print(f"    {v['pubkey']}  {MINT_NAMES.get(mint, mint)}  amount={amt['uiAmountString']} (raw {amt['amount']})")
