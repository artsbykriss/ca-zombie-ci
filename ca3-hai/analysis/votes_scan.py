import csv, json, urllib.request
rows=list(csv.DictReader(open('kite_holders.csv')))
addrs=[r['addr'] for r in rows]
# add infra
for a in ["0xe807f3282f3391d237BA8B9bECb0d8Ea3ba23777","0xd68e7D20008a223dD48A6076AAf5EDd4fe80a899"]:
    addrs.append(a)
R="https://optimism-rpc.publicnode.com"
K="0xf467C7d5a4A9C4687fFc7986aC6aD5A4c81E1404"
sel="0x9ab24eb0"  # getVotes(address)
res={}
for i in range(0,len(addrs),100):
    chunk=addrs[i:i+100]
    batch=[{"jsonrpc":"2.0","id":j,"method":"eth_call","params":[{"to":K,"data":sel+"0"*24+a[2:].lower()},"latest"]} for j,a in enumerate(chunk)]
    req=urllib.request.Request(R,data=json.dumps(batch).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    out=json.load(urllib.request.urlopen(req,timeout=60))
    for item in out:
        j=item["id"]; v=int(item.get("result","0x0"),16)/1e18 if item.get("result") else 0
        res[chunk[j]]=v
tot=sum(res.values())
print("total delegated votes across holders+gov/tl:", f"{tot:,.4f}")
top=sorted(res.items(), key=lambda x:-x[1])[:20]
for a,v in top: print(f"{a} {v:,.4f}")
json.dump({"total_delegated":tot,"by_addr":res},open("votes_scan.json","w"),indent=1)
