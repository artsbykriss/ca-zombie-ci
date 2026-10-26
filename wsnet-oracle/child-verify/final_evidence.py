import json
from probe import rpc, dec
M="0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010"
ID="0xaa586d26a6fe62d9c0f0948fede6e2130500ac7a655587447e2d4a37e6330589"
O="0xCDE9599059f8Ae6D6B9F33A0aF7877827ec75F16"
PAIR="0x59F95461E68e0c77605299791E1449f175165B54"
T="0x04822Ea321A0DEE6F40656172F29312104855d66"
S="0xb773ec2C326B7f98a5a83fc098825492F020a4c7"
PO="0x929631b33F4070D6f54477fba3FD27566567dAca"
bn=rpc("eth_blockNumber",[]); b=int(bn,16); blk=hex(b)
blkobj=rpc("eth_getBlockByNumber",[blk,False]); ts=int(blkobj["timestamp"],16)
mkt=rpc("eth_call",[{"to":M,"data":"0x5c60e39a"+ID[2:]},blk])
words=[mkt[2:][i*64:(i+1)*64] for i in range(6)]
mvals=[int(w,16) for w in words]
price=dec(rpc("eth_call",[{"to":O,"data":"0xa035b1fe"},blk]))
floor=dec(rpc("eth_call",[{"to":T,"data":"0x1521843e"},blk]))
index=dec(rpc("eth_call",[{"to":S,"data":"0x2986c0e5"},blk]))
twap=dec(rpc("eth_call",[{"to":PO,"data":"0x10aa790e"},blk]))
res=rpc("eth_call",[{"to":PAIR,"data":"0x0902f1ac"},blk]); r0=int(res[2:66],16); r1=int(res[66:130],16); tsl=int(res[130:],16)
spot=r0*10**21//r1
supply,sshares,borrow,bshares,lastup,fee=mvals
out={
 "block":b,"timestamp":ts,
 "chainId":4663,
 "market_id":ID,"singleton":M,
 "market_state":{"totalSupplyAssets":supply,"totalSupplyShares":sshares,
   "totalBorrowAssets":borrow,"totalBorrowShares":bshares,"lastUpdate":lastup,"fee":fee,
   "free_liquidity_assets":supply-borrow,"free_liquidity_usd":(supply-borrow)/1e6},
 "oracle":{"address":O,"price_1e36_effective":price,
   "treasury_floor_backingPerToken_wad":floor,
   "sNET_index":index,
   "theoretical_cap_price_5x_floor":price*5 if False else None,
   "note":"price=clamp(twap*0.9,floor,5*floor)*index/1e9*1e6"},
 "pair":{"address":PAIR,"reserve0_usdg":r0,"reserve1_net":r1,"blockTimestampLast":tsl,
   "spot_usdg_per_net_wad":spot,"pairoracle_twap_wad":twap},
}
out["oracle"]["cap_price_5x_floor_estimate"]= floor*5*index*10**6//10**9
json.dump(out, open("market_evidence.json","w"), indent=2)
print(json.dumps(out,indent=2))
