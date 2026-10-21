import json,urllib.request,time,sys
R="https://evmrpc.0g.ai"
M="0xac06d1df23a4fa00981afac0f33a5936bd2135af"
T="0x02105621fc31aa3ac04a9845beacd54c700e2ab23ff8acdd755dfd878ae61f02"
B=47841263
out=[]
step=100000
lo=max(0,B-int(sys.argv[1])*step)
for start in range(lo,B+1,step):
    end=min(start+step-1,B)
    req={"jsonrpc":"2.0","id":1,"method":"eth_getLogs","params":[{"address":M,"topics":[T],"fromBlock":hex(start),"toBlock":hex(end)}]}
    for attempt in range(4):
        try:
            r=urllib.request.urlopen(urllib.request.Request(R,data=json.dumps(req).encode(),headers={'content-type':'application/json'}),timeout=60)
            d=json.load(r)
            if 'error' in d: raise Exception(str(d['error']))
            out+=d['result']; break
        except Exception as e:
            if attempt==3: print("FAIL",start,e); break
            time.sleep(1.5)
d=[{"block":int(x['blockNumber'],16),"era":int(x['topics'][1],16),"rate":int(x['data'],16)} for x in out]
d.sort(key=lambda z:z['block'])
json.dump(d,open('newera_logs.json','w'),indent=0)
print("events",len(d))
if d:
    print("first",d[0],"last",d[-1])
    prev=None
    for x in d[-40:]:
        print(x['era'],x['block'],x['rate'])
