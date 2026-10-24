#!/usr/bin/env bash
# Custom heavy-ish job for the lvin finding: re-read live BSC state and re-derive
# the recycle reachability / burn bound. Read-only. No secrets are written out.
# Results land in ./ci-out/ (uploaded as artifacts by the workflow).
set -uo pipefail
mkdir -p ci-out

RPC="${BSC_RPC_URL:-https://bsc-rpc.publicnode.com}"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36"
export RPC UA

python3 - <<'PY' > ci-out/live-state.json 2>ci-out/live-state.err || echo '{}' > ci-out/live-state.json
import json,os,urllib.request,time
RPC=os.environ["RPC"]; UA=os.environ["UA"]
TOKEN="0x33bC8653EcA8469108f65FE87B18c87C136545a8"
PAIR="0x43365C7B7b039bc06dC201Ddf38117cf1C69dc8b"
STAKE="0xe120bBf90eb051A43A3BDc0408b194b6F99b488E"
USDT="0x55d398326f99059fF775485246999027B3197955"
def rpc(method,params,tries=5):
    last=None
    for t in range(tries):
        try:
            req=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
                headers={"Content-Type":"application/json","User-Agent":UA})
            return json.load(urllib.request.urlopen(req,timeout=40))
        except Exception as e:
            last=e; time.sleep(1.5*(t+1))
    raise last
def call(to,data):
    r=rpc("eth_call",[{"to":to,"data":data},"latest"]); return r.get("result")
def pad(a): return "0"*24+a[2:].lower()
def bal(t,w):
    r=call(t,"0x70a08231"+pad(w)); return int(r,16)/1e18 if r else None
blk=int(rpc("eth_blockNumber",[])["result"],16)
res=call(PAIR,"0x0902f1ac"); r0=int(res[2:66],16)/1e18; r1=int(res[66:130],16)/1e18
own=call(TOKEN,"0x8da5cb5b")
stake_own=call(STAKE,"0x8da5cb5b")
slot13=rpc("eth_getStorageAt",[TOKEN,hex(13),"latest"])["result"]
# recycle gate probes
def probe(frm,to,data):
    r=rpc("eth_call",[{"from":frm,"to":to,"data":data},"latest"])
    return {"result":r.get("result"),"error":(r.get("error") or {}).get("message")}
g1=probe("0x000000000000000000000000000000000000beef",TOKEN,"0xdd1c35bc"+"%064x"%1)
g2=probe(STAKE,TOKEN,"0xdd1c35bc"+"%064x"%1)
print(json.dumps({
 "block":blk,
 "pair":{"reserve0_LVIN":r0,"reserve1_USDT":r1,"balanceOf_LVIN":bal(TOKEN,PAIR),"balanceOf_USDT":bal(USDT,PAIR)},
 "stake":{"LVIN":bal(TOKEN,STAKE),"USDT":bal(USDT,STAKE)},
 "token":{"owner":own,"stake_slot13":slot13},
 "stake_owner":stake_own,
 "recycle_from_random":g1,
 "recycle_from_stake":g2,
 "usd_liquidity":r1
},indent=1))
PY

# summary of the top staker reward bound (if the RPC allows the calls)
echo "=== ci-out ==="; ls -la ci-out; head -c 1200 ci-out/live-state.json; echo
exit 0
