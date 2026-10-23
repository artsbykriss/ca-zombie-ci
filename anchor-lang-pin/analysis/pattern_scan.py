#!/usr/bin/env python3
"""Exploitability pattern scan.

The anchor-lang 1.0.0/1.0.1 `Program<'info, System>` bug only yields an exploit
when the program FORWARDS the caller-supplied program key into a CPI target.
Anchor's own `system_program::*` helpers hardcode `system_program::ID`, so they
are immune. The dangerous patterns are:

  (A) `Instruction { program_id: <...system_program...>.key(), ... }`
  (B) an instruction built with `program_id` == the passed system_program account
      then passed to `invoke`/`invoke_signed`

This script downloads each affected repo@commit and reports, per program crate,
whether any dangerous pattern exists. Read-only (HTTP GET + local grep).
"""
import json, os, re, subprocess, sys, urllib.request

WORK = "/tmp/opencode/pattern-scan"

# repo_url -> list of programs verified at that commit (from the OtterSec scan)
TARGETS = json.load(open(os.path.join(os.path.dirname(__file__), "..", "ci-out",
                                      "verified-programs-anchor.json")))["vulnerable_programs"]

DANGER = [
    re.compile(r"Instruction\s*\{"),
    re.compile(r"program_id\s*:"),
    re.compile(r"system_program\.key\(\)"),
    re.compile(r"system_program\.to_account_info\(\)"),
    re.compile(r"system_instruction::"),
]

def fetch_tar(repo_url):
    m = re.match(r"https://github\.com/([^/]+)/([^/]+)/tree/([0-9a-f]{6,40})", repo_url)
    if not m:
        return None
    owner, name, sha = m.groups()
    dest = os.path.join(WORK, f"{owner}__{name}__{sha[:8]}")
    if os.path.isdir(dest):
        return dest
    os.makedirs(WORK, exist_ok=True)
    tgz = dest + ".tgz"
    url = f"https://codeload.github.com/{owner}/{name}/tar.gz/{sha}"
    try:
        urllib.request.urlretrieve(url, tgz)
    except Exception as e:
        print("download failed", url, e)
        return None
    os.makedirs(dest, exist_ok=True)
    subprocess.run(["tar", "xzf", tgz, "-C", dest, "--strip-components=1"], check=False)
    return dest

def scan(d):
    """Return per-file facts for ON-CHAIN program code only (under a programs/ dir,
    excluding tests). A file is DANGEROUS if it builds a raw Instruction{} AND
    mentions system_program (candidate: program_id sourced from the passed account)."""
    hits = []
    for root, _, files in os.walk(d):
        if "/target/" in root or "/tests/" in root or "/helpers/" in root:
            continue
        rel_root = os.path.relpath(root, d)
        if not (rel_root.startswith("programs") or "/programs/" in ("/" + rel_root)):
            continue
        for fn in files:
            if not fn.endswith(".rs"):
                continue
            p = os.path.join(root, fn)
            try:
                t = open(p, encoding="utf-8", errors="replace").read()
            except Exception:
                continue
            has_ix = bool(re.search(r"Instruction\s*\{", t))
            has_sys = "system_program" in t
            has_sysinstr = "system_instruction::" in t
            # precise: does any `Instruction {` block set program_id from system_program?
            pid_exprs = re.findall(r"program_id\s*:\s*([^,\n]+)", t)
            bad_pid = [e.strip() for e in pid_exprs if "system_program" in e]
            if has_ix or has_sys or has_sysinstr:
                hits.append({
                    "file": os.path.relpath(p, d),
                    "raw_Instruction": has_ix,
                    "mentions_system_program": has_sys,
                    "system_instruction_call": has_sysinstr,
                    "program_id_exprs": pid_exprs[:5],
                    "EXPLOITABLE_program_id_from_system_program": bad_pid,
                })
    return hits

def main():
    by_repo = {}
    for r in TARGETS:
        by_repo.setdefault(r["repo_url"], []).append(r["program"])
    out = {}
    for repo, progs in by_repo.items():
        print(f"\n=== {repo}  ({len(progs)} program ids) ===")
        d = fetch_tar(repo)
        if not d:
            out[repo] = {"error": "download failed", "programs": progs}
            continue
        hits = scan(d)
        out[repo] = {"programs": progs, "files": hits}
        danger = [h for h in hits if h["EXPLOITABLE_program_id_from_system_program"]]
        sysinstr = [h for h in hits if h["system_instruction_call"]]
        print(f"  on-chain program files scanned: {len(hits)}")
        print(f"  EXPLOITABLE (Instruction program_id sourced from system_program): {len(danger)}")
        for h in danger[:10]:
            print("    !!", h["file"], h["EXPLOITABLE_program_id_from_system_program"])
        print(f"  system_instruction:: sites (hardcoded-ID helper use, SAFE): {len(sysinstr)}")
        for h in sysinstr[:5]:
            print("     -", h["file"])
    with open(os.path.join(os.path.dirname(__file__), "..", "ci-out", "pattern-scan.json"), "w") as f:
        json.dump(out, f, indent=2)
    print("\nwrote ci-out/pattern-scan.json")

if __name__ == "__main__":
    main()
