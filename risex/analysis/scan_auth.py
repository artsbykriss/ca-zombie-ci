import json,re,urllib.request,os,sys
RPC="https://rpc.risechain.com"
AM="0x1BEe39C01907E3018b7ec2021Cf73F70541b36cC"
targets={
 'PM':("0x53f10fAcFC8965750494E6965F5d6dA39B41d852","0xac3919b01bf61b5da143d61dab472df0a430804b"),
 'CM':("0x2C03C7d7e2974C6599b6B108879109281ef3F818","0x893fc1ce864e5a5c0c9fb23c18bc6486dab8b93f"),
 'OM':("0xE03C1D5081eb2d0E6bFd62A949C5b12eFa44F2cD","0x9b9b37d6abf78774403e2db7ae2975819c488e7e"),
 'ORACLE':("0x8fC4D0Cf74cdF595254cB763d4C05D38Df0e9503",None),
 'FUNDING':("0x069eDF2C2A3c93b54640Ae142B9f5375fe4A207a",None),
 'ACCTREG':("0x1238991Cac4E65902C08213e79909A9c813Eebc3","0x531a0c7687cbaf02383b21443619487eb18b91e5"),
}
def rpc(method,params):
    req=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),headers={'content-type':'application/json','user-agent':'research'})
    return json.load(urllib.request.urlopen(req,timeout=40))['result']
def code(a): return rpc("eth_getCode",[a,"latest"])
def sels(h):
    b=h[2:]
    return sorted(set(m.group(1) for m in re.finditer(r'63([0-9a-f]{8})14',b)))
def cancall(caller,target,sel):
    data="0xc46e3f36"+caller[2:].rjust(64,'0')+target[2:].rjust(64,'0')+sel.ljust(64,'0')
    r=rpc("eth_call",[{"to":AM,"data":data},"latest"])
    return r
out={}
for k,(proxy,impl) in targets.items():
    c=code(impl or proxy)
    ss=sels(c)
    res={}
    for s in ss:
        try:
            r=cancall("0x1111111111111111111111111111111111111111",proxy,"0x"+s)
            res[s]= r[:66]
        except Exception as e:
            res[s]="ERR"
    out[k]={"proxy":proxy,"n_selectors":len(ss),"canCall":res}
    print(k,len(ss),{s:v for s,v in res.items() if v not in ("0x"+"00"*32,"0x"+("0"*64))})
json.dump(out,open("auth_scan.json","w"),indent=1)
