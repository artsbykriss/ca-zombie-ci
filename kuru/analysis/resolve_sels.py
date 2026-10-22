import re,json,urllib.request,time,sys
sel=set()
for f in ['accountcore_impl_0xb52debad.hex','marginaccount_impl_0x35152507.hex','router_impl_0xf1635175.hex']:
    h=open(f).read().strip()
    for m in re.finditer(r'63([0-9a-f]{8})14', h): sel.add(m.group(1))
    for m in re.finditer(r'8063([0-9a-f]{8})14', h): sel.add(m.group(1))
sels=sorted(sel)
out={}
for s in sels:
    try:
        u=f'https://www.4byte.directory/api/v1/signatures/?hex_signature=0x{s}'
        d=json.load(urllib.request.urlopen(u,timeout=15))
        r=d.get('results',[])
        out[s]=r[0]['text_signature'] if r else None
    except Exception as e:
        out[s]='ERR'
    time.sleep(0.15)
json.dump(out,open('selectors_resolved.json','w'),indent=0)
print('done',len(out))
