#!/usr/bin/env python3
"""Tiny SBF/BPF instruction decoder for the 512-byte dijkbk ELF."""
import struct, sys, os

OUT = os.path.dirname(os.path.abspath(__file__))
OPCODES = {
    0x18: "lddw", 0x61: "ldxw", 0x69: "ldxh", 0x71: "ldxb", 0x79: "ldxdw",
    0x62: "stw", 0x6b: "sth", 0x73: "stb", 0x7b: "stdw",
    0x07: "add64", 0x0f: "add32", 0x17: "sub64", 0x1f: "sub32",
    0x27: "mul64", 0x2f: "mul32", 0x37: "div64", 0x3f: "div32",
    0x47: "or64", 0x4f: "or32", 0x57: "and64", 0x5f: "and32",
    0x67: "lsh64", 0x6f: "lsh32", 0x77: "rsh64", 0x7f: "rsh32",
    0x87: "neg64", 0x8f: "neg32", 0x97: "mod64", 0x9f: "mod32",
    0xa7: "xor64", 0xaf: "xor32", 0xb7: "mov64", 0xbf: "mov32",
    0xc7: "arsh64", 0xcf: "arsh32",
    0x15: "jeq", 0x1d: "jgt", 0x25: "jge", 0x2d: "jset", 0x35: "jne",
    0x3d: "jsgt", 0x45: "jsge", 0x55: "jne", 0x5d: "jsgt",
    0x65: "jsge", 0x6d: "jlt", 0x75: "jle", 0x7d: "jslt", 0x85: "jsle",
    0x95: "exit", 0x85: "call",
}
REG = ["r0", "r1", "r2", "r3", "r4", "r5", "r6", "r7", "r8", "r9", "r10", "r11"]
IMM = {0x15: "jeq", 0x35: "jne", 0x25: "jge", 0x1d: "jgt", 0x6d: "jlt", 0x75: "jle", 0x2d: "jset"}


def main():
    elf = open(os.path.join(OUT, "dijkbk.elf"), "rb").read()
    assert elf[:4] == b"\x7fELF"
    text_off, text_size = 0x40, 0xF0
    text = elf[text_off:text_off + text_size]
    n = len(text) // 8
    print(f"text: {n} instructions @0x40..0x{text_off + text_size:x}")
    i = 0
    while i < n:
        b = text[i * 8:(i + 1) * 8]
        op, regs = b[0], b[1]
        dst, src = regs & 0xF, regs >> 4
        off = struct.unpack("<h", b[2:4])[0]
        imm = struct.unpack("<i", b[4:8])[0]
        immu = struct.unpack("<I", b[4:8])[0]
        cls = op & 0x07
        name = OPCODES.get(op, f"op_{op:02x}")
        line = f"{i*8+0x40:04x}: {b.hex()}  "
        if op == 0x18:
            b2 = text[(i + 1) * 8:(i + 2) * 8]
            hi = struct.unpack("<i", b2[4:8])[0]
            val = (hi << 32) | immu
            line += f"lddw {REG[dst]}, 0x{val:x}"
            i += 2
            print(line); continue
        elif op in (0x95,):
            line += "exit"
        elif op == 0x85:
            line += f"call {imm}"
        elif op in (0x79, 0x61, 0x69, 0x71):
            line += f"{name} {REG[dst]}, [{REG[src]}{off:+d}]"
        elif op in (0x7b, 0x63, 0x6b, 0x73):
            line += f"{name} [{REG[dst]}{off:+d}], {REG[src]}"
        elif cls in (1, 3, 5, 7, 9, 11, 13):  # jumps
            if op in IMM or name in ("jeq", "jne", "jgt", "jge", "jlt", "jle", "jset", "jsgt", "jsge", "jslt", "jsle"):
                tgt = (i + 1 + off) * 8 + 0x40
                line += f"{name} {REG[dst]}, {immu if immu < 0x80000000 else imm}, -> 0x{tgt:x}"
            else:
                tgt = (i + 1 + off) * 8 + 0x40
                line += f"{name} {REG[dst]}, {REG[src]}, -> 0x{tgt:x}"
        else:
            # alu
            if op in (0xb7, 0xbf):
                if op == 0xbf:
                    line += f"mov64 {REG[dst]}, {REG[src]}"
                else:
                    line += f"mov64 {REG[dst]}, {imm}"
            else:
                line += f"{name} {REG[dst]}, {REG[src] if cls == 7 else imm}"
        print(line)
        i += 1


if __name__ == "__main__":
    main()
