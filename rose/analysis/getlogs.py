#!/usr/bin/env python3
import json, urllib.request, time, sys
RPC='https://mainnet.aurora.dev'
def rpc(m,p,retries=3):
    for i in range(retries):
        try:
            req=urllib.request.Request(RPC,data=json.dumps({'jsonrpc':'2.0','id':1,'method':m,'params':p}).encode(),headers={'Content-Type':'application/json','User-Agent':'Mozilla/5.0'})
            r=json.load(urllib.request.urlopen(req,timeout=90))
            if 'result' in r: return r['result']
            print('RPCERR', str(r)[:200], file=sys.stderr)
        except Exception as e:
            print('ERR', e, file=sys.stderr); time.sleep(2)
    return None
GARDENS={'gardenNear':'0x64C922E3824ab40cbbEdd6C8092d148C283d3D3D','gardenUsdc':'0xfbAF3eBF228eB712b1267285787e51aDd70086bB','gardenUsdt':'0x0F44fCD177098Cb2B063B50f6C62e4F1E1f9d596','gardenWeth':'0x084355FDd5fcfd55d60C5B8626756a6906576f13','gardenAtust':'0xe8F7F08D50e12145Cb722cfF861e6A9b43EADBA1'}
TOPICS={
 'addCollateral':'0x9ed03113de523cebfe5e49d5f8e12894b1c0d42ce805990461726444c90eab87',
 'borrow':'0xb92cb6bca8e3270b9170930f03b17571e55791acdb1a0e9f339eec88bdb35e24',
 'removeCollateral':'0x8ad4d3ff00da092c7ad9a573ea4f5f6a3dffc6712dc06d3f78f49b862297c402',
 'repay':'0xc8e512d8f188ca059984b5853d2bf653da902696b8512785b182b2c813789a6e',
}
alllogs={}
for lab,g in GARDENS.items():
    logs=[]
    for tname,topic in TOPICS.items():
        r=rpc('eth_getLogs',[{'fromBlock':'0x0','toBlock':'latest','address':g,'topics':[topic]}])
        if r: logs.extend([dict(x,kind=tname) for x in r])
    alllogs[lab]=logs
    print(f"{lab}: {len(logs)} events")
    for l in logs:
        blk=int(l['blockNumber'],16)
        topics=l['topics']
        data=l['data']
        if l['kind']=='addCollateral':
            frm='0x'+topics[1][-40:]; to='0x'+topics[2][-40:]; share=int(data,16)
            print(f"   [{blk}] addCollateral from={frm} to={to} share={share}")
        elif l['kind']=='borrow':
            frm='0x'+topics[1][-40:]; to='0x'+topics[2][-40:]
            amount=int(data[2:66],16); part=int(data[66:130],16)
            print(f"   [{blk}] borrow from={frm} to={to} amount={amount} part={part}")
        elif l['kind']=='removeCollateral':
            frm='0x'+topics[1][-40:]; to='0x'+topics[2][-40:]; share=int(data,16)
            print(f"   [{blk}] removeCollateral from={frm} to={to} share={share}")
        elif l['kind']=='repay':
            frm='0x'+topics[1][-40:]; to='0x'+topics[2][-40:]
            amount=int(data[2:66],16); part=int(data[66:130],16)
            print(f"   [{blk}] repay from={frm} to={to} amount={amount} part={part}")
json.dump(alllogs, open('garden_logs.json','w'), indent=1)
