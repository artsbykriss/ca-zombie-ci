#!/usr/bin/env python3
"""Investigate the dijkbk oracle program: ELF strings, programdata, recent updates of 7yecFG22."""
import base64, json, os, re, struct, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc

OUT = os.path.dirname(os.path.abspath(__file__))
ALPHA='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
def b58d(s):
    n=0
    for c in s: n=n*58+ALPHA.index(c)
    return n.to_bytes((n.bit_length()+7)//8,'big') if n else b''
def b58e(b):
    n=int.from_bytes(b,'big'); out=''
    while n: n,r2=divmod(n,58); out=ALPHA[r2]+out
    for c in b:
        if c==0: out='1'+out
        else: break
    return out

PROG="dijkbkCAKfFTCxQg3u1pg82gVU1jJGHBBRcteD11mBu"
ORACLE_ACCT="7yecFG22heommABQ5svcbQLK1Ua4ZrJsHPiktZ17jfm3"

r=rpc("getAccountInfo",[PROG,{"encoding":"base64","commitment":"confirmed"}])
v=(r.get("result") or {}).get("value")
raw=base64.b64decode(v["data"][0])
pd=b58e(raw[4:36])
print("oracle programdata:", pd)
r2=rpc("getAccountInfo",[pd,{"encoding":"base64","commitment":"confirmed"}])
v2=(r2.get("result") or {}).get("value")
raw2=base64.b64decode(v2["data"][0])
print("pdata len", len(raw2), "lastDeploy", struct.unpack_from("<Q",raw2,4)[0], "auth", b58e(raw2[13:45]))
elf=raw2[45:]
open(os.path.join(OUT,"oracle-program.elf"),"wb").write(elf)
strings=[s.decode() for s in re.findall(rb"[\x20-\x7e]{5,}", elf)]
open(os.path.join(OUT,"oracle-strings.txt"),"w").write("\n".join(strings))
print("strings:", len(strings))
for s in strings[:80]: print("  |",s[:140])

# recent updates of the oracle account
r3=rpc("getSignaturesForAddress",[ORACLE_ACCT,{"limit":10,"commitment":"confirmed"}])
print("\nrecent oracle account txs:")
for s in (r3.get("result") or []):
    print("  ", s["slot"], s["signature"][:24], "err", s["err"])
