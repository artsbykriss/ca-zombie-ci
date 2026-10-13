#!/usr/bin/env python3
"""Child1: build flat source from Etherscan flattened bundle, compile variants with solc 0.6.12,
compare runtime bytecode with live contracts (masking immutables + metadata)."""
import json, re, subprocess, os, sys
from Crypto.Hash import keccak

ANALYSIS = "/home/heisenberg/CA/rose/analysis"
src = open(f"{ANALYSIS}/child1_bentobox_src.txt", newline='').read()

# split into sections at '// File <path>' markers
marks = [m for m in re.finditer(r'// File ([^\r\n]+)', src)]
sections = []   # (path, content)
first = src[:marks[0].start()]
sections.append(("__prologue__", first))
for i, m in enumerate(marks):
    end = marks[i+1].start() if i+1 < len(marks) else len(src)
    content = src[m.end():end]
    sections.append((m.group(1).strip(), content))

# flat source: everything except the '// File' marker comments themselves
flat = src
flat = re.sub(r'// File [^\r\n]+\r?\n', '', flat)
open(f"{ANALYSIS}/child1_bentobox_flat.sol", "w", newline='').write(flat)
print("flat source written:", len(flat), "bytes")

def compile_stdjson(source_text, outfile):
    inp = {
        "language": "Solidity",
        "sources": {"BentoBoxFlat.sol": {"content": source_text}},
        "settings": {
            "optimizer": {"enabled": True, "runs": 999999},
            "metadata": {"bytecodeHash": "ipfs"},
            "outputSelection": {"*": {"*": ["abi", "evm.deployedBytecode", "evm.deployedBytecode.immutableReferences", "metadata"]}},
        },
    }
    open(f"{ANALYSIS}/child1_stdin.json", "w").write(json.dumps(inp))
    solc_bin = os.path.expanduser("~/.solc-select/artifacts/solc-0.6.12/solc-0.6.12")
    with open(f"{ANALYSIS}/child1_stdin.json") as f:
        r = subprocess.run([solc_bin, "--standard-json"], stdin=f,
                           cwd=ANALYSIS, capture_output=True, text=True)
    if r.returncode != 0:
        print("solc failed:", r.stderr[:2000])
        sys.exit(1)
    out = json.loads(r.stdout)
    if "errors" in out:
        for e in out["errors"]:
            if e.get("severity") == "error":
                print("SOLC ERROR:", e.get("formattedMessage", e)[:600])
        errs = [e for e in out["errors"] if e.get("severity") == "error"]
        if errs:
            sys.exit(1)
    json.dump(out, open(outfile, "w"))
    return out

if __name__ == "__main__":
    variant = sys.argv[1] if len(sys.argv) > 1 else "original"
    text = flat
    if variant in ("renamed", "vase1", "vase2", "vase3"):
        text = text.replace("BentoBox: ", "Vase: ")
        print("rename 'BentoBox: ' -> 'Vase: ' x", flat.count("BentoBox: "))
    if variant in ("vase2", "vase3"):
        before = text
        text = text.replace('keccak256("BentoBox V1")', 'keccak256("Vase")')
        text = text.replace("BentoBox?", "Vase?")
        assert text != before, "domain/warning-name patch did not apply"
        print("renamed domain name -> 'Vase' and warning strings")
    if variant in ("vase1", "vase2", "vase3"):
        before = text
        text = text.replace("STRATEGY_DELAY = 2 weeks;", "STRATEGY_DELAY = 0;")
        assert text != before, "STRATEGY_DELAY patch did not apply"
        print("STRATEGY_DELAY -> 0 applied")
    if variant == "vase3":
        # guess: batch is public instead of external
        before = text
        text = text.replace("function batch(bytes[] calldata calls, bool revertOnFail) external payable",
                            "function batch(bytes[] calldata calls, bool revertOnFail) public payable")
        print("batch public patch:", "applied" if text != before else "NO MATCH")
    if variant in ("vase4", "vase6"):
        before = text
        text = text.replace("        bytes calldata data,\r\n        bool useCreate2",
                            "        bytes memory data,\r\n        bool useCreate2")
        print("deploy bytes memory patch:", "applied" if text != before else "NO MATCH")
    if variant in ("vase5", "vase6"):
        before = text
        text = text.replace("function batch(bytes[] calldata calls, bool revertOnFail) external payable",
                            "function batch(bytes[] memory calls, bool revertOnFail) external payable")
        print("batch bytes[] memory patch:", "applied" if text != before else "NO MATCH")
    open(f"{ANALYSIS}/child1_{variant}_flat.sol", "w", newline='').write(text)
    out = compile_stdjson(text, f"{ANALYSIS}/child1_solc_{variant}.json")
    for fname, c in out["contracts"].items():
        for cname, art in c.items():
            if cname != "BentoBoxV1":
                continue
            db = art["evm"]["deployedBytecode"]["object"]
            print(f"{variant}: compiled {fname}:{cname} runtime {len(db)//2} bytes")
            imm = art["evm"]["deployedBytecode"].get("immutableReferences", {})
            print("  immutables:", json.dumps(imm)[:300])
