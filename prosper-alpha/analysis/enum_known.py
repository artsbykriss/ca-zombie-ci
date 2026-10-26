import json,urllib.request
R="https://rpc.pharos.xyz"
def rpc(m,p):
    req=urllib.request.Request(R,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"content-type":"application/json"})
    return json.load(urllib.request.urlopen(req,timeout=30))
def getlogs(addr,topics,frm,to):
    return rpc("eth_getLogs",[{"address":addr,"topics":topics,"fromBlock":hex(frm),"toBlock":hex(to)}]).get("result")
F="0xefdbb0ea7647b0e21aef7a3b7a5d6a632c3116c8"
T="0x6d679d9dcb91cccb2f253f24f8f9b53871eac50c475cb8335cfdd93a32212865"
wins=[17666201,17674201,17680201,17681201,17688201,17689201,17693201]
for w in wins:
    for lg in (getlogs(F,[T],w,w+999) or []):
        topics=lg["topics"]; data=lg["data"][2:]
        r25="0x"+topics[1][-40:]; camp=topics[2]; pt="0x"+topics[3][-40:]
        market="0x"+data[24:64]; buyback="0x"+data[88:128]
        print(json.dumps({"block":int(lg["blockNumber"],16),"tx":lg["transactionHash"],"r25":r25,"campaign":camp,"pToken":pt,"market":market,"buyback":buyback}))
