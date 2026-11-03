import hashlib, json, sys
from ecdsa import VerifyingKey, SECP256k1
from ecdsa.util import sigdecode_string

def be(n):
    if n==0: return b''
    return n.to_bytes((n.bit_length()+7)//8,'big')

def be2(n):  # alternative: zero encodes as 0x00
    return n.to_bytes(max(1,(n.bit_length()+7)//8),'big')

def digest(fields, intenc=be, skip_last=True, extra=b''):
    f=fields[:13] if skip_last else fields
    parts=[]
    for i,x in enumerate(f):
        if isinstance(x,str): parts.append(bytes.fromhex(x))
        else: parts.append(intenc(x))
    return hashlib.sha3_256(b''.join(parts)+extra).digest(), b''.join(parts)

d=json.load(open('analysis/attack_tx_full.json'))
red=[c for c in d[0]['plutus_contracts'] if c['script_hash'].startswith('485a')][0]['input']['redeemer']['datum']['value']
fields=[x['bytes'] if 'bytes' in x else x['int'] for x in red['fields'][0]['fields']]
sig=bytes.fromhex(fields[13])
pub=bytes.fromhex('0335664ecb713efe92e94b30e2273fcfcb2cc3efcb2d25a734cf119f27c7ffd98a')
for name,enc in [('empty0',be),('zero0',be2)]:
    dg,pre=digest(fields,enc)
    vk=VerifyingKey.from_string(pub, curve=SECP256k1, valid_encodings=["compressed"])
    ok=vk.verify_digest(sig,dg,sigdecode=sigdecode_string)
    print(name,'preimage_len',len(pre),'digest',dg.hex()[:16],'verify',ok)
print('preimage hex', digest(fields,be)[1].hex())
