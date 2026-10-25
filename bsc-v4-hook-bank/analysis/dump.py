#!/usr/bin/env python3
"""Dump opcode listing for a pc range. Usage: dump.py <hexfile> <start> <end>"""
import sys
sys.path.insert(0,'/home/heisenberg/CA/bsc-v4-hook-bank/analysis')
from disasm import load, disasm, fmt

path, start, end = sys.argv[1], int(sys.argv[2],0), int(sys.argv[3],0)
code = load(path)
ins = disasm(code)
for pc,op,imm,sz in ins:
    if start <= pc < end:
        mark = "JUMPDEST" if op==0x5b else ""
        print(f"{pc:6d}: {fmt(op,imm)}")
