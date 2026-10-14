#!/usr/bin/env python3
"""Focused variant probe for one chain+addresses (fast, minimal calls)."""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpcb as B

SELS = [
    ("stable()", "0x22be3de1"),
    ("fees()", "0x9af1d35a"),
    ("_transferFeesSupportingTaxTokens(address,uint256)", "0xec7e683d"),
    ("kLast()", "0x7464fc3d"),
    ("isPaused()", "0xb187bd26"),
    ("protocolFeesShare()", "0xafda13e9"),
    ("protocolFeesRecipient()", "0x68930637"),
    ("pauser()", "0x9fd0506d"),
    ("owner()", "0x8da5cb5b"),
    ("feeTo()", "0x017e7e58"),
    ("skim(address)", "0xbc25cf77"),
    ("sync()", "0xfff6cae9"),
    ("mint(address)", "0x6a627842"),
    ("burn(address)", "0x89afcb44"),
]

def probe(chain, addrs):
    for a in addrs:
        print("---", a, flush=True)
        calls = [("eth_call", [{"to": a, "data": s}, "latest"]) for _, s in SELS]
        try:
            rs = B.batch(chain, calls)
        except Exception as e:
            print("  batch fail", str(e)[:120]); continue
        for (name, sel), r in zip(SELS, rs):
            if r is None or r == "0x":
                print(f"  {name:55s} ABSENT/REVERT")
            else:
                ws = B.words(r)
                if len(r) == 66:
                    print(f"  {name:55s} word0={B.dec_uint(ws[0])}")
                else:
                    print(f"  {name:55s} ret={r[:80]}")
        print("  code_size", len(B.code(chain, a) or "0x") // 2)

if __name__ == "__main__":
    chain = sys.argv[1]
    probe(chain, sys.argv[2:])
