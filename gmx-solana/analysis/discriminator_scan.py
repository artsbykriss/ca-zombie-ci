#!/usr/bin/env python3
"""Anchor discriminator scan: determine which source commit the deployed store ELF was built from.

Anchor instruction dispatch embeds the 8-byte discriminator sha256("global:<name>")[:8] in the
program's read-only data. Anchor account discriminators are sha256("account:<Name>")[:8].
Scanning the deployed ELF for these 8-byte constants gives a cheap, high-confidence "what changed".
"""
import hashlib, json, os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = "/tmp/opencode/gmx-solana-repo"
ELF = os.path.join(HERE, "store_deployed.elf")

COMMITS = [
    ("8af1e70", "audit-2026-10-08"),
    ("76818869", "2026-10-13 sdk"),
    ("2c368773", "2026-10-13 docs"),
    ("dfeaf14e", "2026-10-14 bump0.12"),
    ("e2aa230a", "2026-10-14 creditGT"),
    ("1e05ae76", "2026-10-14 gt-delegate"),
    ("acaece1f", "2026-10-14 gt-rent-receiver"),
    ("6cc72716", "2026-10-15 cli"),
    ("884d121d", "2026-10-16 close-gt-exchange"),
    ("7133cd1d", "2026-10-17 bundle"),
    ("928f2d32", "2026-10-17 builder-fee-accts"),
    ("c65fbd6d", "2026-10-18 npm"),
    ("d6d4dc7f", "2026-10-19 gt-manage"),
    ("a8f3937d", "2026-10-21 sdk"),
    ("f102501f", "2026-10-21 HEAD"),
]

def git_show(commit, path):
    r = subprocess.run(["git", "-C", REPO, "show", f"{commit}:{path}"],
                       capture_output=True, text=True)
    if r.returncode != 0:
        return None
    return r.stdout

def instr_names(commit):
    src = git_show(commit, "programs/store/src/lib.rs")
    if src is None:
        return None
    return sorted(set(re.findall(r"^\s+pub fn ([a-z0-9_]+)", src, re.M)))

def disc(prefix, name):
    return hashlib.sha256((prefix + name).encode()).digest()[:8]

def account_names(commit):
    # collect #[account] struct names under programs/store/src/states
    r = subprocess.run(["git", "-C", REPO, "ls-tree", "-r", "--name-only",
                        f"{commit}", "programs/store/src/states"],
                       capture_output=True, text=True)
    names = set()
    for f in r.stdout.split():
        if not f.endswith(".rs"):
            continue
        src = git_show(commit, f)
        if not src:
            continue
        for m in re.finditer(r"#\[account(?:\([^)]*\))?\]\s*(?:#\[[^\]]*\]\s*)*pub struct ([A-Za-z0-9_]+)", src):
            names.add(m.group(1))
        for m in re.finditer(r"#\[account(?:\([^)]*\))?\]\s*(?:#\[[^\]]*\]\s*)*pub struct ([A-Za-z0-9_]+)", src):
            names.add(m.group(1))
    return sorted(names)

def scan(elf, needles):
    res = {}
    for name, d in needles.items():
        res[name] = elf.count(d)
    return res

def main():
    elf = open(ELF, "rb").read()
    report = {"elf_bytes": len(elf), "commits": {}}

    head_names = instr_names("f102501f")
    head_accts = account_names("f102501f")
    print("HEAD instructions:", len(head_names), "accounts:", len(head_accts))

    for commit, label in COMMITS:
        inames = instr_names(commit)
        if inames is None:
            report["commits"][commit] = {"label": label, "error": "no lib.rs"}
            continue
        needles = {f"i:{n}": disc("global:", n) for n in inames}
        anames = account_names(commit)
        needles.update({f"a:{n}": disc("account:", n) for n in anames})
        counts = scan(elf, needles)
        present = sorted(k for k, v in counts.items() if v > 0)
        missing = sorted(k for k, v in counts.items() if v == 0)
        report["commits"][commit] = {
            "label": label,
            "n_instr": len(inames),
            "n_accounts": len(anames),
            "instr_present": sum(1 for k in present if k.startswith("i:")),
            "instr_missing": sum(1 for k in missing if k.startswith("i:")),
            "accounts_present": sum(1 for k in present if k.startswith("a:")),
            "accounts_missing": sum(1 for k in missing if k.startswith("a:")),
            "missing_instr": [k[2:] for k in missing if k.startswith("i:")],
            "missing_accounts": [k[2:] for k in missing if k.startswith("a:")],
        }

    # Detailed per-instruction presence for HEAD (to see exactly which post-audit additions are deployed)
    head_needles = {f"i:{n}": disc("global:", n) for n in head_names}
    head_counts = scan(elf, head_needles)
    report["head_instr_present"] = sorted(k[2:] for k, v in head_counts.items() if v > 0)
    report["head_instr_absent"] = sorted(k[2:] for k, v in head_counts.items() if v == 0)

    with open(os.path.join(HERE, "discriminator_scan.json"), "w") as f:
        json.dump(report, f, indent=2)

    for commit, label in COMMITS:
        c = report["commits"][commit]
        if "error" in c:
            print(f"{commit} {label}: {c['error']}")
        else:
            print(f"{commit} {label}: instr present {c['instr_present']}/{c['n_instr']} "
                  f"missing={c['instr_missing']} | accts present {c['accounts_present']}/{c['n_accounts']} "
                  f"missing={c['accounts_missing']}")
    print("\nHEAD instructions ABSENT from deployed ELF:",
          report["head_instr_absent"])

if __name__ == "__main__":
    main()
