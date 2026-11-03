CHARSET="qpzry9x8gf2tvdw0s3jn54khce6mua7l"
def bech32_decode(bech):
    pos=bech.rfind('1'); hrp=bech[:pos]; data=bech[pos+1:]
    vals=[CHARSET.index(c) for c in data]
    # verify checksum
    def polymod(values):
        GEN=[0x3b6a57b2,0x26508e6d,0x1ea119fa,0x3d4233dd,0x2a1462b3]
        chk=1
        for v in values:
            b=chk>>25; chk=(chk&0x1ffffff)<<5 ^ v
            for i in range(5):
                if (b>>i)&1: chk^=GEN[i]
        return chk
    exp=[ord(x)>>5 for x in hrp]+[0]+[ord(x)&31 for x in hrp]
    assert polymod(exp+vals)==1, "bad checksum"
    conv=[(x>>5) for x in range(32)]  # noop
    out=[];acc=0;bits=0
    for v in vals[:-6]:
        acc=(acc<<5)|v; bits+=5
        while bits>=8:
            bits-=8; out.append((acc>>bits)&255)
    return hrp,bytes(out)
def conv5to8(data):
    acc=0;bits=0;out=bytearray()
    for v in data:
        acc=(acc<<5)|v;bits+=5
        while bits>=8:
            bits-=8;out.append((acc>>bits)&0xff)
    return bytes(out)
def addr_decode(a):
    hrp,d=bech32_decode(a)
    h=d[0]; net=h&0x0f; typ=h>>4
    rest=d[1:]
    if typ in (0,1,2,3): pay=rest[:28]; stake=rest[28:56] if typ in (2,3) else None
    elif typ in (4,5): pay=rest[:28]; stake=None
    elif typ in (6,7): pay=rest[:28]; stake=rest[28:56]
    elif typ in (14,15): pay=rest[:28]; stake=None
    else: pay=None;stake=None
    s=''
    if pay: s+='payment=%s '%pay.hex()
    if stake: s+='stake=%s'%stake.hex()
    return f'type={typ} net={net} {s}'
if __name__=='__main__':
    import sys
    for a in sys.argv[1:]:
        print(a[:24]+'...', addr_decode(a))
