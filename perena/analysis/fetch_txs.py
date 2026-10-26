#!/usr/bin/env python3
"""Fast fetch of recent program txs using JSON-RPC batch. Read-only."""
import sys, json, hashlib
from rpc import call, batch
from b58 import b58dec

NAMES = ["swap_exact_in","swap_exact_in_hinted","swap_exact_in_quote","swap_exact_out",
         "swap_exact_out_hinted","add_liquidity","remove_liquidity","remove_all_liquidity",
         "compound","skim","create_pool","init_virtual_stable_pair","set_rate","set_owner",
         "set_fee","set_inv_t_max","set_status","set_lp_token_metadata","set_numeraire_owner",
         "set_numeraire_status","set_numeraire_whitelisted_pool_creator","set_whitelisted_adder"]
def disc(name): return hashlib.sha256(("global:"+name).encode()).digest()[:8]

def main():
    pid = sys.argv[1]; n = int(sys.argv[2]) if len(sys.argv)>2 else 100
    sigs = call("getSignaturesForAddress",[pid,{"limit":n}])
    good = [s for s in sigs if not s.get("err")]
    dm = {disc(x): x for x in NAMES}
    reqs = [{"jsonrpc":"2.0","id":i,"method":"getTransaction",
             "params":[s["signature"],{"encoding":"jsonParsed","maxSupportedTransactionVersion":0}]}
            for i,s in enumerate(good)]
    res = batch(reqs)
    found = []
    for item in res:
        i = item.get("id"); tx = item.get("result")
        if tx is None: continue
        s = good[i]
        msg = tx["transaction"]["message"]
        keys = [k["pubkey"] if isinstance(k,dict) else k for k in msg["accountKeys"]]
        for ix in msg["instructions"]:
            if ix.get("programId") != pid: continue
            d = ix.get("data")
            if not d: continue
            try: raw = b58dec(d)[:8]
            except Exception: continue
            nm = dm.get(raw)
            if nm:
                found.append({"sig":s["signature"],"slot":s["slot"],"ix":nm,
                              "keys":keys,"data":d,
                              "ixaccts":[k for k in ix.get("accounts",[])]})
    print(json.dumps(found, indent=1))

if __name__ == "__main__":
    main()
