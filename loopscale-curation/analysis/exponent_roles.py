#!/usr/bin/env python3
import solrpc as s, json, base64
try:
    import base58 as b58
except Exception:
    import b58
DISC=bytes([98,228,39,201,116,210,39,11])
PROG="sVau1tXvayVWfotzm9Ahcv2qfnnfRWttt78BCnNC6dD"
CUR=b58.b58decode("bs1PuRvB9rBBZkryBjADYvxc2qYh51EVW2fsb1uTiBN")
r=s.rpc("getProgramAccounts",[PROG,{"encoding":"base64","commitment":"confirmed",
    "filters":[{"memcmp":{"offset":0,"bytes":b58.b58encode(DISC).decode()}}]}])
res=r["result"]
print("total vaults",len(res))
curated=[]
for a in res:
    d=base64.b64decode(a["account"]["data"][0])
    if CUR not in d: continue
    curated.append((a["pubkey"],d))
print("curated",len(curated))
out=[]
for pk,d in curated:
    X=d.find(CUR)
    # curator vec: count u32 at X-4 (if curator is first)
    def u32(o): return int.from_bytes(d[o:o+4],'little')
    cnt_cur=u32(X-4)
    curators=[b58.b58encode(d[X+32*i:X+32*i+32]).decode() for i in range(min(cnt_cur,8))]
    # managers vec ends at X-4-4 (count) preceded by managers
    mgr_count_off=X-4-4
    cnt_mgr=u32(mgr_count_off) if mgr_count_off>=0 else -1
    mgr_off=mgr_count_off-cnt_mgr*32 if 0<cnt_mgr<20 else None
    managers=[b58.b58encode(d[mgr_off+32*i:mgr_off+32*i+32]).decode() for i in range(cnt_mgr)] if mgr_off and 0<cnt_mgr<20 else []
    # squads settings/vault are at offset 8+32, 8+64
    squads_settings=b58.b58encode(d[40:72]).decode()
    squads_vault=b58.b58encode(d[72:104]).decode()
    underlying=b58.b58encode(d[8+32*3+ 0: 8+32*3+32]).decode() if False else None
    out.append({"vault":pk,"len":len(d),"curator_off":X,"curator_count":cnt_cur,"curators":curators,
                "manager_count":cnt_mgr,"managers":managers,"squads_settings":squads_settings,"squads_vault":squads_vault})
    print(json.dumps(out[-1]))
json.dump(out,open("exponent_curated_roles.json","w"),indent=1)
