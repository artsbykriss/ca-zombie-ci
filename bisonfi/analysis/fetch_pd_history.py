#!/usr/bin/env python3
"""Fetch full signature history of BisonFi ProgramData (and old authority) back past the exploit slot."""
import json, os, sys, time, urllib.request

OUT = os.path.dirname(os.path.abspath(__file__))
URL = "https://api.mainnet-beta.solana.com"
PD = "42snJ7ip4zKKsip3EtaMoBo8wzoRsQJSzgUSFXAVJFfG"
OLD_AUTH = "UfSM2ZFRMeurGs1gqrMREjZDyzPweUY9Wt67BMVeo8j"
TARGET_SLOT = 409_000_000  # stop below exploit slot 409,430,505

def batch(reqs):
    payload = json.dumps(reqs).encode()
    last=None
    for a in range(8):
        try:
            req = urllib.request.Request(URL, data=payload, headers={"Content-Type": "application/json", "User-Agent": "zr/1.0"})
            with urllib.request.urlopen(req, timeout=120) as r:
                out = json.loads(r.read())
            if isinstance(out, dict) and out.get("error"):
                time.sleep(2*(a+1)); last=out["error"]; continue
            return out
        except Exception as ex:
            last=str(ex); time.sleep(2*(a+1))
    raise RuntimeError(f"batch failed: {last}")

def page(addr, before=None, limit=1000):
    params=[addr, {"limit": limit, "commitment": "confirmed"}]
    if before: params[1]["before"]=before
    r=batch([{"jsonrpc":"2.0","id":1,"method":"getSignaturesForAddress","params":params}])
    return r[0].get("result",[])

def fetch_all(addr, stop_slot, max_pages=80, tag=""):
    sigs=[]; before=None
    for i in range(max_pages):
        res=page(addr, before)
        if not res: break
        sigs.extend(res)
        before=res[-1]["signature"]
        oldest=res[-1]["slot"]
        print(f"  [{tag}] page {i+1}: {len(res)} sigs, oldest slot {oldest}", file=sys.stderr)
        if oldest < stop_slot: break
        if len(res)<1000: break
    return sigs

if __name__=="__main__":
    what=sys.argv[1] if len(sys.argv)>1 else "pd"
    if what=="pd":
        sigs=fetch_all(PD, TARGET_SLOT, tag="PD")
        json.dump(sigs, open(os.path.join(OUT,"history-programdata-full.json"),"w"), indent=1)
        print("PD total:", len(sigs), "oldest:", sigs[-1]["slot"] if sigs else None)
    elif what=="oldauth":
        sigs=fetch_all(OLD_AUTH, 0, max_pages=20, tag="OLDAUTH")
        json.dump(sigs, open(os.path.join(OUT,"history-old-authority.json"),"w"), indent=1)
        print("OLDAUTH total:", len(sigs), "oldest:", sigs[-1]["slot"] if sigs else None)
