#!/usr/bin/env python3
"""Full instruction-surface scan of the deployed store ELF via 32-bit discriminator halves.

Anchor 0.31 compiles the 8-byte instruction discriminator comparison into two 32-bit immediates
(the raw 8 bytes are not contiguous in the ELF), so we scan for both 4-byte halves. A random
4-byte collision is ~2^-32 per needle, so hits are real.

For each candidate commit we compute the set of instruction names in programs/store/src/lib.rs
and report presence/absence of their discriminator halves in the deployed ELF.
"""
import hashlib, json, os, re, struct, subprocess

REPO = "/tmp/opencode/gmx-solana-repo"
HERE = os.path.dirname(os.path.abspath(__file__))
ELF = os.path.join(HERE, "store_deployed.elf")

COMMITS = [
    ("8af1e70", "audit-2026-10-08"),
    ("1e05ae76", "2026-10-14 gt-delegate-record"),
    ("acaece1f", "2026-10-14 gt-rent-receiver-record"),
    ("884d121d", "2026-10-16 close-gt-exchange-v2"),
    ("7133cd1d", "2026-10-17 bundle"),
    ("928f2d32", "2026-10-17 builder-fee-accts"),
    ("c65fbd6d", "2026-10-18 npm"),
    ("d6d4dc7f", "2026-10-19 gt-manage-delegate"),
    ("a8f3937d", "2026-10-21 sdk"),
    ("f102501f", "2026-10-21 HEAD"),
]

def instr_names(commit):
    src = subprocess.run(["git", "-C", REPO, "show", f"{commit}:programs/store/src/lib.rs"],
                         capture_output=True, text=True).stdout
    return sorted(set(re.findall(r"^\s+pub fn ([a-z0-9_]+)", src, re.M)))

def disc(n):
    return hashlib.sha256(("global:" + n).encode()).digest()[:8]

def present(elf, n):
    x = disc(n)
    return (elf.count(x[:4]) > 0) and (elf.count(x[4:]) > 0)

def main():
    elf = open(ELF, "rb").read()
    # control: random non-existent names to estimate false positives
    import random
    random.seed(1)
    fp = 0
    for _ in range(500):
        n = "".join(random.choice("abcdefghijklmnopqrstuvwxyz_") for _ in range(16))
        if present(elf, n):
            fp += 1
    out = {"false_positive_controls": fp, "commits": {}}
    print(f"random-name false-positive control: {fp}/500\n")

    head = instr_names("f102501f")
    for commit, label in COMMITS:
        names = instr_names(commit)
        pres = [n for n in names if present(elf, n)]
        absent = [n for n in names if not present(elf, n)]
        out["commits"][commit] = {"label": label, "n": len(names),
                                  "present": len(pres), "absent": absent}
        print(f"{commit} {label}: {len(pres)}/{len(names)} present; absent={absent}")

    # Which HEAD instructions are absent (i.e., added after the deployed build)?
    head_absent = [n for n in head if not present(elf, n)]
    out["head_absent"] = head_absent
    print("\nHEAD instructions ABSENT from deployed ELF:", head_absent)
    with open(os.path.join(HERE, "discriminator_halves_scan.json"), "w") as f:
        json.dump(out, f, indent=2)

if __name__ == "__main__":
    main()
