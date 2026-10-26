#!/usr/bin/env python3
"""Find string literals introduced by each post-audit commit and test presence in the deployed ELF.

If the deployed ELF contains a literal that only exists at commit X (and later), the deployed
program includes X. This pins the deployed commit without a full rebuild.
"""
import os, re, subprocess, json

REPO = "/tmp/opencode/gmx-solana-repo"
HERE = os.path.dirname(os.path.abspath(__file__))
ELF = os.path.join(HERE, "store_deployed.elf")

# commit -> parent-ish: we diff each commit against its own parent to get exactly what it added
CAND = [
    ("8af1e70", "audit"),
    ("1e05ae76", "gt-delegate-record"),
    ("acaece1f", "gt-rent-receiver-record"),
    ("884d121d", "close-gt-exchange"),
    ("d6d4dc7f", "gt-manage-delegate-allowance"),
    ("f102501f", "delegated-gt-exchange-v2"),
]

def sh(*a):
    return subprocess.run(a, cwd=REPO, capture_output=True, text=True).stdout

def added_literals(commit):
    """String literals (>=8 chars) added in programs/store/src by this commit vs its first parent."""
    files = sh("git", "diff", "--name-only", f"{commit}^", commit, "--", "programs/store/src").split()
    lits = set()
    for f in files:
        d = sh("git", "diff", f"{commit}^", commit, "--", f)
        for line in d.splitlines():
            if line.startswith("+") and not line.startswith("+++"):
                for m in re.findall(r'"([^"\\]{8,})"', line):
                    lits.add(m)
    return sorted(lits)

def main():
    elf = open(ELF, "rb").read()
    out = {}
    for commit, label in CAND:
        lits = added_literals(commit)
        rows = []
        for L in lits:
            rows.append({"lit": L, "in_elf": L.encode() in elf})
        present = [r for r in rows if r["in_elf"]]
        out[commit] = {"label": label, "added_literals": len(lits),
                       "present_in_elf": len(present),
                       "present_list": [r["lit"] for r in present],
                       "absent_list": [r["lit"] for r in rows if not r["in_elf"]]}
        print(f"{commit} {label}: added {len(lits)} literals, {len(present)} present in ELF")
        for L in out[commit]["present_list"]:
            print(f"    PRESENT: {L[:90]}")
    with open(os.path.join(HERE, "literal_fingerprint.json"), "w") as f:
        json.dump(out, f, indent=2)

if __name__ == "__main__":
    main()
