import cbor2, hashlib, json

def head(major, n):
    if n<24: return bytes([(major<<5)|n])
    if n<256: return bytes([(major<<5)|24, n])
    if n<65536: return bytes([(major<<5)|25])+n.to_bytes(2,'big')
    if n<2**32: return bytes([(major<<5)|26])+n.to_bytes(4,'big')
    return bytes([(major<<5)|27])+n.to_bytes(8,'big')

def enc_int(i):
    if i>=0:
        if i < 2**64: return head(0,i)
        b=i.to_bytes((i.bit_length()+7)//8,'big'); return head(6,2)+head(2,len(b))+b
    else:
        i=-1-i
        if i < 2**64: return head(1,i)
        b=i.to_bytes((i.bit_length()+7)//8,'big'); return head(6,3)+head(2,len(b))+b

def enc(x):
    k=x[0]
    if k=='constr':
        tag=x[1]; fields=x[2]
        if 0<=tag<=6: h=bytes([0xd8,121+tag])
        elif 7<=tag<=127: h=bytes([0xd9])+(1280+tag-7).to_bytes(2,'big')
        else: h=bytes([0xda])+(102+tag).to_bytes(4,'big')
        return h+head(4,len(fields))+b''.join(enc(f) for f in fields)
    if k=='int': return enc_int(x[1])
    if k=='bytes': return head(2,len(x[1]))+x[1]
    if k=='list': return head(4,len(x[1]))+b''.join(enc(f) for f in x[1])
    if k=='map': return head(5,len(x[1]))+b''.join(enc(a)+enc(b) for a,b in x[1])
    raise TypeError(k)

def conv(v):
    if 'constructor' in v: return ('constr',v['constructor'],[conv(f) for f in v['fields']])
    if 'int' in v: return ('int',v['int'])
    if 'bytes' in v: return ('bytes',bytes.fromhex(v['bytes']))
    if 'list' in v: return ('list',[conv(f) for f in v['list']])
    if 'map' in v: return ('map',[(conv(a),conv(b)) for a,b in [(p['k'],p['v']) for p in v['map']]])
    raise TypeError(v)
