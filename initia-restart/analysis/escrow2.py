import hashlib, json, urllib.request
exec(open('escrow.py').read().split('chans=')[0])
def get(url):
    req=urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0 research'})
    with urllib.request.urlopen(req,timeout=25) as r: return json.load(r)
chans={"echelon-1":35,"yominet-1":25,"civitia-1":27,"cabal-1":97,"inertia-2":69,"strat-1":99,"rave-1":38,"embrmainnet-1":62,"moo-1":29,"intergaze-1":66,"noble-1":3,"osmosis-1":71,"neutron-1":37}
for name,ch in chans.items():
    a=escrow(ch); out=[]
    try:
        d=get(f"https://rest.initia.xyz/cosmos/bank/v1beta1/balances/{a}?pagination.limit=200")
        for b in d.get("balances",[]):
            den=b['denom']; amt=int(b['amount'])
            if den.startswith('ibc/'):
                try:
                    t=get(f"https://rest.initia.xyz/ibc/apps/transfer/v1/denom_traces/{den[4:]}")
                    path=t['denom_trace']['path']; base=t['denom_trace']['base_denom']
                    out.append(f"{amt} {base} [{path}]")
                except Exception:
                    out.append(f"{amt} {den[:18]}?")
            else:
                out.append(f"{amt} {den[:40]}")
    except Exception as e: out=[f"ERR {e}"]
    print(f"== {name} ch-{ch} {a}")
    for x in out: print("   ",x)
