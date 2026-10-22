import re,json,urllib.request,time
h=open('ibera_impl_0xc0654903.hex').read().strip()
sel=set()
for m in re.finditer(r'63([0-9a-f]{8})14', h): sel.add(m.group(1))
for m in re.finditer(r'8063([0-9a-f]{8})14', h): sel.add(m.group(1))
out={}
for s in sorted(sel):
    try:
        d=json.load(urllib.request.urlopen(f'https://www.4byte.directory/api/v1/signatures/?hex_signature=0x{s}',timeout=15))
        r=d.get('results',[]); out[s]=r[0]['text_signature'] if r else None
    except Exception: out[s]='ERR'
    time.sleep(0.1)
json.dump(out,open('ibera_selectors_resolved.json','w'),indent=0)
for k,v in out.items(): print(k,v)
