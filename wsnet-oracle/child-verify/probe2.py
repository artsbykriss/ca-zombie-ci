import json, urllib.request
from probe import rpc, call_price, ov_both, dec, PAIRORACLE, PAIR, h32, slot8, FLOOR, INDEX, R0, R1, TS
# read live values fresh
fl = rpc("eth_call",[{"to":"0x04822Ea321A0DEE6F40656172F29312104855d66","data":"0x1521843e"},"latest"])
ix = rpc("eth_call",[{"to":"0xb773ec2C326B7f98a5a83fc098825492F020a4c7","data":"0x2986c0e5"},"latest"])
floor=dec(fl); index=dec(ix)
print("floor",floor,"index",index)
r1=R1
for mult in [0.0, 5.0, 6.0, 10.0, 1000.0]:
    T=int(floor*mult) if mult>0 else 1
    r0=max(1, T*r1//10**21)
    if mult==0.0:
        # stub twap tiny, spot normal -> guard would fail; instead just use live pairoracle by not overriding
        res=call_price({})
    else:
        res=call_price(ov_both(T,r0))
    p=dec(res)
    pred=5*floor*index*10**6//10**9 if mult>0 else None
    print("mult",mult,"price",p,"implied_credited", (p*10**9//(index*10**6) if mult>0 else None), "5xfloor",5*floor)
