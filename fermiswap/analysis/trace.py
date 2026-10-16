#!/usr/bin/env python3
"""Fetch callTracer traces from drpc. Read-only."""
import json, urllib.request, sys

RPC = "https://eth.drpc.org"

def trace(txhash):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":"debug_traceTransaction",
                       "params":[txhash,{"tracer":"callTracer"}]}).encode()
    req = urllib.request.Request(RPC, data=body, headers={'Content-Type':'application/json','User-Agent':'Mozilla/5.0'})
    return json.load(urllib.request.urlopen(req, timeout=60))

def show(call, depth=0, maxdepth=6):
    if depth > maxdepth: return
    ind = '  '*depth
    val = int(call.get('value','0x0'),16)
    print(f"{ind}{call.get('type')} -> {call.get('to','')[:42]} sel={call.get('input','0x')[:10]} gas={call.get('gas','')} gasUsed={call.get('gasUsed','')} value={val} err={call.get('error','')}")
    for c in call.get('calls',[]):
        show(c, depth+1, maxdepth)

if __name__ == '__main__':
    tx = sys.argv[1]
    t = trace(tx)
    if 'result' in t:
        show(t['result'])
        json.dump(t['result'], open(f'analysis/trace_{tx[:14]}.json','w'), indent=1)
    else:
        print(json.dumps(t)[:800])
