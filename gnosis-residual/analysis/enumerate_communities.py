#!/usr/bin/env python3
"""Enumerate all Gardens communities created on Gnosis + their HNY holdings."""
import json, urllib.request, time, sys, subprocess
RPC="https://rpc.gnosischain.com"
OUT="/home/heisenberg/CA/gnosis-residual/analysis"
def rpc(m,p):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode()
    req=urllib.request.Request(RPC,data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    for a in range(6):
        try:
            with urllib.request.urlopen(req,timeout=120) as r: d=json.load(r)
            if "error" in d: raise RuntimeError(d["error"])
            return d["result"]
        except Exception as e:
            print("retry",a,str(e)[:80],file=sys.stderr); time.sleep(2*(a+1))
    raise RuntimeError("fail")
def call(to,data):
    try: return rpc("eth_call",[{"to":to,"data":data},"latest"])
    except Exception as e: return "ERR:"+str(e)[:60]
def logs(addr,topics):
    try: return rpc("eth_getLogs",[{"address":addr,"topics":topics,"fromBlock":"0x0","toBlock":"latest"}])
    except Exception as e: return []
def sig(s): return "0x"+subprocess.check_output(["cast","keccak",s]).decode().strip()[2:]

FACT="0x08Df82f74D1f56F650E98da2dd4240F1A31711bc"
HNY="0x71850b7E9Ee3f13Ab46d67167341E4bDc905Eef9"
pc_created=sig("CommunityCreated(address)")
pc_pool=sig("PoolCreated(uint256,address,address,address,(uint256,string))")

cl=logs(FACT,[pc_created])
comms=[]
for l in cl:
    a="0x"+l["data"][2+24:2+64]
    comms.append({"addr":a,"blk":int(l["blockNumber"],16),"tx":l["transactionHash"]})
print("communities:",len(comms))
res=[]
for c in comms:
    a=c["addr"]
    name=call(a,"0xc6d572ae")  # communityName()? verify below
    tok=call(a,"0xdb61d65c")   # gardenToken()? verify below
    def decostr(r):
        if not r or r=="0x" or r.startswith("ERR"): return r
        try:
            raw=bytes.fromhex(r[2:])
            off=int.from_bytes(raw[0:32],"big"); ln=int.from_bytes(raw[off:off+32],"big")
            return raw[off+32:off+32+ln].decode("utf8",errors="replace")
        except Exception: return r[:40]
    nm=decostr(name)
    t="0x"+tok[2+24:2+64] if tok and len(tok)>=66 else tok
    bal=call(HNY,"0x70a08231"+"00"*12+a[2:])
    members=call(a,"0x76e92559")
    pools=logs(a,[pc_pool])
    pl=[]
    for p in pools:
        d=p["data"][2:]
        w=[d[i:i+64] for i in range(0,min(len(d),64*4),64)]
        if len(w)>=4:
            pid=int(w[0],16); strat="0x"+w[1][-40:]; community="0x"+w[2][-40:]; token="0x"+w[3][-40:]
            sb=call(HNY,"0x70a08231"+"00"*12+strat[2:])
            sbal=int(sb,16)/1e18 if sb and sb!="0x" and not sb.startswith("ERR") else None
            pl.append({"poolId":pid,"strategy":strat,"token":token,"hny_balance":sbal})
    rec={"community":a,"blk":c["blk"],"name":nm,"gardenToken":t,"hny_balance":int(bal,16)/1e18 if bal and bal!="0x" and not bal.startswith("ERR") else None,
         "totalMembers":int(members,16) if members and members!="0x" else None,"pools":pl}
    res.append(rec)
    print(json.dumps(rec)[:400])
with open(f"{OUT}/gardens-communities.json","w") as f: json.dump(res,f,indent=1)
print("written", f"{OUT}/gardens-communities.json")
