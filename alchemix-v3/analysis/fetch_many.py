import json,os,urllib.request,sys
key=os.environ['ETHERSCANV2_API_KEY']
def get(chain,addr):
    u=f"https://api.etherscan.io/v2/api?chainid={chain}&module=contract&action=getsourcecode&address={addr}&apikey={key}"
    return json.load(urllib.request.urlopen(u))['result'][0]
def dump(chain,addr,label):
    d=get(chain,addr); name=d['ContractName']; src=d['SourceCode']
    out=f"src_{label}_{name}"; os.makedirs(out,exist_ok=True)
    s=src[1:] if src.startswith('{{') else src
    j=json.JSONDecoder().raw_decode(s)[0]
    for p,c in j['sources'].items():
        fp=os.path.join(out,p); os.makedirs(os.path.dirname(fp),exist_ok=True)
        open(fp,'w').write(c['content'])
    json.dump({'name':name,'addr':addr,'chain':chain,'compiler':d['CompilerVersion']},open(os.path.join(out,'meta.json'),'w'),indent=1)
    print(out,len(j['sources']))
if __name__=='__main__':
    dump(sys.argv[1],sys.argv[2],sys.argv[3])
