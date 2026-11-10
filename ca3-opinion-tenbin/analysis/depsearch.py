import json,subprocess,time
RPC="https://1rpc.io/bnb"
def rpc(m,p):
    for _ in range(6):
        out=subprocess.run(["curl","-s","--max-time","20","-X","POST","-H","Content-Type: application/json","--data",json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}),RPC],capture_output=True,text=True).stdout
        try:
            j=json.loads(out)
            if 'result' in j: return j['result']
        except Exception: pass
        time.sleep(0.5)
    return None
A="0xE19B1645ef54D703b5Ee6DFB7EdF91DEcAae64A4"
latest=int(rpc("eth_blockNumber",[]),16)
print("latest",latest)
# coarse scan backward by 20000 from 132650000
b=132650000
while b>130000000:
    c=rpc("eth_getCode",[A,hex(b)])
    if c is None: print("rpc fail at",b); break
    print(b, "code" if c not in ("0x","0x0") else "nocode")
    if c in ("0x","0x0"): break
    b-=20000
lo,hi=b,b+20000
print("range",lo,hi)
for _ in range(25):
    if lo>=hi: break
    mid=(lo+hi)//2
    c=rpc("eth_getCode",[A,hex(mid)])
    if c is None: print("fail"); break
    if c not in ("0x","0x0"): hi=mid
    else: lo=mid+1
print("first code",lo)
