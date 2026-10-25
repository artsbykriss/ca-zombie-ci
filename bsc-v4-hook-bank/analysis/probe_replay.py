#!/usr/bin/env python3
"""Fetch representative prober tx inputs and replay from stranger + authorized bot."""
import json, sys
sys.path.insert(0,'/home/heisenberg/CA/bsc-v4-hook-bank/analysis')
import rpclib as R

TGT='0x16ceff8d5a4c8648fcc7293f8bd3ac9ada454219'
STRANGER='0x000000000000000000000000000000000000dEaD'
# representative txs (one per probed selector) from pass6
txs={
 '0xf35ca728':'0x39f85e7857b39d11afb7160df8922af2e84b130123dfe2c44497ceb8634cb6d5',
 '0xd1e57635':'0xc34b6eea1f731fdefbd66295f3462f061891079a61403ce224bcbbe7b07d4ac4',
 '0x9e1941ca':'0x44f80d0721e7e5814e1779e27e54edc9a930c8313b4476fce38d4fd1f4416a4b',
 '0xa3f8ea7c':'0xdbb3813d8c923f7d3cfaa1019855a182d759448c3ce19ded152ed2a089b8e240',
}
res={}
for sel,tx in txs.items():
    t=R.rpc('eth_getTransactionByHash',[tx])
    inp=t['input']; frm=t['from']; bn=t['blockNumber']
    rec={'tx':tx,'from':frm,'block':bn,'input':inp,'inlen':(len(inp)-2)//2}
    def run(f):
        r=R.call(TGT,inp,bn,f)
        if isinstance(r,dict):
            e=r.get('__error__',{})
            if isinstance(e,dict):
                return {'revert':True,'msg':e.get('message'),'data':e.get('data')}
            return {'revert':True,'msg':str(e)}
        return {'revert':False,'ret':r}
    rec['as_stranger']=run(STRANGER)
    rec['as_bot']=run(frm)
    rec['as_owner']=run('0xf050633406ee54abd99b9d834c1b622fb8d35d0b')
    res[sel]=rec
    print(sel, 'inlen', rec['inlen'])
    print('   stranger:', rec['as_stranger'])
    print('   bot     :', rec['as_bot'])
    print('   owner   :', rec['as_owner'])
open('probe_replay.json','w').write(json.dumps(res,indent=1))
