import json,subprocess,sys
RPC="https://bsc-rpc.publicnode.com"
def rpc(m,p):
    out=subprocess.run(["curl","-s","--max-time","20","-X","POST","-H","Content-Type: application/json","--data",json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}),RPC],capture_output=True,text=True).stdout
    return json.loads(out).get("result")
def has_code(a,b):
    c=rpc("eth_getCode",[a,hex(b)])
    return c not in (None,"0x","0x0")
latest=int(rpc("eth_blockNumber",[]),16)
for a in ["0x5E09dab0CC6f952c715919a1AbCe81AF918a5985","0xE19B1645ef54D703b5Ee6DFB7EdF91DEcAae64A4"]:
    lo,hi=1,latest
    while lo<hi:
        mid=(lo+hi)//2
        if has_code(a,mid): hi=mid
        else: lo=mid+1
    print(a,"first code block",lo,hex(lo))
