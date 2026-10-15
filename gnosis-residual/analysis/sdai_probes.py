#!/usr/bin/env python3
"""Second pass: verify allowlist holders live, role admins, proposal history (pools 8/67),
activatePoints eth_call probes, votingPowerRegistry, Celeste/arbitrator context."""
import json, urllib.request, time

RPC = "https://rpc.gnosischain.com"
RPC_FB = "https://gnosis-rpc.publicnode.com"
RC   = "0xE2396fe2169ca026962971d3B2E373Ba925B6257"
SDAI = "0xaf204776c7245bF4147c2612BF6e5972Ee483701"
STR8 = "0xaa0195986ffe8f3371444fa77ee3ed04ac787eea"
STR67= "0x96dee4849a6ab9e51ae36712794318001515dc91"
ROLE8  = "1e7e708759cd587d69adab3835168eb789586b24a36a778167d4461dadd00250"
ROLE67 = "b607c8c0ce5262160e662a9746016cc82f962c77947c16644f2364fbaeb65c19"
ALLOW8 = ["0x625236038836cecc532664915bd0399647e7826b","0x8aac40061e258d6e45fd13e214710abdf356285a",
 "0xc44caeb7f0724a156806664d2361fd6f32a2d2c8","0x2f9e113434aebdd70bb99cb6505e1f726c578d6d",
 "0x8d5fe65f1e78244972af4106cdf8e559247491ae","0xbbbf9761ed965d8df66f416b01bbcb224aeafd4f",
 "0x8758e5741de847363dd2715a62431cc0cbda4ca6","0xdf8f53b9f83e611e1154402992c6f6cb7daf246c",
 "0x6c965b656c450259a6d4d95a2e68fb4319eecbc0","0xa25211b64d041f690c0c818183e32f28ba9647dd",
 "0xed0f0c4de6150b7e3262e537d9691fc750b2ba23","0x14d92832265eeafdef9e526356fefc90105966c3",
 "0x07ad02e0c1fa0b09fc945ff197e18e9c256838c6","0x809c9f8dd8ca93a41c3adca4972fa234c28f7714",
 "0xb2206f941a5206b55bfa33e665687523a8bced80"]
EXTRA_MEMBERS=["0x121e1573b7c6c15aa4c036d54bfd2974cf38a163","0x01a1de6cc68c80bc905cb6b1a8cd9cf099a97209","0x3af7f9f073060bffbf97c89ef3ec525d30860208"]
NONMEMBER="0x000000000000000000000000000000000000dEaD"

