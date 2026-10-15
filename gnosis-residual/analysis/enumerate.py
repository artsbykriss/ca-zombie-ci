#!/usr/bin/env python3
"""Robust enumeration/reconciliation for Gardens v2 Gnosis. READ-ONLY."""
import json, urllib.request, time, sys, subprocess
from collections import Counter

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
def logs(addr,topics): return rpc("eth_getLogs",[{"address":addr,"topics":topics,"fromBlock":"0x0","toBlock":"latest"}])
def call(to,data): return rpc("eth_call",[{"to":to,"data":data},"latest"])
def sig(s): return "0x"+subprocess.check_output(["cast","keccak",s]).decode().strip()[2:]

RC="0xE2396fe2169ca026962971d3B2E373Ba925B6257"
STRAT="0x9Fb2f1813228a97f559E29A6492EE27357FAF8A2"
HNY="0x71850b7E9Ee3f13Ab46d67167341E4bDc905Eef9"
FACT="0x08Df82f74D1f56F650E98da2dd4240F1A31711bc"

def evaddr(l):
    if len(l["topics"])>2: return "0x"+l["topics"][2][-40:]
    if len(l["topics"])==2: return "0x"+l["topics"][1][-40:]
    d=l["data"]; return "0x"+d[2+24:2+64]

evs = {
 "reg": (sig("MemberRegisteredWithCovenant(address,uint256,string)"), "add"),
 "regold": (sig("MemberRegistered(address,uint256)"), "add"),
 "unreg": (sig("MemberUnregistered(address,uint256)"), "del"),
 "kick": (sig("MemberKicked(address,address,uint256)"), "del"),
}
raw={}
addrs=set()
for k,(t,op) in evs.items():
    ls=logs(RC,[t]); raw[k]=ls
    for l in ls:
        a=evaddr(l)
        # for kick: first arg in data is member; for unreg: member; ok
        addrs.add(a.lower())
    print(k,len(ls))
# add senders of HNY into RC (they must be members)
tr=rpc("eth_getLogs",[{"address":HNY,"topics":["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",None,"0x"+"00"*12+RC[2:].lower()],"fromBlock":"0x0","toBlock":"latest"}])
for l in tr: addrs.add(("0x"+l["topics"][1][-40:]).lower())
print("hny_in transfers",len(tr))

info={}
for m in sorted(addrs):
    r=call(RC,"0x88cfe684"+"00"*12+m[2:])
    if r and len(r)>=2+64*3:
        staked=int(r[2+64:2+128],16); isreg=int(r[2+128:2+192],16)==1
        if isreg or staked>0:
            info[m]={"member":"0x"+r[2+24:2+64],"staked":staked,"isRegistered":isreg}
sum_all=sum(v["staked"] for v in info.values() if v["isRegistered"])
sum_reg=sum(v["staked"] for v in info.values())
bal=int(call(HNY,"0x70a08231"+"00"*12+RC[2:].lower()),16)
print("addresses probed:",len(addrs))
print("registered members found:",sum(1 for v in info.values() if v["isRegistered"]))
print("sum staked (registered only):",sum_all/1e18)
print("sum staked (all incl unreg):",sum_reg/1e18)
print("RC HNY balance:",bal/1e18)
print("diff (bal - sum_registered):",(bal-sum_all)/1e18)

# --- strategies/pools in RC (data-only events)
def dec_words(d):
    d=d[2:]; return [d[i:i+64] for i in range(0,len(d),64)]
sa=logs(RC,[sig("StrategyAdded(address)")]); sr=logs(RC,[sig("StrategyRemoved(address)")])
pc=logs(RC,[sig("PoolCreated(uint256,address,address,address,(uint256,string))")])
print("StrategyAdded",len(sa),"Removed",len(sr),"PoolCreated",len(pc))
strat_events=[]
for l in sa: strat_events.append({"op":"add","blk":int(l["blockNumber"],16),"strategy":"0x"+dec_words(l["data"])[0][-40:]})
for l in sr: strat_events.append({"op":"rem","blk":int(l["blockNumber"],16),"strategy":"0x"+dec_words(l["data"])[0][-40:]})
for e in strat_events: print(" ",e)
pools=[]
for l in pc:
    w=dec_words(l["data"])
    pools.append({"blk":int(l["blockNumber"],16),"poolId":int(w[0],16),"strategy":"0x"+w[1][-40:],"community":"0x"+w[2][-40:],"token":"0x"+w[3][-40:]})
for p in pools: print("  pool",p)

# --- factory: topic0 histogram + community events
fl=logs(FACT,[None])
c=Counter(l["topics"][0] for l in fl)
print("factory logs:",len(fl))
for t,n in c.items(): print("  topic",t,"count",n)

# --- balances of every strategy ever created in this RC
strat_bal={}
for p in pools:
    r=call(HNY,"0x70a08231"+"00"*12+p["strategy"][2:].lower())
    strat_bal[p["strategy"]]=int(r,16)/1e18 if r and r!="0x" else None
print("strategy HNY balances:",strat_bal)

outp={"member_info":info,"sum_staked_registered":str(sum_all),"rc_hny_balance":str(bal),
      "strategy_events":strat_events,"pools":pools,"factory_topic_counts":{k:v for k,v in c.items()},
      "strategy_hny_balances":strat_bal}
with open(f"{OUT}/gardens-enumeration.json","w") as f: json.dump(outp,f,indent=1)
print("written")
