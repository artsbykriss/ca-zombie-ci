import json,sys,os,urllib.request,re
key=os.environ['ETHERSCANV2_API_KEY']
def get(chain,addr):
    u=f"https://api.etherscan.io/v2/api?chainid={chain}&module=contract&action=getsourcecode&address={addr}&apikey={key}"
    return json.load(urllib.request.urlopen(u))['result'][0]
def dump(chain,addr,label):
    d=get(chain,addr)
    name=d['ContractName']; src=d['SourceCode']
    out=f"src_{label}_{name}"
    os.makedirs(out,exist_ok=True)
    try:
        j=json.loads(src[1:] if src.startswith('{{') else src)
        for p,c in j['sources'].items():
            fp=os.path.join(out,p.replace('..','__'))
            os.makedirs(os.path.dirname(fp),exist_ok=True)
            open(fp,'w').write(c['content'])
        meta={'name':name,'addr':addr,'chain':chain,'verified':True,'proxy':d['Proxy'],'impl':d['Implementation'],'compiler':d['CompilerVersion'],'settings':d.get('EVMVersion')}
    except Exception as e:
        open(os.path.join(out,'RAW.sol'),'w').write(src)
        meta={'name':name,'addr':addr,'chain':chain,'raw':True,'err':str(e),'proxy':d['Proxy'],'impl':d['Implementation'],'compiler':d['CompilerVersion']}
    json.dump(meta,open(os.path.join(out,'meta.json'),'w'),indent=1)
    print(out, name, len(src), meta.get('proxy'), meta.get('impl'))
if __name__=='__main__':
    dump(sys.argv[1],sys.argv[2],sys.argv[3])
