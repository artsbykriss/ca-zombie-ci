#!/usr/bin/env python3
"""Child1: find best instruction phase for a region, then disassemble it.

Anomaly score for a phase: count of INVALID (0xfe) instructions, plus count of
JUMP/JUMPI not immediately preceded by PUSH2, plus count of PUSH2 immediates
that lie inside the region and do not point at a JUMPDEST byte.
"""
import json, sys
sys.path.insert(0, ".")
from child1_disasm import dis, OPS

d = json.load(open("child1_bytecodes.json"))

def body(name):
    code = bytes.fromhex(d[name]["code"][2:])
    ml = int.from_bytes(code[-2:], "big")
    return code[: -(ml + 2)]

def score(code, start, end):
    i = start
    anomalies = 0
    prev = None
    insns = []
    while i < end:
        op = code[i]
        if op == 0xfe:
            anomalies += 2
        if 0x60 <= op <= 0x7f:
            ln = op - 0x5f
            if op == 0x61:
                tgt = int.from_bytes(code[i+1:i+3], "big")
                if start <= tgt < end and (tgt >= len(code) or code[tgt] != 0x5b):
                    anomalies += 1
            val = code[i+1:i+1+ln]
            raw = code[i:i+1+ln]
            i += 1 + ln
            insns.append((start if not insns else None, op, raw))
        else:
            if op in (0x56, 0x57):
                # check previous instruction was PUSH2
                if not (prev is not None and prev[0] == 0x61):
                    anomalies += 1
            raw = code[i:i+1]
            i += 1
            insns.append((None, op, raw))
        prev = (op,)
        if len(insns) > 4000:
            break
    return anomalies

def best_phase(code, s, e):
    # a phase p means disassembly starts at s - p; score over [s-p, e]
    best = None
    for p in range(0, 16):
        st = s - p
        if st < 0:
            continue
        sc = score(code, st, e)
        if best is None or sc < best[0]:
            best = (sc, p, st)
    return best

if __name__ == "__main__":
    which = sys.argv[1]
    s = int(sys.argv[2])
    e = int(sys.argv[3])
    code = body(which)
    sc, p, st = best_phase(code, s, e)
    print(f"# {which}: best phase p={p} start={st} score={sc}")
    for off, mnem, raw in dis(code, st, 200):
        if off > e:
            break
        print(f"{off:6d}: {raw:<50} {mnem}")
