#!/usr/bin/env python3
"""childB: negative-path simulations (eth_call as fresh attacker) + gauge/voter state + TeamSafe veNFTs."""
import json, urllib.request
RPC="https://rpc.scroll.io"
def rpcm(batch):
    req=urllib.request.Request(RPC,data=json.dumps(batch).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    o=json.load(urllib.request.urlopen(req,timeout=120)); return [o] if isinstance(o,dict) else sorted(o,key=lambda x:x["id"])
from eth_hash.auto import keccak
def sel(s): return "0x"+keccak(s.encode()).hex()[:8]
def a(x): return x.lower().replace("0x","").rjust(64,"0")
def u(x): return hex(x)[2:].rjust(64,"0")
def call(to,data,frm=None,val=None):
    o={"to":to,"data":data}
    if frm: o["from"]=frm
    if val: o["value"]=val
    return {"jsonrpc":"2.0","method":"eth_call","params":[o,"latest"]}
NFP="0xAAA78E8C4241990B4ce159E105dA08129345946A"
VE="0xAAAEa1fB9f3DE3F70E89f37B69Ab11B47eb9Ce6F"
GAUGE="0xc32dff16353bce12e0bc85963c2caf41bac5ca25"
VOTER="0xaaaf3d9cdd3602d117c67d80eec37a160c8d9869"
TOKENID=67113
ATT="0x00000000000000000000000000000000000000A1"
USDC="0x06efdbff2a14a7c8e15944d1f4a48f9f95f663a4"
batch=[];ids=[]
def add(t,item): item["id"]=len(batch); ids.append(t); batch.append(item)

# --- NFP negative tests (from attacker) ---
tid=u(TOKENID)
add(("NFP","collect_from_attacker"), call(NFP, sel("collect((uint256,address,uint128,uint128))")
    +u(TOKENID)+a(ATT)+u(2**128-1)+u(2**128-1), frm=ATT))
add(("NFP","decreaseLiquidity_from_attacker"), call(NFP, sel("decreaseLiquidity((uint256,uint128,uint256,uint256,uint256))")
    +u(TOKENID)+u(1)+u(0)+u(0)+u(2**64), frm=ATT))
add(("NFP","burn_from_attacker"), call(NFP, sel("burn(uint256)")+u(TOKENID), frm=ATT))
add(("NFP","getReward_from_attacker"), call(NFP, sel("getReward(uint256,address[])")+u(TOKENID)+u(0x40)+u(0), frm=ATT))
add(("NFP","sweepToken_real_token_min1"), call(NFP, sel("sweepToken(address,uint256,address)")+a(USDC)+u(1)+a(ATT), frm=ATT))
add(("NFP","refundETH_anyone"), call(NFP, sel("refundETH()"), frm=ATT))
add(("NFP","increaseLiquidity_burned_id1"), call(NFP, sel("increaseLiquidity((uint256,uint256,uint256,uint256,uint256,uint256))")
    +u(1)+u(1000)+u(1000)+u(0)+u(0)+u(2**64), frm=ATT))
add(("NFP","positions_of_67113"), call(NFP, sel("positions(uint256)")+u(TOKENID)))
add(("NFP","ownerOf_67113"), call(NFP, sel("ownerOf(uint256)")+u(TOKENID)))
add(("NFP","getApproved_67113"), call(NFP, sel("getApproved(uint256)")+u(TOKENID)))
# --- Gauge negative tests ---
add(("Gauge","getRewardForOwner_from_attacker"), call(GAUGE, sel("getRewardForOwner(uint256,address[])")+u(TOKENID)+u(0x40)+u(0), frm=ATT))
add(("Gauge","getReward_owner_variant_from_attacker"), call(GAUGE, sel("getReward(address,uint256,int24,int24,address[],address)")
    +a(NFP)+u(TOKENID)+u(0)+u(1)+u(0xc0)+a(ATT)+u(0), frm=ATT))
add(("Gauge","getReward_tokenId_from_attacker"), call(GAUGE, sel("getReward(uint256,address[])")+u(TOKENID)+u(0x40)+u(0), frm=ATT))
add(("Gauge","getPeriodReward_from_attacker"), call(GAUGE, sel("getPeriodReward(uint256,address[],uint256,address)")+u(0)+u(0x80)+u(TOKENID)+a(ATT)+u(0), frm=ATT))
add(("Gauge","nfpManager"), call(GAUGE, sel("nfpManager()")))
add(("Gauge","voter"), call(GAUGE, sel("voter()")))
add(("Gauge","pool"), call(GAUGE, sel("pool()")))
add(("Gauge","firstPeriod"), call(GAUGE, sel("firstPeriod()")))
add(("Gauge","nuri_balance"), call("0xaaae8378809bb8815c08d3c59eb0c7d1529ad769", sel("balanceOf(address)")+a(GAUGE)))
# --- Voter passthrough negative test: claimClGaugeRewards to gauge with victim tokenId ---
# args: address[] _gauges, address[][] _tokens, uint256[][] _nfpTokenIds  => offsets
# build manually: head: 0x60, 0xa0, 0x100; then arrays
def dyn_array_addrs(addrs):
    return u(len(addrs))+"".join(a(x) for x in addrs)
gauges=[GAUGE]; tokens=[[USDC]]; tids=[[TOKENID]]
enc = sel("claimClGaugeRewards(address[],address[][],uint256[][])")
enc += u(0x60) + u(0xa0) + u(0x100)
# gauges array at 0x60
enc += dyn_array_addrs(gauges)
# tokens array-of-arrays at 0xa0: len 1, offset 0x20, then inner array
enc += u(1)+u(0x20)+dyn_array_addrs(tokens[0])
# tids array-of-arrays
enc += u(1)+u(0x20)+u(len(tids[0]))+"".join(u(x) for x in tids[0])
add(("Voter","claimClGaugeRewards_from_attacker"), call(VOTER, enc, frm=ATT))
# --- VE negative tests ---
add(("VE","withdraw_from_attacker"), call(VE, sel("withdraw(uint256)")+u(1), frm=ATT))
add(("VE","transferFrom_from_attacker"), call(VE, sel("transferFrom(address,address,uint256)")+a("0xc9d28676b7d470210a3c490b60729660ee5a7257")+a(ATT)+u(1), frm=ATT))
add(("VE","merge_from_attacker"), call(VE, sel("merge(uint256,uint256)")+u(2)+u(1), frm=ATT))
add(("VE","locked_1"), call(VE, sel("locked(uint256)")+u(1)))
add(("VE","ownerOf_1"), call(VE, sel("ownerOf(uint256)")+u(1)))
out={};CH=8
for i in range(0,len(batch),CH):
    ch=batch[i:i+CH]
    for j,c in enumerate(ch): c["id"]=j
    rr=rpcm(ch)
    for c,r in zip(ch,rr):
        out["::".join(ids[c["id"]+i])]=r.get("result",{"error":r.get("error")})
for k,v in out.items():
    if isinstance(v,dict) and "error" in v:
        print(f"{k:50s} REVERT: {str(v['error'].get('message',''))[:80]}")
    else:
        print(f"{k:50s} OK: {str(v)[:90]}")
