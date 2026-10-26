#!/usr/bin/env python3
"""Fingerprint the deployed store ELF by source-file paths embedded in Anchor error origins.

Anchor's require!/err! embed the originating source file path as a string constant. The set of
such paths in the deployed ELF therefore identifies which source tree produced it.
"""
import os, re, subprocess, json

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = "/tmp/opencode/gmx-solana-repo"
STR = os.path.join(HERE, "store_deployed.strings.txt")

COMMITS = [
    ("8af1e70", "audit-2026-10-08"),
    ("884d121d", "2026-10-16 close-gt-exchange"),
    ("7133cd1d", "2026-10-17 bundle"),
    ("928f2d32", "2026-10-17 builder-fee-accts"),
    ("c65fbd6d", "2026-10-18 npm"),
    ("d6d4dc7f", "2026-10-19 gt-manage"),
    ("a8f3937d", "2026-10-21 sdk"),
    ("f102501f", "2026-10-21 HEAD"),
]

def elf_paths():
    txt = open(STR, errors="replace").read()
    return set(re.findall(r"programs/store/src/[A-Za-z0-9_/]+\.rs", txt))

def tree(commit):
    r = subprocess.run(["git", "-C", REPO, "ls-tree", "-r", "--name-only", commit],
                       capture_output=True, text=True)
    return set(x for x in r.stdout.split() if x.startswith("programs/store/src/") and x.endswith(".rs"))

def main():
    ep = elf_paths()
    print(f"ELF embeds {len(ep)} store source paths\n")
    out = {"elf_paths": sorted(ep), "commits": {}}
    for commit, label in COMMITS:
        t = tree(commit)
        # paths referenced in ELF that do not exist at this commit -> commit is too old
        elf_not_in_tree = sorted(p for p in ep if p not in t)
        tree_not_in_elf = sorted(p for p in t if p not in ep)
        out["commits"][commit] = {
            "label": label,
            "elf_paths_missing_at_commit": elf_not_in_tree,
            "commit_paths_never_referenced": tree_not_in_elf,
        }
        print(f"{commit} {label}: ELF-paths-not-at-commit={len(elf_not_in_tree)} "
              f"commit-paths-not-in-ELF={len(tree_not_in_elf)}")
        if elf_not_in_tree:
            print("   ELF has paths absent at commit:", elf_not_in_tree)
    with open(os.path.join(HERE, "path_fingerprint.json"), "w") as f:
        json.dump(out, f, indent=2)

if __name__ == "__main__":
    main()
