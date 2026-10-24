#!/usr/bin/env python3
"""Probe: is any contract an authorized router (swap_prefunded path)? And audit pool admins."""
import sys, json
from stellar_sdk import scval, Address, xdr
sys.path.insert(0, "/home/heisenberg/CA/sushi-stellar/analysis")
from state import sim, val
from sval import py

POOL = "CA5R5L7QE7WC2M4YAPSBITV7M2R6LX5366UURH3REHQMOJV6R5QWTH2K"
CANDIDATES = {
  "router": "CDMIM23WOUL5CZBKX3GOA3V5R5AMVIMTCP52KCDQORWELAPLJ27WZCHL",
  "posmgr": "CARTUL5AWDZYBSN7HUUJZSKCAKCIAKM7M54Z76G6KRYCK4XPR3OHUQZ4",
  "lens": "CASKWJSINHFW7BF7RUOA4E2FP6B2TYRKFX2UOPWLCPOOPUR6UU3G2RWC",
  "flash_exec": "CDKKPFBNNQETVN4Y2CIU6CQMWCPIZDXDZE76IDSTF7HLQT6Q573PCDTH",
  "factory": "CD3KRKGDRVWPXVB3VXLUMQKMX6XZ6Q2H334IVZD4XXNAMKSRVQL5GLYF",
}
def hints(): return scval.to_struct({"checkpoint": scval.to_uint32(0), "checkpoint_min": scval.to_uint32(0), "slot": scval.to_uint128(0)})

if __name__ == "__main__":
    for lab, r in CANDIDATES.items():
        p = [Address(r).to_xdr_sc_val(), Address(r).to_xdr_sc_val(), scval.to_bool(True),
             scval.to_int128(1), scval.to_uint256(4295128739), hints()]
        resp = sim(POOL, "swap_prefunded", p)
        err = (resp.error or "NONE").split("\n")[0]
        print(f"swap_prefunded(router={lab}): {err}")
