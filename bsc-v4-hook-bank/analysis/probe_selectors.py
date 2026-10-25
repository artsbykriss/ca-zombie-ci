#!/usr/bin/env python3
"""Probe all dispatch selectors of the BSC bank from a stranger; record non-revert vs revert."""
import json, sys
sys.path.insert(0,'/home/heisenberg/CA/bsc-v4-hook-bank/analysis')
import rpclib as R
from disasm import load, dispatch

TGT='0x16ceff8d5a4c8648fcc7293f8bd3ac9ada454219'
STRANGER='0x000000000000000000000000000000000000dEaD'
code=load('/tmp/opencode/kh/bsc_bank.hex')
tbl,_=dispatch(code)
sels=sorted(tbl.keys())

def probe(data, frm):
    r=R.call(TGT, data, 'latest', frm)
    if isinstance(r, dict):
        e=r.get('__error__',{})
        return {'revert':True,'msg':e.get('message'),'data':e.get('data')}
    return {'revert':False,'ret':r}

out={}
for s in sels:
    # empty args (4-byte selector only)
    out['0x'+s]={}
    for label,frm in [('empty_stranger',STRANGER),('empty_zero',None)]:
        out['0x'+s][label]=probe('0x'+s, frm)
print(json.dumps(out,indent=1))
