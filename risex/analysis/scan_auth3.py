import json,re,urllib.request
RPC="https://rpc.risechain.com"; AM="0x1BEe39C01907E3018b7ec2021Cf73F70541b36cC"
targets={'ORACLE':"0x8fC4D0Cf74cdF595254cB763d4C05D38Df0e9503",'FUNDING':"0x069eDF2C2A3c93b54640Ae142B9f5375fe4A207a",
 'ACCTREG':"0x1238991Cac4E65902C08213e79909A9c813Eebc3",'AUTHZ':"0x0D919DAA3f12AE715744Eb648c00066c5DBd66f0",'FEE':"0x11541dc387b9C307043ea732127DF92b80bab52b"}
H={'content-type':'application/json','user-agent':'Mozilla/5.0'}
def post(o):
    return json.load(urllib.request.urlopen(urllib.request.Request(RPC,data=json.dumps(o).encode(),headers=H),timeout=90))
def getcode(a): return post({"jsonrpc":"2.0","id":1,"method":"eth_getCode","params":[a,"latest"]})['result']
def sels(h): return sorted(set(m.group(1) for m in re.finditer(r'63([0-9a-f]{8})14',h[2:])))
for k,proxy in targets.items():
    ss=sels(getcode(proxy))
    calls=[];order=[]
    for s in ss:
        data="0xb7009613"+("0"*24+"11"*20)+proxy[2:].rjust(64,'0')+s.ljust(64,'0')
        calls.append({"jsonrpc":"2.0","id":len(order),"method":"eth_call","params":[{"to":AM,"data":data},"latest"]}); order.append(s)
    resp=post(calls); true=[]
    for it in resp:
        if not isinstance(it,dict): continue
        v=it.get('result','')
        if isinstance(v,str) and len(v)>=66 and v[2:66].strip('0'): true.append((order[it['id']],v[:66]))
    print(k,len(ss),"public:",[t[0] for t in true],flush=True)
