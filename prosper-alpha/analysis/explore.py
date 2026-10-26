import json,urllib.request
R="https://rpc.pharos.xyz"
def rpc(m,p):
    r=urllib.request.Request(R,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"content-type":"application/json"})
    return json.load(urllib.request.urlopen(r,timeout=40)).get("result")
def getlogs(addr,topics,frm,to):
    return rpc("eth_getLogs",[{"address":addr,"topics":topics,"fromBlock":hex(frm),"toBlock":hex(to)}]) or []
M="0x21e1c2dd76cf9c3223dc38fe53bb63b4f1234d8a"
# find any logs from this market recently
found=[]
for frm in range(21234000,21240300,1000):
    l=getlogs(M,None,frm,frm+999)
    if l: found+=[(int(x["blockNumber"],16),x["transactionHash"],x["topics"][0],len(x["data"])) for x in l]
print("market logs recent:",found[:20], "total",len(found))
# extra getters
for name,sel in [("g_0172d417","0x0172d417"),("g_36010120","0x36010120"),("g_4bc55300","0x4bc55300"),("g_cf7e2533","0xcf7e2533"),("g_edd1f45e","0xedd1f45e"),("g_f074a48f","0xf074a48f"),("g_55c0fdae","0x55c0fdae")]:
    r=rpc("eth_call",[{"to":M,"data":sel},"latest"])
    print(name, r, int(r,16) if r and len(r)==66 else None)
