#!/usr/bin/env python3
"""Attribute isAuthorized/owner guards to dispatch functions."""
import sys
sys.path.insert(0,'/home/heisenberg/CA/bsc-v4-hook-bank/analysis')
from disasm import load, disasm, dispatch

code=load('/tmp/opencode/kh/bsc_bank.hex')
tbl,_=dispatch(code)
ins=disasm(code)
# map pc->index
idx={pc:i for i,(pc,op,imm,sz) in enumerate(ins)}

# body starts from dispatch (dest of each selector)
body_by_dest={}
for sel,(pc,dest) in tbl.items():
    body_by_dest.setdefault(dest,[]).append(sel)

# guard modifier blocks: find 'CALLER PUSH2 0x4730 JUMP' (isAuthorized) and 'PUSH0 SLOAD ... CALLER EQ' (owner)
def find_blocks():
    blocks=[]  # (entry_pc, kind)
    for i,(pc,op,imm,sz) in enumerate(ins):
        if op==0x61 and imm==(0x4730).to_bytes(2,'big'):  # PUSH2 0x4730
            # preceding: PUSH2 ret, CALLER
            if i>=2 and ins[i-1][1]==0x33:  # CALLER
                # entry = JUMPDEST preceding the PUSH2 ret (ins[i-2])
                j=i-3
                while j>0 and ins[j][1]!=0x5b: j-=1
                blocks.append((ins[j][0],'isAuthorized'))
        if op==0x54:  # SLOAD  (owner check: PUSH0 SLOAD ... CALLER EQ)
            if i>=1 and ins[i-1][1]==0x5f:  # PUSH0
                j=i-1
                while j>0 and ins[j][1]!=0x5b: j-=1
                blocks.append((ins[j][0],'owner'))
    return blocks

blocks=find_blocks()
print("guard blocks:", blocks)

# for each block entry, find PUSH2 <entry> JUMP sites and the containing function
bodies=sorted(body_by_dest.keys())
def func_of(pc):
    f=None
    for b in bodies:
        if b<=pc: f=b
        else: break
    return f

for entry,kind in blocks:
    callers=[]
    tgt=entry.to_bytes(2,'big')
    for i,(pc,op,imm,sz) in enumerate(ins):
        if op==0x61 and imm==tgt:
            # next should be JUMP
            if i+1<len(ins) and ins[i+1][1]==0x56:
                f=func_of(pc)
                callers.append((pc,f,body_by_dest.get(f)))
    print(f"block {entry} ({kind}) called from:")
    for pc,f,sels in callers:
        print(f"   jump@pc={pc} -> func body {f} sels={sels}")
