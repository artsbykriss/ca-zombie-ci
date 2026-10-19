#!/usr/bin/env python3
"""Read-only AlpsCon state snapshot. No secrets. Usage: RPC=... python3 collect_state.py"""
import json, os, subprocess, datetime
RPC = os.environ.get("RPC", "https://bsc-rpc.publicnode.com")
BLOCK = int(os.environ.get("BLOCK", "128633400"))
USDC = "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d"
F = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
SWAP = "0x7227d229be754fa49f416d48e8eaa121184b1721"
V = {
 "V4":"0xeecfcf2ff8200f642ed7bb7fe259e258869572b7",
 "V5":"0x466762aae51a862c05dfa937e3da295627b09161",
 "V6":"0x74f091a719fdd47a95f378c7fb5c3d18a4582405",
 "V7":"0x047284b1e752e39ae7a721d361ec0b0a554ef014",
 "V8":"0xa58fbe390210460b7b07e52a29d4eb84308472e1",
 "V9":"0x9b210da482217afc24074e57f6f8337fe07f0124",
 "Vault":"0x7e84f721d8082639d8dba7ed357b34523ffffa0b",
 "Swap":"0x7227d229be754fa49f416d48e8eaa121184b1721",
 "FundEOA":"0x3E3899adB50acd77BB010262803bB240dcC51223",
 "FundV2":"0x442c5d0e6b5399e1e8a3f160b1840ef41e1d4a81",
 "NewV6":"0x275B8E042abC1D1AC79b61a8938eF7324aF95c9e",
 "NewSwap":"0x29307e91dbc5ed7a8843eebd48ff9eddd206852b",
 "OldSwap":"0x5e4ff9fadf96dd6e8a32a7b66d99faf0060d4c10",
 "TRAI":"0x7379793595df041488f9bf917d1fab6c692b580c",
}
def call(to, sig, *args, block=BLOCK):
    cmd=["cast","call",to,sig,*args,"--block",str(block),"--rpc-url",RPC,"--json"]
    out=subprocess.run(cmd,capture_output=True,text=True)
    if out.returncode: raise RuntimeError(out.stderr.strip()[:300])
    return json.loads(out.stdout)
S10="getStats(address)(uint256,uint256,uint256,uint256,uint256,uint256,uint256,int256,uint256,uint8)"
S11=S10[:-1]+",bool)"
state={"block":BLOCK,"timestamp":int(subprocess.check_output(["cast","block",str(BLOCK),"--rpc-url",RPC,"--field","timestamp"]).decode().strip()),
       "gate":{},
       "balances_usdc":{},
       "stats_f39f":{},
       "v6_slot3":None,
       "old_swap":{},
       "trai_pairs":{}}
for a in [F,"0x3E3899adB50acd77BB010262803bB240dcC51223","0xa2f5b45e614a99fe6e653012275e8c3df472ccf7","0x0000000000000000000000000000000000000000"]:
    state["gate"][a]=call(SWAP,"isInWhiteList(address)(bool)",a)[0]
for k,a in V.items():
    state["balances_usdc"][k]=int(call(USDC,"balanceOf(address)(uint256)",a)[0])/1e18
for k in ["V6","V7","V8"]:
    o=call(V[k],S10,F)
    state["stats_f39f"][k]={"locked":int(o[4])/1e18,"pending":int(o[5])/1e18,"paid":int(o[6])/1e18,"earnings":int(o[7])/1e18}
o=call(V["V9"],S11,F)
state["stats_f39f"]["V9"]={"locked":int(o[4])/1e18,"pending":int(o[5])/1e18,"paid":int(o[6])/1e18,"earnings":int(o[7])/1e18}
state["v6_slot3"]=subprocess.check_output(["cast","storage",V["V6"],"3","--rpc-url",RPC]).decode().strip()
state["old_swap"]["gate_f39f"]=call(V["OldSwap"],"isInWhiteList(address)(bool)",F)[0]
state["old_swap"]["usdc"]=int(call(USDC,"balanceOf(address)(uint256)",V["OldSwap"])[0])/1e18
state["old_swap"]["trai"]=int(call(V["TRAI"],"balanceOf(address)(uint256)",V["OldSwap"])[0])/1e18
state["old_swap"]["fund_allowance_usdc"]=int(call(USDC,"allowance(address,address)(uint256)",V["FundEOA"],V["OldSwap"])[0])/1e18
state["old_swap"]["fund_allowance_trai"]=int(call(V["TRAI"],"allowance(address,address)(uint256)",V["FundEOA"],V["OldSwap"])[0])/1e18
state["v9_owner"]=call(V["V9"],"getConfig()(address,address,address,uint256,uint256,uint256,uint256)")[0]
import os
out=os.path.join(os.path.dirname(os.path.abspath(__file__)),"state-%d.json"%BLOCK)
json.dump(state,open(out,"w"),indent=1)
print(json.dumps(state,indent=1))
