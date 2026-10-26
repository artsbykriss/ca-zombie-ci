import json
from probe import rpc, dec, slot8, stub_return, PAIR, TREASURY, SNET, R1, TS, R0
def bpt(ov,block="latest"):
    return rpc("eth_call",[{"to":TREASURY,"data":"0x1521843e"},block,ov])
bn=rpc("eth_blockNumber",[]); blk=hex(int(bn,16))
print("bpt plain", dec(bpt({})))
for T in [10**20,10**21,10**30]:
    ov={PAIR:{"stateDiff":{"0x0000000000000000000000000000000000000000000000000000000000000008":slot8(T*R1//10**21,R1,TS)}}}
    print("bpt with pair r0~",T*R1//10**21, "->", dec(bpt(ov)))
# also index with pair override
def idx(ov): return rpc("eth_call",[{"to":SNET,"data":"0x2986c0e5"},"latest",ov])
print("index plain", dec(idx({})))
print("index with pair override", dec(idx({PAIR:{"stateDiff":{"0x0000000000000000000000000000000000000000000000000000000000000008":slot8(10**30*R1//10**21,R1,TS)}}})))
