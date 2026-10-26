#!/usr/bin/env python3
"""Find a recent real swap tx (incl. CPI/inner) for a program. Read-only, gentle pacing."""
import sys, json, hashlib, time, random
from rpc import call, batch
from b58 import b58dec

NAMES = ["swap_exact_in","swap_exact_in_hinted","swap_exact_in_quote","swap_exact_out",
         "swap_exact_out_hinted","add_liquidity","remove_liquidity","remove_all_liquidity",
         "compound","skim","create_pool","init_virtual_stable_pair","set_rate","set_owner",
         "set_fee","set_inv_t_max","set_status","set_lp_token_metadata","set_numeraire_owner",
         "set_numeraire_status","set_numeraire_whitelisted_pool_creator","set_whitelisted_adder"]
def disc(name): return hashlib.sha256(("global:"+name).encode()).digest()[:8]

def main():
    pid = sys.argv[1]; n = int(sys.argv[2]) if len(sys.argv)>2 else 60
    want = sys.argv[3] if len(sys.argv)>3 else "swap"
    dm = {disc(x): x for x in NAMES}
    sigs = call("getSignaturesForAddress",[pid,{"limit":n}])
    good = [s for s in sigs if not s.get("err")]
    out = []
    for s in good[:40]:
        for attempt in range(4):
            try:
                tx = call("getTransaction",[s["signature"],{"encoding":"jsonParsed","maxSupportedTransactionVersion":0}])
                break
            except Exception:
                time.sleep(1.5*(attempt+1))
        else:
            continue
        if tx is None: continue
        msg = tx["transaction"]["message"]
        keys = [k["pubkey"] if isinstance(k,dict) else k for k in msg["accountKeys"]]
        ixs = list(msg["instructions"])
        for inner in tx["meta"].get("innerInstructions",[]) or []:
            ixs += inner["instructions"]
        for ix in ixs:
            if ix.get("programId") != pid: continue
            d = ix.get("data")
            try: raw = b58dec(d)[:8] if d else b""
            except Exception: raw = b"?"
            nm = dm.get(raw, raw.hex() if raw else "empty")
            if want in nm:
                out.append({"sig":s["signature"],"slot":s["slot"],"ix":nm,"data":d,
                            "keys":keys,"accts":ix.get("accounts"),
                            "allix":[{"programId":x.get("programId"),"data":x.get("data")} for x in ixs]})
        if len(out) >= 5: break
        time.sleep(0.25)
    print(json.dumps(out, indent=1))

if __name__ == "__main__":
    main()
