import json,subprocess,sys,time
RPC="https://bsc-rpc.publicnode.com"
def rpc(m,p):
    for _ in range(3):
        out=subprocess.run(["curl","-s","--max-time","30","-X","POST","-H","Content-Type: application/json","--data",json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}),RPC],capture_output=True,text=True).stdout
        try:
            j=json.loads(out)
            if 'result' in j: return j['result']
        except Exception: pass
        time.sleep(1)
    print("FAIL",m,out[:200],file=sys.stderr); return None
addrs=["0x5E09dab0CC6f952c715919a1AbCe81AF918a5985","0xE19B1645ef54D703b5Ee6DFB7EdF91DEcAae64A4",
       "0x291cb502716FF742bc531BD7F683b34aE1f26069","0x78A016e4A8707300f2aEC3cC895A01FbCC70d5D6"]
latest=int(rpc("eth_blockNumber",[]),16)
out={}
for a in addrs:
    logs=[]; start=132650000
    while start<=latest:
        end=min(start+1999,latest)
        r=rpc("eth_getLogs",[{"address":a,"fromBlock":hex(start),"toBlock":hex(end)}])
        if r is None: break
        logs+=r
        start=end+1
    out[a]=logs
    print(a,"logs",len(logs))
json.dump(out,open("resolver-logs.json","w"),indent=1)
