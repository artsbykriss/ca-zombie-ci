#!/usr/bin/env python3
import json, urllib.request, time
RPCS=["https://bsc-rpc.publicnode.com","https://bsc-dataseed.bnbchain.org"]
def rpc(m,p):
    for url in RPCS:
        for a in range(3):
            try:
                r=urllib.request.Request(url,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"Content-Type":"application/json","User-Agent":"z"})
                with urllib.request.urlopen(r,timeout=25) as f: d=json.load(f)
                if "result" in d: return d["result"]
            except Exception: time.sleep(0.3)
    return None
succ=json.load(open("bsc_bank_succ.json"))
TRANSFER="0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
BANK="0x7817dbf38e9d1c95671625f0052c147864692fe0"
VAULT="0x238a358808379702088667322f80ac48bad5e6c4"
sel_counts={}
flows=[]
for s in succ[:120]:
    tx=rpc("eth_getTransactionByHash",[s["tx"]])
    if not tx: continue
    frm=tx["from"].lower(); sel=tx["input"][:10]
    sel_counts[sel]=sel_counts.get(sel,0)+1
    trs=[]
    for l in s["logs"]:
        if l["topics"] and l["topics"][0].lower()==TRANSFER:
            f="0x"+l["topics"][1][-40:]; t="0x"+l["topics"][2][-40:]
            amt=int(l["data"],16)
            trs.append((l["addr"].lower(),f.lower(),t.lower(),amt))
    flows.append({"tx":s["tx"],"from":frm,"sel":sel,"trs":trs})
print("selector counts (successful):",sel_counts)
# classify
from collections import Counter
pats=Counter()
for fl in flows:
    for (tok,f,t,amt) in fl["trs"]:
        if f==BANK and t==VAULT: pats["BANK->VAULT"]+=1
        elif t==fl["from"]: pats["->CALLER"]+=1
        elif f==fl["from"]: pats["CALLER->"]+=1
        elif t==BANK: pats["->BANK"]+=1
        elif f==BANK: pats["BANK->"]+=1
        else: pats[f"{f[:10]}->{t[:10]}"]+=1
print("flow patterns:",pats)
# show a few with the caller involved
shown=0
for fl in flows:
    invol=any(t==fl["from"] or f==fl["from"] for (_,f,t,_) in fl["trs"])
    if invol and shown<6:
        print("\n",fl["tx"][:18],fl["sel"],"from",fl["from"][:12])
        for (tok,f,t,amt) in fl["trs"]:
            print("   ",tok[:12],f[:12],"->",t[:12],amt)
        shown+=1
