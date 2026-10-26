#!/usr/bin/env python3
"""Compare a locally-built gmsol_store.so against the deployed program's instruction surface.

Method (same as the offline analysis): Anchor 0.31 compiles the 8-byte instruction discriminator
comparison into two 32-bit immediates, so the raw 8 bytes are not contiguous in the ELF. We
therefore scan for both 4-byte halves of sha256("global:<name>")[:8].
"""
import hashlib, json, os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.join(HERE, "..", "ci-work")
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "..", "ci-out")
DEPLOYED_SHA = "8fbdc5cf1a446b467460764990a2002360ebde330513fa45d8e57e7ce2b00e15"

def instr_names(commit):
    src = subprocess.run(["git", "-C", REPO, "show", f"{commit}:programs/store/src/lib.rs"],
                         capture_output=True, text=True).stdout
    return sorted(set(re.findall(r"^\s+pub fn ([a-z0-9_]+)", src, re.M)))

def present(elf, name):
    x = hashlib.sha256(("global:" + name).encode()).digest()[:8]
    return elf.count(x[:4]) > 0 and elf.count(x[4:]) > 0

def main():
    head = instr_names("f102501")
    report = {"deployed_sha256_trunc": DEPLOYED_SHA, "built": {}}
    for tag in ("8af1e70", "f102501"):
        p = os.path.join(OUT, f"gmsol_store_{tag}.so")
        if not os.path.exists(p):
            print(f"{tag}: no built ELF")
            continue
        elf = open(p, "rb").read()
        sha = hashlib.sha256(elf).hexdigest()
        pres = [n for n in head if present(elf, n)]
        absent = [n for n in head if not present(elf, n)]
        report["built"][tag] = {"sha256": sha, "size": len(elf),
                                "present": len(pres), "absent": absent,
                                "sha_matches_deployed": sha == DEPLOYED_SHA}
        print(f"{tag}: sha256={sha} size={len(elf)} instr_present={len(pres)}/{len(head)} "
              f"absent={absent} sha_matches_deployed={sha == DEPLOYED_SHA}")
    with open(os.path.join(OUT, "compare.json"), "w") as f:
        json.dump(report, f, indent=2)

if __name__ == "__main__":
    main()
