#!/usr/bin/env python3
import sys, json
from stellar_sdk import scval, Address, xdr, Keypair
sys.path.insert(0, "/home/heisenberg/CA/sushi-stellar/analysis")
from state import sim, val

POOL = "CA5R5L7QE7WC2M4YAPSBITV7M2R6LX5366UURH3REHQMOJV6R5QWTH2K"
SRC = "GCFB64LD5OX6XXUQW44LXAE7RAHORF2FJTSQ3DXEAV6DXVOML433X6HF"
OTHER = Keypair.random().public_key

def A(a): return Address(a).to_xdr_sc_val()

def dec(resp):
    for e in (resp.events or []):
        try:
            v = xdr.SCVal.from_xdr(e)
            print("  EV:", str(v)[:400])
        except Exception as ex:
            print("  EV(raw):", str(e)[:200])

if __name__ == "__main__":
    fn = sys.argv[1]
    if fn == "collect_protocol":
        for who,label in [(SRC,"self"),(OTHER,"other")]:
            print("===", label)
            r = sim(POOL, "collect_protocol", [A(who), scval.to_int128(0), scval.to_int128(0)])
            print("error:", (r.error or "")[:150])
            dec(r)
    elif fn == "protocol_fees":
        print(val(sim(POOL, "protocol_fees", [])))
        print(val(sim(POOL, "slot0", [])))
        print(val(sim(POOL, "liquidity", [])))
    elif fn == "mint":
        p = [A(SRC), A(SRC), scval.to_int32(0), scval.to_int32(10), scval.to_int128(100), scval.to_vec([])]
        r = sim(POOL, "mint", p)
        print("error:", (r.error or "")[:200])
        dec(r)
        if r.results: print("auth:", json.dumps(getattr(r.results[0],"auth",None), default=str)[:400])
