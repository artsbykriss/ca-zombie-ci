#!/usr/bin/env python3
"""Read-only auth probe v2 — correct argument types (u128 amounts, OracleHints struct).
simulateTransaction only; never signs, never sends.
"""
import sys, json
from stellar_sdk import scval, Address, xdr, Keypair
sys.path.insert(0, "/home/heisenberg/CA/sushi-stellar/analysis")
from state import sim, val
from sval import py

POOL = "CA5R5L7QE7WC2M4YAPSBITV7M2R6LX5366UURH3REHQMOJV6R5QWTH2K"
FACTORY = "CD3KRKGDRVWPXVB3VXLUMQKMX6XZ6Q2H334IVZD4XXNAMKSRVQL5GLYF"
SRC = "GCFB64LD5OX6XXUQW44LXAE7RAHORF2FJTSQ3DXEAV6DXVOML433X6HF"
OTHER = Keypair.random().public_key
FLASH_EXEC = "CDKKPFBNNQETVN4Y2CIU6CQMWCPIZDXDZE76IDSTF7HLQT6Q573PCDTH"

def A(a): return Address(a).to_xdr_sc_val()
def hints(checkpoint=0, cmin=0, slot=0):
    return scval.to_struct({"checkpoint": scval.to_uint32(checkpoint),
                            "checkpoint_min": scval.to_uint32(cmin),
                            "slot": scval.to_uint128(slot)})

def show(label, resp):
    err = getattr(resp, "error", None)
    auth = resp.results[0].auth if resp.results else None
    print(f"--- {label}")
    if err: print("    ERROR:", err.replace("\n", " | ")[:180])
    if auth: print("    AUTH-REQUIRED:", json.dumps(auth, default=str)[:600])
    if not err and resp.results:
        print("    RETVAL:", py(val(resp)) if not isinstance(val(resp), dict) else val(resp))

BIG = 10**20

def run():
    tests = [
      ("collect_protocol(self,MAX,MAX)", "collect_protocol", [A(SRC), scval.to_uint128(BIG), scval.to_uint128(BIG)]),
      ("collect_protocol(other,MAX,MAX)", "collect_protocol", [A(OTHER), scval.to_uint128(BIG), scval.to_uint128(BIG)]),
      ("collect_protocol(self,1,1)", "collect_protocol", [A(SRC), scval.to_uint128(1), scval.to_uint128(1)]),
      ("flash_begin(self,1,1,self)", "flash_begin", [A(SRC), scval.to_uint128(1), scval.to_uint128(1), A(SRC)]),
      ("flash_begin(self,1,1,flash_exec)", "flash_begin", [A(SRC), scval.to_uint128(1), scval.to_uint128(1), A(FLASH_EXEC)]),
      ("flash_end()", "flash_end", []),
      ("set_router_authorized(factory,self,true)", "set_router_authorized", [A(FACTORY), A(SRC), scval.to_bool(True)]),
      ("mint(self,self,0,10,100,{})", "mint", [A(SRC), A(SRC), scval.to_int32(0), scval.to_int32(10), scval.to_uint128(100), hints()]),
      ("burn(self,0,10,1,{})", "burn", [A(SRC), scval.to_int32(0), scval.to_int32(10), scval.to_uint128(1), hints()]),
      ("collect(self,self,0,10,1,1)", "collect", [A(SRC), A(SRC), scval.to_int32(0), scval.to_int32(10), scval.to_uint128(1), scval.to_uint128(1)]),
      ("swap(self,self,true,1000,min,{})", "swap", [A(SRC), A(SRC), scval.to_bool(True), scval.to_int128(1000), scval.to_uint256(4295128739), hints()]),
      ("swap_prefunded(self,self,true,1000,min,{})", "swap_prefunded", [A(SRC), A(SRC), scval.to_bool(True), scval.to_int128(1000), scval.to_uint256(4295128739), hints()]),
      ("initialize(2^96)", "initialize", [scval.to_uint256(2**96)]),
      ("poke_oracle()", "poke_oracle", []),
    ]
    for label, fn, params in tests:
        try:
            show(label, sim(POOL, fn, params))
        except Exception as e:
            print(f"--- {label}\n    EXC: {e}")

if __name__ == "__main__":
    run()
