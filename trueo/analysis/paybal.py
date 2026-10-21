import json, os, sys, time, requests
from eth_abi import encode, decode
from eth_utils import keccak
RPC=os.environ.get("BASE_RPC","https://base-rpc.publicnode.com"); MC3="0xcA11bde05977b3631167028862bE2a173976CA11"
HERE=os.path.dirname(os.path.abspath(__file__))
sig=lambda s:"0x"+keccak(text=s).hex()[:8]
SEL_MC=sig("aggregate3((address,bool,bytes)[])"); BAL=sig("balanceOf(address)"); DEC=sig("decimals()")
def rpc(m,p,tries=6):
    for i in range(tries):
        try:
            r=requests.post(RPC,json={"jsonrpc":"2.0","id":1,"method":m,"params":p},timeout=90).json()
            if "result" in r: return r["result"]
        except Exception: pass
        time.sleep(1.5*(i+1))
    raise RuntimeError("rpc")
def mc(calls):
    enc=encode(["(address,bool,bytes)[]"],[[(t,True,bytes.fromhex(d[2:])) for t,d in calls]])
    res=rpc("eth_call",[{"to":MC3,"data":SEL_MC+enc.hex()},"latest"])
    return decode(["(bool,bytes)[]"],bytes.fromhex(res[2:]))[0]
d=json.load(open(os.path.join(HERE,"markets.json"))); mk=d["markets"]
for i in range(0,len(mk),80):
    ch=mk[i:i+80]; calls=[]
    for x in ch:
        calls.append((x["pay"], BAL+"0"*24+x["address"][2:]))
        calls.append((x["pay"], DEC))
    res=mc(calls)
    for j,x in enumerate(ch):
        ok,b=res[2*j]; x["paybal"]=int.from_bytes(b,"big") if ok else None
        ok,b=res[2*j+1]; x["paydec"]=int.from_bytes(b,"big") if ok else None
    print(f"  {min(i+80,len(mk))}/{len(mk)}",file=sys.stderr)
json.dump(d,open(os.path.join(HERE,"markets.json"),"w"),indent=1)
