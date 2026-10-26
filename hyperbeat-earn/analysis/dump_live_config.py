#!/usr/bin/env python3
import json, urllib.request, sys, time, subprocess
RPC="https://rpc.hyperliquid.xyz/evm"; BLK=int(sys.argv[1]) if len(sys.argv)>1 else 49508160
_id=0
def rpc(m,p):
    global _id; _id+=1
    body=json.dumps({"jsonrpc":"2.0","id":_id,"method":m,"params":p}).encode()
    req=urllib.request.Request(RPC,data=body,headers={"Content-Type":"application/json","User-Agent":"r/1"})
    for a in range(4):
        try:
            with urllib.request.urlopen(req,timeout=40) as r: d=json.loads(r.read())
            return d.get("result") if "error" not in d else {"__err__":d["error"]}
        except Exception as e:
            if a==3: return {"__exc__":str(e)}
            time.sleep(1.2)
def call(to,data): return rpc("eth_call",[{"to":to,"data":data},hex(BLK)])
def a(h): return "0x"+h[-40:] if isinstance(h,str) and len(h)>=42 else h
def u(h):
    try: return int(h,16)
    except: return h
def s4(s): return subprocess.run(["cast","sig",s],capture_output=True,text=True).stdout.strip()

S={k:s4(v) for k,v in {
 "owner":"owner()","depositsPaused":"depositsPaused()","withdrawalsPaused":"withdrawalsPaused()",
 "maxDepositAmount":"maxDepositAmount()","maxWithdrawalAmount":"maxWithdrawalAmount()","maxSupply":"maxSupply()",
 "externalAssets":"externalAssets()","totalAssets":"totalAssets()","totalSupply":"totalSupply()",
 "lagDuration":"lagDuration()","operator":"operator()","settlementAccount":"settlementAccount()",
 "feesCollector":"feesCollector()","withdrawalFee":"withdrawalFee()","underlyingAsset":"underlyingAsset()",
 "globalLiabilityShares":"globalLiabilityShares()","globalLiabilityAssets":"globalLiabilityAssets()",
 "totalCollectableFees":"totalCollectableFees()","asset":"asset()","skimRecipient":"skimRecipient()",
 "balanceOf":"balanceOf(address)","curator":"curator()","fee":"fee()","decimals":"decimals()",
}.items()}

ULTRA={"UltraHYPE":"0x96C6cBB6251Ee1c257b2162ca0f39AA5Fa44B1FB","UltrauBTC":"0xc061d38903b99aC12713B550C2CB44B221674F94"}
out={"block":BLK,"ultra":{},"morpho":{},"depositReceivers":{}}
for n,v in ULTRA.items():
    row={}
    for k in ["owner","depositsPaused","withdrawalsPaused","maxDepositAmount","maxWithdrawalAmount","maxSupply",
              "externalAssets","totalAssets","totalSupply","lagDuration","operator","settlementAccount","feesCollector",
              "withdrawalFee","underlyingAsset","globalLiabilityShares","globalLiabilityAssets","totalCollectableFees","decimals"]:
        r=call(v,S[k]); row[k]= a(r) if k in ("owner","operator","settlementAccount","feesCollector","underlyingAsset") else u(r)
    out["ultra"][n]=row
    print(n, json.dumps(row,default=str),flush=True)

MORPHO={"MEVHYPE":"0xd19e3d00f8547f7d108abfd4bbb015486437b487","GauntletUSDC":"0x08C00F8279dFF5B0CB5a04d349E7d79708Ceadf3",
        "MEVUSDC":"0x4851D4891321035729713D43bE1F4bb883Dffd34","GauntletUSDeCore":"0x5eEC795d919FA97688Fb9844eeB0072E6B846F9d"}
for n,v in MORPHO.items():
    row={}
    for k in ["totalAssets","totalSupply","skimRecipient","curator","fee","asset"]:
        r=call(v,S[k]); row[k]= a(r) if k in ("skimRecipient","curator","asset") else u(r)
    bal=call(row["asset"], S["balanceOf"]+v[2:].rjust(64,"0"))
    row["asset_balance_of_vault"]=u(bal)
    row["decimals"]=u(call(row["asset"],S["decimals"]))
    out["morpho"][n]=row
    print("MORPHO",n,json.dumps(row,default=str),flush=True)

# DepositReceiver base-asset balances
DRS={"lstHYPE":("0xa980d98de0fff436e1a3e7d9a06999b03c8aa59e","0x5555555555555555555555555555555555555555"),
     "hbUSDT":("0xfd1fd829e4e89cae8190596698e84754c3fec16c","0xb8ce59fc3717ada4c02eadf9682a9e934f625ebb"),
     "hbUSDC":("0x7abf6da6c2c131b58c1f4cb3947b0cfe2edc1c2a","0xb88339cb7199b77e23db6e890353e22632ba630f")}
for n,(dr,base) in DRS.items():
    bal=u(call(base,S["balanceOf"]+dr[2:].rjust(64,"0")))
    dec=u(call(base,S["decimals"]))
    out["depositReceivers"][n]={"dr":dr,"base":base,"base_balance":bal,"base_decimals":dec}
    print("DR",n,"base_balance",bal,"dec",dec)
json.dump(out,open("/home/heisenberg/CA/hyperbeat-earn/analysis/live_config.json","w"),indent=1)
print("WROTE")
