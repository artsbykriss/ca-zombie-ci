import json,subprocess,time
RPC="https://bsc-rpc.publicnode.com"
def rpc(m,p):
    for _ in range(5):
        out=subprocess.run(["curl","-s","--max-time","25","-X","POST","-H","Content-Type: application/json","--data",json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}),RPC],capture_output=True,text=True).stdout
        try:
            j=json.loads(out)
            if 'result' in j: return j['result']
        except Exception: pass
        time.sleep(1)
    raise Exception("rpc fail")
def code(a,b):
    c=rpc("eth_getCode",[a,hex(b)])
    return c and c!='0x'
latest=int(rpc("eth_blockNumber",[]),16)
for a in ["0xE19B1645ef54D703b5Ee6DFB7EdF91DEcAae64A4","0x5E09dab0CC6f952c715919a1AbCe81AF918a5985"]:
    # sanity
    assert code(a,latest), a
    lo,hi=130000000,latest
    while lo<hi:
        mid=(lo+hi)//2
        if code(a,mid): hi=mid
        else: lo=mid+1
    print(a,"first code block",lo)
