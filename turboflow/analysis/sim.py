import json,base64,struct
from rpc import call
from b58 import b58dec,b58enc

def cu(n):
    # compact-u16
    out=bytearray()
    while True:
        b=n&0x7f; n>>=7
        if n: out.append(b|0x80)
        else: out.append(b); break
    return bytes(out)

def build_legacy(payer, signers, writable, readonly, blockhash, instructions, extra_signer_keys=()):
    # instructions: list of (program_id, [account_pubkeys], data_bytes)
    # account key order: payer(signers) first, then writable unsigned, then readonly unsigned
    # required signers: signers (list of pubkeys, includes payer)
    keys=list(signers)+list(writable)+list(readonly)
    idx={k:i for i,k in enumerate(keys)}
    nreq=len(signers); nro_signed=0
    nro_unsigned=len(readonly)
    msg=bytearray()
    msg+=bytes([nreq,nro_signed,nro_unsigned])
    msg+=cu(len(keys))
    for k in keys: msg+=b58dec(k)
    msg+=b58dec(blockhash)
    msg+=cu(len(instructions))
    for pid,accts,data in instructions:
        msg+=bytes([idx[pid]])
        msg+=cu(len(accts))
        for a in accts: msg+=bytes([idx[a]])
        msg+=cu(len(data))
        msg+=data
    # signature slots (zeroed; sigVerify false)
    sigs=b''.join(b'\x00'*64 for _ in signers)
    return base64.b64encode(cu(len(signers))+sigs+bytes(msg)).decode()

def simulate(tx_b64, cfg_extra=None):
    cfg={"encoding":"base64","sigVerify":False,"replaceRecentBlockhash":True,"commitment":"processed"}
    if cfg_extra: cfg.update(cfg_extra)
    return call("simulateTransaction",[tx_b64,cfg])
