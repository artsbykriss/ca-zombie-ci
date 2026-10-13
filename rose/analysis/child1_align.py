#!/usr/bin/env python3
"""Child1: instruction-level alignment between compiled vase1 and live vase.

Linear-disassemble both, align instruction sequences with difflib, then classify
every replacement region:
  - SHIFT: same opcode sequence; all payload diffs are PUSH2 whose value differs by
    the local shift and both point at JUMPDESTs
  - IMMUTABLE: region inside known immutable slots (should be masked already)
  - FACTOR: the 3 known ABI-helper factoring regions (semantic check done separately)
  - UNEXPLAINED: anything else
"""
import json, sys
from difflib import SequenceMatcher
sys.path.insert(0, ".")
from child1_disasm import OPS

ANALYSIS = "/home/heisenberg/CA/rose/analysis"

def dis_linear(code):
    ins = []
    i = 0
    n = len(code)
    while i < n:
        op = code[i]
        if 0x60 <= op <= 0x7f:
            ln = op - 0x5f
            ins.append((i, op, code[i+1:i+1+ln]))
            i += 1 + ln
        else:
            ins.append((i, op, b""))
            i += 1
    return ins

def strip_meta(c):
    ml = int.from_bytes(c[-2:], "big")
    return c[: -(ml + 2)]

def load_pair():
    variant = sys.argv[1] if len(sys.argv) > 1 else "vase1"
    live_name = sys.argv[2] if len(sys.argv) > 2 else "vase"
    out = json.load(open(f"{ANALYSIS}/child1_solc_{variant}.json"))
    db = bytes.fromhex(out["contracts"]["BentoBoxFlat.sol"]["BentoBoxV1"]["evm"]["deployedBytecode"]["object"])
    imm = out["contracts"]["BentoBoxFlat.sol"]["BentoBoxV1"]["evm"]["deployedBytecode"].get("immutableReferences", {})
    d = json.load(open(f"{ANALYSIS}/child1_bytecodes.json"))
    live = bytes.fromhex(d[live_name]["code"][2:])
    A, B = bytearray(strip_meta(db)), bytearray(strip_meta(live))
    for refs in imm.values():
        for r in refs:
            for k in range(r["length"]):
                p = r["start"] + k
                A[p] = 0
                if p < len(B):
                    B[p] = 0
    return bytes(A), bytes(B)

def main():
    A, B = load_pair()
    ia, ib = dis_linear(A), dis_linear(B)
    print("compiled bytes:", len(A), "->", len(ia), "instructions")
    print(f"live vase     : {len(B)} bytes -> {len(ib)} instructions")

    ka = [(op, pl.hex()) for _, op, pl in ia]
    kb = [(op, pl.hex()) for _, op, pl in ib]
    sm = SequenceMatcher(None, ka, kb, autojunk=False)
    blocks = sm.get_matching_blocks()
    print(f"matching blocks: {len(blocks)}, matched instructions: {sum(b.size for b in blocks)}")

    # classify
    shift = 0
    report = []
    for bi in range(len(blocks) - 1):
        b = blocks[bi]
        nb = blocks[bi + 1]
        a_end = b.a + b.size
        b_end = b.b + b.size
        a_next = nb.a
        b_next = nb.b
        if a_end == a_next and b_end == b_next:
            continue  # contiguous
        # replacement region: instructions ia[a_end:a_next] vs ib[b_end:b_next]
        regA = ia[a_end:a_next]
        regB = ib[b_end:b_next]
        shift = regB[0][0] - regA[0][0] if regA and regB else shift
        entry = {
            "a_ins": (a_end, a_next), "b_ins": (b_end, b_next),
            "a_bytes": (regA[0][0] if regA else None, (regA[-1][0] + 1 + (regA[-1][1] - 0x5f if 0x60 <= regA[-1][1] <= 0x7f else 0)) if regA else None),
            "b_bytes": (regB[0][0] if regB else None, (regB[-1][0] + 1 + (regB[-1][1] - 0x5f if 0x60 <= regB[-1][1] <= 0x7f else 0)) if regB else None),
            "n_a": len(regA), "n_b": len(regB),
            "a_ops": [op for _, op, _ in regA],
            "b_ops": [op for _, op, _ in regB],
        }
        # classification
        if len(regA) == len(regB) and entry["a_ops"] == entry["b_ops"]:
            # same opcode sequence: check payload diffs
            ok = True
            details = []
            for (oa, opa, pla), (ob, opb, plb) in zip(regA, regB):
                if pla == plb:
                    continue
                if opa == 0x61 and opb == 0x61:  # PUSH2
                    va = int.from_bytes(pla, "big"); vb = int.from_bytes(plb, "big")
                    d = vb - va
                    tgt_ok = (vb < len(B) and B[vb] == 0x5b) and (va < len(A) and A[va] == 0x5b)
                    details.append((oa, va, vb, d, tgt_ok))
                    if not tgt_ok:
                        ok = False
                else:
                    ok = False
                    details.append((oa, pla.hex(), plb.hex(), None, None))
            entry["class"] = "SHIFT" if ok else "PAYLOAD"
            entry["details"] = details
        else:
            entry["class"] = "STRUCT"
        report.append(entry)

    from collections import Counter
    print(Counter(e["class"] for e in report))
    for e in report:
        if e["class"] != "SHIFT":
            print(f"\n### {e['class']} a_ins {e['a_ins']} b_ins {e['b_ins']} | a_bytes {e['a_bytes']} b_bytes {e['b_bytes']}")
            if e["class"] == "SHIFT":
                pass
            print(f"    a_ops: {[hex(o) for o in e['a_ops'][:80]]}")
            print(f"    b_ops: {[hex(o) for o in e['b_ops'][:80]]}")
            if "details" in e and e["class"] == "PAYLOAD":
                print(f"    payload diffs: {e['details'][:10]}")
        else:
            # summarize shift deltas
            ds = {d for (_, va, vb, d, ok) in e.get("details", []) if d is not None}
            if ds:
                for d in sorted(ds):
                    pass
    # aggregate shift deltas observed
    allg = [d for e in report for (_, va, vb, d, ok) in e.get("details", []) if d is not None]
    from collections import Counter as C2
    print("\nPUSH2 target deltas (compiled->live):", C2(allg).most_common())
    # verify all SHIFT details ok
    bad = [e for e in report if e["class"] == "SHIFT" and not all(x[4] for x in e["details"])]
    print("SHIFT regions with invalid jumpdest:", len(bad))
    json.dump([{k: v for k, v in e.items() if k != "details"} |
               ({"details": e["details"]} if "details" in e else {}) for e in report],
              open(f"{ANALYSIS}/child1_align_report.json", "w"), indent=1, default=str)

if __name__ == "__main__":
    main()
