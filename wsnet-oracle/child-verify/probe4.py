import json
from probe import rpc, dec, slot8, stub_return, ORACLE, PAIR, PAIRORACLE, TREASURY, SNET, R0, R1, TS
bn = rpc("eth_blockNumber",[])
blk = hex(int(bn,16))
print("pinned block", bn, int(bn,16))
def call(ov):
    return rpc("eth_call",[{"to":ORACLE,"data":"0xa035b1fe"}, blk, ov])
floor = dec(rpc("eth_call",[{"to":TREASURY,"data":"0x1521843e"},blk]))
index = dec(rpc("eth_call",[{"to":SNET,"data":"0x2986c0e5"},blk]))
print("floor@blk",floor,"index@blk",index)
base=call({}); b=dec(base)
print("baseline price", b, "implied credited", b*10**9//(index*10**6))
# max via real pairoracle? no: stub twap huge, real treasury/sNet
T=10**30
ov={PAIRORACLE:{"code":stub_return(T)},
    PAIR:{"stateDiff":{"0x0000000000000000000000000000000000000000000000000000000000000008":slot8(T*R1//10**21,R1,TS)}}}
mx=call(ov); m=dec(mx)
print("max price", m, "implied credited", m*10**9//(index*10**6), "5*floor",5*floor)
print("ratio max/base", m/b)
