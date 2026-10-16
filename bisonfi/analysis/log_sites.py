#!/usr/bin/env python3
"""Map every sol_log_ call site to the rodata string it loads; dump context."""
import struct, os

OUT = os.path.dirname(os.path.abspath(__file__))
elf = open(os.path.join(OUT, "bisonfi-live.elf"), "rb").read()
e_phoff = struct.unpack_from("<Q", elf, 32)[0]
e_phnum = struct.unpack_from("<H", elf, 56)[0]
segs = []
for i in range(e_phnum):
    off = e_phoff + i * 56
    p_type, p_flags, p_offset, p_vaddr, p_paddr, p_filesz, p_memsz, p_align = struct.unpack_from("<IIQQQQQQ", elf, off)
    segs.append(dict(flags=p_flags, offset=p_offset, vaddr=p_vaddr, filesz=p_filesz))
seg0 = [s for s in segs if s["flags"] == 4][0]
seg1 = [s for s in segs if s["flags"] == 1][0]
rodata = elf[seg0["offset"]:seg0["offset"]+seg0["filesz"]]
T = elf[seg1["offset"]:seg1["offset"]+seg1["filesz"]]

def cstr(off):
    end = rodata.find(b"\x00", off)
    return rodata[off:end].decode("latin1", "replace")

LOG = 0x207559bd
sites = []
for i in range(0, len(T) - 8, 8):
    op = T[i]
    if op == 0x85:
        imm = struct.unpack_from("<i", T, i+4)[0] & 0xFFFFFFFF
        if imm == LOG:
            sites.append(i)

print(f"sol_log_ sites: {len(sites)}")
for s in sites:
    # look back up to 20 instructions for lddw into r1 and b7 into r2
    str_addr = None; strlen = None
    for j in range(s - 8, max(0, s - 160), -8):
        op = T[j]
        if op == 0x18:
            imm_lo = struct.unpack_from("<i", T, j+4)[0] & 0xFFFFFFFF
            imm_hi = struct.unpack_from("<i", T, j+12)[0] & 0xFFFFFFFF
            val = (imm_hi << 32) | imm_lo
            if T[j+1] & 0xF == 1:  # dst = r1
                str_addr = val
        if op == 0xb7 and (T[j+1] & 0xF) == 2 and str_addr is not None:
            strlen = struct.unpack_from("<i", T, j+4)[0] & 0xFFFFFFFF
            break
    desc = "?"
    if str_addr is not None and str_addr < len(rodata):
        desc = cstr(str_addr)[:90]
    print(f"  site text+{s:#x} vaddr={hex(seg1['vaddr']+s)} str@{str_addr} len={strlen} -> {desc!r}")
