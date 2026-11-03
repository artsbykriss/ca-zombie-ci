CHARSET="qpzry9x8gf2tvdw0s3jn54khce6mua7l"
def polymod(values):
    GEN=[0x3b6a57b2,0x26508e6d,0x1ea119fa,0x3d4233dd,0x2a1462b3]
    chk=1
    for v in values:
        b=chk>>25; chk=(chk&0x1ffffff)<<5 ^ v
        for i in range(5):
            if (b>>i)&1: chk^=GEN[i]
    return chk
def hrp_expand(hrp): return [ord(x)>>5 for x in hrp]+[0]+[ord(x)&31 for x in hrp]
def create_checksum(hrp,data):
    values=hrp_expand(hrp)+data
    pm=polymod(values+[0,0,0,0,0,0])^1
    return [(pm>>5*(5-i))&31 for i in range(6)]
def convertbits(data,frombits,tobits,pad=True):
    acc=0;bits=0;ret=[];maxv=(1<<tobits)-1
    for value in data:
        acc=(acc<<frombits)|value;bits+=frombits
        while bits>=tobits:
            bits-=tobits;ret.append((acc>>bits)&maxv)
    if pad and bits: ret.append((acc<<(tobits-bits))&maxv)
    return ret
def encode(hrp,data):
    d=convertbits(data,8,5)
    return hrp+'1'+''.join(CHARSET[x] for x in d+create_checksum(hrp,d))
def addr(typ,pay,stake=None,net=1):
    b=bytes([(typ<<4)|net])+bytes.fromhex(pay)
    if stake: b+=bytes.fromhex(stake)
    return encode('addr',b)
if __name__=='__main__':
    import sys
    pay=sys.argv[1]; stake=sys.argv[2] if len(sys.argv)>2 and sys.argv[2]!='-' else None
    for t in ([7] if not stake else [3]):
        print(t, addr(t,pay,stake))
