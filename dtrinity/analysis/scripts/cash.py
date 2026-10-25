import json,sys,urllib.request,time
def rpc(url,method,params):
    for a in range(5):
        try:
            req=urllib.request.Request(url,data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
            return json.load(urllib.request.urlopen(req,timeout=30))["result"]
        except Exception: time.sleep(1.2*(a+1))
    raise RuntimeError("fail")
SEL_BAL="0x70a08231"  # balanceOf(address)
url=sys.argv[1]
for line in sys.stdin:
    line=line.strip()
    if not line.startswith('{'): continue
    try: o=json.loads(line)
    except: continue
    at=o['aToken']; 
    if at=="0x"+"0"*40: continue
    try:
        cash=int(rpc(url,"eth_call",[{"to":o['asset'],"data":SEL_BAL+at[2:].rjust(64,'0')},"latest"]),16)
    except Exception: cash=-1
    dec=o.get('decimals',18)
    human = cash/10**dec if (dec and dec>0 and cash>=0) else cash
    print(f"{o['symbol']:24} cash={cash:>24} ({human:.6f}) aTok={o['aTokenSupply']:>22} varDebt={o['varDebtSupply']:>20}")
