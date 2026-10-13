#!/usr/bin/env python3
"""Fetch Anchor IDL PDA for the 01 program; decode embedded base58 pubkeys from ELF strings."""
import json, urllib.request, time, base64, hashlib, re

RPC = "https://api.mainnet-beta.solana.com"
ALPH='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
def b58e(b):
    n=int.from_bytes(b,'big'); s=''
    while n: n,rem=divmod(n,58); s=ALPH[rem]+s
    for by in b:
        if by==0: s='1'+s
        else: break
    return s or '1'
def b58d(s):
    n=0
    for c in s: n=n*58+ALPH.index(c)
    b=n.to_bytes((n.bit_length()+7)//8,'big')
    pad=len(s)-len(s.lstrip('1'))
    return b'\x00'*pad+b

def rpc(method, params, retries=5):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for i in range(retries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req, timeout=60) as r:
                out = json.loads(r.read())
            if "error" in out: raise RuntimeError(out["error"])
            return out
        except Exception as e:
            last=e; time.sleep(1.2*(i+1))
    raise RuntimeError(str(last))

def find_pda(seeds, program_id):
    pid = b58d(program_id)
    for bump in range(255, -1, -1):
        h = hashlib.sha256(pid + b''.join(seeds) + bytes([bump]) + pid + b"ProgramDerivedAddress").digest()
        # on-curve check
        if not on_curve(h):
            return b58e(h), bump
    return None, None

def on_curve(y_bytes):
    p=0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed
    d=(p-121665)*pow(121666,p-2,p)%p
    y=int.from_bytes(y_bytes,'little') & ((1<<255)-1)
    if y>=p: return False
    y2=y*y%p
    u=(y2-1)%p; v=(d*y2+1)%p
    x2=u*pow(v,p-2,p)%p
    if x2==0: return True
    return pow(x2,(p-1)//2,p)==1

prog="Zo1ggzTUKMY5bYnDvT5mtVeZxzf2FaLTbKkmvGUhUQk"
# Anchor IDL account PDA: seeds = ["anchor:idl", program_id] under program
idl, bump = find_pda([b"anchor:idl", b58d(prog)], prog)
print("Anchor IDL PDA:", idl, "bump", bump)
r=rpc("getAccountInfo",[idl,{"encoding":"base64"}])
v=r["result"]["value"]
if v is None:
    print("IDL account does not exist")
else:
    raw=base64.b64decode(v["data"][0])
    print("IDL account exists: owner",v["owner"],"size",len(raw))
    # Anchor IDL account data: 8-byte discriminator + authority(32) + compressed idl (zlib) with 4-byte length
    print("head hex:", raw[:80].hex())
    try:
        import zlib
        comp = raw[44:]
        ln = int.from_bytes(comp[:4],"little")
        data = zlib.decompress(comp[4:4+ln])
        open("analysis/zo_idl.json","wb").write(data)
        print("IDL decompressed bytes:", len(data))
    except Exception as e:
        print("IDL decompress failed:", e)
        open("analysis/zo_idl_raw.bin","wb").write(raw)
