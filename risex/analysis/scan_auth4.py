import json,re,urllib.request
RPC="https://rpc.risechain.com"; AM="0x1BEe39C01907E3018b7ec2021Cf73F70541b36cC"
targets={'PM':("0x53f10fAcFC8965750494E6965F5d6dA39B41d852","0xac3919b01bf61b5da143d61dab472df0a430804b"),
 'ORACLE':("0x8fC4D0Cf74cdF595254cB763d4C05D38Df0e9503","0xe275c453d8d84177ebe637022d16593d483b5a39"),
 'FUNDING':("0x069eDF2C2A3c93b54640Ae142B9f5375fe4A207a","0x52b80e88b67ebc7f1c67652b200aec63bf9b314e"),
 'ACCTREG':("0x1238991Cac4E65902C08213e79909A9c813Eebc3","0x531a0c7687cbaf02383b21443619487eb18b91e5"),
 'AUTHZ':("0x0D919DAA3f12AE715744Eb648c00066c5DBd66f0","0xcccb0483342d77abc4337f3e12514ec8e78b3e28"),
 'FEE':("0x11541dc387b9C307043ea732127DF92b80bab52b","0x379a6321f5e3659930c5096d209a6bce0f8acfbd"),
 'OM':("0xE03C1D5081eb2d0E6bFd62A949C5b12eFa44F2cD","0x9b9b37d6abf78774403e2db7ae2975819c488e7e")}
H={'content-type':'application/json','user-agent':'Mozilla/5.0'}
def post(o): return json.load(urllib.request.urlopen(urllib.request.Request(RPC,data=json.dumps(o).encode(),headers=H),timeout=90))
def getcode(a): return post({"jsonrpc":"2.0","id":1,"method":"eth_getCode","params":[a,"latest"]})['result']
def sels(h): return sorted(set(m.group(1) for m in re.finditer(r'63([0-9a-f]{8})14',h[2:])))
allres={}
for k,(proxy,impl) in targets.items():
    ss=sels(getcode(impl)); calls=[];order=[]
    for s in ss:
        data="0xb7009613"+("0"*24+"11"*20)+proxy[2:].rjust(64,'0')+s.ljust(64,'0')
        calls.append({"jsonrpc":"2.0","id":len(order),"method":"eth_call","params":[{"to":AM,"data":data},"latest"]}); order.append(s)
    resp=post(calls); true=[]
    for it in resp:
        if not isinstance(it,dict): continue
        v=it.get('result','')
        if isinstance(v,str) and len(v)>=66 and v[2:66].strip('0'): true.append(order[it['id']])
    print(k,len(ss),"public:",true,flush=True); allres[k]=true
json.dump(allres,open('public_selectors.json','w'),indent=1)
