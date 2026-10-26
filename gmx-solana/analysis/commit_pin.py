#!/usr/bin/env python3
"""Pin the deployed store commit by string-literal set matching.

All candidate commits 8af1e70..6cc72716 have the same 134-instruction surface, so we distinguish
them by the set of string literals present in programs/store/src at each commit vs those found in
the deployed ELF.
"""
import os, re, subprocess, json

REPO = "/tmp/opencode/gmx-solana-repo"
HERE = os.path.dirname(os.path.abspath(__file__))
ELF = os.path.join(HERE, "store_deployed.elf")

CAND = [
    ("8af1e70", "audit-2026-10-08"),
    ("76818869", "2026-10-13 sdk"),
    ("2c368773", "2026-10-13 docs"),
    ("dfeaf14e", "2026-10-14 bump"),
    ("e2aa230a", "2026-10-14 credit-gt"),
    ("1e05ae76", "2026-10-14 gt-delegate-record"),
    ("acaece1f", "2026-10-14 gt-rent-receiver"),
    ("6cc72716", "2026-10-15 cli"),
]

def files(commit):
    r = subprocess.run(["git", "-C", REPO, "ls-tree", "-r", "--name-only", commit,
                        "programs/store/src"], capture_output=True, text=True)
    return r.stdout.split()

def literals(commit):
    lits = set()
    for f in files(commit):
        if not f.endswith(".rs"):
            continue
        src = subprocess.run(["git", "-C", REPO, "show", f"{commit}:{f}"],
                             capture_output=True, text=True).stdout
        # string literals >=10 chars, no escapes (approximate but consistent)
        for m in re.findall(r'"([^"\\\n]{10,})"', src):
            lits.add(m)
    return lits

def main():
    elf = open(ELF, "rb").read()
    sets = {}
    for c, l in CAND:
        sets[c] = literals(c)
    base = sets["8af1e70"]
    out = {"commits": {}}
    for c, label in CAND:
        s = sets[c]
        missing = sorted(x for x in s if x.encode() not in elf)          # in source, not in ELF
        extra_added = sorted(x for x in (s - base) if x.encode() in elf)  # added after audit AND in ELF
        out["commits"][c] = {"label": label, "n_lits": len(s),
                             "n_missing_in_elf": len(missing),
                             "added_after_audit_present_in_elf": extra_added,
                             "added_after_audit": sorted(s - base)}
        print(f"{c} {label}: lits={len(s)} missing_in_elf={len(missing)} "
              f"added_after_audit={len(s-base)} added_present_in_elf={len(extra_added)}")
        for x in extra_added:
            print("    ADDED-AFTER-AUDIT & IN ELF:", x[:100])
    with open(os.path.join(HERE, "commit_pin.json"), "w") as f:
        json.dump(out, f, indent=2)

if __name__ == "__main__":
    main()
