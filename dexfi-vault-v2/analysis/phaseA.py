import json,time,sys
import rpc_scan as R
url=R.RPC['base']; fac=R.FACTORY['base']
WETH='0x4200000000000000000000000000000000000006'
sel_v=R.selector('vaults(uint256)'); sel_pd=R.selector('publishData()'); sel_ts=R.selector('totalSupply()'); sel_b=R.selector('balanceOf(address)'); sel_ow=R.selector('owner()')
n=R.dec_uint(R.call_one(url,fac,'0x'+R.selector('vaultsCount()')))
print('n',n,flush=True)
vaults=[]
for i in range(0,n,50):
    calls=[(fac,'0x'+sel_v+R.enc_uint(j)) for j in range(i,min(i+50,n))]
    res=R.rpc_batch(url,calls)
    for h in res: vaults.append(R.dec_addr(h))
print('got',len(vaults),'none=',sum(1 for x in vaults if not x),flush=True)
out=[]
for i in range(0,len(vaults),50):
    chunk=[v for v in vaults[i:i+50] if v]
    calls=[]
    for v in chunk:
        calls += [(v,'0x'+sel_pd),(v,'0x'+sel_ts),(WETH,'0x'+sel_b+R.enc_addr(v)),(v,'0x'+sel_ow)]
    res=R.rpc_batch(url,calls)
    for k,v in enumerate(chunk):
        pd=res[4*k]; ts=res[4*k+1]; wb=res[4*k+2]; ow=res[4*k+3]
        published=None; publisher=None
        if pd and len(pd)>=130:
            published = int(pd[2:66],16)!=0
            publisher = R.dec_addr('0x'+pd[90:130])
        out.append({'vault':v,'published':published,'publisher':publisher,'supply':R.dec_uint(ts),'weth':R.dec_uint(wb),'owner':R.dec_addr(ow)})
    print('phaseA',i,flush=True)
json.dump({'n':n,'records':out},open('/home/heisenberg/CA/dexfi-vault-v2/ci-out/base_phaseA.json','w'))
print('done')
