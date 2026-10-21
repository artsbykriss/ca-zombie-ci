import json,re,urllib.request
RPC="https://rpc.risechain.com"; AM="0x1BEe39C01907E3018b7ec2021Cf73F70541b36cC"
targets={'PM':("0x53f10fAcFC8965750494E6965F5d6dA39B41d852","0xac3919b01bf61b5da143d61dab472df0a430804b"),
 'CM':("0x2C03C7d7e2974C6599b6B108879109281ef3F818","0x893fc1ce864e5a5c0c9fb23c18bc6486dab8b93f")}
def batch(calls):
    req=urllib.request.Request(RPC,data=json.dumps(calls).encode(),headers={"content-type":"application/json","user-agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req,timeout=90))
def getcode(a):
    r=json.load(urllib.request.urlopen(urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_getCode","params":[a,"latest"]}).encode(),headers={"content-type":"application/json","user-agent":"Mozilla/5.0"}),timeout=60))
    return r['result']
def sels(h): return sorted(set(m.group(1) for m in re.finditer(r'63([0-9a-f]{8})14',h[2:])))
out={}
for k,(proxy,impl) in targets.items():
    ss=sels(getcode(impl)); print(k,len(ss),flush=True)
    calls=[]; order=[]
    for s in ss:
        data="0xb7009613"+"11"*20+b"\x00".hex()+proxy[2:].rjust(64,'0')+s.ljust(64,'0')
        data="0xb7009613"+("0"*24+"11"*20)+proxy[2:].rjust(64,'0')+s.ljust(64,'0')
        calls.append({"jsonrpc":"2.0","id":len(order),"method":"eth_call","params":[{"to":AM,"data":data},"latest"]}); order.append(s)
    resp=batch(calls)
    res={}
    for item in resp:
        i=item['id']; s=order[i]
        v=item.get('result') or item.get('error',{}).get('message','ERR')
        res[s]=v
    out[k]={"proxy":proxy,"sels":ss,"res":res}
    true=[s for s,v in res.items() if isinstance(v,str) and v.startswith('0x') and len(v)>=66 and v[2:66].strip('0')]
    print(k,"public/true:",true,flush=True)
json.dump(out,open("auth_scan.json","w"),indent=1)
