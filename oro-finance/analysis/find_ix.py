#!/usr/bin/env python3
"""Find a recent real swap tx (incl. CPI/inner) for a program. Read-only, gentle pacing."""
import sys, json, hashlib, time, random
from rpc import call, batch
from b58 import b58dec

NAMES = ["autorize","add_to_whitelist_by_auth","whitelist","update_price","sell","withdraw",
         "deposit","mint_gold","burn_gold","init_integrator","update_integrator_fees",
         "close_integrator","withdraw_from_integrator","update_integrator_market_override",
         "init_integrator_v2","update_integrator_v2_fees","close_integrator_v2",
         "withdraw_from_integrator_v2","update_integrator_v2_market_overrides"]
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
