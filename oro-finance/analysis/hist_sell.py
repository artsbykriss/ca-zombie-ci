import sys,json,base64
sys.path.insert(0,'.')
import rpc2
d=json.load(open('inv_HKMT2i4kGzktb4AVo4fKkHK4AmpxVyvGEAfotVX3tML4.json'))
sells=[x for x in d if x['name'] in ('sell','buy')]
seen=set(); out=[]
for x in sells:
    if x['slot'] in seen: continue
    seen.add(x['slot'])
    tx=rpc2.call("getTransaction",[x['sig'],{"encoding":"jsonParsed","maxSupportedTransactionVersion":0}])
    if not tx: continue
    evs=[l for l in (tx["meta"].get("logMessages") or []) if l.startswith("Program data:")]
    dec=[]
    for e in evs:
        b=base64.b64decode(e.split("Program data: ")[1])
        dec.append(b.hex())
    print(x['name'],'slot',x['slot'],'args',x['args'])
    for h in dec: print('   ev',h)
    out.append((x['name'],x['slot'],x['args'],dec))
json.dump(out,open('hist_sells.json','w'),indent=1)
