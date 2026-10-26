#!/usr/bin/env python3
"""Locate the holder's resume slot S in the scan artifacts.

For every crashing nested run (nested-vuln-sa-*.stderr), correlate the crash PC
(the value the holder jumped to / faulted at) with the scanner's TOP dumps:
if the PC value appears at `+offset` of some region, that address is the slot
that carried the resume address (or the value was read from there).

Usage: locate_slot.py <ci-out/harness dir>
"""
import glob
import re
import sys
from collections import Counter

RX_TOP = re.compile(r'TOP\[0x([0-9a-f]+)\]:\s*([^|]+)')
RX_TOPV = re.compile(r'\+([0-9a-f]+)=0x([0-9a-f]+)')
RX_PC = re.compile(r'PC=0x([0-9a-f]+)')
RX_ADDR = re.compile(r'addr=0x([0-9a-f]+)')


def main():
    d = sys.argv[1] if len(sys.argv) > 1 else "."
    found_pc = []
    found_ad = []
    summary = Counter()
    n_files = 0
    for f in sorted(glob.glob(f"{d}/nested-vuln-*.stderr")):
        txt = open(f, errors="replace").read()
        mp = RX_PC.search(txt)
        if not mp or "SIGSEGV" not in txt and "SIGILL" not in txt:
            continue
        n_files += 1
        pc = mp.group(1)
        ma = RX_ADDR.search(txt)
        ad = ma.group(1) if ma else None
        hits_pc, hits_ad = [], []
        for tm in RX_TOP.finditer(txt):
            base = int(tm.group(1), 16)
            for vm in RX_TOPV.finditer(tm.group(2)):
                off = int(vm.group(1), 16)
                val = vm.group(2)
                if val == pc:
                    hits_pc.append((base, off))
                if ad and val == ad:
                    hits_ad.append((base, off))
        tag = f.split("/")[-1].replace(".stderr", "")
        if hits_pc:
            found_pc.append((tag, pc, hits_pc[:3]))
            summary[hits_pc[0][1]] += 1
        if hits_ad:
            found_ad.append((tag, ad, hits_ad[:3]))
    print(f"crashing runs with TOP dumps: {n_files}")
    print(f"PC value found in dumps: {len(found_pc)}")
    for t, pc, h in found_pc[:30]:
        print(f"  {t}: PC=0x{pc} @ " + ", ".join(f"base=0x{b:x}+0x{o:x}" for b, o in h))
    print(f"\nADDR value found in dumps: {len(found_ad)}")
    for t, ad, h in found_ad[:15]:
        print(f"  {t}: addr=0x{ad} @ " + ", ".join(f"base=0x{b:x}+0x{o:x}" for b, o in h))
    print("\nslot-offset histogram (PC hits):", summary.most_common(15))


if __name__ == "__main__":
    main()
