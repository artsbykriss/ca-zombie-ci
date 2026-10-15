#!/usr/bin/env python3
"""Find first-log block for each market via binary search over 50k-block chunks."""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc_batch, block_number

MKTS = {
 "seFDUSD": "0xfe62ba7400d902A9773dA9F7469dA457cF54a565",
 "seUSDT": "0x7ADd376cF7b33B7d09B0F0f4Ef0a741C3cB95102",
 "seETH": "0x81b98b2896f1F262714F12Be36264AA8E02A08D2",
 "seBTC": "0x567558167F102BB45c0437F1Fd5a527c5c534c3C",
 "seBNB": "0x7e844423510A5081DE839e600F7960C7cE84eb82",
}
CHUNK = 50000

def any_logs(addr, lo, hi):
    r = rpc_batch([("eth_getLogs", [{"fromBlock": hex(lo), "toBlock": hex(hi), "address": addr}])])[0]
    if isinstance(r, dict):
        raise RuntimeError(r)
    return len(r)

def first_log_block(addr, tip):
    lo, hi = 0, tip
    # ensure there are logs at all
    if any_logs(addr, tip - CHUNK + 1, tip) == 0:
        # search backwards in chunks
        b = tip
        while b > 0:
            nb = max(0, b - CHUNK)
            if any_logs(addr, nb, b) > 0:
                break
            b = nb
        if b == 0:
            return None
    # binary search boundary: find smallest x such that logs exist in [x, tip]
    lo, hi = 0, tip
    while lo < hi:
        mid = (lo + hi) // 2
        # query [mid, min(mid+CHUNK-1, tip)] to test presence near mid
        hi2 = min(mid + CHUNK - 1, tip)
        if any_logs(addr, mid, hi2) > 0:
            hi = mid
        else:
            # no logs in [mid, mid+chunk); continue searching upward
            lo = mid + 1
    return lo

if __name__ == "__main__":
    tip = block_number()
    print("tip", tip, flush=True)
    out = {}
    for name, addr in MKTS.items():
        b = first_log_block(addr, tip)
        out[name] = b
        print(name, addr, "first_log_block", b, flush=True)
    json.dump(out, open("/tmp/opencode/deploy_blocks.json", "w"), indent=1)
