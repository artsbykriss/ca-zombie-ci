#!/usr/bin/env python3
import json, urllib.request, time, re
RPC='https://mainnet.aurora.dev'
def rpc(m,p):
    req=urllib.request.Request(RPC,data=json.dumps({'jsonrpc':'2.0','id':1,'method':m,'params':p}).encode(),headers={'Content-Type':'application/json','User-Agent':'Mozilla/5.0'})
    return json.load(urllib.request.urlopen(req,timeout=60))['result']
def call(to,data): return rpc('eth_call',[{'to':to,'data':data},'latest'])
def addr(x): return '0x'+x[-40:] if x and len(x)>=42 else None
GARDENS={'gardenNear':'0x64C922E3824ab40cbbEdd6C8092d148C283d3D3D','gardenUsdc':'0xfbAF3eBF228eB712b1267285787e51aDd70086bB','gardenUsdt':'0x0F44fCD177098Cb2B063B50f6C62e4F1E1f9d596','gardenWeth':'0x084355FDd5fcfd55d60C5B8626756a6906576f13','gardenAtust':'0xe8F7F08D50e12145Cb722cfF861e6A9b43EADBA1'}
for lab,g in GARDENS.items():
    r=call(g,'0x1d1c9390')
    w2='0x'+r[2+64*2:2+64*3]
    w8='0x'+r[2+64*8:2+64*9]
    ln=int(r[2+64*8:2+64*9],16)
    data='0x'+r[2+64*9:2+64*9+64][:ln*2] if ln<=32 else 'long'
    print(f"{lab}: oracle={addr(w2)} oracleDataLen={ln} data={data}")
    orc=addr(w2)
    # call get(bytes) with the data
    if orc and orc!='0x0000000000000000000000000000000000000000':
        # encode get(bytes): selector d6d7d525 + offset(0x20) + len + data padded
        enc = '0xd6d7d525' + f"{0x20:064x}" + f"{ln:064x}" + (r[2+64*9:2+64*9+64] if ln>0 else '')
        try:
            res=call(orc, enc)
            updated = int(res[2:66],16) if res and len(res)>=66 else None
            rate = int(res[66:130],16) if res and len(res)>=130 else None
            print(f"    get() -> updated={updated} rate={rate}")
        except Exception as e:
            print("    get() ERR", e)
        # also raw code selectors
        c=rpc('eth_getCode',[orc,'latest'])
        p4=sorted(set(re.findall(r'63([0-9a-f]{8})',c)))
        print(f"    codelen={(len(c)-2)//2} selectors: {' '.join(p4[:25])}")
