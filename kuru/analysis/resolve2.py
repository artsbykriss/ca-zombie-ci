import re,json,urllib.request,time
h=open('accountcore_impl_0xb52debad.hex').read().strip()
sel=set()
for m in re.finditer(r'63([0-9a-f]{8})14', h): sel.add(m.group(1))
for m in re.finditer(r'8063([0-9a-f]{8})14', h): sel.add(m.group(1))
sels=sorted(sel); out={}
for i in range(0,len(sels),8):
    ch=sels[i:i+8]
    q='&'.join('function=0x'+s for s in ch)
    url='https://api.openchain.xyz/signature-database/v1/lookup?'+q
    ok=False
    for a in range(4):
        try:
            d=json.load(urllib.request.urlopen(url,timeout=20))
            res=d['result']['function']
            for s in ch:
                v=res.get('0x'+s); out[s]=v[0]['name'] if v else None
            ok=True; break
        except Exception as e:
            time.sleep(1)
    if not ok:
        for s in ch: out.setdefault(s,'ERR')
    time.sleep(0.4)
json.dump(out,open('accountcore_selectors_resolved.json','w'),indent=0)
print('done',len(out))
