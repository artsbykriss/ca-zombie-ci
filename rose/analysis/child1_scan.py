#!/usr/bin/env python3
"""Child1: scan compiler settings (optimize runs, evmVersion, optimizer on/off) for the vase2
source and score each artifact against live VASE (masked immutables+metadata)."""
import json, subprocess, os, sys

ANALYSIS = "/home/heisenberg/CA/rose/analysis"
solc_bin = os.path.expanduser("~/.solc-select/artifacts/solc-0.6.12/solc-0.6.12")

text = open(f"{ANALYSIS}/child1_vase2_flat.sol", newline='').read()
live = bytes.fromhex(json.load(open(f"{ANALYSIS}/child1_bytecodes.json"))["vase"]["code"][2:])

def strip_meta(c):
    ml = int.from_bytes(c[-2:], "big")
    return c[: -(ml + 2)]

live_body = strip_meta(live)

def compile_with(settings):
    inp = {
        "language": "Solidity",
        "sources": {"BentoBoxFlat.sol": {"content": text}},
        "settings": settings,
    }
    with open(f"{ANALYSIS}/child1_scan_stdin.json", "w") as f:
        json.dump(inp, f)
    with open(f"{ANALYSIS}/child1_scan_stdin.json") as f:
        r = subprocess.run([solc_bin, "--standard-json"], stdin=f, cwd=ANALYSIS,
                           capture_output=True, text=True)
    out = json.loads(r.stdout)
    errs = [e for e in out.get("errors", []) if e.get("severity") == "error"]
    if errs:
        return None, None, errs[0].get("formattedMessage", "")[:200]
    art = out["contracts"]["BentoBoxFlat.sol"]["BentoBoxV1"]["evm"]["deployedBytecode"]
    return bytes.fromhex(art["object"]), art.get("immutableReferences", {}), None

def body_and_diff(db, imm, nregions_limit=100):
    b = bytearray(strip_meta(db))
    lb = bytearray(live_body)
    for refs in imm.values():
        for r in refs:
            for k in range(r["length"]):
                p = r["start"] + k
                b[p] = 0
                if p < len(lb):
                    lb[p] = 0
    n = min(len(b), len(lb))
    # count differing bytes and regions (crude: not shift-tolerant, but informative)
    ndiff = sum(1 for i in range(n) if b[i] != lb[i])
    regs = 0
    i = 0
    while i < n:
        if b[i] != lb[i]:
            regs += 1
            while i < n and b[i] != lb[i]:
                i += 1
        else:
            i += 1
    return len(b), ndiff, regs

print(f"live vase body: {len(live_body)}")
print(f"{'settings':60s} {'len':>6s} {'diffbytes':>9s} {'regions':>7s}")
for runs in (1, 50, 200, 999, 10000, 200000, 999999, 1000000, 4294967295):
    settings = {"optimizer": {"enabled": True, "runs": runs},
                "metadata": {"bytecodeHash": "ipfs"},
                "outputSelection": {"*": {"*": ["evm.deployedBytecode", "evm.deployedBytecode.immutableReferences"]}}}
    db, imm, err = compile_with(settings)
    if err:
        print(f"runs={runs:<10d} ERROR {err}")
        continue
    ln, nd, rg = body_and_diff(db, imm)
    print(f"runs={runs:<10d} {'':47s} {ln:6d} {nd:9d} {rg:7d}")

# evmVersion scan at runs=999999
for evm in ("istanbul", "berlin", "petersburg", "constantinople"):
    settings = {"optimizer": {"enabled": True, "runs": 999999},
                "evmVersion": evm,
                "metadata": {"bytecodeHash": "ipfs"},
                "outputSelection": {"*": {"*": ["evm.deployedBytecode", "evm.deployedBytecode.immutableReferences"]}}}
    db, imm, err = compile_with(settings)
    if err:
        print(f"evm={evm:<10s} ERROR {err}")
        continue
    ln, nd, rg = body_and_diff(db, imm)
    print(f"evm={evm:<10s} {'':47s} {ln:6d} {nd:9d} {rg:7d}")

# optimizer off
settings = {"optimizer": {"enabled": False},
            "metadata": {"bytecodeHash": "ipfs"},
            "outputSelection": {"*": {"*": ["evm.deployedBytecode", "evm.deployedBytecode.immutableReferences"]}}}
db, imm, err = compile_with(settings)
if not err:
    ln, nd, rg = body_and_diff(db, imm)
    print(f"optimizer=off {'':47s} {ln:6d} {nd:9d} {rg:7d}")
