#!/usr/bin/env python3
"""Child1: scan optimizer detail toggles for the vase2 source vs live VASE."""
import json, subprocess, os

ANALYSIS = "/home/heisenberg/CA/rose/analysis"
solc_bin = os.path.expanduser("~/.solc-select/artifacts/solc-0.6.12/solc-0.6.12")
text = open(f"{ANALYSIS}/child1_vase2_flat.sol", newline='').read()
live = bytes.fromhex(json.load(open(f"{ANALYSIS}/child1_bytecodes.json"))["vase"]["code"][2:])

def strip_meta(c):
    ml = int.from_bytes(c[-2:], "big")
    return c[: -(ml + 2)]
live_body = strip_meta(live)

def compile_with(settings):
    inp = {"language": "Solidity", "sources": {"BentoBoxFlat.sol": {"content": text}}, "settings": settings}
    with open(f"{ANALYSIS}/child1_scan_stdin.json", "w") as f:
        json.dump(inp, f)
    with open(f"{ANALYSIS}/child1_scan_stdin.json") as f:
        r = subprocess.run([solc_bin, "--standard-json"], stdin=f, cwd=ANALYSIS, capture_output=True, text=True)
    out = json.loads(r.stdout)
    errs = [e for e in out.get("errors", []) if e.get("severity") == "error"]
    if errs:
        return None, None, errs[0].get("formattedMessage", "")[:150]
    art = out["contracts"]["BentoBoxFlat.sol"]["BentoBoxV1"]["evm"]["deployedBytecode"]
    return bytes.fromhex(art["object"]), art.get("immutableReferences", {}), None

def score(db, imm):
    b = bytearray(strip_meta(db)); lb = bytearray(live_body)
    for refs in imm.values():
        for r in refs:
            for k in range(r["length"]):
                p = r["start"] + k
                b[p] = 0
                if p < len(lb): lb[p] = 0
    n = min(len(b), len(lb))
    ndiff = sum(1 for i in range(n) if b[i] != lb[i])
    return len(b), ndiff

base = {"optimizer": {"enabled": True, "runs": 999999,
                      "details": {}},
        "metadata": {"bytecodeHash": "ipfs"},
        "outputSelection": {"*": {"*": ["evm.deployedBytecode", "evm.deployedBytecode.immutableReferences"]}}}

toggles = ["peepholeOptimizer", "jumpdestRemover", "orderLiterals", "deduplicate",
           "constantOptimizer", "yul", "cse", "inliner", "simplify", "unusedPruner",
           "dev::peephole", "jumpDestRemover", "typeBasedOptimization"]
print(f"live body: {len(live_body)}")
for t in toggles:
    s = json.loads(json.dumps(base))
    s["optimizer"]["details"][t] = False
    db, imm, err = compile_with(s)
    if err:
        print(f"{t}=false: SOLC ERR {err}")
        continue
    ln, nd = score(db, imm)
    print(f"{t}=false: len={ln} diffbytes={nd}")
# all details false
s = json.loads(json.dumps(base))
for t in toggles:
    s["optimizer"]["details"][t] = False
db, imm, err = compile_with(s)
if not err:
    ln, nd = score(db, imm)
    print(f"all false: len={ln} diffbytes={nd}")
