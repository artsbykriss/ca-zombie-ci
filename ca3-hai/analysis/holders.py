import json, urllib.request, time
base="https://optimism.blockscout.com/api/v2/tokens/0xf467C7d5a4A9C4687fFc7986aC6aD5A4c81E1404/holders"
params={}
rows=[]
for page in range(40):
    url=base
    if params:
        url+="?"+"&".join(f"{k}={v}" for k,v in params.items())
    req=urllib.request.Request(url, headers={"User-Agent":"Mozilla/5.0"})
    d=json.load(urllib.request.urlopen(req, timeout=30))
    items=d.get("items",[])
    for it in items:
        rows.append({
            "addr":it["address"]["hash"],
            "is_contract":it["address"]["is_contract"],
            "name":it["address"].get("name"),
            "value":int(it["value"])/1e18,
        })
    nxt=d.get("next_page_params")
    if not nxt: break
    params=nxt
    time.sleep(0.25)
tot=sum(r["value"] for r in rows)
print("holders fetched:",len(rows),"sum:",f"{tot:,.2f}")
print("total supply 973,967,000; pct held in fetched:",f"{tot/973967000*100:.3f}%")
rows.sort(key=lambda r:-r["value"])
print("\nTop 30:")
for r in rows[:30]:
    print(f'{r["addr"]} {r["value"]:>18,.2f} {r["value"]/973967000*100:7.4f}% contract={r["is_contract"]} {r["name"]}')
import csv
with open("kite_holders.csv","w") as f:
    w=csv.DictWriter(f,fieldnames=["addr","is_contract","name","value"]); w.writeheader(); w.writerows(rows)
