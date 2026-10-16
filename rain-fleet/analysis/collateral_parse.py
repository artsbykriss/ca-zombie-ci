#!/usr/bin/env python3
"""Parse Collateral + Coordinator account data. Detect admin lists, thresholds, vaults."""
import sys, json, base64
import sol_rpc as S

def get_raw(addr):
    a = S.get_account(addr)
    if not a or not a.get("value"):
        return None
    return base64.b64decode(a["value"]["data"][0])

def hexdump(b, start=0, end=None):
    end = end or len(b)
    for i in range(start, min(end, len(b)), 16):
        chunk = b[i:i+16]
        print(f"  {i:4d}: {chunk.hex(' ')}  |{''.join(chr(c) if 32<=c<127 else '.' for c in chunk)}|")

def find_pubkeys(b):
    """Scan for 32-byte windows that look like pubkeys and test on-curve."""
    out = []
    for off in range(0, len(b)-32+1, 1):
        cand = b[off:off+32]
        s = S.b58encode(cand)
        out.append((off, s))
    return out

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "dump":
        for addr in sys.argv[2:]:
            raw = get_raw(addr)
            print(f"=== {addr} len={len(raw) if raw else None} ===")
            if raw: hexdump(raw)
    elif cmd == "pk":
        addr = sys.argv[2]
        raw = get_raw(addr)
        print(f"=== {addr} len={len(raw)} ===")
        # print all 32-byte-aligned windows as base58 (likely pubkey fields)
        for off in range(0, len(raw)-32+1, 1):
            s = S.b58encode(raw[off:off+32])
            if 32 <= len(s) <= 44:
                print(f"  off {off:4d}: {s}")
