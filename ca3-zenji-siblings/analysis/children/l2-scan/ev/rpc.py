#!/usr/bin/env python3
"""Read-only RPC helper. URL from env var name given by --rpc VAR (never stored).
Usage:
  rpc.py VAR block                      -> latest block
  rpc.py VAR code ADDR                  -> eth_getCode
  rpc.py VAR call TO DATA [FROM] [BLOCK]
  rpc.py VAR logs TO TOPIC0 FROM TO
"""
import json,os,sys,urllib.request

def post(url,payload):
    req=urllib.request.Request(url,data=json.dumps(payload).encode(),
        headers={"content-type":"application/json","user-agent":"research/1.0"})
    with urllib.request.urlopen(req,timeout=45) as r: return json.load(r)

def one(url,method,params):
    r=post(url,{"jsonrpc":"2.0","id":1,"method":method,"params":params})
    return r.get("result"), r.get("error")

def errstr(hexdata):
    if not hexdata or hexdata=="0x": return None
    b=hexdata[2:]
    # Error(string) selector 08c379a0
    if b.startswith("08c379a0"):
        try:
            ln=int(b[8+64:8+128],16); return bytes.fromhex(b[8+128:8+128+ln*2]).decode()
        except Exception: return None
    # Panic(uint256)
    if b.startswith("4e487b71"):
        try: return "Panic(0x%x)"%int(b[8:72],16)
        except Exception: return None
    return None

if __name__=="__main__":
    url=os.environ[sys.argv[1]]; cmd=sys.argv[2]
    if cmd=="block":
        print(int(one(url,"eth_blockNumber",[])[0],16))
    elif cmd=="code":
        c,e=one(url,"eth_getCode",[sys.argv[3],"latest"]); print(len(c)//2-1 if c else e, "bytes")
    elif cmd=="call":
        to,data=sys.argv[3],sys.argv[4]
        frm=sys.argv[5] if len(sys.argv)>5 else "0x0000000000000000000000000000000000000001"
        blk=sys.argv[6] if len(sys.argv)>6 else "latest"
        c,e=one(url,"eth_call",[{"to":to,"data":data,"from":frm},blk])
        if e: print("ERROR",json.dumps(e)[:400])
        else:
            print("OK len=%d"%(len(c)//2-1))
            if len(c)<=2: print("0x")
            else:
                for i in range(2,len(c),64): print(c[i:i+64])
            d=errstr(c)
            if d: print("REASON:",d)
    elif cmd=="raw":
        to,data=sys.argv[3],sys.argv[4]
        frm=sys.argv[5] if len(sys.argv)>5 else "0x0000000000000000000000000000000000000001"
        c,e=one(url,"eth_call",[{"to":to,"data":data,"from":frm},"latest"])
        print(json.dumps({"result":c,"error":e,"reason":errstr(c)}))
    elif cmd=="logs":
        to,topic,frm,to_b=sys.argv[3],sys.argv[4],int(sys.argv[5]),int(sys.argv[6])
        c,e=one(url,"eth_getLogs",[{"address":to,"topics":[topic],"fromBlock":hex(frm),"toBlock":hex(to_b)}])
        print(json.dumps({"n":len(c) if c else 0,"error":e,"logs":(c or [])[:3]})[:2000])
