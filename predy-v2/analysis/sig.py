#!/usr/bin/env python3
import json,sys
abi=json.load(open('/home/heisenberg/CA/predy-v2/analysis/impl_abi.json'))
def t(x):
    if x['type']=='tuple':
        return '('+','.join(t(c) for c in x['components'])+')'
    if x['type'].endswith('[]'):
        return t({'type':x['type'][:-2],'components':x.get('components',[])})+'[]'
    return x['type']
fn=[e for e in abi if e.get('name')=='getPairStatus'][0]
ins=','.join(t(i) for i in fn['inputs'])
outs=','.join(t(o) for o in fn['outputs'])
print(f"getPairStatus({ins})({outs})")
