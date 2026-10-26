import json,urllib.request
R="https://rpc.pharos.xyz"
def rpc(m,p):
    req=urllib.request.Request(R,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"content-type":"application/json"})
    return json.load(urllib.request.urlopen(req,timeout=30))
def getlogs(addr,topics,frm,to):
    return rpc("eth_getLogs",[{"address":addr,"topics":topics,"fromBlock":hex(frm),"toBlock":hex(to)}]).get("result")
F="0xefdbb0ea7647b0e21aef7a3b7a5d6a632c3116c8"
print("factory any logs 17516201-17517200:",len(getlogs(F,None,17516201,17517200) or []))
T="0x6d679d9dcb91cccb2f253f24f8f9b53871eac50c475cb8335cfdd93a32212865"
print("topic logs 17516201-17517200:",len(getlogs(F,[T],17516201,17517200) or []))
# full scan first 300k blocks
hits=[]
for frm in range(17516201,17816201,1000):
    r=getlogs(F,[T],frm,frm+999) or []
    if r: hits.append((frm,len(r))); print("HIT",frm,len(r),flush=True)
print("first300k hits:",hits)
