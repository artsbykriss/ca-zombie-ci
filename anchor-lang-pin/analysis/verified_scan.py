#!/usr/bin/env python3
"""Breadth scan: enumerate OtterSec-verified Solana programs, resolve each
program's verified git commit, read its Cargo.lock / Anchor.toml, and flag any
program whose verified build pins anchor-lang 1.0.0 or 1.0.1 (the vulnerable
versions for GHSA-c6rc-8jpp-2fgc / CVE-2026-45137).

Read-only: HTTP GETs only. No chain writes.
Usage: verified_scan.py [--limit N] [--out FILE] [--workers W]
"""
import argparse, concurrent.futures as cf, json, re, sys, urllib.request

UA = {"User-Agent": "Mozilla/5.0 (research)"}
OSEc = "https://verify.osec.io"
VULN = {"1.0.0", "1.0.1"}

def get(url, timeout=30):
    try:
        req = urllib.request.Request(url, headers=UA)
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.read().decode("utf-8", "replace")
    except Exception:
        return None

def get_ids():
    ids = []
    page = 1
    while True:
        t = get(f"{OSEc}/verified-programs/{page}")
        if not t:
            break
        try:
            j = json.loads(t)
        except Exception:
            break
        ids += j.get("verified_programs", [])
        if not j.get("meta", {}).get("has_next_page"):
            break
        page += 1
        if page > 200:
            break
    return sorted(set(ids))

LOCK_RE = re.compile(r'name = "anchor-lang"\s*\nversion = "([^"]+)"')

def scan_one(pid):
    t = get(f"{OSEc}/status/{pid}")
    if not t:
        return {"program": pid, "error": "status fetch failed"}
    try:
        s = json.loads(t)
    except Exception:
        return {"program": pid, "error": "bad status json"}
    commit = s.get("commit") or ""
    repo = s.get("repo_url") or ""
    out = {"program": pid, "verified": s.get("is_verified"), "frozen": s.get("is_frozen"),
           "closed": s.get("is_closed"), "commit": commit, "repo_url": repo,
           "last_verified_at": s.get("last_verified_at")}
    m = re.match(r"https://github\.com/([^/]+)/([^/]+)/tree/([0-9a-f]{6,40})", repo)
    if not m:
        out["anchor_lang"] = None
        return out
    owner, name, sha = m.group(1), m.group(2), m.group(3)
    base = f"https://raw.githubusercontent.com/{owner}/{name}/{sha}"
    lock = get(base + "/Cargo.lock")
    vers = set()
    if lock:
        vers |= set(LOCK_RE.findall(lock))
    at = get(base + "/Anchor.toml")
    anchor_toml = None
    if at:
        mm = re.search(r'anchor_version\s*=\s*"([^"]+)"', at)
        if mm:
            anchor_toml = mm.group(1)
    out["anchor_lang_lock"] = sorted(vers)
    out["anchor_version_toml"] = anchor_toml
    # also try program-level Cargo.toml files via the repo tree API (skip; keep light)
    vuln = bool(vers & VULN) or (anchor_toml in VULN)
    out["vulnerable_anchor"] = vuln
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--workers", type=int, default=8)
    ap.add_argument("--out", default="ci-out/verified-programs-anchor.json")
    a = ap.parse_args()

    ids = get_ids()
    print(f"verified programs: {len(ids)}", flush=True)
    if a.limit:
        ids = ids[: a.limit]
    rows = []
    with cf.ThreadPoolExecutor(max_workers=a.workers) as ex:
        for i, r in enumerate(ex.map(scan_one, ids)):
            rows.append(r)
            if (i + 1) % 25 == 0:
                print(f"  scanned {i+1}/{len(ids)}", flush=True)
    anchor_rows = [r for r in rows if r.get("anchor_lang_lock") or r.get("anchor_version_toml")]
    vuln_rows = [r for r in rows if r.get("vulnerable_anchor")]
    with open(a.out, "w") as f:
        json.dump({"scanned": len(rows), "anchor_programs": len(anchor_rows),
                   "vulnerable_programs": vuln_rows, "all": rows}, f, indent=2)
    print(f"\nanchor-based verified programs: {len(anchor_rows)}")
    print(f"VERIFIED PROGRAMS PINNING anchor-lang 1.0.0/1.0.1: {len(vuln_rows)}")
    for r in vuln_rows:
        print("  !!", r["program"], r.get("anchor_lang_lock"), r.get("anchor_version_toml"), r.get("repo_url"))
    print(f"wrote {a.out}")

if __name__ == "__main__":
    main()
