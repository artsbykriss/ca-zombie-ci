import json
from probe import rpc, dec, slot8, stub_return, ORACLE, PAIR, PAIRORACLE, TREASURY, SNET, R1, TS
bn=rpc("eth_blockNumber",[]); b=int(bn,16); blk=hex(b)
blkobj=rpc("eth_getBlockByNumber",[blk,False]); now=int(blkobj["timestamp"],16)
slot10=dec(rpc("eth_getStorageAt",[PAIR,hex(10),blk]))
print("block",b,"now",now,"pair.price1CumulativeLast",slot10)
F=10**20; I=10**9
def ov(pumped_r0, ts_last, obs=None):
    o={TREASURY:{"code":stub_return(F)}, SNET:{"code":stub_return(I)},
       PAIR:{"stateDiff":{"0x0000000000000000000000000000000000000000000000000000000000000008":slot8(pumped_r0,R1,ts_last)}}}
    if obs is not None:
        idx,ts,cum=obs
        o[PAIRORACLE]={"stateDiff":{"0x"+format(2*idx,"064x"):"0x"+format(ts,"064x"), "0x"+format(2*idx+1,"064x"):"0x"+format(cum%(2**256),"064x")}}
    return o
def price(o): 
    r=rpc("eth_call",[{"to":ORACLE,"data":"0xa035b1fe"},blk,o]); return r if isinstance(r,dict) else dec(r)
R0=167547905113
print("== same-block (tsLast=now, delta=0) ==")
p_norm=price(ov(R0, now))
p_up  =price(ov(R0*50, now))
print("normal",p_norm,"up50x",p_up,"ratio", (p_up/p_norm if isinstance(p_up,int) and isinstance(p_norm,int) else None))
print("== held 1800s: obs ts=now-1800, cum=C-Puq*1800 ==")
# pumped price target = 6*F  (WAD). Puq = (r0<<112)/r1 ; choose r0 so spot=6*F
P=6*F
r0=P*R1//10**21
Puq=(r0<<112)//R1
cum=slot10 - Puq*1800
# find ring slot for ts=now-1800
ts=now-1800
idx=(ts//1800)%16
p_held=price(ov(r0, now, (idx,ts,cum)))
print("idx",idx,"ts",ts,"price_held",p_held, "cap_5F*I*1e6/1e9",5*F*I*10**6//10**9)
print("ratio held/normal", (p_held/p_norm if isinstance(p_held,int) and isinstance(p_norm,int) else None))
