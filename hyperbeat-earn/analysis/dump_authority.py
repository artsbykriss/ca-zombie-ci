#!/usr/bin/env python3
"""Enumerate MultiRolesAuthority config from logs + test canCall for sensitive selectors."""
import json, urllib.request, sys, time, subprocess
RPC="https://rpc.hyperliquid.xyz/evm"; BLK=int(sys.argv[1]) if len(sys.argv)>1 else 49508160
_id=0
def rpc(m,p):
    global _id; _id+=1
    body=json.dumps({"jsonrpc":"2.0","id":_id,"method":m,"params":p}).encode()
    req=urllib.request.Request(RPC,data=body,headers={"Content-Type":"application/json","User-Agent":"r/1"})
    for a in range(4):
        try:
            with urllib.request.urlopen(req,timeout=60) as r: d=json.loads(r.read())
            return d.get("result") if "error" not in d else {"__err__":d["error"]}
        except Exception as e:
            if a==3: return {"__exc__":str(e)}
            time.sleep(1.5)
def call(to,data): return rpc("eth_call",[{"to":to,"data":data},hex(BLK)])
def s4(s): return subprocess.run(["cast","sig",s],capture_output=True,text=True).stdout.strip()

AUTHS={
 "lstHYPE":"0x82999519c6f7012037375e4930f59474cd27c4eb",
 "hbUSDT":"0x6278d7d6e57db17d002bc9b13e3284f58d05099a",
 "hbUSDC":"0x060690ec182a5a61f5cdfa0aefae058e04342312",
 "nLP":"0x1c9b0b69c932ffb2af0f27c1cdd41c10717d16b1",
 "masterUSD":"0x1fa2dcebc92b1af6030c387ab486c34549a4a971",
 "dnHYPE":"0x342fb4349586af03e390cfcb067d379a338c6fc1",
 "dnPUMP":"0x2e685e1b77ccd9bb52ccc273cf3d5819659e9e09",
 "hbXAUt":"0xa9d525380e279af6d5c9f74772bef511acba3275",
}
SENSITIVE=[
 "updateExchangeRate(uint96)","claimFees(address)","setAssetConfig(address,address)","updateDelay(uint24)",
 "updateUpper(uint16)","updateLower(uint16)","updateManagementFee(uint16)","updatePerformanceFee(uint16)",
 "updateFeeRecipient(address)","updateDepositReceiver(address)","transferOwnership(address)","setAuthority(address)",
 "processWithdrawalRequests((uint256,address,address,uint256,uint256,uint128,uint256,uint256,uint64)[])",
 "rejectWithdrawalRequest((uint256,address,address,uint256,uint256,uint128,uint256,uint256,uint64))",
 "recoverERC20(address,(uint256,address,address,uint256,uint256,uint128,uint256,uint256,uint64)[])",
 "setInstantWithdrawalFee(uint64)","setPaused(bool)","setInstantWithdrawalPaused(bool)","setPricer(address)","setMinimumDeadline(uint64)",
 "mint(address,uint256)","burn(address,uint256)","pause()","unpause()","setMetadata(bytes32,bytes)",
 "sendAssetsToDnCoreWriter(address,address,uint256)","setDnCoreWriter(address,bool)","setWithdrawalQueue(address)",
 "collectFees()","chargeManagementFee()","updateTotalAssets(uint256)","configure(uint256,uint256,uint256,uint256,uint256,uint256,address,address,address,address)",
 "processAllClaimsByDate(uint256,uint256,uint256,uint256)",
 "updateIssuanceLimits(uint256,uint256,uint256)","emergencyWithdraw(address,address)","addToBlacklist(address)","updateOperator(address)",
]
CALLER="0x0000000000000000000000000000000000001111"
out={"block":BLK,"canCall":{}}
# also test isCapabilityPublic directly (slot4) for each selector
for an,aa in AUTHS.items():
    res={}
    for s in SENSITIVE:
        r=call(aa, "0xb7009613"+CALLER[2:].rjust(64,"0")+aa[2:].rjust(64,"0")+s4(s)[2:].ljust(64,"0"))
        val = (isinstance(r,str) and r.endswith("1"))
        # isCapabilityPublic[sig]: mapping slot 4 -> keccak256(pad32(sig) . pad32(4))
        key_sig = s4(s)[2:].ljust(64,"0")
        slot = "0x"+ __import__("hashlib").sha3_256(bytes.fromhex(key_sig+"0"*63+"4")).hexdigest() if False else None
        if val: res[s]=True
    out["canCall"][an]=res
    print(an, "PUBLIC/OPEN selectors:", res if res else "none",flush=True)
json.dump(out,open("/home/heisenberg/CA/hyperbeat-earn/analysis/authority_cancall.json","w"),indent=1)
print("WROTE")
