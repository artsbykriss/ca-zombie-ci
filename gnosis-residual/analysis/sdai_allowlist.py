#!/usr/bin/env python3
"""Enumerate ALLOWLIST role holders for pools 8/67 on the 1Hive RegistryCommunity via RoleGranted/RoleRevoked logs."""
import json, urllib.request, time

RPC = "https://rpc.gnosischain.com"
RC  = "0xE2396fe2169ca026962971d3B2E373Ba925B6257"
TOPIC_GRANTED = "0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d"
TOPIC_REVOKED = "0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b"
ROLE8  = "0x1e7e708759cd587d69adab3835168eb789586b24a36a778167d4461dadd00250"
ROLE67 = "0xb607c8c0ce5262160e662a9746016cc82f962c77947c16644f2364fbaeb65c19"

def rpc(method,params):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req=urllib.request.Request(RPC,data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    for a in range(5):
        try:
            with urllib.request.urlopen(req,timeout=90) as r: d=json.load(r)
            if "error" in d: raise RuntimeError(d["error"])
            return d["result"]
        except Exception as e:
            err=e; time.sleep(1.5*(a+1))
    raise RuntimeError(err)

latest=int(rpc("eth_blockNumber",[]),16)
out={}
for name,role in [("pool8",ROLE8),("pool67",ROLE67)]:
    grants=[]; revokes=[]
    for topic_ev,label,arr in [(TOPIC_GRANTED,"grant",grants),(TOPIC_REVOKED,"revoke",revokes)]:
        # full range; if fails, chunk in 5M windows
        try:
            logs=rpc("eth_getLogs",[{"address":RC,"fromBlock":"0x0","toBlock":hex(latest),"topics":[topic_ev,role]}])
        except Exception as e:
            logs=[]
            for start in range(0,latest+1,5_000_000):
                end=min(start+4_999_999,latest)
                try:
                    logs+=rpc("eth_getLogs",[{"address":RC,"fromBlock":hex(start),"toBlock":hex(end),"topics":[topic_ev,role]}])
                except Exception as e2:
                    print("chunk fail",start,e2)
                time.sleep(0.2)
        for l in logs:
            # RoleGranted(bytes32 role, address account, address sender)
            account="0x"+l["topics"][2][-40:]
            sender ="0x"+l["topics"][3][-40:] if len(l["topics"])>3 else None
            arr.append({"block":int(l["blockNumber"],16),"tx":l["transactionHash"],"account":account,"sender":sender})
    out[name]={"role":role,"grants":sorted(grants,key=lambda x:x["block"]),"revokes":sorted(revokes,key=lambda x:x["block"])}
    print(f"=== {name} {role}")
    for g in sorted(grants,key=lambda x:x["block"]):
        print(f"  GRANT blk {g['block']} account {g['account']} by {g['sender']} tx {g['tx'][:20]}")
    for r_ in sorted(revokes,key=lambda x:x["block"]):
        print(f"  REVOKE blk {r_['block']} account {r_['account']} by {r_['sender']} tx {r_['tx'][:20]}")

json.dump({"block":latest,"roles":out}, open("/home/heisenberg/CA/gnosis-residual/analysis/gardens-sdai-allowlist.json","w"), indent=1)
print("saved.")
