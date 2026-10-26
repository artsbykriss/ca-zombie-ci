import json
from probe import rpc, dec, slot8, stub_return, ORACLE, PAIR, PAIRORACLE, TREASURY, SNET, R1, TS
bn = rpc("eth_blockNumber",[]); blk=hex(int(bn,16))
F=10**20; I=10**9
def pairspot(T):
    return {"0x0000000000000000000000000000000000000000000000000000000000000008":slot8(T*R1//10**21,R1,TS)}
def run(block, stubT, stubS):
    ov={PAIRORACLE:{"code":stub_return(10**30)}, PAIR:{"stateDiff":pairspot(10**30)}}
    if stubT: ov[TREASURY]={"code":stub_return(F)}
    if stubS: ov[SNET]={"code":stub_return(I)}
    r=rpc("eth_call",[{"to":ORACLE,"data":"0xa035b1fe"},block,ov])
    return r
for name,blk_,st,ss in [("A latest realT/S", "latest",False,False),
                        ("B pinned stubT/S", blk,True,True),
                        ("C pinned realT/S", blk,False,False),
                        ("D latest stubT/S", "latest",True,True)]:
    r=run(blk_,st,ss)
    print(name, r if isinstance(r,dict) else dec(r))
