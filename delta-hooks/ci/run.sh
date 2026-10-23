#!/usr/bin/env bash
# delta-hooks heavy job: re-read live state of the 3 hooks (keyless public RPCs only).
# Writes ci-out/live-state-ci.json. The workflow separately runs `forge test -vvv` in poc/.
set -uo pipefail
mkdir -p ci-out
python3 - <<'PY'
import json, urllib.request
def rpc(url, method, params):
    req = urllib.request.Request(url, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
                                 headers={"content-type":"application/json","user-agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=45))
def call(url, to, data):
    try:
        r = rpc(url, "eth_call", [{"to":to,"data":data}, "latest"])
        return r.get("result")
    except Exception as e:
        return "ERR:"+str(e)[:60]
ETH="https://ethereum-rpc.publicnode.com"; BASE="https://base-rpc.publicnode.com"
hooks=[("ETH_fAaad5B7",ETH,"0xfAaad5B731F52cDc9746F2414c823eca9B06E844"),
       ("ETH_d33398d4",ETH,"0xd33398d46cB5749c7319AE1FABC498CdeB0F0FC0"),
       ("BASE_C90eddF5",BASE,"0xC90eddF51569270E06270eA98F7EfFF828dDe0CC")]
out={"block":{}, "hooks":{}}
for name,url,addr in hooks:
    b = rpc(url,"eth_blockNumber",[]).get("result")
    out["block"][name]=int(b,16) if isinstance(b,str) else b
    code = rpc(url,"eth_getCode",[addr,"latest"]).get("result","0x")
    bal  = rpc(url,"eth_getBalance",[addr,"latest"]).get("result","0x0")
    perms= call(url, addr, "0xc4e833ce")
    out["hooks"][name]={"address":addr,"codesize":(len(code)-2)//2,"native":bal,
                        "addr_flags":hex(int(addr,16)&0x3fff),"getHookPermissions":perms}
json.dump(out, open("ci-out/live-state-ci.json","w"), indent=2)
print(json.dumps(out, indent=2))
PY
