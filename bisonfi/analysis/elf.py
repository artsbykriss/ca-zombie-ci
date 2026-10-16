#!/usr/bin/env python3
"""Minimal Solana SBF ELF parser: program headers, dynamic symbols, section-less text extraction."""
import struct, sys, json

class ELF:
    def __init__(self, path):
        self.path = path
        with open(path, "rb") as f:
            self.data = f.read()
        d = self.data
        assert d[:4] == b"\x7fELF", "not ELF"
        (self.e_type, self.e_machine, self.e_version, self.e_entry, self.e_phoff, self.e_shoff,
         self.e_flags, self.e_ehsize, self.e_phentsize, self.e_phnum, self.e_shentsize,
         self.e_shnum, self.e_shstrndx) = struct.unpack_from("<HHIQQQIHHHHHH", d, 16)
        self.phdrs = []
        for i in range(self.e_phnum):
            off = self.e_phoff + i * self.e_phentsize
            p_type, p_flags, p_offset, p_vaddr, p_paddr, p_filesz, p_memsz, p_align = struct.unpack_from("<IIQQQQQQ", d, off)
            self.phdrs.append(dict(type=p_type, flags=p_flags, offset=p_offset, vaddr=p_vaddr,
                                   filesz=p_filesz, memsz=p_memsz, align=p_align))
        self.dynamic = None
        for ph in self.phdrs:
            if ph["type"] == 2:  # PT_DYNAMIC
                self.dynamic = self._parse_dynamic(ph)
    def v2o(self, vaddr):
        for ph in self.phdrs:
            if ph["type"] == 1 and ph["vaddr"] <= vaddr < ph["vaddr"] + ph["filesz"]:
                return ph["offset"] + (vaddr - ph["vaddr"])
        return None
    def _parse_dynamic(self, ph):
        out = {}
        off = ph["offset"]
        while off + 16 <= ph["offset"] + ph["filesz"]:
            tag, val = struct.unpack_from("<QQ", self.data, off)
            out[tag] = out.get(tag, []) + [val]
            off += 16
            if tag == 0: break
        return out
    def symbols(self):
        dyn = self.dynamic or {}
        symtab = (dyn.get(6) or [None])[0]      # DT_SYMTAB
        strtab = (dyn.get(5) or [None])[0]      # DT_STRTAB
        syment = (dyn.get(11) or [24])[0]       # DT_SYMENT
        hash_ = (dyn.get(4) or [None])[0]       # DT_HASH
        gnu_hash = (dyn.get(0x6ffffef5) or [None])[0]
        n = None
        if hash_:
            o = self.v2o(hash_)
            if o is not None:
                nbucket, nchain = struct.unpack_from("<II", self.data, o)
                n = nchain
        if n is None and gnu_hash:
            o = self.v2o(gnu_hash)
            if o is not None:
                # GNU hash: nbuckets u32, symoffset u32, bloom_size u32, bloom_shift u32, bloom[bloom_size u64], buckets[nbuckets] u32, chain[]
                nbuckets, symoffset, bloom_size, bloom_shift = struct.unpack_from("<IIII", self.data, o)
                # count symbols by walking chain from highest bucket
                buckets_off = o + 16 + bloom_size * 8
                buckets = struct.unpack_from("<%dI" % nbuckets, self.data, buckets_off)
                max_sym = max(buckets) if buckets else 0
                # walk chain from max bucket to find last
                chain_off = buckets_off + nbuckets * 4
                idx = max_sym
                if idx >= symoffset:
                    while True:
                        v = struct.unpack_from("<I", self.data, chain_off + (idx - symoffset) * 4)[0]
                        idx += 1
                        if v & 1: break
                    n = idx
        if n is None:
            # brute force: find max sym by scanning until strtab offset
            o_sym = self.v2o(symtab); o_str = self.v2o(strtab)
            n = max(0, (o_str - o_sym) // (syment or 24)) if o_sym and o_str and o_str > o_sym else 0
        syms = []
        o_sym = self.v2o(symtab); o_str = self.v2o(strtab)
        for i in range(n):
            st_name, st_info, st_other, st_shndx, st_value, st_size = struct.unpack_from("<IBBHQQ", self.data, o_sym + i * (syment or 24))
            name_off = o_str + st_name
            end = self.data.index(b"\x00", name_off)
            name = self.data[name_off:end].decode("utf-8", "replace")
            syms.append(dict(i=i, name=name, info=st_info, shndx=st_shndx, value=st_value, size=st_size,
                             bind=st_info >> 4, typ=st_info & 0xF))
        return syms

if __name__ == "__main__":
    e = ELF(sys.argv[1] if len(sys.argv) > 1 else "bisonfi-live.elf")
    print("type", e.e_type, "machine", e.e_machine, "entry", hex(e.e_entry), "flags", hex(e.e_flags))
    for ph in e.phdrs:
        print("PH", ph)
    print("dynamic tags:", {hex(k): v for k, v in (e.dynamic or {}).items()})
    syms = e.symbols()
    print("symbols:", len(syms))
    undef = [s for s in syms if s["shndx"] == 0]
    defi = [s for s in syms if s["shndx"] != 0]
    print(f"\n== UNDEFINED (imports/syscalls) {len(undef)} ==")
    for s in undef:
        print(f"  {s['i']:5d} {s['name']} value={hex(s['value'])}")
    print(f"\n== DEFINED {len(defi)} ==")
    for s in defi[:120]:
        print(f"  {s['i']:5d} {s['name']} value={hex(s['value'])} size={s['size']}")
