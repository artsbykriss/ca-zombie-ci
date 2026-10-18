import json, urllib.request, time
RPC = {
 'monad':'https://rpc.monad.xyz',
 'pharos':'https://rpc.pharos.xyz',
 'robinhood':'https://rpc.mainnet.chain.robinhood.com',
 'sophon':'https://rpc.sophon.xyz',
 'solana':'https://solana-rpc.publicnode.com',
}
def rpc(chain, method, params):
    req = urllib.request.Request(RPC[chain], data=json.dumps({'jsonrpc':'2.0','id':1,'method':method,'params':params}).encode(), headers={'content-type':'application/json','User-Agent':'Mozilla/5.0'})
    return json.load(urllib.request.urlopen(req, timeout=60))
def block(chain): return int(rpc(chain,'eth_blockNumber',[])['result'],16)
def call(chain,to,data): return rpc(chain,'eth_call',[{'to':to,'data':data},'latest'])['result']
def bal20(chain,token,who):
    return int(call(chain,token,'0x70a08231'+'0'*24+who[2:].lower()),16)
out={'generated_at':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime())}
out['blocks']={'monad':block('monad'),'robinhood':block('robinhood'),'sophon':block('sophon'),'pharos':block('pharos'),'solana':rpc('solana','getSlot',[])['result']}
AUSD='0x00000000efe302beaa2b3e6e1b18d08d69a9012a'; USDC_M='0x754704Bc059F8C67012fEd69BC8A327a5aafb603'; USDC_P='0xc879c018db60520f4355c26ed1a6d572cdac1815'
out['perpl']={'exchange':'0x34B6552d57a35a1D042CcAe1951BD1C370112a6F','ausd':bal20('monad',AUSD,'0x34B6552d57a35a1D042CcAe1951BD1C370112a6F')/1e6}
out['levr']={'depository':'0x141B1d9Ebd2E21749d6425CaeBaCc9704aAb9583','usdc':bal20('monad',USDC_M,'0x141B1d9Ebd2E21749d6425CaeBaCc9704aAb9583')/1e6}
out['statics']={'vault':'0x8AAAF9a22f439589987B8f1e69d79ca4f648C297','native_wei':int(rpc('robinhood','eth_getBalance',['0x8AAAF9a22f439589987B8f1e69d79ca4f648C297','latest'])['result'],16)}
out['mosh']={'vaults':{}}
for v in ['0x1eBE4C2A7fe5edbd12783304fe267E50cA499136','0xdE8128796B5DC27c8c87F5d79e071E2aa3C9F7f1','0xe63ff88539F790E15f99CA33450066a84307ee59']:
    out['mosh']['vaults'][v]=int(rpc('robinhood','eth_getBalance',[v,'latest'])['result'],16)
out['faro']={'quote_usdc':USDC_P,'factories':['0xB9319bCEe26F1A6AC7207A738B021cdEC771b30E','0xd0aAC3c1c64038D0cd3aa11941cb002cbd865d4E','0xD15f2D50bbf777EFD529052686d0703e498F8380','0x02d2e6292eC57E84E183909cD0F7Ca513ADdC717','0x18Fab7d7027E9FB33Fa90ca607439449209F7B09','0x2c90CcB0b989afA2433F499698451a25744A552b']}
json.dump(out,open('live-snapshot.json','w'),indent=2)
print(json.dumps(out,indent=2))
