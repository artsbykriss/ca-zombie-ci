#!/usr/bin/env python3
"""Build / decode Solana legacy transactions and simulate read-only (no send)."""
import base64, json, struct
from base58 import b58decode, b58encode
import rpc

def compact(n):
    out=b""
    while True:
        b=n & 0x7f; n >>= 7
        out += bytes([b | (0x80 if n else 0)])
        if not n: return out

def shortvec(n):
    return compact(n)

def decode_msg(raw):
    # returns dict with header, keys, instructions
    o=0
    nsig=raw[o]; o+=1
    sigs=[raw[o+i*64:o+(i+1)*64] for i in range(nsig)]; o+=nsig*64
    hdr=list(raw[o:o+3]); o+=3
    nk=raw[o]; o+=1
    keys=[]
    for _ in range(nk):
        keys.append(b58encode(raw[o:o+32]).decode()); o+=32
    ni=raw[o]; o+=1
    ixs=[]
    for _ in range(ni):
        pid=keys[raw[o]]; o+=1
        na=raw[o]; o+=1
        accts=list(raw[o:o+na]); o+=na
        dl=raw[o]; o+=1
        if dl & 0x80:
            dl = (dl & 0x7f) | (raw[o]<<7); o+=1
        data=raw[o:o+dl]; o+=dl
        ixs.append({"programId":pid,"accounts":accts,"accountKeys":[keys[a] for a in accts],"data":base64.b64encode(data).decode(),"dataHex":data.hex()})
    return {"numSignatures":nsig,"header":hdr,"keys":keys,"instructions":ixs}

def build_tx(payer, ixs, blockhash):
    """ixs: list of {programId, accounts:[{pubkey,isSigner,isWritable}], data:bytes}"""
    keys=[payer]; signer_set={payer}
    for ix in ixs:
        if ix["programId"] not in keys: keys.append(ix["programId"])
        for a in ix["accounts"]:
            if a["pubkey"] not in keys: keys.append(a["pubkey"])
            if a.get("isSigner"): signer_set.add(a["pubkey"])
    # reorder: payer first, then other signers, then writable unsigned, then readonly unsigned
    others=[k for k in keys[1:] if k in signer_set]
    rest=[k for k in keys[1:] if k not in signer_set]
    def is_writable(k):
        for ix in ixs:
            for a in ix["accounts"]:
                if a["pubkey"]==k and a.get("isWritable"): return True
        return False
    w=[k for k in rest if is_writable(k)]; ro=[k for k in rest if not is_writable(k)]
    keys=[payer]+others+w+ro
    idx={k:i for i,k in enumerate(keys)}
    nsig=1+len(others)
    header=bytes([nsig,0,len(ro)])
    msg=header+shortvec(len(keys))+b"".join(b58decode(k) for k in keys)
    msg+=shortvec(len(ixs))
    for ix in ixs:
        msg+=bytes([idx[ix["programId"]]])
        msg+=shortvec(len(ix["accounts"]))+bytes([idx[a["pubkey"]] for a in ix["accounts"]])
        msg+=shortvec(len(ix["data"]))+ix["data"]
    msg+=b58decode(blockhash)
    raw=shortvec(nsig)+b"\x00"*64*nsig+msg
    return base64.b64encode(raw).decode(), msg

if __name__=="__main__":
    import sys
    j=json.load(open(sys.argv[1]))
    print(json.dumps(decode_msg(base64.b64decode(j["transaction"][0])),indent=1))
