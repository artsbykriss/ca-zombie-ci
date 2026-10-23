import json,urllib.request,base64,sys
RPC="https://api.mainnet-beta.solana.com"
def rpc(method,params):
    req=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req,timeout=60))
def b58decode(s):
    a="123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    n=0
    for c in s: n=n*58+a.index(c)
    b=n.to_bytes((n.bit_length()+7)//8,'big')
    pad=len(s)-len(s.lstrip('1'))
    return b'\x00'*pad+b
def b58encode(b):
    a="123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    n=int.from_bytes(b,'big'); s=""
    while n: n,r=divmod(n,58); s=a[r]+s
    pad=len(b)-len(b.lstrip(b'\x00'))
    return '1'*pad+(s or '1')
prog="J7vt5nGQd7YggFTV6GPwmWycfxzLjnHoGX6GRUKo9M7A"
r=rpc("getAccountInfo",[prog,{"encoding":"base64"}])
v=r["result"]["value"]; d=base64.b64decode(v["data"][0])
print("program acct owner",v["owner"],"len",len(d))
pd_pub=b58encode(d[4:36])
print("programdata pubkey",pd_pub)
r2=rpc("getAccountInfo",[pd_pub,{"encoding":"base64"}])
v2=r2["result"]["value"]; d2=base64.b64decode(v2["data"][0])
print("programdata len",len(d2))
tag=int.from_bytes(d2[0:4],'little'); slot=int.from_bytes(d2[4:12],'little')
opt=d2[12]; auth=b58encode(d2[13:45]) if opt else None
print("tag",tag,"last_deploy_slot",slot,"upgrade_authority",auth)
elf=d2[45:]
open("cardboard_exchange.so","wb").write(elf)
open("programdata_pubkey.txt","w").write(pd_pub+"\n")
print("ELF size",len(elf),"magic",elf[:4])
