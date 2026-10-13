#!/usr/bin/env python3
"""Child1: recompile a variant with source maps, map compiled offsets -> source ranges."""
import json, subprocess, os, sys

ANALYSIS = "/home/heisenberg/CA/rose/analysis"
solc_bin = os.path.expanduser("~/.solc-select/artifacts/solc-0.6.12/solc-0.6.12")

def compile_with_maps(srcfile, tag):
    text = open(srcfile, newline='').read()
    inp = {
        "language": "Solidity",
        "sources": {"BentoBoxFlat.sol": {"content": text}},
        "settings": {
            "optimizer": {"enabled": True, "runs": 999999},
            "metadata": {"bytecodeHash": "ipfs"},
            "outputSelection": {"*": {"*": ["evm.deployedBytecode.object",
                                             "evm.deployedBytecode.sourceMap",
                                             "evm.deployedBytecode.generatedSources"]}},
        },
    }
    open(f"{ANALYSIS}/child1_stdin_maps.json", "w").write(json.dumps(inp))
    with open(f"{ANALYSIS}/child1_stdin_maps.json") as f:
        r = subprocess.run([solc_bin, "--standard-json"], stdin=f, cwd=ANALYSIS,
                           capture_output=True, text=True)
    out = json.loads(r.stdout)
    errs = [e for e in out.get("errors", []) if e.get("severity") == "error"]
    if errs:
        print("solc errors:", [e.get("formattedMessage", "")[:200] for e in errs]); sys.exit(1)
    json.dump(out, open(f"{ANALYSIS}/child1_maps_{tag}.json", "w"))
    return out

def parse_source_map(sm, code):
    """Walk code and source map in lockstep: each entry = one instruction.
    Returns list of dicts with code offset/size and source range."""
    entries = sm.split(";")
    res = []
    last = [0, 0, -1, 0, 0]   # s, l, f, j, m
    off = 0
    n = 0
    for e in entries:
        if e:
            parts = e.split(":")
            for i, p in enumerate(parts):
                if p == "":
                    continue
                if p in ("-", "i", "o"):
                    last[i] = p
                else:
                    last[i] = int(p)
        op = code[off]
        size = 1 + (op - 0x5f) if 0x60 <= op <= 0x7f else 1
        res.append({"off": off, "size": size, "s": last[0], "l": last[1],
                    "f": last[2], "j": last[3]})
        off += size
        n += 1
    return res, off, n

if __name__ == "__main__":
    srcfile = sys.argv[1]
    tag = sys.argv[2]
    offsets = [int(x) for x in sys.argv[3:]]
    out = compile_with_maps(srcfile, tag)
    art = out["contracts"]["BentoBoxFlat.sol"]["BentoBoxV1"]["evm"]["deployedBytecode"]
    db = bytes.fromhex(art["object"])
    print(f"{tag}: runtime {len(db)} bytes, metadata tail {db[-8:].hex()}")
    sm = art["sourceMap"]
    maps, consumed, nins = parse_source_map(sm, db)
    print(f"    source map: {nins} instructions, consumed {consumed} of {len(db)} code bytes")
    srctext = open(srcfile, newline='').read()
    # line index
    import bisect
    linestarts = [0]
    for i, ch in enumerate(srctext):
        if ch == '\n':
            linestarts.append(i + 1)
    def srcline(pos):
        li = bisect.bisect_right(linestarts, pos) - 1
        return li + 1
    for o in offsets:
        hit = None
        for ent in maps:
            if ent["off"] <= o < ent["off"] + ent["size"]:
                hit = ent
                break
        if hit:
            s, l = hit["s"], hit["l"]
            print(f"offset {o}: instr@{hit['off']} size={hit['size']} file={hit['f']} src=[{s},{s+l}] line={srcline(s)} jump={hit['j']}")
            print(f"    src text: {srctext[max(0,s):s+l][:200]!r}")
        else:
            print(f"offset {o}: no mapping (padding/metadata?)")