def rpc(method,params,url=RPC):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req=urllib.request.Request(url,data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    last=None
    for a in range(4):
        try:
            with urllib.request.urlopen(req,timeout=90) as r: d=json.load(r)
            if "error" in d: raise RuntimeError(d["error"])
            return d["result"]
        except Exception as e:
            last=e; time.sleep(1.2*(a+1)); url=RPC_FB if url==RPC else RPC
    raise RuntimeError(last)

def batch(calls,url=RPC):
    payload=[]
    for i,c in enumerate(calls):
        obj={"to":c[0],"data":c[1]}
        if len(c)>2 and c[2]: obj["from"]=c[2]
        payload.append({"jsonrpc":"2.0","id":i+1,"method":"eth_call","params":[obj,"latest"]})
    body=json.dumps(payload).encode()
    req=urllib.request.Request(url,data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    for a in range(4):
        try:
            with urllib.request.urlopen(req,timeout=120) as r: d=json.load(r)
            out={}
            for item in d:
                out[item["id"]]=item.get("result") if "error" not in item else {"__err":item["error"]}
            return out
        except Exception as e:
            last=e; time.sleep(1.2*(a+1)); url=RPC_FB if url==RPC else RPC
    raise RuntimeError(last)

def pad(x): return (hex(x)[2:] if isinstance(x,int) else x).rjust(64,"0").lower().replace("0x","")
def enc(a): return a[2:].lower().rjust(64,"0")
def u(x): return int(x,16) if isinstance(x,str) and x.startswith("0x") and x!="0x" else None
def ua(x): return "0x"+x[-40:] if isinstance(x,str) and len(x)>=42 else None

blk=int(rpc("eth_blockNumber",[]),16)
print("block",blk)
res={}

# ---- 1. hasRole live for allowlist candidates + extra members, both pools
calls=[]; labels=[]
for a in ALLOW8+EXTRA_MEMBERS:
    for role,tag in [(ROLE8,"8"),(ROLE67,"67")]:
        calls.append((RC,"0x91d14854"+role+enc(a),None)); labels.append(("hasRole",tag,a))
for role,tag in [(ROLE8,"allows8"),(ROLE67,"allows67")]:
    calls.append((RC,"0x248a9ca3"+role,None)); labels.append(("getRoleAdmin","",tag))  # getRoleAdmin(bytes32)
    calls.append((RC,"0x91d14854"+role+enc("0x00bcc26e792e393217ba895f5e85ae628fc994e9"),None)); labels.append(("hasRoleOwner","",tag))
# DEFAULT_ADMIN_ROLE (0x00) holders
for a in ["0xc6c2E9EFB898A42DB4137B07b727b45e0C353d81","0x00BcC26E792E393217bA895f5e85AE628FC994E9","0xE2396fe2169ca026962971d3B2E373Ba925B6257",
          "0x9518b1e8e4b4b0bcb6b53cf0cbbbe0ba0b813a74","0x156d4bb8b1ffab60eec8ab3a8d1b7a76b43232c9"]:
    calls.append((RC,"0x91d14854"+pad(0)+enc(a),None)); labels.append(("hasRoleDEFAULTADMIN","",a))

out=batch(calls)
role_table={}
for i,(kind,tag,a) in enumerate(labels):
    v=u(out.get(i+1)); 
    role_table[f"{kind}|{tag}|{a}"]=v
res["hasRole"]=role_table

# ---- 2. activatePoints probes (eth_call from member addresses)
calls=[]; labels=[]
for a in ALLOW8[:5]+EXTRA_MEMBERS+[NONMEMBER]:
    for s,tag in [(STR8,"8"),(STR67,"67")]:
        calls.append((s,"0x814516ad",a)); labels.append(("activatePoints",tag,a))
out=batch(calls)
probes={}
for i,(kind,tag,a) in enumerate(labels):
    v=out.get(i+1)
    if isinstance(v,dict):
        err=v["__err"]; probes[f"{kind}|{tag}|{a}"]={"ok":False,"err":err.get("message"),"data":err.get("data","")[:200]}
    else:
        probes[f"{kind}|{tag}|{a}"]={"ok":True,"ret":v}
res["activatePoints_probes"]=probes

# ---- 3. votingPowerRegistry + more strategy fields
calls=[]; labels=[]
for s,tag in [(STR8,"8"),(STR67,"67")]:
    calls.append((s,"0x80fd91cd",None)); labels.append(("votingPowerRegistry",tag))
    calls.append((s,"0xbc63d8f1",None)); labels.append(("x_??",tag))
out=batch(calls)
res["strategy_extra"]={f"{k}|{t}":(ua(v) if k=="votingPowerRegistry" else v) for i,(k,t) in enumerate(labels) for v in [out.get(i+1)]}

# ---- 4. proposal history pools 8 & 67
hist={}
for s,tag in [(STR8,"8"),(STR67,"67")]:
    n=u(rpc("eth_call",[{"to":s,"data":"0x0c0512e9"},"latest"]))
    hist[tag]={"proposalCounter":n}
    calls=[(s,"0xc7f758a8"+pad(pid),None) for pid in range(1,n+1)]
    out=batch(calls)
    plist=[]
    for pid in range(1,n+1):
        v=out.get(pid)
        if not isinstance(v,str) or len(v)<2+64*11: 
            plist.append({"id":pid,"raw":v}); continue
        w=[v[2+i*64:2+(i+1)*64] for i in range(12)]
        plist.append({"id":pid,"submitter":ua("0x"+w[0]),"beneficiary":ua("0x"+w[1]),"requestedToken":ua("0x"+w[2]),
            "requestedAmount":int(w[3],16),"stakedAmount":int(w[4],16),"status":int(w[5],16),
            "blockLast":int(w[6],16),"convictionLast":int(w[7],16),"threshold":int(w[8],16),
            "voterStakedPoints":int(w[9],16),"arbConfigVersion":int(w[10],16),"protocol":int(w[11],16)})
    hist[tag]["proposals"]=plist
res["proposal_history"]=hist

# ---- 5. inbound sDAI transfers to both strategies (who funded)
for s,tag in [(STR8,"8"),(STR67,"67")]:
    try:
        logs=rpc("eth_getLogs",[{"address":SDAI,"fromBlock":"0x0","toBlock":hex(blk),
              "topics":["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",None,"0x"+enc(s)]}])
    except Exception as e:
        logs=rpc("eth_getLogs",[{"address":SDAI,"fromBlock":hex(blk-2_000_000),"toBlock":hex(blk),
              "topics":["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",None,"0x"+enc(s)]}])
    tr=[]
    for l in logs:
        tr.append({"block":int(l["blockNumber"],16),"from":"0x"+l["topics"][1][-40:],"value":int(l["data"],16) if len(l["data"])>=66 else None,"tx":l["transactionHash"]})
    res[f"inbound_sdai_{tag}"]=tr
    print(tag,"inbound transfers:",len(tr))

# also outbound from strategies
for s,tag in [(STR8,"8"),(STR67,"67")]:
    logs=rpc("eth_getLogs",[{"address":SDAI,"fromBlock":"0x0","toBlock":hex(blk),
              "topics":["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef","0x"+enc(s)]}])
    res[f"outbound_sdai_{tag}"]=[{"block":int(l["blockNumber"],16),"to":"0x"+l["topics"][2][-40:],"value":int(l["data"],16),"tx":l["transactionHash"]} for l in logs]
    print(tag,"outbound transfers:",len(logs))

json.dump({"block":blk,"results":res}, open("/home/heisenberg/CA/gnosis-residual/analysis/gardens-sdai-allowlist-probes.json","w"), indent=1)

# ---- compact print
print("\nALLOWLIST8 members (live):")
for a in ALLOW8:
    print("  ",a, role_table.get(f"hasRole|8|{a}"))
print("\nOTHER members (live, expect 0):")
for a in EXTRA_MEMBERS:
    print("  ",a,"pool8:",role_table.get(f"hasRole|8|{a}"),"pool67:",role_table.get(f"hasRole|67|{a}"))
print("\nr2:",json.dumps(res["strategy_extra"]))
print("probes:",json.dumps({k:v for k,v in list(probes.items())[:14]},default=str)[:1500])
print("getRoleAdmin ROLE8:",res["hasRole"]["getRoleAdmin||allows8"], "ROLE67:",res["hasRole"]["getRoleAdmin||allows67"])
