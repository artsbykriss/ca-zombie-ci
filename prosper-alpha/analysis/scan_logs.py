import json,urllib.request,sys
R="https://rpc.pharos.xyz"
def rpc(method,params):
    req=urllib.request.Request(R,data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),headers={"content-type":"application/json"})
    return json.load(urllib.request.urlopen(req,timeout=30))
def getlogs(addr,topics,frm,to):
    return rpc("eth_getLogs",[{"address":addr,"topics":topics,"fromBlock":hex(frm),"toBlock":hex(to)}]).get("result")
F="0xefdbb0ea7647b0e21aef7a3b7a5d6a632c3116c8"
T="0x6d679d9dcb91cccb2f253f24f8f9b53871eac50c475cb8335cfdd93a32212865"
start=17516201; end=21240221
step=100000
hits=[]
for frm in range(start,end,step):
    to=min(frm+999,end)
    r=getlogs(F,[T],frm,to)
    n=len(r) if r is not None else -1
    if n: hits.append((frm,n)); print("HIT",frm,n,flush=True)
print("done coarse; hits:",hits)
# also total any-logs on factory at one recent window
print("factory any-logs 21239000:",len(getlogs(F,None,21239000,21239999) or []))
