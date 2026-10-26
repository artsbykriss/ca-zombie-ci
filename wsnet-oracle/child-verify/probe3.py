import json
from probe import rpc, dec, h32, slot8, stub_return, ORACLE, PAIR, PAIRORACLE, TREASURY, SNET, R1, TS
def call(overrides):
    return rpc("eth_call",[{"to":ORACLE,"data":"0xa035b1fe"},"latest",overrides])
F=10**20
I=10**9
T=10**30   # huge twap
r0=T*R1//10**21
for T_,label in [(10**30,"huge")]:
    ov={PAIRORACLE:{"code":stub_return(T_)},
        TREASURY:{"code":stub_return(F)},
        SNET:{"code":stub_return(I)},
        PAIR:{"stateDiff":{"0x0000000000000000000000000000000000000000000000000000000000000008":slot8(T_*R1//10**21,R1,TS)}}}
    res=call(ov)
    p=dec(res) if isinstance(res,str) else res
    exp=5*F*I*10**6//10**9
    print(label,"price",p,"expected_5xF",exp,"ratio",(p/exp if isinstance(p,int) else None))
# also test PREMIUM_CAP by scanning F with fixed T,I: price should be 5*F
for F2 in [10**19,10**20,3*10**20]:
    ov={PAIRORACLE:{"code":stub_return(10**30)},
        TREASURY:{"code":stub_return(F2)},
        SNET:{"code":stub_return(10**9)},
        PAIR:{"stateDiff":{"0x0000000000000000000000000000000000000000000000000000000000000008":slot8(10**30*R1//10**21,R1,TS)}}}
    res=call(ov); p=dec(res) if isinstance(res,str) else res
    print("F",F2,"price",p,"price/F",(p/F2 if isinstance(p,int) else None))
