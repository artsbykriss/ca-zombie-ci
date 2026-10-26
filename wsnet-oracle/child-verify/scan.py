import json
from concurrent.futures import ThreadPoolExecutor
from probe import rpc
d=json.load(open('markets.json'))
ms=d['data']['markets']['items']
funded=[]
for m in ms:
    st=m.get('state') or {}
    sa=st.get('supplyAssetsUsd')
    if m.get('oracle') and sa and float(sa)>100:
        funded.append((m['marketId'], m['oracle']['address'], (m.get('collateralAsset') or {}).get('symbol'), float(sa), float(st.get('borrowAssetsUsd') or 0)))
oracles=sorted(set(o.lower() for _,o,_,_,_ in funded))
def getcode(o):
    return o, rpc("eth_getCode",[o,"latest"])
hits=[]; errs=0
with ThreadPoolExecutor(max_workers=6) as ex:
    for o,code in ex.map(getcode, oracles):
        if not isinstance(code,str): errs+=1; continue
        lc=code.lower()
        has_r="0902f1ac" in lc; has_s0="3850c7bd" in lc
        if has_r or has_s0:
            mk=[(m,s,sa,bo) for m,oo,s,sa,bo in funded if oo.lower()==o]
            hits.append({"oracle":o,"code_len_bytes":(len(code)-2)//2,"getReserves_0902f1ac":has_r,"slot0_3850c7bd":has_s0,
                         "funded_markets":[{"id":m,"collateral":s,"supplyUsd":sa,"borrowUsd":bo} for m,s,sa,bo in mk]})
print("funded",len(funded),"oracles",len(oracles),"errors",errs,"hits",len(hits))
print(json.dumps(hits,indent=2))
json.dump({"funded_count":len(funded),"distinct_oracles":len(oracles),"errors":errs,"hits":hits}, open("oracle_scan.json","w"), indent=2)
