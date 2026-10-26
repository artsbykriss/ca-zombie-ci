import json
import rpc_scan as R
chain='base'; url=R.RPC[chain]; fac=R.FACTORY[chain]
d=json.load(open('/home/heisenberg/CA/dexfi-vault-v2/ci-out/base_phaseA.json'))
pub=[r['vault'] for r in d['records'] if r.get('published')]
print("published",len(pub))
out=R.scan_vaults(chain,url,fac,pub,'pub')
json.dump({'chain':chain,'records':out},open('/home/heisenberg/CA/dexfi-vault-v2/ci-out/scan_base_published.json','w'),indent=1)
print("done",len(out))
