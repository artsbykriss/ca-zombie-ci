import hashlib, json, urllib.request
CHARSET="qpzry9x8gf2tvdw0s3jn54khce6mua7l"
def bech32_polymod(values):
    GEN=[0x3b6a57b2,0x26508e6d,0x1ea119fa,0x3d4233dd,0x2a1462b3]
    chk=1
    for v in values:
        b=chk>>25
        chk=(chk&0x1ffffff)<<5 ^ v
        for i in range(5):
            chk ^= GEN[i] if ((b>>i)&1) else 0
    return chk
def hrp_expand(hrp):
    return [ord(x)>>5 for x in hrp]+[0]+[ord(x)&31 for x in hrp]
def bech32_encode(hrp,data):
    values=hrp_expand(hrp)+data
    polymod=bech32_polymod(values+[0,0,0,0,0,0]) ^ 1
    checksum=[(polymod>>5*(5-i))&31 for i in range(6)]
    return hrp+'1'+''.join(CHARSET[d] for d in data+checksum)
def convertbits(data,frm,to,pad=True):
    acc=0; bits=0; ret=[]; maxv=(1<<to)-1
    for value in data:
        if value<0 or value>>frm: return None
        acc=(acc<<frm)|value; bits+=frm
        while bits>=to:
            bits-=to; ret.append((acc>>bits)&maxv)
    if pad:
        if bits: ret.append((acc<<(to-bits))&maxv)
    elif bits>=frm or ((acc<<(to-bits))&maxv): return None
    return ret
def escrow(channel,hrp="init"):
    key=("ics20-1"+chr(0)+f"transfer/channel-{channel}").encode()
    h=hashlib.sha256(key).digest()[:20]
    return bech32_encode(hrp,convertbits(h,8,5))
chans={"echelon-1":35,"yominet-1":25,"civitia-1":27,"cabal-1":97,"inertia-2":69,"strat-1":99,"rave-1":38,"embrmainnet-1":62,"moo-1":29,"intergaze-1":66,"noble-1":3,"osmosis-1":71,"neutron-1":37}
for name,ch in chans.items():
    a=escrow(ch)
    try:
        with urllib.request.urlopen(f"https://rest.initia.xyz/cosmos/bank/v1beta1/balances/{a}?pagination.limit=200",timeout=20) as r:
            d=json.load(r)
        bals=d.get("balances",[])
        tot=", ".join(f"{b['amount']} {b['denom'][:24]}" for b in bals) or "0"
    except Exception as e:
        tot=f"ERR {e}"
    print(f"{name:15s} ch-{ch:<3d} {a}  {tot[:180]}")
