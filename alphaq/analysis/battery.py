import json
from b58 import b58dec
from sim import build_legacy,simulate
PID="ALPHAQmeA7bjrVuccPsYPiCvsi428SNwte66Srvs4pHA"
BH="11111111111111111111111111111111"
USER="ARu4n5mFdZogZAravu7CcizaojWnS6oqka37gdLT5SZn"
MARKET="9xPhpwq6GLUkrDBNfXCbnSP9ARAMMyUQqgkrqaDW6NLV"
STATS="H18xqLYd5uEenmiFKoXkgrTvyhnLgJMPT8sSvdZPpi3p"
UA="C1qMskwQhQ4cn1M6RG8uWfUuMrq6ysRPEHccGxk4tjw8"
UB="8XrtGP8RG33AnrN2yJ6H3gnXPNQ3dYXKqM72bpzhcsd6"
VA="CQUfYBxF2KFVjYyCPyGa7JCFX9zw2PwmNnECzY3merGA"
VB="F2KCaXcp7AoQtxTDvNEDCyMyWjSCAMWNzcyN9dsPfPs5"
TK="TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
SI="Sysvar1nstructions1111111111111111111111111"
USD1="USD1ttGY1N17NEEHLmELoaybftRBUSErhqYiQzvEmuB"
USDC="EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
def base():
    return [USER,MARKET,STATS,UA,UB,VA,VB,VA,VB,VB,TK,SI]
def run(label,accts,data,signer=None):
    signer=signer or USER
    allk=[signer]+accts
    writable=[]
    readonly=[]
    for a in accts:
        (writable if a not in readonly else readonly).append(a)
    # simple: mark everything unsigned writable except program/token/sysvar
    writable=[]; readonly=[]
    for a in accts:
        if a in (TK,SI,PID,MARKET): readonly.append(a)
        else: writable.append(a)
    # dedupe preserving order
    def dd(x):
        o=[]
        for v in x:
            if v not in o: o.append(v)
        return o
    writable=dd(writable); readonly=dd([x for x in readonly if x not in writable])
    writable=[x for x in writable if x!=signer]; readonly=[x for x in readonly if x!=signer]
    if PID not in readonly: readonly.append(PID)
    tx=build_legacy(signer,[signer],writable,readonly,BH,[(PID,accts,data)])
    r=simulate(tx)
    res=r["value"]
    print(f"[{label}] err={res['err']} cu={res.get('unitsConsumed')}")
    pre={b['accountIndex']:int(b['uiTokenAmount']['amount']) for b in (res.get('preTokenBalances') or [])}
    post={b['accountIndex']:int(b['uiTokenAmount']['amount']) for b in (res.get('postTokenBalances') or [])}
    for i in sorted(set(pre)|set(post)):
        if pre.get(i)!=post.get(i):
            print(f"    idx{i} {accts[i] if i<len(accts) else '?'} {pre.get(i)}->{post.get(i)} delta {post.get(i,0)-pre.get(i,0)}")
    for l in (res.get('logs') or []):
        if 'failed' in l or 'Error' in l: print("    LOG:",l)
    return res
