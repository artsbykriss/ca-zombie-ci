#!/usr/bin/env python3
"""debug_traceCall helper. Read-only."""
import json, urllib.request, sys

RPC = "https://eth.drpc.org"

def trace_call(to, data, frm="0x000000000000000000000000000000000000dEaD", block="latest"):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":"debug_traceCall",
                       "params":[{"from":frm,"to":to,"data":data,"gas":"0x2fffffff"}, "latest",
                                 {"tracer":"callTracer"}]}).encode()
    req = urllib.request.Request(RPC, data=body, headers={'Content-Type':'application/json','User-Agent':'Mozilla/5.0'})
    return json.load(urllib.request.urlopen(req, timeout=60))

def show(call, depth=0, maxdepth=8):
    if depth > maxdepth: return
    ind = '  '*depth
    val = int(call.get('value','0x0'),16)
    inp = call.get('input','0x')
    print(f"{ind}{call.get('type')} -> {call.get('to','')[:42]} sel={inp[:10]} len={len(inp)} err={call.get('error','')} revertReason={call.get('revertReason','')}")
    if call.get('error') and call.get('output') and call['output']!='0x':
        print(f"{ind}   output={call['output'][:200]}")
    for c in call.get('calls',[]):
        show(c, depth+1, maxdepth)

if __name__ == '__main__':
    to = sys.argv[1]
    data = sys.argv[2]
    frm = sys.argv[3] if len(sys.argv)>3 else "0x000000000000000000000000000000000000dEaD"
    t = trace_call(to, data, frm)
    if 'result' in t:
        show(t['result'])
        json.dump(t['result'], open('analysis/tracecall_%s.json' % data[:10].replace('0x',''), 'w'), indent=1)
    else:
        print(json.dumps(t)[:1000])
