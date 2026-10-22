#!/usr/bin/env python3
"""Materialize an Etherscan standard-JSON source bundle into a Foundry project so
that the *exact* deployed bytecode can be reproduced locally.

Usage: python3 analysis/materialize_verified.py <verified-json> <outdir>
Writes <outdir>/src/**  (all 73 sources at their original paths) and <outdir>/foundry.toml
with the compiler settings + library linking taken verbatim from the verification record.
"""
import json, os, sys, textwrap

def main():
    vjson, outdir = sys.argv[1], sys.argv[2]
    d = json.load(open(vjson))
    r = d["result"][0]
    sc = r["SourceCode"].strip()
    if sc.startswith("{{"):
        sc = sc[1:-1]
    sj = json.loads(sc)
    settings = sj["settings"]
    srcs = sj["sources"]

    # wipe + recreate
    os.system(f"rm -rf {outdir}")
    os.makedirs(outdir, exist_ok=True)
    for path, obj in srcs.items():
        p = os.path.join(outdir, path)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "w") as f:
            f.write(obj.get("content", ""))

    opt = settings.get("optimizer", {})
    libs = settings.get("libraries", {})
    remaps = settings.get("remappings", [])
    lines = [
        "[profile.default]",
        'src = "."',
        'out = "out"',
        'libs = ["lib"]',
        f'solc = "{r["CompilerVersion"].lstrip("v").split("+")[0]}"',
        f'optimizer = {str(bool(opt.get("enabled", True))).lower()}',
        f'optimizer_runs = {opt.get("runs", 200)}',
        f'evm_version = "{settings.get("evmVersion", "cancun")}"',
        f'via_ir = {str(bool(settings.get("viaIR", False))).lower()}',
        f'bytecode_hash = "{settings.get("metadata", {}).get("bytecodeHash", "ipfs")}"',
        f'cbor_metadata = {str(bool(settings.get("metadata", {}).get("appendCBOR", True))).lower()}',
    ]
    if remaps:
        lines.append("remappings = [")
        for rem in remaps:
            lines.append(f'  "{rem}",')
        lines.append("]")
    lines.append("")
    if libs:
        entries = []
        for f, m in libs.items():
            for name, addr in m.items():
                entries.append(f'"{f}:{name}:{addr}"')
        lines.append(f"libraries = [{', '.join(entries)}]")
        lines.append("")
    open(os.path.join(outdir, "foundry.toml"), "w").write("\n".join(lines))
    print(f"materialized {len(srcs)} sources -> {outdir}")
    print(f"compiler={r['CompilerVersion']} runs={opt.get('runs')} evm={settings.get('evmVersion')} libs={libs}")

if __name__ == "__main__":
    main()
