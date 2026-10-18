#!/usr/bin/env python3
"""Page through ALL txs to the HaiGovernor via explorer.optimism.io v2 API."""
import json, urllib.request, urllib.parse, time
BASE="https://explorer.optimism.io/api/v2/addresses/0xe807f3282f3391d237BA8B9bECb0d8Ea3ba23777/transactions?filter=to"
def get(url):
    req=urllib.request.Request(url, headers={'User-Agent':'Mozilla/5.0'})
    return json.load(urllib.request.urlopen(req, timeout=45))
items=[]; url=BASE; page=0
while url and page<600:
    for attempt in range(4):
        try:
            d=get(url); break
        except Exception as e:
            print('retry', page, e, flush=True); time.sleep(2)
    else:
        print('FAILED at page', page); break
    it=d.get('items',[]); items.extend(it); page+=1
    if page%20==0: print('page',page,'items',len(items), flush=True)
    nxt=d.get('next_page_params')
    if not nxt: break
    url=BASE+"&"+urllib.parse.urlencode(nxt)
    time.sleep(0.1)
print('DONE pages',page,'total txs',len(items))
json.dump(items, open('analysis/gov_txs_all.json','w'))
