#!/usr/bin/env bash
# Canonical pinned live-state snapshot -> analysis/live_state.json (keyless public RPC).
set -uo pipefail
R="${RPC:-https://worldchain-mainnet.g.alchemy.com/public}"
V=0x5C6F9354b6176C14f7dF1C1e16a0DC4A0Ff9c3E1
WLD=0x2cFc85d8E48F8EAB294be644d9E25C3030863003
BLK=$(cast block-number --rpc-url "$R")
c() { cast call --rpc-url "$R" "$@" 2>/dev/null | head -1; }
OWNER=$(c "$V" 'owner()(address)')
python3 - "$V" "$WLD" "$BLK" "$OWNER" "$R" <<'PY'
import json,subprocess,sys
V,WLD,BLK,OWNER,R=sys.argv[1:6]
def call(sig,*args):
    try:
        return subprocess.check_output(["cast","call","--rpc-url",R,V,sig,*args],text=True).strip().split()[0]
    except Exception:
        return None
def callat(addr,sig,*args):
    try:
        return subprocess.check_output(["cast","call","--rpc-url",R,addr,sig,*args],text=True).strip().split()[0]
    except Exception:
        return None
sels={
 "setIsAllocator":"0xb192a84a","setReceiveSharesGate":"0x2cb19f98","setSendSharesGate":"0xc21ad028",
 "setReceiveAssetsGate":"0x04dbf0ce","setSendAssetsGate":"0x871c979c","setAdapterRegistry":"0x5b34b823",
 "addAdapter":"0x60d54d41","removeAdapter":"0x585cd34b","increaseTimelock":"0x47966291",
 "decreaseTimelock":"0x5c1a1a4f","abdicate":"0xb2e32848","setPerformanceFee":"0x70897b23",
 "setManagementFee":"0xfe56e232","setPerformanceFeeRecipient":"0x6a5f1aa2","setManagementFeeRecipient":"0x9faae464",
 "increaseAbsoluteCap":"0xf6f98fd5","increaseRelativeCap":"0x2438525b","setForceDeallocatePenalty":"0x3e9d2ac7",
}
out={
 "chain":"worldchain","chain_id":480,"block":int(BLK),
 "vault":V,"asset":WLD,"owner":OWNER,
 "name":call("name()(string)"),"symbol":call("symbol()(string)"),
 "decimals":call("decimals()(uint8)"),"virtualShares":call("virtualShares()(uint256)"),
 "totalAssets_wei":call("totalAssets()(uint256)"),"totalSupply_wei":call("totalSupply()(uint256)"),
 "stored_totalAssets_wei":call("_totalAssets()(uint128)"),
 "vault_wld_balance_wei":callat(WLD,"balanceOf(address)(uint256)",V),
 "curator":call("curator()(address)"),
 "receiveSharesGate":call("receiveSharesGate()(address)"),"sendSharesGate":call("sendSharesGate()(address)"),
 "receiveAssetsGate":call("receiveAssetsGate()(address)"),"sendAssetsGate":call("sendAssetsGate()(address)"),
 "adapterRegistry":call("adapterRegistry()(address)"),
 "liquidityAdapter":call("liquidityAdapter()(address)"),"liquidityData":call("liquidityData()(bytes)"),
 "adaptersLength":call("adaptersLength()(uint256)"),"maxRate":call("maxRate()(uint64)"),
 "performanceFee":call("performanceFee()(uint96)"),"managementFee":call("managementFee()(uint96)"),
 "performanceFeeRecipient":call("performanceFeeRecipient()(address)"),
 "managementFeeRecipient":call("managementFeeRecipient()(address)"),
 "isSentinel(owner)":call("isSentinel(address)(bool)",OWNER),
 "isAllocator(owner)":call("isAllocator(address)(bool)",OWNER),
 "timelocks":{k:{"timelock":call("timelock(bytes4)(uint256)",s),"abdicated":call("abdicated(bytes4)(bool)",s)} for k,s in sels.items()},
}
json.dump(out,open("live_state.json","w"),indent=1)
print(json.dumps(out,indent=1))
PY
