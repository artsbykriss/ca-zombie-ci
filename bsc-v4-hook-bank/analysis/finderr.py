#!/usr/bin/env python3
"""Locate error-selector constructions (PUSH3/PUSH4 + SHL) and print the guard context."""
import sys
sys.path.insert(0,'/home/heisenberg/CA/bsc-v4-hook-bank/analysis')
from disasm import load, disasm, fmt, OPNAMES

path=sys.argv[1]
needles=[bytes.fromhex(x) for x in sys.argv[2:]]
code=load(path)
ins=disasm(code)
# map pc->index
pcmap={pc:i for i,(pc,op,imm,sz) in enumerate(ins)}
for needle in needles:
    print(f"\n===== needle {needle.hex()} =====")
    start=0
    while True:
        p=code.find(needle,start)
        if p<0: break
        start=p+1
        # find instruction containing this pc
        i=pcmap.get(p)
        if i is None:
            # find nearest <= p
            best=None
            for pc,idx in pcmap.items():
                if pc<=p and (best is None or pc>best): best=pc
            i=pcmap[best]
        lo=max(0,i-16); hi=min(len(ins),i+10)
        print(f"--- at pc={p} ---")
        for j in range(lo,hi):
            pc,op,imm,sz=ins[j]
            tag='>>' if pc==ins[i][0] else '  '
            print(f"{tag} {pc:6d}: {fmt(op,imm)}")
