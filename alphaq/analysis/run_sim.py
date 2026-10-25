import json,sys
from b58 import b58dec
from sim import build_legacy,simulate
PID="ALPHAQmeA7bjrVuccPsYPiCvsi428SNwte66Srvs4pHA"
BH="11111111111111111111111111111111"
def run(label,signers,writable,readonly,accts,data,extra_ix=None,verbose=True):
    ixs=[(PID,accts,data)]
    if extra_ix: ixs=extra_ix+ixs
    tx=build_legacy(signers[0],signers,writable,readonly,BH,ixs)
    r=simulate(tx)
    res=r["value"]
    if verbose:
        print(f"[{label}] err={res['err']} cu={res.get('unitsConsumed')}")
        for l in (res.get("logs") or []):
            if "ALPHAQ" in l or "failed" in l: print("    ",l)
    return r,tx
