#!/usr/bin/env python3
"""Classify the CWA-2026-006 weaponization campaign stderr artifacts.

Usage: python3 classify_wpn.py <ci-artifacts-dir-or-ci-out/wpn>
Looks for sw-*.stderr + sw-*.json and reports:
  HIJACKS   : PC/RIP = 0x4141..  (control transfer to a planted marker)
  SIGILL    : executed the aimed ud2 gadget
  READS     : addr = 0x4141..    (marker consumed as a read address)
  holder / trigger / clean / error
"""
import glob, json, os, re, sys
from collections import Counter, defaultdict

def load(root):
    return sorted(glob.glob(os.path.join(root, "**", "sw-*.stderr"), recursive=True))

def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "ci-out/wpn"
    files = load(root)
    if not files:
        print("no sw-*.stderr under", root); return
    hijack, sigill, reads, holder, trigger, clean, errd, other = [], [], [], [], [], [], [], []
    for f in files:
        tag = os.path.basename(f)[3:-7]
        txt = open(f, errors="replace").read()
        j = f[:-7] + ".json"
        mpc = re.search(r'(?:PC|RIP)=0x([0-9a-f]+)', txt)
        mad = re.search(r'addr=0x([0-9a-f]+)', txt)
        pc = mpc.group(1) if mpc else ""
        ad = mad.group(1) if mad else ""
        if "SIGILL" in txt:
            sigill.append((tag, pc)); continue
        if pc.startswith("4141"):
            hijack.append((tag, pc)); continue
        if ad.startswith("4141"):
            reads.append((tag, ad)); continue
        if os.path.exists(j) and os.path.getsize(j) > 0:
            try:
                e = (json.load(open(j)).get("executes") or [{}])[0].get("error") or ""
            except Exception:
                e = ""
            if e:
                errd.append((tag, e[:70])); continue
            clean.append(tag); continue
        if "nestedQuerier" in txt:
            trigger.append((tag, pc)); continue
        if "CRASHDIAG" in txt or pc or ad:
            holder.append((tag, pc, ad)); continue
        other.append(tag)
    def show(name, xs, n=80):
        print(f"{name:34s}: {len(xs)}")
        for x in xs[:n]:
            print("   ", x)
    show("HIJACKS (PC/RIP=0x4141..)", hijack)
    show("SIGILL (aimed ud2 hit)", sigill)
    show("MARKER-READS (addr=0x4141..)", reads)
    show("holder-side crashes", holder, 40)
    show("trigger-side crashes", trigger, 40)
    show("wasm-caught errors", errd, 40)
    print(f"{'clean':34s}: {len(clean)}")
    print(f"{'other':34s}: {len(other)} {other[:20]}")
    print("holder PC tails:", Counter(p[-3:] for _, p, _ in holder if p).most_common(12))
    print("holder addr tails:", Counter(a[-4:] for _, _, a in holder if a).most_common(12))
    # depth histogram: which K/R produced holder crashes
    for label, xs in (("holder", holder),):
        c = Counter()
        for t, *_ in xs:
            m = re.search(r'K(\d+)-R(\d+)', t)
            if m: c[int(m.group(1))] += 1
        print(f"{label} crashes by K:", sorted(c.items()))

if __name__ == "__main__":
    main()
