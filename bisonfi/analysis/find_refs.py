#!/usr/bin/env python3
"""Locate rodata strings (LRS0, bookpool, RFQ v3...) and find code references (lddw) in the sBPF text."""
import struct, sys, os

OUT = os.path.dirname(os.path.abspath(__file__))
elf = open(os.path.join(OUT, "bisonfi-live.elf"), "rb").read()
# program headers
e_phoff = struct.unpack_from("<Q", elf, 32)[0]
e_phnum = struct.unpack_from("<H", elf, 56)[0]
phdrs = []
for i in range(e_phnum):
    off = e_phoff + i * 56
    p_type, p_flags, p_offset, p_vaddr, p_paddr, p_filesz, p_memsz, p_align = struct.unpack_from("<IIQQQQQQ", elf, off)
    phdrs.append(dict(type=p_type, flags=p_flags, offset=p_offset, vaddr=p_vaddr, filesz=p_filesz))
seg0 = [p for p in phdrs if p["flags"] == 4][0]   # R (rodata, vaddr 0)
seg1 = [p for p in phdrs if p["flags"] == 1][0]   # X (text, vaddr 0x100000000)
rodata = elf[seg0["offset"]:seg0["offset"]+seg0["filesz"]]
text = elf[seg1["offset"]:seg1["offset"]+seg1["filesz"]]
print(f"rodata: file {seg0['offset']} vaddr {hex(seg0['vaddr'])} size {len(rodata)}")
print(f"text:   file {seg1['offset']} vaddr {hex(seg1['vaddr'])} size {len(text)}")

def find_str(s):
    return rodata.find(s.encode())

for s in ["LRS0", "bookpool", "POOLSTAT", "RFQ v3", "dark-amm", "pricing_v3", "update_oracle"]:
    off = find_str(s)
    print(f"string {s!r}: rodata offset {off} vaddr {hex(off)}")

# vaddr of rodata byte i (segment vaddr 0) = i
# find lddw (0x18) pairs referencing a target vaddr in text
def find_refs(target):
    refs = []
    for i in range(0, len(text) - 16, 8):
        op1 = text[i]
        op2 = text[i+8]
        if op1 == 0x18 and op2 == 0x00:
            imm_lo = struct.unpack_from("<i", text, i+4)[0]
            imm_hi = struct.unpack_from("<i", text, i+12)[0]
            val = (imm_hi & 0xFFFFFFFF) << 32 | (imm_lo & 0xFFFFFFFF)
            if val == target:
                refs.append(i)
    return refs

for s in ["LRS0", "bookpool"]:
    off = find_str(s)
    if off < 0: continue
    for delta in (0,):
        refs = find_refs(off + delta)
        print(f"\nrefs to {s!r} (vaddr {hex(off+delta)}): {len(refs)} in text")
        for r in refs[:6]:
            start = max(0, r - 24)
            print(f"  text offset {r} (vaddr {hex(seg1['vaddr'] + r)}):")
            for j in range(start, min(r + 40, len(text)), 8):
                ins = text[j:j+8]
                op = ins[0]
                dst = ins[1] & 0xF; src = ins[1] >> 4
                off16 = struct.unpack_from("<h", ins, 2)[0]
                imm = struct.unpack_from("<i", ins, 4)[0]
                mark = " <== ref" if j == r else ""
                print(f"    +{j:6d}: {ins.hex()} op={op:#04x} dst=r{dst} src=r{src} off={off16} imm={imm}{mark}")
