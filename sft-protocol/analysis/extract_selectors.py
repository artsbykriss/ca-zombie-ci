#!/usr/bin/env python3
"""Extract 4-byte function selectors from EVM runtime bytecode.

Heuristic: scan for PUSH4 (0x63) opcodes whose immediate value is followed
by dispatch-style opcodes (EQ 0x14, ISZERO 0x15, DUP1 0x80, DUP2 0x81,
JUMPI 0x57, SHR 0x1c ...) OR any PUSH4 constant that appears before a JUMPI.
Also picks selectors referenced via `0x1c` SHR of calldata loads (compiler>=0.8
dispatch via `shr(224, calldataload(0))`), which still uses PUSH4 constants.
"""
import sys, json

def main(path):
    h = open(path).read().strip()
    if h.startswith('0x'):
        h = h[2:]
    b = bytes.fromhex(h)
    cands = {}
    i = 0
    n = len(b)
    while i < n:
        op = b[i]
        if op == 0x63 and i + 4 < n:  # PUSH4
            sel = b[i+1:i+5]
            nxt = b[i+5] if i+5 < n else None
            nxt2 = b[i+6] if i+6 < n else None
            # dispatch-ish: PUSH4 sel EQ / DUP / JUMPI, or PUSH4 sel followed by SHR? (rare)
            if nxt in (0x14, 0x15, 0x80, 0x81, 0x82, 0x90, 0x91, 0x57, 0x1c) or nxt2 in (0x14, 0x57):
                cands[sel.hex()] = cands.get(sel.hex(), 0) + 1
            i += 5
        else:
            # skip push immediates
            if 0x60 <= op <= 0x7f:
                i += 1 + (op - 0x5f)
            else:
                i += 1
    print(json.dumps([{'selector': '0x'+k, 'hits': v} for k, v in sorted(cands.items(), key=lambda kv: -kv[1])], indent=1))

if __name__ == '__main__':
    main(sys.argv[1])
